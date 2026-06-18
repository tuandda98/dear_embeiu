// Daily mood rules (feature mood) — couples/{coupleId}/moods/{uid}.
// One doc per member (id == uid); both members read each other's, each writes
// only their own. Mirrors the receipts/reactions per-member ownership pattern.

const {
  doc,
  setDoc,
  getDoc,
  deleteDoc,
} = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  seedDoc,
  seedActiveCouple,
  TS,
} = require('./helpers');

describe('firestore: daily mood', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  const validMood = (uid, overrides = {}) => ({
    authorUserId: uid,
    mood: 'happy',
    note: 'đi làm vui',
    date: '2026-06-19',
    updatedAt: TS,
    ...overrides,
  });

  it('lets a member set their own mood (doc id == uid)', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'couples/c1/moods/alice'), validMood('alice')),
    );
  });

  it('lets a member set a mood without authorUserId / note (both optional)', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'couples/c1/moods/alice'), {
        mood: 'loved',
        date: '2026-06-19',
        updatedAt: TS,
      }),
    );
  });

  it('lets the partner read the other member mood', async () => {
    await seedDoc('couples/c1/moods/alice', validMood('alice'));
    await assertSucceeds(
      getDoc(doc(authedDb('bob'), 'couples/c1/moods/alice')),
    );
  });

  it('forbids writing under another uid', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/moods/bob'), validMood('alice')),
    );
  });

  it('forbids spoofing authorUserId to the partner', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/moods/alice'), validMood('alice', { authorUserId: 'bob' })),
    );
  });

  it('forbids an over-long note', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/moods/alice'), validMood('alice', { note: 'x'.repeat(101) })),
    );
  });

  it('forbids an unexpected field', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/moods/alice'), validMood('alice', { secret: 'x' })),
    );
  });

  it('forbids an outsider reading the couple mood', async () => {
    await seedDoc('couples/c1/moods/alice', validMood('alice'));
    await assertFails(
      getDoc(doc(authedDb('dave'), 'couples/c1/moods/alice')),
    );
  });

  it('forbids deleting a mood', async () => {
    await seedDoc('couples/c1/moods/alice', validMood('alice'));
    await assertFails(
      deleteDoc(doc(authedDb('alice'), 'couples/c1/moods/alice')),
    );
  });
});
