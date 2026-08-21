// Daily-question answer reactions rules (feature: daily-question reactions).
//
// Mirrors the photo-reaction suite, because the same Firestore trap applies:
// the app reads through a SINGLE collection-group query
// (answer_reaction_service.dart):
//   collectionGroup('answerReactions').where('coupleId','==',coupleId).snapshots()
// and a nested path rule does NOT authorise that query on its own. If the
// recursive `match /{path=**}/answerReactions/{id}` rule is missing, A reacts
// and B never sees it (B's stream errors out) — exactly the bug that shipped
// once already for photo reactions.
//
// Also pins the product rule that you react to your PARTNER's answer, never
// your own.

const assert = require('node:assert');
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

const DATE = '2026-08-22';
const ALICE_ANSWER = `couples/c1/dailyAnswers/${DATE}/responses/alice`;
const BOB_ANSWER = `couples/c1/dailyAnswers/${DATE}/responses/bob`;

describe('firestore: daily-answer reactions', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
    await seedDoc(`couples/c1/dailyAnswers/${DATE}`, {
      date: DATE,
      questionVi: 'Câu hỏi hôm nay?',
      questionEn: "Today's question?",
    });
    await seedDoc(ALICE_ANSWER, {
      authorUserId: 'alice',
      text: 'Câu trả lời của Alice',
      answeredAt: TS,
    });
    await seedDoc(BOB_ANSWER, {
      authorUserId: 'bob',
      text: "Bob's answer",
      answeredAt: TS,
    });
  });

  const validReaction = (uid, overrides = {}) => ({
    reactorUserId: uid,
    emoji: '❤️',
    coupleId: 'c1',
    date: DATE,
    reactedAt: TS,
    ...overrides,
  });

  // ---- direct doc path -----------------------------------------------------
  it("lets a member react to their PARTNER's answer (doc id == reactor uid)", async () => {
    await assertSucceeds(
      setDoc(
        doc(authedDb('alice'), `${BOB_ANSWER}/answerReactions/alice`),
        validReaction('alice'),
      ),
    );
  });

  it('forbids reacting to your OWN answer', async () => {
    await assertFails(
      setDoc(
        doc(authedDb('alice'), `${ALICE_ANSWER}/answerReactions/alice`),
        validReaction('alice'),
      ),
    );
  });

  it('lets the answer author read the reaction directly', async () => {
    await seedDoc(`${BOB_ANSWER}/answerReactions/alice`, validReaction('alice'));
    await assertSucceeds(
      getDoc(doc(authedDb('bob'), `${BOB_ANSWER}/answerReactions/alice`)),
    );
  });

  it('forbids reacting under another uid / spoofing the reactor', async () => {
    await assertFails(
      setDoc(
        doc(authedDb('alice'), `${BOB_ANSWER}/answerReactions/bob`),
        validReaction('alice'),
      ),
    );
    await assertFails(
      setDoc(
        doc(authedDb('alice'), `${BOB_ANSWER}/answerReactions/alice`),
        validReaction('alice', { reactorUserId: 'bob' }),
      ),
    );
  });

  it('rejects an emoji outside the six allowed reactions', async () => {
    await assertFails(
      setDoc(
        doc(authedDb('alice'), `${BOB_ANSWER}/answerReactions/alice`),
        validReaction('alice', { emoji: '💩' }),
      ),
    );
  });

  it('rejects a forged coupleId or a date that disagrees with the path', async () => {
    await assertFails(
      setDoc(
        doc(authedDb('alice'), `${BOB_ANSWER}/answerReactions/alice`),
        validReaction('alice', { coupleId: 'c2' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(authedDb('alice'), `${BOB_ANSWER}/answerReactions/alice`),
        validReaction('alice', { date: '2026-01-01' }),
      ),
    );
  });

  it('rejects unknown extra fields (hasOnly)', async () => {
    await assertFails(
      setDoc(
        doc(authedDb('alice'), `${BOB_ANSWER}/answerReactions/alice`),
        validReaction('alice', { answerText: 'leaked' }),
      ),
    );
  });

  it('forbids an outsider reading or writing', async () => {
    await seedDoc(`${BOB_ANSWER}/answerReactions/alice`, validReaction('alice'));
    await assertFails(
      getDoc(doc(authedDb('dave'), `${BOB_ANSWER}/answerReactions/alice`)),
    );
    await assertFails(
      setDoc(
        doc(authedDb('dave'), `${BOB_ANSWER}/answerReactions/dave`),
        validReaction('dave'),
      ),
    );
  });

  // ---- delete --------------------------------------------------------------
  it('lets a member delete their own reaction but not their partner\'s', async () => {
    await seedDoc(`${BOB_ANSWER}/answerReactions/alice`, validReaction('alice'));
    await seedDoc(`${ALICE_ANSWER}/answerReactions/bob`, validReaction('bob'));
    await assertSucceeds(
      deleteDoc(doc(authedDb('alice'), `${BOB_ANSWER}/answerReactions/alice`)),
    );
    await assertFails(
      deleteDoc(doc(authedDb('alice'), `${ALICE_ANSWER}/answerReactions/bob`)),
    );
  });

  // ---- collection-group query (the cross-device sync path) ------------------
  it('lets a member stream the couple\'s answer reactions via collectionGroup', async () => {
    await seedDoc(`${BOB_ANSWER}/answerReactions/alice`, validReaction('alice'));
    await seedDoc(`${ALICE_ANSWER}/answerReactions/bob`, validReaction('bob'));

    const q = query(
      collectionGroup(authedDb('bob'), 'answerReactions'),
      where('coupleId', '==', 'c1'),
    );
    const snap = await assertSucceeds(getDocs(q));
    assert.strictEqual(snap.size, 2);
  });

  it('forbids an outsider streaming answer reactions via collectionGroup', async () => {
    await seedDoc(`${BOB_ANSWER}/answerReactions/alice`, validReaction('alice'));
    const q = query(
      collectionGroup(authedDb('dave'), 'answerReactions'),
      where('coupleId', '==', 'c1'),
    );
    await assertFails(getDocs(q));
  });

  it('keeps answer reactions OUT of the photo-reaction collection group', async () => {
    // The whole reason the subcollection is not called `reactions`: a photo
    // reaction stream filtered only by coupleId must never pick these up.
    await seedDoc(`${BOB_ANSWER}/answerReactions/alice`, validReaction('alice'));
    const q = query(
      collectionGroup(authedDb('alice'), 'reactions'),
      where('coupleId', '==', 'c1'),
    );
    const snap = await assertSucceeds(getDocs(q));
    assert.strictEqual(snap.size, 0);
  });
});
