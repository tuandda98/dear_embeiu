const { doc, setDoc, getDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  seedDoc,
  seedActiveCouple,
  seedWaitingCouple,
  validCouple,
} = require('./helpers');

describe('firestore: /couples/{coupleId}', () => {
  describe('create (solo, waiting_partner)', () => {
    it('lets a user create a solo couple owned by themselves', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1'), validCouple({ memberIds: ['alice'] })),
      );
    });

    it('rejects creating a couple that already has two members', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1'),
          validCouple({ memberIds: ['alice', 'bob'] }),
        ),
      );
    });

    it('rejects creating a couple owned by someone else (IDOR)', async () => {
      // bob signs in but tries to create alice's couple.
      await assertFails(
        setDoc(doc(authedDb('bob'), 'couples/c1'), validCouple({ memberIds: ['alice'] })),
      );
    });

    it('rejects creating an already-active couple', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1'),
          validCouple({ memberIds: ['alice'], status: 'active' }),
        ),
      );
    });

    it('rejects a member/count mismatch', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1'),
          validCouple({ memberIds: ['alice'], memberCount: 2 }),
        ),
      );
    });

    it('rejects an unauthenticated create', async () => {
      await assertFails(
        setDoc(doc(unauthedDb(), 'couples/c1'), validCouple({ memberIds: ['alice'] })),
      );
    });
  });

  describe('read', () => {
    it('lets a member read their couple', async () => {
      await seedActiveCouple('c1', 'alice', 'bob');
      await assertSucceeds(getDoc(doc(authedDb('alice'), 'couples/c1')));
    });

    it('forbids a non-member reading an active couple', async () => {
      await seedActiveCouple('c1', 'alice', 'bob');
      await assertFails(getDoc(doc(authedDb('dave'), 'couples/c1')));
    });

    it('lets any signed-in user read a WAITING couple (join discovery)', async () => {
      await seedWaitingCouple('cw', 'carol');
      await assertSucceeds(getDoc(doc(authedDb('dave'), 'couples/cw')));
    });

    it('forbids an unauthenticated read', async () => {
      await seedActiveCouple('c1', 'alice', 'bob');
      await assertFails(getDoc(doc(unauthedDb(), 'couples/c1')));
    });
  });

  describe('update: profile edit', () => {
    beforeEach(async () => {
      await seedActiveCouple('c1', 'alice', 'bob');
    });

    it('lets a member edit profile fields (e.g. person1Name)', async () => {
      await assertSucceeds(
        updateDoc(doc(authedDb('alice'), 'couples/c1'), { person1Name: 'Alicia' }),
      );
    });

    it('forbids a non-member editing the profile', async () => {
      await assertFails(
        updateDoc(doc(authedDb('dave'), 'couples/c1'), { person1Name: 'hacked' }),
      );
    });

    it('forbids changing the immutable inviteCode', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couples/c1'), { inviteCode: 'ZZZ999' }),
      );
    });

    it('forbids changing the immutable createdByUserId', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couples/c1'), { createdByUserId: 'dave' }),
      );
    });
  });

  describe('update: join transition (waiting_partner -> active)', () => {
    beforeEach(async () => {
      await seedWaitingCouple('cw', 'carol');
    });

    it('lets a second user join (memberIds 1->2, status active)', async () => {
      await assertSucceeds(
        updateDoc(doc(authedDb('bob'), 'couples/cw'), {
          memberIds: ['carol', 'bob'],
          memberCount: 2,
          status: 'active',
        }),
      );
    });

    it('forbids joining without including yourself', async () => {
      await assertFails(
        updateDoc(doc(authedDb('bob'), 'couples/cw'), {
          memberIds: ['carol', 'dave'],
          memberCount: 2,
          status: 'active',
        }),
      );
    });

    it('forbids a join that drops the existing member', async () => {
      await assertFails(
        updateDoc(doc(authedDb('bob'), 'couples/cw'), {
          memberIds: ['bob', 'dave'],
          memberCount: 2,
          status: 'active',
        }),
      );
    });

    it('forbids an inconsistent join (count != members)', async () => {
      await assertFails(
        updateDoc(doc(authedDb('bob'), 'couples/cw'), {
          memberIds: ['carol', 'bob'],
          memberCount: 1,
          status: 'active',
        }),
      );
    });
  });

  describe('update: leave transition (active -> waiting_partner)', () => {
    beforeEach(async () => {
      await seedActiveCouple('c1', 'alice', 'bob');
    });

    it('lets a member leave (removes self, demotes to waiting)', async () => {
      await assertSucceeds(
        updateDoc(doc(authedDb('alice'), 'couples/c1'), {
          memberIds: ['bob'],
          memberCount: 1,
          status: 'waiting_partner',
        }),
      );
    });

    it('forbids "leaving" by removing the OTHER member instead of yourself', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couples/c1'), {
          memberIds: ['alice'],
          memberCount: 1,
          status: 'waiting_partner',
        }),
      );
    });

    it('forbids a non-member triggering a leave', async () => {
      await assertFails(
        updateDoc(doc(authedDb('dave'), 'couples/c1'), {
          memberIds: ['bob'],
          memberCount: 1,
          status: 'waiting_partner',
        }),
      );
    });
  });

  describe('delete', () => {
    it('lets the sole member delete their waiting couple', async () => {
      await seedWaitingCouple('cw', 'carol');
      await assertSucceeds(deleteDoc(doc(authedDb('carol'), 'couples/cw')));
    });

    it('forbids deleting an active (two-member) couple', async () => {
      await seedActiveCouple('c1', 'alice', 'bob');
      await assertFails(deleteDoc(doc(authedDb('alice'), 'couples/c1')));
    });

    it('forbids a non-member deleting a waiting couple', async () => {
      await seedWaitingCouple('cw', 'carol');
      await assertFails(deleteDoc(doc(authedDb('dave'), 'couples/cw')));
    });
  });
});
