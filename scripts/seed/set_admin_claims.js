import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import admin from 'firebase-admin';

const rootDir = path.resolve(path.dirname(new URL(import.meta.url).pathname), '../..');
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT || path.join(rootDir, 'scripts/seed/serviceAccount.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Missing service account JSON. Set FIREBASE_SERVICE_ACCOUNT or place file at scripts/seed/serviceAccount.json');
  process.exit(1);
}

const uids = process.argv.slice(2).filter(Boolean);
if (uids.length === 0) {
  console.error('Usage: node set_admin_claims.js <uid1> <uid2> ...');
  process.exit(1);
}

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf-8'));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function main() {
  for (const uid of uids) {
    await admin.auth().setCustomUserClaims(uid, { admin: true });
    console.log(`Set admin claim for ${uid}`);
  }
  process.exit(0);
}

main().catch((err) => {
  console.error('Failed to set admin claims:', err);
  process.exit(1);
});
