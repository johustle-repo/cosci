import { spawn } from 'node:child_process';

const compilerOrigin = process.env.COSCI_COMPILER_ORIGIN?.trim()
  || 'http://localhost:8787';
const healthUrl = `${compilerOrigin}/api/v2/runtimes`;
const executeUrl = `${compilerOrigin}/api/v2/execute`;
const quizEvaluatorUrl = `${compilerOrigin}/quiz/evaluate`;
const isWindows = process.platform === 'win32';
const flutterCommand = isWindows ? 'flutter.bat' : 'flutter';

let compilerProcess;
let flutterProcess;
let shuttingDown = false;

async function compilerIsOnline() {
  try {
    const response = await fetch(healthUrl, {
      signal: AbortSignal.timeout(1500),
    });
    return response.ok;
  } catch (_) {
    return false;
  }
}

async function waitForCompiler() {
  for (let attempt = 1; attempt <= 20; attempt += 1) {
    if (await compilerIsOnline()) return;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`Compiler did not become ready at ${healthUrl}.`);
}

function stopChildren(exitCode = 0) {
  if (shuttingDown) return;
  shuttingDown = true;
  if (flutterProcess && !flutterProcess.killed) flutterProcess.kill('SIGTERM');
  if (compilerProcess && !compilerProcess.killed) compilerProcess.kill('SIGTERM');
  process.exitCode = exitCode;
}

process.on('SIGINT', () => stopChildren(130));
process.on('SIGTERM', () => stopChildren(143));

if (await compilerIsOnline()) {
  process.stdout.write(`Using compiler already running at ${compilerOrigin}.\n`);
} else {
  process.stdout.write('Starting the bundled CoSci compiler service...\n');
  compilerProcess = spawn(
    process.execPath,
    ['compiler_server/server.mjs'],
    { cwd: process.cwd(), env: process.env, stdio: 'inherit' },
  );
  compilerProcess.on('error', (error) => {
    process.stderr.write(`Could not start compiler service: ${error.message}\n`);
    stopChildren(1);
  });
  compilerProcess.on('exit', (code) => {
    if (!shuttingDown && code !== 0) {
      process.stderr.write(`Compiler service stopped with exit code ${code}.\n`);
      stopChildren(code ?? 1);
    }
  });
}

try {
  await waitForCompiler();
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  stopChildren(1);
  process.exit();
}

process.stdout.write('Compiler is ready. Starting CoSci in Chrome...\n');
flutterProcess = spawn(
  flutterCommand,
  [
    'run',
    '-d',
    'chrome',
    `--dart-define=COMPILER_API_URL=${executeUrl}`,
    `--dart-define=QUIZ_EVALUATOR_URL=${quizEvaluatorUrl}`,
  ],
  { cwd: process.cwd(), env: process.env, stdio: 'inherit' },
);
flutterProcess.on('error', (error) => {
  process.stderr.write(`Could not start Flutter: ${error.message}\n`);
  stopChildren(1);
});
flutterProcess.on('exit', (code) => stopChildren(code ?? 0));
