// Reactions ❤️ rules — focused on the cross-device sync path.
//
// The app reads reactions through a SINGLE collection-group query
// (reaction_service.dart):
//   collectionGroup('reactions').where('coupleId', '==', coupleId).snapshots()
// so this suite asserts that query is permitted for a member — not just a
// direct doc read. A nested `match /couples/{c}/photos/{p}/reactions/{uid}`
// rule secures the doc-path read/write but does NOT necessarily authorise the
// collection-group query: that is exactly the bug we are hunting (A reacts, B
// never sees it because B's stream errors out).

const {
  doc,
  setDoc,
  getDoc,
  deleteDoc,
  collectionGroup,
  query,
  where,
  getDocs,
} = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  seedDoc,
  seedActiveCouple,
  TS,
} = require('./helpers');

describe('firestore: reactions ❤️ (cross-device sync)', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
    await seedDoc('couples/c1/photos/p1', {
      coupleId: 'c1',
      authorUserId: 'alice',
      uploadDate: TS,
      remoteUrl: 'https://example.com/p.jpg',
    });
  });

  const validReaction = (uid, overrides = {}) => ({
    authorUserId: uid,
    emoji: '❤️',
    coupleId: 'c1',
    reactedAt: TS,
    ...overrides,
  });

  // ---- direct doc path (write + single-doc read) ---------------------------
  it('lets a member set their own reaction (doc id == uid)', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'couples/c1/photos/p1/reactions/alice'), validReaction('alice')),
    );
  });

  it('lets the partner read a reaction doc directly', async () => {
    await seedDoc('couples/c1/photos/p1/reactions/alice', validReaction('alice'));
    await assertSucceeds(
      getDoc(doc(authedDb('bob'), 'couples/c1/photos/p1/reactions/alice')),
    );
  });

  it('forbids reacting under another uid / spoofing author / bad emoji', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/photos/p1/reactions/bob'), validReaction('alice')),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/photos/p1/reactions/alice'), validReaction('alice', { authorUserId: 'bob' })),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/photos/p1/reactions/alice'), validReaction('alice', { emoji: '💩' })),
    );
  });

  it('lets a member delete their own reaction', async () => {
    await seedDoc('couples/c1/photos/p1/reactions/alice', validReaction('alice'));
    await assertSucceeds(
      deleteDoc(doc(authedDb('alice'), 'couples/c1/photos/p1/reactions/alice')),
    );
  });

  // ---- THE BUG: collection-group query the app actually runs ----------------
  it('lets a member stream every reaction of the couple via collectionGroup', async () => {
    await seedDoc('couples/c1/photos/p1/reactions/alice', validReaction('alice'));
    // Bob is alice's partner — his app issues exactly this query.
    const q = query(
      collectionGroup(authedDb('bob'), 'reactions'),
      where('coupleId', '==', 'c1'),
    );
    await assertSucceeds(getDocs(q));
  });

  it('also lets the reacting member read back via collectionGroup', async () => {
    await seedDoc('couples/c1/photos/p1/reactions/alice', validReaction('alice'));
    const q = query(
      collectionGroup(authedDb('alice'), 'reactions'),
      where('coupleId', '==', 'c1'),
    );
    await assertSucceeds(getDocs(q));
  });

  it('forbids an outsider streaming the couple reactions', async () => {
    await seedDoc('couples/c1/photos/p1/reactions/alice', validReaction('alice'));
    const q = query(
      collectionGroup(authedDb('dave'), 'reactions'),
      where('coupleId', '==', 'c1'),
    );
    await assertFails(getDocs(q));
  });
});
