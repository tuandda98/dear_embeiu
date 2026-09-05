// Question engine rules (feature endless-questions) —
// couples/{coupleId}/questionState/main + the prefs.aiQuestionsEnabled opt-in.
//
// ONE shared doc per couple (`main`): whichever phone opens today's card first
// advances it, so BOTH members read and write. Every field is optional (writes
// merge); the rules only pin shapes + size caps.

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

describe('firestore: question engine state', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  const validState = (overrides = {}) => ({
    askedBankIds: [3, 17, 42],
    recentTemplateKeys: ['week_start', 'mood_today'],
    recentRevisitDates: ['2026-08-01', '2026-07-04'],
    updatedAt: TS,
    ...overrides,
  });

  it('lets a member write questionState/main', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'couples/c1/questionState/main'), validState()),
    );
  });

  it('lets the partner overwrite the same doc (shared state)', async () => {
    await seedDoc('couples/c1/questionState/main', validState());
    await assertSucceeds(
      setDoc(doc(authedDb('bob'), 'couples/c1/questionState/main'), validState({
        askedBankIds: [3, 17, 42, 99],
      })),
    );
  });

  it('lets a member write a partial state (all fields optional)', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'couples/c1/questionState/main'), {
        askedBankIds: [1],
      }),
    );
  });

  it('lets a member read questionState', async () => {
    await seedDoc('couples/c1/questionState/main', validState());
    await assertSucceeds(
      getDoc(doc(authedDb('bob'), 'couples/c1/questionState/main')),
    );
  });

  it('forbids a doc id other than main', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/questionState/other'), validState()),
    );
  });

  it('forbids an unexpected field', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/questionState/main'), validState({
        secret: 'x',
      })),
    );
  });

  it('forbids askedBankIds over the 2000 cap', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/questionState/main'), validState({
        askedBankIds: Array.from({length: 2001}, (_, i) => i),
      })),
    );
  });

  it('forbids recentTemplateKeys over the 60 cap', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/questionState/main'), validState({
        recentTemplateKeys: Array.from({length: 61}, (_, i) => `k${i}`),
      })),
    );
  });

  it('forbids recentRevisitDates over the 60 cap', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/questionState/main'), validState({
        recentRevisitDates: Array.from({length: 61}, (_, i) => `2026-01-${i}`),
      })),
    );
  });

  it('forbids a non-list askedBankIds', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/questionState/main'), validState({
        askedBankIds: 'nope',
      })),
    );
  });

  it('forbids an outsider writing questionState', async () => {
    await assertFails(
      setDoc(doc(authedDb('dave'), 'couples/c1/questionState/main'), validState()),
    );
  });

  it('forbids an outsider reading questionState', async () => {
    await seedDoc('couples/c1/questionState/main', validState());
    await assertFails(
      getDoc(doc(authedDb('dave'), 'couples/c1/questionState/main')),
    );
  });

  it('forbids deleting questionState', async () => {
    await seedDoc('couples/c1/questionState/main', validState());
    await assertFails(
      deleteDoc(doc(authedDb('alice'), 'couples/c1/questionState/main')),
    );
  });

  // ---- prefs opt-in ---------------------------------------------------------

  it('lets a member turn on aiQuestionsEnabled in prefs/home', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
        aiQuestionsEnabled: true,
      }),
    );
  });

  it('forbids a non-bool aiQuestionsEnabled', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
        aiQuestionsEnabled: 'yes',
      }),
    );
  });

  // ---- marker stays open for engine metadata --------------------------------
  //
  // The engine stamps source/questionId/templateKey/refDate onto the marker so
  // the journal can tell where a day's question came from. The marker rule has
  // no hasOnly on purpose — this test pins that it stays that way.
  it('lets a member write the daily marker with engine metadata fields', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'couples/c1/dailyAnswers/2026-09-05'), {
        date: '2026-09-05',
        questionVi: 'Hôm nay chúng mình biết ơn điều gì?',
        questionEn: 'What are we grateful for today?',
        source: 'ai',
        questionId: 'ai-2026-09-05',
        templateKey: 'week_start',
        refDate: '2026-08-06',
        updatedAt: TS,
      }),
    );
  });
});
