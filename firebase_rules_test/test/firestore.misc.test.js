const { doc, setDoc, getDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  seedDoc,
  seedActiveCouple,
  TS,
} = require('./helpers');

describe('firestore: /reports/{reportId} (UGC moderation, create-only)', () => {
  const report = {
    reporterUid: 'alice',
    coupleId: 'c1',
    photoId: 'p1',
    authorUserId: 'bob',
    reason: 'inappropriate',
    createdAt: TS,
  };

  it('lets any signed-in user file a report', async () => {
    await assertSucceeds(setDoc(doc(authedDb('alice'), 'reports/r1'), report));
  });

  it('forbids an unauthenticated report', async () => {
    await assertFails(setDoc(doc(unauthedDb(), 'reports/r1'), report));
  });

  it('forbids reading, updating, or deleting reports (admin-only via console)', async () => {
    await seedDoc('reports/r1', report);
    await assertFails(getDoc(doc(authedDb('alice'), 'reports/r1')));
    await assertFails(updateDoc(doc(authedDb('alice'), 'reports/r1'), { reason: 'spam' }));
    await assertFails(deleteDoc(doc(authedDb('alice'), 'reports/r1')));
  });
});

describe('firestore: /couple_codes/{code} (entry code -> coupleId map)', () => {
  beforeEach(async () => {
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  const code = (overrides = {}) => ({
    coupleId: 'c1',
    createdAt: TS,
    updatedAt: TS,
    ...overrides,
  });

  describe('create', () => {
    it('lets a couple member create a code for their couple', async () => {
      await assertSucceeds(setDoc(doc(authedDb('alice'), 'couple_codes/XYZ789'), code()));
    });

    it('forbids a non-member creating a code for that couple', async () => {
      await assertFails(setDoc(doc(authedDb('dave'), 'couple_codes/XYZ789'), code()));
    });

    it('rejects an extra (non-whitelisted) field', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couple_codes/XYZ789'), code({ owner: 'alice' })),
      );
    });

    it('rejects a missing coupleId', async () => {
      const c = code();
      delete c.coupleId;
      await assertFails(setDoc(doc(authedDb('alice'), 'couple_codes/XYZ789'), c));
    });

    it('rejects an unauthenticated create', async () => {
      await assertFails(setDoc(doc(unauthedDb(), 'couple_codes/XYZ789'), code()));
    });
  });

  describe('read', () => {
    beforeEach(async () => {
      await seedDoc('couple_codes/XYZ789', code());
    });

    it('lets any signed-in user read a code (join lookup)', async () => {
      await assertSucceeds(getDoc(doc(authedDb('dave'), 'couple_codes/XYZ789')));
    });

    it('forbids an unauthenticated read', async () => {
      await assertFails(getDoc(doc(unauthedDb(), 'couple_codes/XYZ789')));
    });
  });

  describe('update / delete', () => {
    beforeEach(async () => {
      await seedDoc('couple_codes/XYZ789', code());
    });

    it('forbids any update (codes are immutable)', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couple_codes/XYZ789'), { coupleId: 'c2' }),
      );
    });

    it('lets a member of the mapped couple delete the code', async () => {
      await assertSucceeds(deleteDoc(doc(authedDb('alice'), 'couple_codes/XYZ789')));
    });

    it('forbids a non-member deleting the code', async () => {
      await assertFails(deleteDoc(doc(authedDb('dave'), 'couple_codes/XYZ789')));
    });
  });
});
