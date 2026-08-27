import { readFileSync } from 'node:fs';
import { cert, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!credentialsPath) {
  throw new Error('Set GOOGLE_APPLICATION_CREDENTIALS to the Firebase Admin JSON file.');
}

const credentials = JSON.parse(readFileSync(credentialsPath, 'utf8'));
initializeApp({ credential: cert(credentials) });
const db = getFirestore();

function isUnsafeJavaScript(data) {
  if (String(data.language ?? '').toLowerCase() !== 'javascript') return false;
  const source = String(data.sourceCode ?? data.codeSnippet ?? '');
  return /mockfile/i.test(source) ||
    /(^|\n)\s*(await\s+)?using\s+[a-z_$][\w$]*\s*=/i.test(source) ||
    /show(open|save)filepicker/i.test(source);
}

function safeProgram(topic) {
  return `console.log("Lesson example: ${String(topic).replaceAll('"', '\\"')}");`;
}

let repaired = 0;
for (const collectionName of ['lessons', 'simulations']) {
  const snapshot = await db.collection(collectionName).get();
  for (const document of snapshot.docs) {
    const data = document.data();
    if (!isUnsafeJavaScript(data)) continue;
    const topic = data.topic || data.title || 'JavaScript';
    const field = collectionName === 'lessons' ? 'sourceCode' : 'codeSnippet';
    await document.ref.update({
      [field]: safeProgram(topic),
      expectedOutput: `Lesson example: ${topic}`,
      compilerValidated: false,
      updatedAt: new Date(),
    });
    repaired += 1;
    process.stdout.write(`Repaired ${collectionName}/${document.id}\n`);
  }
}

process.stdout.write(`Repair complete. ${repaired} document(s) updated.\n`);
