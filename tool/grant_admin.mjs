// Run only from a trusted administrator machine using Application Default Credentials.
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
const uid = process.argv[2];
if (!uid) throw new Error('Usage: node tool/grant_admin.mjs FIREBASE_USER_UID');
initializeApp({ credential: applicationDefault() });
const user = await getAuth().getUser(uid);
await getAuth().setCustomUserClaims(uid, { ...user.customClaims, admin: true });
console.log('Admin role granted. User must sign out and sign in to refresh their token.');
