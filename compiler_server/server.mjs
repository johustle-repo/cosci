import { createServer } from 'node:http';
import { spawn } from 'node:child_process';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { existsSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const port = Number(process.env.PORT || 8787);
const jobsDirectory = process.env.COSCI_JOBS_DIR || tmpdir();
const maxSourceBytes = 50_000;
const timeoutMs = 7_000;
const maxConcurrentJobs = 2;
let activeJobs = 0;

// Include the standard MSYS2 UCRT64 toolchain automatically on Windows. This
// keeps the bundled compiler service working even when it was launched from a
// terminal that has not yet reloaded the user's updated PATH.
const projectRoot = dirname(dirname(fileURLToPath(import.meta.url)));

function bundledJdkBin() {
  const root = join(projectRoot, '.tools', 'jdk21');
  if (!existsSync(root)) return '';
  for (const name of readdirSync(root)) {
    const bin = join(root, name, 'bin');
    if (existsSync(join(bin, process.platform === 'win32' ? 'javac.exe' : 'javac'))) {
      return bin;
    }
  }
  return '';
}

const jdkBin = bundledJdkBin();
const compilerPath = process.platform === 'win32'
  ? [jdkBin, 'C:\\msys64\\ucrt64\\bin', process.env.PATH ?? ''].filter(Boolean).join(';')
  : (process.env.PATH ?? '');

const runtimes = [
  { language: 'c++', version: 'system', aliases: ['cpp', 'gcc'] },
  { language: 'java', version: 'system', aliases: [] },
  { language: 'javascript', version: process.version, aliases: ['js', 'node'] },
];

function headers() {
  return {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': process.env.COSCI_ALLOWED_ORIGIN || '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type, authorization',
    'cache-control': 'no-store',
  };
}

function firebaseAdmin() {
  if (!getApps().length) {
    initializeApp({ credential: applicationDefault() });
  }
  return { auth: getAuth(), db: getFirestore() };
}

async function deleteUserAccount(request) {
  const authorization = request.headers.authorization || '';
  if (!authorization.startsWith('Bearer ')) {
    return { status: 401, data: { message: 'Authentication required.' } };
  }
  const { auth, db } = firebaseAdmin();
  const identity = await auth.verifyIdToken(authorization.slice(7));
  const administrator = await db.collection('users').doc(identity.uid).get();
  const administratorData = administrator.data() ?? {};
  if (!administrator.exists || administratorData.role !== 'admin' ||
      administratorData.isActive === false ||
      administratorData.accountStatus === 'suspended') {
    return {
      status: 403,
      data: { message: 'Only an active administrator can delete accounts.' },
    };
  }

  const payload = await readJson(request);
  const targetUid = String(payload.uid ?? '').trim();
  if (!targetUid) return { status: 400, data: { message: 'A user ID is required.' } };
  if (targetUid === identity.uid) {
    return {
      status: 409,
      data: { message: 'You cannot delete your own administrator account.' },
    };
  }
  const target = await db.collection('users').doc(targetUid).get();
  if (!target.exists) {
    return { status: 404, data: { message: 'The user account no longer exists.' } };
  }
  const targetData = target.data() ?? {};
  if (targetData.role === 'admin') {
    const administrators = await db.collection('users')
      .where('role', '==', 'admin').get();
    if (administrators.size <= 1) {
      return {
        status: 409,
        data: { message: 'The last administrator account cannot be deleted.' },
      };
    }
  }

  try {
    await auth.deleteUser(targetUid);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  const legacyUserDocuments = await db.collection('users')
    .where('uid', '==', targetUid).get();
  const accountDocuments = new Map([
    [db.collection('users').doc(targetUid).path, db.collection('users').doc(targetUid)],
    ...legacyUserDocuments.docs.map((document) => [document.ref.path, document.ref]),
  ]);
  for (const document of [
    ...accountDocuments.values(),
    db.collection('user_profiles').doc(targetUid),
    db.collection('progress').doc(targetUid),
  ]) {
    await db.recursiveDelete(document);
  }
  const attempts = await db.collection('quiz_attempts')
    .where('userId', '==', targetUid).get();
  const batch = db.batch();
  for (const attempt of attempts.docs) batch.delete(attempt.ref);
  batch.set(db.collection('activity_logs').doc(), {
    actionType: 'delete',
    targetModule: 'users',
    targetId: targetUid,
    description: `Deleted account: ${targetData.displayName ?? targetData.email ?? targetUid}`,
    previousValue: targetData,
    newValue: null,
    adminUid: identity.uid,
    adminEmail: identity.email ?? null,
    timestamp: new Date(),
  });
  await batch.commit();
  return { status: 200, data: { deleted: true, uid: targetUid } };
}

function normalizeAnswer(value) {
  return String(value ?? '')
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .join('\n')
    .toLowerCase();
}

async function evaluateQuiz(request) {
  const authorization = request.headers.authorization || '';
  if (!authorization.startsWith('Bearer ')) {
    return { status: 401, data: { message: 'Authentication required.' } };
  }

  const { auth, db } = firebaseAdmin();
  const identity = await auth.verifyIdToken(authorization.slice(7));
  const payload = await readJson(request);
  const quizId = String(payload.quizId ?? '').trim();
  const answers = payload.answers;
  if (!quizId || !answers || typeof answers !== 'object' || Array.isArray(answers)) {
    return { status: 400, data: { message: 'Invalid quiz submission.' } };
  }

  const quizRef = db.collection('quizzes').doc(quizId);
  const [quizDocument, questions, profileDocument] = await Promise.all([
    quizRef.get(),
    quizRef.collection('questions').get(),
    db.collection('users').doc(identity.uid).get(),
  ]);
  if (!quizDocument.exists || quizDocument.data()?.isPublished !== true) {
    return { status: 404, data: { message: 'Published quiz not found.' } };
  }
  if (questions.empty || Object.keys(answers).length !== questions.size) {
    return { status: 400, data: { message: 'Answer every question before submitting.' } };
  }

  const quiz = quizDocument.data() ?? {};
  const profile = profileDocument.data() ?? {};
  const attemptLimit = Math.max(1, Number(quiz.attemptLimit ?? 3));
  const previousSnapshot = await db.collection('quiz_attempts')
    .where('userId', '==', identity.uid).get();
  const previousAttempts = previousSnapshot.docs
    .filter((document) => document.data().quizId === quizId);
  if (previousAttempts.length >= attemptLimit) {
    return {
      status: 429,
      data: { message: `Attempt limit reached (${attemptLimit}).` },
    };
  }

  const answerKeySnapshots = await Promise.all(
    questions.docs.map((question) => db.collection('quiz_answer_keys')
      .doc(quizId).collection('questions').doc(question.id).get()),
  );
  let correct = 0;
  const feedback = {};
  const questionOutcomes = {};
  for (let index = 0; index < questions.docs.length; index += 1) {
    const question = questions.docs[index];
    const key = answerKeySnapshots[index];
    const correctAnswer = String(key.data()?.correctAnswer ?? '').trim();
    if (!key.exists || !correctAnswer) {
      return {
        status: 409,
        data: { message: 'This quiz is missing its secure answer key.' },
      };
    }
    const isCorrect = normalizeAnswer(answers[question.id]) ===
      normalizeAnswer(correctAnswer);
    if (isCorrect) correct += 1;
    questionOutcomes[question.id] = isCorrect;
    feedback[question.id] = {
      correct: isCorrect,
      correctAnswer,
      explanation: key.data()?.explanation ?? '',
    };
  }

  const scorePercent = Math.round(correct * 100 / questions.size);
  const passed = scorePercent >= Number(quiz.passingScore ?? 80);
  const attemptNumber = previousAttempts.length + 1;
  await db.collection('quiz_attempts').add({
    userId: identity.uid,
    quizId,
    title: quiz.title ?? 'Quiz',
    scorePercent,
    correct,
    total: questions.size,
    passed,
    attemptNumber,
    answers,
    language: quiz.language ?? 'C++',
    errorFocus: quiz.errorFocus ?? 'concept',
    topic: quiz.topic ?? 'General',
    program: profile.program ?? 'Unknown',
    yearLevel: profile.yearLevel ?? 'Unknown',
    questionOutcomes,
    createdAt: new Date(),
  });

  return {
    status: 200,
    data: {
      scorePercent,
      correct,
      total: questions.size,
      passed,
      attemptNumber,
      attemptsRemaining: attemptLimit - attemptNumber,
      feedback,
    },
  };
}

function send(response, status, data) {
  response.writeHead(status, headers());
  response.end(JSON.stringify(data));
}

async function readJson(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > maxSourceBytes * 2) throw new Error('Request is too large.');
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function run(command, args, cwd, stdin = '') {
  return new Promise((resolve) => {
    const child = spawn(command, args, {
      cwd,
      shell: false,
      windowsHide: true,
      env: { ...process.env, PATH: compilerPath },
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    let stdout = '';
    let stderr = '';
    let timedOut = false;
    const timer = setTimeout(() => {
      timedOut = true;
      child.kill('SIGKILL');
    }, timeoutMs);
    child.stdout.on('data', (data) => {
      if (stdout.length < maxSourceBytes) stdout += data.toString();
    });
    child.stderr.on('data', (data) => {
      if (stderr.length < maxSourceBytes) stderr += data.toString();
    });
    child.on('error', (error) => {
      clearTimeout(timer);
      resolve({ code: 127, stdout: '', stderr: `Runtime unavailable: ${error.message}` });
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      resolve({
        code: timedOut ? 124 : (code ?? 1),
        stdout,
        stderr: timedOut ? 'Execution timed out.' : stderr,
      });
    });
    child.stdin.end(stdin);
  });
}

function normalizeLanguage(value = '') {
  const language = String(value).toLowerCase();
  if (['c++', 'cpp', 'gcc'].includes(language)) return 'c++';
  if (language === 'java') return 'java';
  if (['javascript', 'js', 'node'].includes(language)) return 'javascript';
  return '';
}

function javaEntryPoint(source, requestedName = '') {
  const publicType = source.match(
    /\bpublic\s+(?:(?:final|abstract)\s+)?(?:class|interface|enum|record)\s+([A-Za-z_$][A-Za-z0-9_$]*)/,
  )?.[1];
  if (publicType) return publicType;

  const safeRequestedName = String(requestedName).match(
    /^([A-Za-z_$][A-Za-z0-9_$]*)\.java$/,
  )?.[1];
  if (safeRequestedName) return safeRequestedName;

  const mainType = source.match(
    /\bclass\s+([A-Za-z_$][A-Za-z0-9_$]*)[\s\S]*?\bstatic\s+void\s+main\s*\(/,
  )?.[1];
  return mainType || 'Main';
}

async function execute(payload) {
  const language = normalizeLanguage(payload.language);
  const source = payload.files?.[0]?.content;
  const requestedFileName = payload.files?.[0]?.name;
  const stdin = typeof payload.stdin === 'string' ? payload.stdin : '';
  if (!language) throw new Error('Supported languages are C++, Java, and JavaScript.');
  if (typeof source !== 'string' || !source.trim()) throw new Error('Source code is required.');
  if (Buffer.byteLength(source, 'utf8') > maxSourceBytes) throw new Error('Source code exceeds 50 KB.');
  if (activeJobs >= maxConcurrentJobs) throw new Error('Compiler is busy. Try again shortly.');

  activeJobs += 1;
  let directory = '';
  try {
    directory = await mkdtemp(join(jobsDirectory, 'cosci-'));
    if (language === 'javascript') {
      await writeFile(join(directory, 'main.js'), source, 'utf8');
      const result = await run('node', ['--no-warnings', 'main.js'], directory, stdin);
      return { language, version: process.version, run: result };
    }
    if (language === 'c++') {
      await writeFile(join(directory, 'main.cpp'), source, 'utf8');
      const executable = process.platform === 'win32' ? 'program.exe' : 'program';
      const compile = await run(
        'g++',
        ['-std=c++17', '-O0', '-Wall', '-Wextra', 'main.cpp', '-o', executable],
        directory,
      );
      if (compile.code !== 0) return { language, version: 'system', compile };
      const runResult = await run(
        process.platform === 'win32' ? executable : `./${executable}`,
        [],
        directory,
        stdin,
      );
      return { language, version: 'system', compile: { code: 0, stdout: '', stderr: '' }, run: runResult };
    }
    const javaClass = javaEntryPoint(source, requestedFileName);
    const javaFile = `${javaClass}.java`;
    await writeFile(join(directory, javaFile), source, 'utf8');
    const compile = await run('javac', ['-encoding', 'UTF-8', javaFile], directory);
    if (compile.code !== 0) return { language, version: 'system', compile };
    const runResult = await run('java', ['-Xmx128m', '-cp', directory, javaClass], directory, stdin);
    return { language, version: 'system', compile: { code: 0, stdout: '', stderr: '' }, run: runResult };
  } finally {
    activeJobs -= 1;
    if (directory) await rm(directory, { recursive: true, force: true });
  }
}

createServer(async (request, response) => {
  if (request.method === 'OPTIONS') return send(response, 204, {});
  if (request.method === 'GET' && (request.url === '/' || request.url === '/health')) {
    return send(response, 200, {
      service: 'CoSci Compiler',
      status: 'online',
      executeEndpoint: '/api/v2/execute',
      runtimesEndpoint: '/api/v2/runtimes',
      note: 'Submit code to the execute endpoint using an HTTP POST request.',
    });
  }
  if (request.method === 'GET' && request.url === '/favicon.ico') {
    response.writeHead(204, { 'cache-control': 'public, max-age=86400' });
    return response.end();
  }
  if (request.method === 'GET' && request.url === '/api/v2/runtimes') {
    return send(response, 200, runtimes);
  }
  if (request.method === 'POST' && request.url === '/admin/users/delete') {
    try {
      const result = await deleteUserAccount(request);
      return send(response, result.status, result.data);
    } catch (error) {
      const missingCredentials = String(error?.message ?? '').includes(
        'default credentials',
      );
      const message = missingCredentials
        ? 'Firebase Admin credentials are not configured on the local server.'
        : error?.code === 'auth/id-token-expired'
          ? 'Your admin session expired. Sign in again and retry.'
          : error?.code === 'auth/argument-error'
            ? 'The admin session token is invalid. Sign in again and retry.'
            : `The user account could not be deleted (${error?.code ?? 'server-error'}).`;
      process.stderr.write(`Delete user failed: ${error?.stack ?? error}\n`);
      return send(response, 500, { message });
    }
  }
  if (request.method === 'POST' && request.url === '/quiz/evaluate') {
    try {
      const result = await evaluateQuiz(request);
      return send(response, result.status, result.data);
    } catch (error) {
      const missingCredentials = String(error?.message ?? '').includes(
        'default credentials',
      );
      const message = missingCredentials
        ? 'Firebase Admin credentials are not configured on the local server.'
        : error?.code === 'auth/id-token-expired'
          ? 'Your session expired. Sign in again and retry.'
          : 'Secure quiz grading could not be completed.';
      process.stderr.write(`Quiz evaluation failed: ${error?.stack ?? error}\n`);
      return send(response, 500, { message });
    }
  }
  if (request.method !== 'POST' || request.url !== '/api/v2/execute') {
    return send(response, 404, { error: 'Not found.' });
  }
  try {
    const result = await execute(await readJson(request));
    return send(response, 200, result);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Compiler request failed.';
    return send(response, message.includes('busy') ? 429 : 400, { error: message });
  }
}).listen(port, '0.0.0.0', () => {
  process.stdout.write(`CoSci compiler listening on http://localhost:${port}/api/v2/execute\n`);
  process.stdout.write(`CoSci admin API listening on http://localhost:${port}/admin/users/delete\n`);
  process.stdout.write(`CoSci quiz evaluator listening on http://localhost:${port}/quiz/evaluate\n`);
});
