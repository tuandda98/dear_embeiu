const { doc, setDoc, getDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  seedDoc,
  validUser,
  validDevice,
} = require('./helpers');

describe('firestore: /users/{userId}', () => {
  describe('create', () => {
    it('lets a signed-in user create their own valid profile', async () => {
      const db = authedDb('alice');
      await assertSucceeds(setDoc(doc(db, 'users/alice'), validUser()));
    });

    it('rejects creating a profile for a different uid (IDOR)', async () => {
      const db = authedDb('alice');
      await assertFails(setDoc(doc(db, 'users/bob'), validUser()));
    });

    it('rejects an unauthenticated create', async () => {
      const db = unauthedDb();
      await assertFails(setDoc(doc(db, 'users/alice'), validUser()));
    });

    it('rejects an extra (non-whitelisted) field at create time', async () => {
      const db = authedDb('alice');
      // sessionToken may be CHANGED on update but must not be present at create.
      await assertFails(
        setDoc(doc(db, 'users/alice'), validUser({ sessionToken: 'x' })),
      );
    });

    it('rejects a missing required field (inviteCode)', async () => {
      const db = authedDb('alice');
      const u = validUser();
      delete u.inviteCode;
      await assertFails(setDoc(doc(db, 'users/alice'), u));
    });

    it('rejects an empty email', async () => {
      const db = authedDb('alice');
      await assertFails(setDoc(doc(db, 'users/alice'), validUser({ email: '' })));
    });

    it('rejects an invalid status value', async () => {
      const db = authedDb('alice');
      await assertFails(
        setDoc(doc(db, 'users/alice'), validUser({ status: 'married' })),
      );
    });
  });

  describe('read', () => {
    beforeEach(async () => {
      await seedDoc('users/alice', validUser());
    });

    it('lets a user read their own profile', async () => {
      await assertSucceeds(getDoc(doc(authedDb('alice'), 'users/alice')));
    });

    it('forbids reading another user profile', async () => {
      await assertFails(getDoc(doc(authedDb('bob'), 'users/alice')));
    });

    it('forbids an unauthenticated read', async () => {
      await assertFails(getDoc(doc(unauthedDb(), 'users/alice')));
    });
  });

  describe('update', () => {
    beforeEach(async () => {
      await seedDoc('users/alice', validUser({ inviteCode: 'ABC123' }));
    });

    it('lets a user edit their own displayName', async () => {
      await assertSucceeds(
        updateDoc(doc(authedDb('alice'), 'users/alice'), { displayName: 'Alice 2' }),
      );
    });

    it('lets a user set sessionToken (whitelisted on update)', async () => {
      await assertSucceeds(
        updateDoc(doc(authedDb('alice'), 'users/alice'), { sessionToken: 'tok' }),
      );
    });

    it('forbids changing the immutable email', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'users/alice'), { email: 'evil@x.com' }),
      );
    });

    it('forbids changing the immutable createdAt', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'users/alice'), {
          createdAt: new Date('2030-01-01'),
        }),
      );
    });

    it('forbids changing inviteCode once it is set', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'users/alice'), { inviteCode: 'ZZZ999' }),
      );
    });

    it('forbids writing a non-whitelisted field', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'users/alice'), { isAdmin: true }),
      );
    });

    it('forbids another user updating the profile', async () => {
      await assertFails(
        updateDoc(doc(authedDb('bob'), 'users/alice'), { displayName: 'hacked' }),
      );
    });
  });

  describe('delete', () => {
    beforeEach(async () => {
      await seedDoc('users/alice', validUser());
    });

    it('never lets a client delete a user (only the deleteAccount CF can)', async () => {
      await assertFails(deleteDoc(doc(authedDb('alice'), 'users/alice')));
    });
  });

  describe('subcollection /users/{uid}/devices/{id}', () => {
    it('lets a user register their own device', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'users/alice/devices/d1'), validDevice()),
      );
    });

    it('lets a device be written with languageCode set to null', async () => {
      await assertSucceeds(
        setDoc(
          doc(authedDb('alice'), 'users/alice/devices/d1'),
          validDevice({ languageCode: null }),
        ),
      );
    });

    it('allows a device that omits languageCode (optional, backward-compat)', async () => {
      // languageCode is read via data.get() in the rules, so the old (1.0) app
      // that omits the key still registers its device. See
      // firestore.backward-compat.test.js for the cross-cutting guarantee.
      const d = validDevice();
      delete d.languageCode;
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'users/alice/devices/d1'), d),
      );
    });

    it("forbids writing to another user's devices", async () => {
      await assertFails(
        setDoc(doc(authedDb('bob'), 'users/alice/devices/d1'), validDevice()),
      );
    });

    it('rejects an invalid platform value', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'users/alice/devices/d1'),
          validDevice({ platform: 'windows' }),
        ),
      );
    });

    it('rejects an extra (non-whitelisted) device field', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'users/alice/devices/d1'),
          validDevice({ secretFlag: true }),
        ),
      );
    });

    it('lets a user read and delete their own device', async () => {
      await seedDoc('users/alice/devices/d1', validDevice());
      await assertSucceeds(getDoc(doc(authedDb('alice'), 'users/alice/devices/d1')));
      await assertSucceeds(deleteDoc(doc(authedDb('alice'), 'users/alice/devices/d1')));
    });
  });
});
