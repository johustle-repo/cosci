const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();
const compilerApiUrl = defineSecret('COMPILER_API_URL');

const normalize = (value) => String(value ?? '')
  .split(/\r?\n/)
  .map((line) => line.trim())
  .filter(Boolean)
  .join('\n');

const files = {
  'c++': 'main.cpp',
  java: 'Main.java',
  javascript: 'main.js',
};

exports.evaluateSimulation = onRequest(
  { timeoutSeconds: 60, memory: '256MiB', cors: true,
    secrets: [compilerApiUrl] },
  async (request, response) => {
    if (request.method !== 'POST') {
      response.status(405).json({ message: 'POST required.' });
      return;
    }
    try {
      const authorization = request.get('Authorization');
      if (!authorization.startsWith('Bearer ')) {
        response.status(401).json({ message: 'Authentication required.' });
        return;
      }
      await getAuth().verifyIdToken(authorization.slice(7));
      const { activityId, language, sourceCode } = request.body ?? {};
      if (!activityId || !files[language] || !String(sourceCode).trim()) {
        response.status(400).json({ message: 'Invalid evaluation request.' });
        return;
      }
      if (Buffer.byteLength(sourceCode, 'utf8') > 50000) {
        response.status(413).json({ message: 'Source code exceeds 50 KB.' });
        return;
      }
      const compilerUrl = compilerApiUrl.value();
      if (!compilerUrl) {
        response.status(503).json({ message: 'Compiler service is not configured.' });
        return;
      }
      const privateDocument = await getFirestore()
        .collection('simulation_private_tests').doc(activityId).get();
      if (!privateDocument.exists) {
        response.status(404).json({ message: 'Trusted tests are unavailable.' });
        return;
      }
      const tests = privateDocument.data().testCases ?? [];
      let passedTests = 0;
      for (const test of tests) {
        const compilerResponse = await fetch(compilerUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            language,
            version: '*',
            files: [{ name: files[language], content: sourceCode }],
            compile_timeout: 10000,
            run_timeout: 5000,
            stdin: test.stdin ?? '',
          }),
          signal: AbortSignal.timeout(20000),
        });
        if (!compilerResponse.ok) {
          response.status(503).json({ message: 'Compiler service unavailable.' });
          return;
        }
        const execution = await compilerResponse.json();
        const compileFailed = (execution.compile?.code ?? 0) !== 0;
        const runFailed = (execution.run?.code ?? 0) !== 0;
        if (!compileFailed && !runFailed &&
            normalize(execution.run?.stdout) === normalize(test.expectedOutput)) {
          passedTests += 1;
        }
      }
      const passed = tests.length > 0 && passedTests === tests.length;
      response.json({
        passed,
        passedTests,
        totalTests: tests.length,
        message: passed
          ? 'All trusted tests passed.'
          : 'A hidden case failed. Review how the algorithm handles other inputs.',
      });
    } catch (error) {
      response.status(500).json({ message: 'Trusted evaluation could not be completed.' });
    }
  },
);

