// Care message rules (feature care-message) —
// couples/{coupleId}/careMessages/{messageId}.
//
// A member sends a short "quan tâm" note; the Cloud Function notifyCareMessage
// pushes its title/body VERBATIM to the partner. Because the stored text lands
// straight on the partner's lock screen, the payload is pinned hard: exactly
// four fields, author == writer, non-empty bounded title/body, server-stamped
// createdAt. Write-once — a sent note can never be edited or unsent.

const {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
} = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  seedDoc,
  seedActiveCouple,
  TS,
} = require('./helpers');

const PATH = 'couples/c1/careMessages/m1';

describe('firestore: care messages', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  const validCare = (uid, overrides = {}) => ({
    authorUserId: uid,
    title: 'Nhớ ăn cơm nhé',
    body: 'Trưa nay nhớ ăn đủ bữa, chiều về mình đi dạo nha.',
    createdAt: serverTimestamp(),
    ...overrides,
  });

  // ---- create --------------------------------------------------------------
  it('lets a member send a care message', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice')),
    );
  });

  it('forbids an outsider sending a care message', async () => {
    await assertFails(
      setDoc(doc(authedDb('dave'), PATH), validCare('dave')),
    );
  });

  it('forbids spoofing authorUserId to the partner', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {authorUserId: 'bob'})),
    );
  });

  it('rejects a missing field', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), {
        authorUserId: 'alice',
        body: 'thiếu title',
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), {
        authorUserId: 'alice',
        title: 'thiếu body',
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), {
        authorUserId: 'alice',
        title: 'thiếu createdAt',
        body: 'không có dấu thời gian',
      }),
    );
  });

  it('rejects an unexpected extra field (hasOnly)', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {imageUrl: 'https://x/y.jpg'})),
    );
  });

  it('rejects an empty or over-long title', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {title: ''})),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {title: 'x'.repeat(61)})),
    );
  });

  it('rejects an empty or over-long body', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {body: ''})),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {body: 'x'.repeat(201)})),
    );
  });

  it('rejects a client-chosen createdAt (must be request.time)', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {createdAt: TS})),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {createdAt: 'now'})),
    );
  });

  it('rejects a wrong-typed title / body', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {title: 42})),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validCare('alice', {body: ['a']})),
    );
  });

  // ---- read ----------------------------------------------------------------
  it('lets both members read a care message', async () => {
    await seedDoc(PATH, {
      authorUserId: 'alice',
      title: 'Nhớ ăn cơm nhé',
      body: 'Trưa nay nhớ ăn đủ bữa nha.',
      createdAt: TS,
    });
    await assertSucceeds(getDoc(doc(authedDb('bob'), PATH)));
    await assertSucceeds(getDoc(doc(authedDb('alice'), PATH)));
  });

  it('forbids an outsider reading a care message', async () => {
    await seedDoc(PATH, {
      authorUserId: 'alice',
      title: 'Nhớ ăn cơm nhé',
      body: 'Trưa nay nhớ ăn đủ bữa nha.',
      createdAt: TS,
    });
    await assertFails(getDoc(doc(authedDb('dave'), PATH)));
  });

  // ---- immutability --------------------------------------------------------
  it('forbids updating a sent care message (even by its author)', async () => {
    await seedDoc(PATH, {
      authorUserId: 'alice',
      title: 'Nhớ ăn cơm nhé',
      body: 'Trưa nay nhớ ăn đủ bữa nha.',
      createdAt: TS,
    });
    await assertFails(
      updateDoc(doc(authedDb('alice'), PATH), {body: 'sửa lại rồi'}),
    );
    await assertFails(
      updateDoc(doc(authedDb('bob'), PATH), {body: 'người ấy sửa'}),
    );
  });

  it('forbids deleting a sent care message (even by its author)', async () => {
    await seedDoc(PATH, {
      authorUserId: 'alice',
      title: 'Nhớ ăn cơm nhé',
      body: 'Trưa nay nhớ ăn đủ bữa nha.',
      createdAt: TS,
    });
    await assertFails(deleteDoc(doc(authedDb('alice'), PATH)));
    await assertFails(deleteDoc(doc(authedDb('bob'), PATH)));
  });
});
