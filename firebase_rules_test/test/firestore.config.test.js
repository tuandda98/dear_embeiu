const { doc, setDoc, getDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  seedDoc,
} = require('./helpers');

// App config (force-update gate): config/{document} is PUBLIC-READ so the
// cold-start version check can run BEFORE sign-in (a launching guest hits it).
// Written only from the Firebase Console (Admin SDK bypasses rules) — clients
// can never write.
describe('firestore: /config/{document} (force-update gate)', () => {
  const PATH = 'config/app';
  const cfg = {
    minBuildNumber: 12,
    iosStoreUrl: 'https://apps.apple.com/app/id123',
    androidStoreUrl:
      'https://play.google.com/store/apps/details?id=com.tony.dearembeiu',
  };

  describe('read (public)', () => {
    it('lets an UNAUTHENTICATED client read config (gate runs pre-login)', async () => {
      await seedDoc(PATH, cfg);
      await assertSucceeds(getDoc(doc(unauthedDb(), PATH)));
    });

    it('lets a signed-in user read config', async () => {
      await seedDoc(PATH, cfg);
      await assertSucceeds(getDoc(doc(authedDb('alice'), PATH)));
    });
  });

  describe('write (admin-only — clients can never write)', () => {
    it('forbids an unauthenticated create', async () => {
      await assertFails(setDoc(doc(unauthedDb(), PATH), cfg));
    });

    it('forbids a signed-in user creating config', async () => {
      await assertFails(setDoc(doc(authedDb('alice'), PATH), cfg));
    });

    it('forbids a signed-in user updating config', async () => {
      await seedDoc(PATH, cfg);
      await assertFails(
        updateDoc(doc(authedDb('alice'), PATH), { minBuildNumber: 99 }),
      );
    });

    it('forbids a signed-in user deleting config', async () => {
      await seedDoc(PATH, cfg);
      await assertFails(deleteDoc(doc(authedDb('alice'), PATH)));
    });
  });
});
