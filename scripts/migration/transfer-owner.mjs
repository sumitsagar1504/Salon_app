import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = 'salonapp-419d7';
const ownerUid = 'NIgb3JbjMBXGzaQaGKNfgGwNxyv1';
const emailFlag = process.argv.indexOf('--email');
const newEmail = emailFlag >= 0 ? process.argv[emailFlag + 1]?.trim().toLowerCase() : '';
const apply = process.argv.includes('--apply');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  throw new Error('Set GOOGLE_APPLICATION_CREDENTIALS to the service account JSON path.');
}
if (!newEmail || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(newEmail)) {
  throw new Error('Usage: node transfer-owner.mjs --email owner@example.com [--apply]');
}

initializeApp({ credential: applicationDefault(), projectId });
const auth = getAuth();
const db = getFirestore();
const currentUser = await auth.getUser(ownerUid);
const profileRef = db.collection('users').doc(ownerUid);
const profile = await profileRef.get();

if (!profile.exists) {
  throw new Error(`Firestore owner profile ${ownerUid} does not exist. No changes made.`);
}

try {
  const existing = await auth.getUserByEmail(newEmail);
  if (existing.uid !== ownerUid) {
    throw new Error(`The new email already belongs to another Firebase user (${existing.uid}).`);
  }
} catch (error) {
  if (error.code !== 'auth/user-not-found') throw error;
}

const oldEmail = currentUser.email;
if (!oldEmail) {
  throw new Error('The existing owner account has no email address. No changes made.');
}

console.log(`Project: ${projectId}`);
console.log(`Owner UID: ${ownerUid}`);
console.log(`Current email: ${oldEmail}`);
console.log(`New email: ${newEmail}`);

if (!apply) {
  console.log('Dry run only. Run again with --apply after checking the values above.');
  process.exit(0);
}

if (oldEmail !== newEmail) {
  await auth.updateUser(ownerUid, { email: newEmail, emailVerified: false });
  try {
    await profileRef.update({ email: newEmail });
  } catch (error) {
    await auth.updateUser(ownerUid, {
      email: oldEmail,
      emailVerified: currentUser.emailVerified,
    });
    throw new Error(`Firestore update failed; Authentication email was restored. ${error.message}`);
  }
}

await auth.revokeRefreshTokens(ownerUid);
console.log('Owner email updated and existing refresh tokens revoked.');
console.log('Ask the buyer to use Forgot password in the Salon app with the new email.');
