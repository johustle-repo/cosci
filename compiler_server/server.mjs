import { createServer } from 'node:http';
import { spawn } from 'node:child_process';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { existsSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const port = Number(process.env.PORT || 8787);
const jobsDirectory = process.env.COSCI_JOBS_DIR || tmpdir();
const maxSourceBytes = 50_000;
const timeoutMs = 7_000;
const ocrTimeoutMs = 35_000;
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

function allowedOrigin(requestOrigin = '') {
  const configured = (process.env.COSCI_ALLOWED_ORIGIN || '*')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  if (configured.includes('*')) return '*';

  const trusted = new Set([
    ...configured,
    'https://psueducode-apk.web.app',
    'https://psueducode-apk.firebaseapp.com',
  ]);
  const isLocalDevelopment = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(
    requestOrigin,
  );
  return trusted.has(requestOrigin) || isLocalDevelopment
    ? requestOrigin
    : configured[0];
}

function headers(requestOrigin = '') {
  return {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': allowedOrigin(requestOrigin),
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type, authorization',
    'cache-control': 'no-store',
    vary: 'Origin',
  };
}

function parseServiceAccount(rawValue) {
  let value = String(rawValue ?? '').trim();
  if (!value) return null;
  if (!value.startsWith('{')) {
    try {
      const decoded = Buffer.from(value, 'base64').toString('utf8').trim();
      if (decoded.startsWith('{')) value = decoded;
    } catch (_) {
      // JSON.parse below will return a clear configuration error.
    }
  }
  if (value.startsWith('"{') && value.endsWith('}"')) value = JSON.parse(value);
  const account = JSON.parse(value);
  if (!account.project_id || !account.client_email || !account.private_key) {
    throw new Error('firebase-admin-invalid-service-account');
  }
  account.private_key = account.private_key.replace(/\\n/g, '\n');
  return account;
}

function firebaseAdmin() {
  if (!getApps().length) {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
    if (process.env.RENDER && !serviceAccountJson) {
      throw new Error('firebase-admin-missing-render-credentials');
    }
    const serviceAccount = parseServiceAccount(serviceAccountJson);
    const credential = serviceAccount
      ? cert(serviceAccount)
      : applicationDefault();
    initializeApp({ credential });
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
  const administratorRole = String(administratorData.role ?? '')
    .trim().toLowerCase().replaceAll('-', '_');
  if (!administrator.exists ||
      !['admin', 'super_admin'].includes(administratorRole) ||
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
  const targetRole = String(targetData.role ?? '')
    .trim().toLowerCase().replaceAll('-', '_');
  if (['admin', 'super_admin'].includes(targetRole)) {
    const userDocuments = await db.collection('users').get();
    const administratorCount = userDocuments.docs.filter((document) => {
      const role = String(document.data().role ?? '')
        .trim().toLowerCase().replaceAll('-', '_');
      return ['admin', 'super_admin'].includes(role) &&
        document.data().isActive !== false &&
        document.data().accountStatus !== 'suspended';
    }).length;
    if (administratorCount <= 1) {
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

function adminApiError(error, sessionLabel = 'admin') {
  const code = String(error?.code ?? '');
  const detail = String(error?.message ?? '');
  const credentialsInvalid =
    detail.includes('default credentials') ||
    detail.includes('Unable to detect a Project Id') ||
    detail.includes('Could not load the default credentials') ||
    detail.includes('firebase-admin-missing-render-credentials') ||
    detail.includes('firebase-admin-invalid-service-account') ||
    detail.includes('Failed to parse private key') ||
    code === 'app/invalid-credential';
  if (credentialsInvalid) {
    return {
      status: 503,
      message: 'The online admin service is missing valid Firebase Admin credentials. Configure FIREBASE_SERVICE_ACCOUNT_JSON on Render and redeploy the service.',
    };
  }
  if (code === 'auth/id-token-expired') {
    return { status: 401, message: `Your ${sessionLabel} session expired. Sign in again and retry.` };
  }
  if (code === 'auth/argument-error' || code === 'auth/invalid-id-token') {
    return { status: 401, message: `The ${sessionLabel} session token is invalid. Sign in again and retry.` };
  }
  if (code.includes('permission-denied') || code === 'auth/insufficient-permission') {
    return {
      status: 403,
      message: 'The Render service account does not have permission to manage Firebase Authentication and Firestore.',
    };
  }
  return {
    status: 500,
    message: `The user account could not be deleted (${code || 'server-error'}). Check the Render service logs for the protected error details.`,
  };
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

function normalizedIdText(value) {
  return String(value ?? '').toUpperCase()
    .replace(/[–—]/g, '-')
    .replace(/\s+/g, ' ')
    .trim();
}

function canonicalStudentNumber(value) {
  const compact = normalizedIdText(value).replace(/[^A-Z0-9]/g, '');
  const match = compact.match(/^(\d{2})([A-Z]{2})(\d{4})$/);
  return match ? `${match[1]}-${match[2]}-${match[3]}` : '';
}

function detectedStudentNumbers(text) {
  const results = new Set();
  const candidates = text.match(/\b\d{2}\s*[- ]?\s*[A-Z]{2}\s*[- ]?\s*\d{4}\b/g) ?? [];
  for (const candidate of candidates) {
    const normalized = canonicalStudentNumber(candidate);
    if (normalized) results.add(normalized);
  }
  return [...results];
}

function detectEligibleProgram(text) {
  if (/B\s*S\s*(?:INFORMATION\s*TECHNOLOGY|IT)\b|\bBSIT\b|BACHELOR\s+OF\s+SCIENCE\s+(?:IN\s+)?INFORMATION\s+TECHNOLOGY/.test(text)) {
    return 'BS Information Technology';
  }
  if (/B\s*S\s*(?:COMPUTER\s*SCIENCE|CS)\b|\bBSCS\b|BACHELOR\s+OF\s+SCIENCE\s+(?:IN\s+)?COMPUTER\s+SCIENCE/.test(text)) {
    return 'BS Computer Science';
  }
  if (/BS\s*(?:MATHEMATICS|MATH)(?:\s*[-–]?\s*CIT)?\b/.test(text)) {
    return 'BS Mathematics';
  }
  if (/\bBSMATH\b|BACHELOR\s+OF\s+SCIENCE\s+(?:IN\s+)?MATHEMATICS/.test(text)) {
    return 'BS Mathematics';
  }
  return null;
}

function normalizeProgramText(value) {
  return String(value ?? '')
    .toUpperCase()
    .replace(/&/g, ' AND ')
    .replace(/[^A-Z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function evaluateCcsEligibility(program) {
  const value = normalizeProgramText(program);
  if (!value || value.length < 4 || ['UNREADABLE', 'UNKNOWN', 'NOT DETECTED', 'N A'].includes(value)) {
    return {
      status: 'reviewRequired',
      normalizedProgram: null,
      message: "We could not clearly verify the student's program. Please review the extracted information or scan the ID again.",
    };
  }
  const accepted = detectEligibleProgram(value);
  if (accepted) {
    return {
      status: 'accepted',
      normalizedProgram: accepted,
      message: 'Student ID verified. The student belongs to the College of Computing Sciences.',
    };
  }
  const validProgram = /\bBACHELOR\b|^BS\s*[A-Z]|\b(BUSINESS ADMINISTRATION|NURSING|ARCHITECTURE|ELEMENTARY EDUCATION|SECONDARY EDUCATION|ENGINEERING|CRIMINOLOGY)\b/.test(value);
  if (validProgram) {
    return {
      status: 'rejected',
      normalizedProgram: String(program).trim(),
      message: `This student is not enrolled in a program under the College of Computing Sciences. Only BS Information Technology, BS Computer Science, and BS Mathematics students are eligible. Detected program: ${String(program).trim()}.`,
    };
  }
  return {
    status: 'reviewRequired',
    normalizedProgram: String(program).trim() || null,
    message: "We could not clearly verify the student's program. Please review the extracted information or scan the ID again.",
  };
}

function extractProgramLine(text) {
  const lines = String(text).split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  const accepted = lines.find((line) => detectEligibleProgram(normalizeProgramText(line)));
  if (accepted) return accepted;
  return lines.find((line) => /\bB\.?\s*S\.?\b|BACHELOR\s+OF\s+SCIENCE|\b(NURSING|ARCHITECTURE|EDUCATION|ENGINEERING|CRIMINOLOGY)\b/i.test(line)) ?? null;
}

function extractStudentName(text, studentNumber) {
  const lines = String(text).split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  const candidates = lines.filter((line) => {
    const normalized = normalizeProgramText(line);
    return normalized.length >= 6 &&
      !/PSU|PANGASINAN|UNIVERSITY|COLLEGE|BACHELOR|\bBS\b|INFORMATION|COMPUTER|MATHEMATICS|TECHNOLOGY|STUDENT|NUMBER|SIGNATURE/.test(normalized) &&
      !/\d/.test(normalized) &&
      /^[A-Z .,'-]+$/.test(normalized);
  });
  return candidates.sort((a, b) => b.length - a.length)[0] ?? null;
}

function comparableText(value) {
  return normalizeProgramText(value)
    .replace(/\b(JR|SR|II|III|IV)\b/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function namesMatch(left, right) {
  const a = comparableText(left);
  const b = comparableText(right);
  if (!a || !b) return false;
  if (a === b) return true;
  const aTokens = new Set(a.split(' ').filter((token) => token.length > 1));
  const bTokens = new Set(b.split(' ').filter((token) => token.length > 1));
  const shared = [...aTokens].filter((token) => bTokens.has(token)).length;
  return shared >= 2 && shared >= Math.min(aTokens.size, bTokens.size) - 1;
}

async function verifyStudentId(request) {
  const authorization = request.headers.authorization || '';
  if (!authorization.startsWith('Bearer ')) {
    return { status: 401, data: { message: 'Authentication required.' } };
  }
  const { auth, db } = firebaseAdmin();
  const identity = await auth.verifyIdToken(authorization.slice(7));
  if (!identity.email_verified) {
    return { status: 403, data: { message: 'Verify your email before submitting a student ID.' } };
  }
  let profileRef = db.collection('users').doc(identity.uid);
  let profileDocument = await profileRef.get();
  if (!profileDocument.exists && identity.email) {
    const emailRef = db.collection('users').doc(String(identity.email).trim().toLowerCase());
    const emailDocument = await emailRef.get();
    if (emailDocument.exists) {
      profileRef = emailRef;
      profileDocument = emailDocument;
    }
  }
  const profile = profileDocument.data() ?? {};
  if (!profileDocument.exists || String(profile.role ?? 'student').toLowerCase() !== 'student') {
    return { status: 403, data: { message: 'Student ID verification is only available to learner accounts.' } };
  }

  const payload = await readJson(request, 7_200_000);
  const action = payload.action === 'confirm' ? 'confirm' : 'scan';
  const enteredStudentNumber = canonicalStudentNumber(payload.studentNumber);
  if (String(payload.studentNumber ?? '').trim() && !enteredStudentNumber) {
    return { status: 400, data: { message: 'Check the student number, or leave it blank so CoSci can read it from the ID.' } };
  }
  const mimeType = String(payload.mimeType ?? '').toLowerCase();
  if (!['image/jpeg', 'image/jpg', 'image/png'].includes(mimeType)) {
    return { status: 400, data: { message: 'Upload a JPG or PNG image.' } };
  }
  const image = Buffer.from(String(payload.imageBase64 ?? ''), 'base64');
  if (!image.length || image.length > 5_000_000) {
    return { status: 400, data: { message: 'Upload a valid ID image smaller than 5 MB.' } };
  }

  const directory = await mkdtemp(join(jobsDirectory, 'cosci-id-'));
  try {
    const fileName = mimeType === 'image/png' ? 'student-id.png' : 'student-id.jpg';
    const preparedName = 'student-id-prepared.png';
    await writeFile(join(directory, fileName), image);

    // Phone photos of laminated IDs often contain glare, a rotated EXIF
    // orientation, and a much larger resolution than OCR needs. Preparing a
    // compact, high-contrast copy makes recognition both faster and more
    // reliable while preserving the original only for the duration of this
    // request.
    const prepared = await run(
      'convert',
      [
        fileName,
        '-auto-orient',
        '-resize', '1800x1800>',
        '-colorspace', 'Gray',
        '-contrast-stretch', '1%x1%',
        '-sharpen', '0x1',
        preparedName,
      ],
      directory,
      '',
      15_000,
    );
    const ocrInput = prepared.code === 0 ? preparedName : fileName;
    let ocr = await run(
      'tesseract',
      [ocrInput, 'stdout', '--psm', '11', '-l', 'eng', '-c', 'preserve_interword_spaces=1'],
      directory,
      '',
      ocrTimeoutMs,
    );
    // Sparse mode works best for the separated labels on PSU IDs. If it found
    // too little text, retry once in uniform-block mode.
    if (ocr.code === 0 && normalizedIdText(ocr.stdout).length < 20) {
      ocr = await run(
        'tesseract',
        [ocrInput, 'stdout', '--psm', '6', '-l', 'eng'],
        directory,
        '',
        ocrTimeoutMs,
      );
    }
    if (ocr.code !== 0) {
      const analyzerMissing = ocr.code === 127 || /not found|unavailable|enoent|error opening data file|failed loading language/i.test(ocr.stderr);
      const analyzerTimedOut = ocr.code === 124;
      process.stderr.write(
        `Student ID OCR failed (code ${ocr.code}): ${ocr.stderr || 'No diagnostic output.'}\n`,
      );
      return {
        status: 503,
        data: {
          code: analyzerMissing
            ? 'id-analyzer-not-installed'
            : analyzerTimedOut
              ? 'id-analyzer-timeout'
              : 'id-analyzer-failed',
          fields: {
            institution: '',
            studentName: String(profile.displayName ?? ''),
            studentNumber: enteredStudentNumber || '',
            program: String(profile.program ?? ''),
          },
          status: 'reviewRequired',
          message: analyzerMissing
            ? 'Student ID verification is being updated. Please try again shortly.'
            : analyzerTimedOut
              ? 'Automatic text extraction took too long. Review the information below and correct it using the visible ID.'
              : 'The ID photo could not be analyzed. Upload a clear JPG or PNG showing the complete card and try again.',
        },
      };
    }
    const text = normalizedIdText(ocr.stdout);
    const hasPsuBranding = /\bPSU\b|PANGASINAN\s+STATE\s+UNIVERSITY/.test(text);
    const extractedProgram = extractProgramLine(ocr.stdout);
    const detectedProgram = detectEligibleProgram(text);
    const detectedNumbers = detectedStudentNumbers(text);
    const studentNumber = enteredStudentNumber || detectedNumbers[0] || '';
    const fields = {
      institution: hasPsuBranding ? 'Pangasinan State University' : null,
      studentName: extractStudentName(ocr.stdout, studentNumber),
      studentNumber: studentNumber || null,
      program: extractedProgram || detectedProgram,
    };

    if (action === 'scan') {
      const eligibility = evaluateCcsEligibility(fields.program);
      return {
        status: 200,
        data: { ...eligibility, fields },
      };
    }

    const corrected = payload.fields && typeof payload.fields === 'object' ? payload.fields : {};
    const confirmedFields = {
      institution: String(corrected.institution ?? '').trim(),
      studentName: String(corrected.studentName ?? '').trim(),
      studentNumber: canonicalStudentNumber(corrected.studentNumber),
      program: String(corrected.program ?? '').trim(),
    };
    const eligibility = evaluateCcsEligibility(confirmedFields.program);
    if (eligibility.status !== 'accepted') {
      return { status: 200, data: { ...eligibility, fields: confirmedFields } };
    }
    if (!hasPsuBranding || !/PANGASINAN\s+STATE\s+UNIVERSITY|\bPSU\b/i.test(confirmedFields.institution)) {
      return { status: 200, data: { status: 'reviewRequired', normalizedProgram: eligibility.normalizedProgram, message: 'The PSU institution could not be confirmed from this ID. Please scan the complete PSU ID again.', fields: confirmedFields } };
    }
    if (!confirmedFields.studentName || !confirmedFields.studentNumber) {
      return { status: 200, data: { status: 'reviewRequired', normalizedProgram: eligibility.normalizedProgram, message: "We could not clearly verify the student's name or student number. Please review the extracted information or scan the ID again.", fields: confirmedFields } };
    }
    if (!namesMatch(confirmedFields.studentName, profile.displayName)) {
      return { status: 200, data: { status: 'reviewRequired', normalizedProgram: eligibility.normalizedProgram, message: 'The name on the ID does not clearly match the registered learner name. Please review it or contact your CCS administrator.', fields: confirmedFields } };
    }
    const registeredEligibility = evaluateCcsEligibility(profile.program);
    if (registeredEligibility.status !== 'accepted' || registeredEligibility.normalizedProgram !== eligibility.normalizedProgram) {
      return { status: 200, data: { status: 'reviewRequired', normalizedProgram: eligibility.normalizedProgram, message: 'The corrected ID program does not match the program registered on this learner account.', fields: confirmedFields } };
    }

    const idHash = createHash('sha256').update(confirmedFields.studentNumber).digest('hex');
    const duplicate = await db.collection('users').where('schoolIdHash', '==', idHash).get();
    if (duplicate.docs.some((document) => document.id !== profileRef.id)) {
      return { status: 200, data: { status: 'rejected', normalizedProgram: eligibility.normalizedProgram, message: 'This student number is already linked to another CoSci account. Contact your CCS administrator.', fields: confirmedFields } };
    }

    const verification = {
      status: 'approved',
      normalizedProgram: eligibility.normalizedProgram,
      institution: confirmedFields.institution,
      studentName: confirmedFields.studentName,
      studentNumber: confirmedFields.studentNumber,
      reviewedAt: new Date(),
      method: 'server_ocr_reviewed_rules',
    };
    await profileRef.set({
      idVerificationStatus: 'approved',
      id_verification_status: 'approved',
      schoolIdHash: idHash,
      schoolIdVerification: verification,
      school_id_verification: verification,
      updatedAt: new Date(),
      updated_at: new Date(),
    }, { merge: true });
    return { status: 200, data: { ...eligibility, fields: { ...confirmedFields, program: eligibility.normalizedProgram } } };
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

function send(response, status, data) {
  response.writeHead(status, headers(response.requestOrigin));
  response.end(JSON.stringify(data));
}

async function readJson(request, maxBytes = maxSourceBytes * 2) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > maxBytes) throw new Error('Request is too large.');
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function run(command, args, cwd, stdin = '', executionTimeoutMs = timeoutMs) {
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
    }, executionTimeoutMs);
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
  response.requestOrigin = request.headers.origin || '';
  if (request.method === 'OPTIONS') return send(response, 204, {});
  if (request.method === 'GET' && (request.url === '/' || request.url === '/health')) {
    return send(response, 200, {
      service: 'CoSci Compiler',
      status: 'online',
      executeEndpoint: '/api/v2/execute',
      runtimesEndpoint: '/api/v2/runtimes',
      adminApiConfigured: Boolean(process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim()),
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
      const failure = adminApiError(error);
      process.stderr.write(`Delete user failed: ${error?.stack ?? error}\n`);
      return send(response, failure.status, { message: failure.message });
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
  if (request.method === 'POST' && request.url === '/student/id/verify') {
    try {
      const result = await verifyStudentId(request);
      return send(response, result.status, result.data);
    } catch (error) {
      process.stderr.write(`Student ID verification failed: ${error?.stack ?? error}\n`);
      const failure = adminApiError(error, 'student');
      const message = failure.status === 500
        ? 'The ID analyzer could not complete this request. Please try again.'
        : failure.message;
      return send(response, failure.status, { message });
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
