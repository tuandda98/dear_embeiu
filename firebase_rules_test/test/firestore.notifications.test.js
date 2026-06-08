const { doc, setDoc, getDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  seedDoc,
  TS,
} = require('./helpers');

// Notification inbox / center: users/{uid}/notifications/{id}. Written ONLY by
// Cloud Functions (Admin SDK bypasses rules). Clients may read their own,
// toggle the `read` flag, and delete — never create or forge other fields.
describe('firestore: /users/{uid}/notifications/{id} (notification center)', () => {
  const PATH = 'users/alice/notifications/n1';

  const notif = (overrides = {}) => ({
    type: 'photo_posted',
    coupleId: 'c1',
    actorUserId: 'bob',
    actorName: 'Bob',
    photoId: 'p1',
    createdAt: TS,
    read: false,
    ...overrides,
  });

  describe('create (admin-only — clients can never create)', () => {
    it('forbids the owner creating their own notification', async () => {
      await assertFails(setDoc(doc(authedDb('alice'), PATH), notif()));
    });

    it('forbids anyone else creating a notification for a user', async () => {
      await assertFails(setDoc(doc(authedDb('bob'), PATH), notif()));
    });

    it('forbids an unauthenticated create', async () => {
      await assertFails(setDoc(doc(unauthedDb(), PATH), notif()));
    });
  });

  describe('read', () => {
    beforeEach(async () => {
      await seedDoc(PATH, notif());
    });

    it('lets the owner read their own notification', async () => {
      await assertSucceeds(getDoc(doc(authedDb('alice'), PATH)));
    });

    it('forbids another user reading it', async () => {
      await assertFails(getDoc(doc(authedDb('bob'), PATH)));
    });

    it('forbids an unauthenticated read', async () => {
      await assertFails(getDoc(doc(unauthedDb(), PATH)));
    });
  });

  describe('update (only the read flag, by the owner)', () => {
    beforeEach(async () => {
      await seedDoc(PATH, notif());
    });

    it('lets the owner mark it read', async () => {
      await assertSucceeds(updateDoc(doc(authedDb('alice'), PATH), { read: true }));
    });

    it('forbids changing any field other than read', async () => {
      await assertFails(updateDoc(doc(authedDb('alice'), PATH), { type: 'love_note' }));
    });

    it('forbids changing read together with another field', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), PATH), { read: true, actorName: 'Eve' }),
      );
    });

    it('forbids a non-bool read value', async () => {
      await assertFails(updateDoc(doc(authedDb('alice'), PATH), { read: 'yes' }));
    });

    it('forbids another user updating it', async () => {
      await assertFails(updateDoc(doc(authedDb('bob'), PATH), { read: true }));
    });
  });

  describe('delete (dismiss / clear, by the owner)', () => {
    beforeEach(async () => {
      await seedDoc(PATH, notif());
    });

    it('lets the owner delete their own notification', async () => {
      await assertSucceeds(deleteDoc(doc(authedDb('alice'), PATH)));
    });

    it('forbids another user deleting it', async () => {
      await assertFails(deleteDoc(doc(authedDb('bob'), PATH)));
    });

    it('forbids an unauthenticated delete', async () => {
      await assertFails(deleteDoc(doc(unauthedDb(), PATH)));
    });
  });
});
