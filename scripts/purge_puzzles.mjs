import { readFileSync } from 'node:fs';
import { cert, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

if (process.env.CONFIRM_PURGE_PUZZLES !== 'yes') {
  throw new Error('Set CONFIRM_PURGE_PUZZLES=yes to confirm the destructive operation.');
}

const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!credentialsPath) {
  throw new Error('GOOGLE_APPLICATION_CREDENTIALS is required.');
}

const credentials = JSON.parse(readFileSync(credentialsPath, 'utf8'));
const app = initializeApp({ credential: cert(credentials) });
const db = getFirestore(app);
const snapshot = await db.collection('puzzles').get();

let deleted = 0;
for (let offset = 0; offset < snapshot.docs.length; offset += 400) {
  const batch = db.batch();
  for (const document of snapshot.docs.slice(offset, offset + 400)) {
    batch.delete(document.ref);
    deleted += 1;
  }
  await batch.commit();
}

const remaining = await db.collection('puzzles').count().get();
console.log(JSON.stringify({ deleted, remaining: remaining.data().count }));
