import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'psueducode-apk',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/student-1'), {
      uid: 'student-1', email: 'student@psu.edu.ph', role: 'student', accountStatus: 'active',
      program: 'BS Computer Science', yearLevel: '1st Year',
    });
    await setDoc(doc(context.firestore(), 'users/instructor-1'), {
      uid: 'instructor-1', email: 'instructor@psu.edu.ph', role: 'instructor', accountStatus: 'active',
    });
    await setDoc(doc(context.firestore(), 'users/student-1/simulation_attempts/attempt-1'), {
      title: 'Loops', sourceCode: 'code', result: 'possibleLogicError',
    });
  });
});

after(async () => environment.cleanup());

test('student cannot read another learner attempt', async () => {
  const db = () => environment.authenticatedContext('student-2', { email: 'other@psu.edu.ph' }).firestore();
  await assertFails(getDoc(doc(db(), 'users/student-1/simulation_attempts/attempt-1')));
});

test('instructor can read attempts and update feedback only', async () => {
  const db = environment.authenticatedContext('instructor-1', { email: 'instructor@psu.edu.ph' }).firestore();
  const attempt = doc(db, 'users/student-1/simulation_attempts/attempt-1');
  await assertSucceeds(getDoc(attempt));
  await assertSucceeds(updateDoc(attempt, {
    instructorFeedback: 'Review the loop condition.', reviewedBy: 'instructor-1', reviewedAt: new Date(),
  }));
  await assertFails(updateDoc(attempt, { sourceCode: 'tampered' }));
});

test('student can create an attempt in their own account', async () => {
  const db = environment.authenticatedContext('student-1', { email: 'student@psu.edu.ph' }).firestore();
  await assertSucceeds(setDoc(doc(db, 'users/student-1/simulation_attempts/new-attempt'), {
    title: 'Variables', result: 'passed',
  }));
  assert.ok(true);
});