exports.deleteUserAccount = onRequest(
  { timeoutSeconds: 60, memory: '256MiB', cors: true },
  async (request, response) => {
    if (request.method !== 'POST') {
      response.status(405).json({ message: 'POST required.' });
      return;
    }
    try {
      const authorization = request.get('Authorization');
      if (!authorization.startsWith('Bearer ')) {
        response.status(401).json({ message: 'Authentication required.' });
        return;
      }
      const identity = await getAuth().verifyIdToken(authorization.slice(7));
      const db = getFirestore();
      const administrator = await db.collection('users').doc(identity.uid).get();
      const administratorData = administrator.data() ?? {};
      if (!administrator.exists || administratorData.role !== 'admin' ||
          administratorData.isActive === false ||
          administratorData.accountStatus === 'suspended') {
        response.status(403).json({ message: 'Only an active administrator can delete accounts.' });
        return;
      }

      const targetUid = String(request.body?.uid ?? '').trim();
      if (!targetUid) {
        response.status(400).json({ message: 'A user ID is required.' });
        return;
      }
      if (targetUid === identity.uid) {
        response.status(409).json({ message: 'You cannot delete your own administrator account.' });
        return;
      }
      const target = await db.collection('users').doc(targetUid).get();
      if (!target.exists) {
        response.status(404).json({ message: 'The user account no longer exists.' });
        return;
      }
      const targetData = target.data() ?? {};
      if (targetData.role === 'admin') {
        const administrators = await db.collection('users')
          .where('role', '==', 'admin').get();
        if (administrators.size <= 1) {
          response.status(409).json({ message: 'The last administrator account cannot be deleted.' });
          return;
        }
      }

      // Remove authentication first so a partially completed cleanup can never
      // leave an account able to sign in without its authorization profile.
      try {
        await getAuth().deleteUser(targetUid);
      } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
      }

      const rootDocuments = [
        db.collection('users').doc(targetUid),
        db.collection('user_profiles').doc(targetUid),
        db.collection('progress').doc(targetUid),
      ];
      for (const document of rootDocuments) {
        await db.recursiveDelete(document);
      }

      // Quiz attempts are top-level records; user-owned simulation and lesson
      // attempts are removed by recursiveDelete(users/{uid}).
      const quizAttempts = await db.collection('quiz_attempts')
        .where('userId', '==', targetUid).get();
      const deleteBatch = db.batch();
      for (const attempt of quizAttempts.docs) deleteBatch.delete(attempt.ref);
      deleteBatch.set(db.collection('activity_logs').doc(), {
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
      await deleteBatch.commit();
      response.json({ deleted: true, uid: targetUid });
    } catch (error) {
      console.error('deleteUserAccount failed', error);
      response.status(500).json({ message: 'The user account could not be deleted.' });
    }
  },
);

exports.evaluateQuiz = onRequest(
  { timeoutSeconds: 30, memory: '256MiB', cors: true },
  async (request, response) => {
    if (request.method !== 'POST') {
      response.status(405).json({ message: 'POST required.' });
      return;
    }
    try {
      const authorization = request.get('Authorization');
      if (!authorization.startsWith('Bearer ')) {
        response.status(401).json({ message: 'Authentication required.' });
        return;
      }
      const identity = await getAuth().verifyIdToken(authorization.slice(7));
      const { quizId, answers } = request.body ?? {};
      if (!quizId || !answers || typeof answers !== 'object' || Array.isArray(answers)) {
        response.status(400).json({ message: 'Invalid quiz submission.' });
        return;
      }
      const db = getFirestore();
      const quizRef = db.collection('quizzes').doc(String(quizId));
      const quizDoc = await quizRef.get();
      if (!quizDoc.exists || quizDoc.data().isPublished !== true) {
        response.status(404).json({ message: 'Published quiz not found.' });
        return;
      }
      const quiz = quizDoc.data();
      const profileDoc = await db.collection('users').doc(identity.uid).get();
      const profile = profileDoc.data() ?? {};
      const attemptLimit = Math.max(1, Number(quiz.attemptLimit ?? 3));
      const attemptsRef = db.collection('quiz_attempts');
      const previous = await attemptsRef.where('userId', '==', identity.uid)
        .where('quizId', '==', String(quizId)).get();
      if (previous.size >= attemptLimit) {
        response.status(429).json({ message: `Attempt limit reached (${attemptLimit}).` });
        return;
      }
      const questions = await quizRef.collection('questions').get();
      if (questions.empty || Object.keys(answers).length !== questions.size) {
        response.status(400).json({ message: 'Answer every question before submitting.' });
        return;
      }
      let correct = 0;
      const feedback = {};
      const questionOutcomes = {};
      for (const question of questions.docs) {
        const key = await db.collection('quiz_answer_keys').doc(String(quizId))
          .collection('questions').doc(question.id).get();
        if (!key.exists || !String(key.data().correctAnswer ?? '').trim()) {
          response.status(409).json({ message: 'This quiz has not migrated to secure answer keys.' });
          return;
        }
        const selected = String(answers[question.id] ?? '');
        const isCorrect = normalize(selected).toLowerCase() ===
          normalize(key.data().correctAnswer).toLowerCase();
        if (isCorrect) correct += 1;
        questionOutcomes[question.id] = isCorrect;
        feedback[question.id] = {
          correct: isCorrect,
          correctAnswer: key.data().correctAnswer,
          explanation: key.data().explanation ?? '',
        };
      }
      const scorePercent = Math.round(correct * 100 / questions.size);
      const passed = scorePercent >= Number(quiz.passingScore ?? 80);
      const attemptRef = attemptsRef.doc();
      await attemptRef.set({
        userId: identity.uid, quizId: String(quizId), title: quiz.title ?? 'Quiz', scorePercent,
        correct, total: questions.size, passed, attemptNumber: previous.size + 1,
        answers, language: quiz.language ?? 'C++', errorFocus: quiz.errorFocus ?? 'concept',
        topic: quiz.topic ?? 'General', program: profile.program ?? 'Unknown',
        yearLevel: profile.yearLevel ?? 'Unknown',
        questionOutcomes,
        createdAt: new Date(),
      });
      response.json({ scorePercent, correct, total: questions.size, passed,
        attemptNumber: previous.size + 1, attemptsRemaining: attemptLimit - previous.size - 1,
        feedback });
    } catch (error) {
      response.status(500).json({ message: 'Secure quiz grading could not be completed.' });
    }
  },
);
