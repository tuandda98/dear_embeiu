const { doc, setDoc, getDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  seedDoc,
  validInviteCode,
} = require('./helpers');

describe('firestore: /invite_codes/{code}', () => {
  describe('create', () => {
    it('lets a user create a code pointing at themselves', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'invite_codes/ABC123'), validInviteCode('alice')),
      );
    });

    it("forbids creating a code that points at someone else's uid", async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'invite_codes/ABC123'), validInviteCode('bob')),
      );
    });

    it('rejects an unauthenticated create', async () => {
      await assertFails(
        setDoc(doc(unauthedDb(), 'invite_codes/ABC123'), validInviteCode('alice')),
      );
    });

    it('rejects an extra (non-whitelisted) field', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'invite_codes/ABC123'),
          validInviteCode('alice', { secret: 1 }),
        ),
      );
    });

    it('rejects a missing required field (displayName)', async () => {
      const c = validInviteCode('alice');
      delete c.displayName;
      await assertFails(setDoc(doc(authedDb('alice'), 'invite_codes/ABC123'), c));
    });
  });

  describe('read (enumeration is allowed by design for the join lookup)', () => {
    beforeEach(async () => {
      await seedDoc('invite_codes/ABC123', validInviteCode('alice'));
    });

    it('lets ANY signed-in user read a code (needed to join by code)', async () => {
      await assertSucceeds(getDoc(doc(authedDb('bob'), 'invite_codes/ABC123')));
    });

    it('forbids an unauthenticated read', async () => {
      await assertFails(getDoc(doc(unauthedDb(), 'invite_codes/ABC123')));
    });
  });

  describe('update', () => {
    beforeEach(async () => {
      await seedDoc('invite_codes/ABC123', validInviteCode('alice'));
    });

    it('lets the owner update coupleId', async () => {
      await assertSucceeds(
        updateDoc(doc(authedDb('alice'), 'invite_codes/ABC123'), { coupleId: 'c1' }),
      );
    });

    it('forbids a non-owner updating the code', async () => {
      await assertFails(
        updateDoc(doc(authedDb('bob'), 'invite_codes/ABC123'), { coupleId: 'c1' }),
      );
    });

    it('forbids reassigning userId (ownership hijack)', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'invite_codes/ABC123'), { userId: 'bob' }),
      );
    });

    it('forbids changing the immutable createdAt', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'invite_codes/ABC123'), {
          createdAt: new Date('2030-01-01'),
        }),
      );
    });
  });

  describe('delete', () => {
    beforeEach(async () => {
      await seedDoc('invite_codes/ABC123', validInviteCode('alice'));
    });

    it('never lets a client delete a code', async () => {
      await assertFails(deleteDoc(doc(authedDb('alice'), 'invite_codes/ABC123')));
    });
  });
});
