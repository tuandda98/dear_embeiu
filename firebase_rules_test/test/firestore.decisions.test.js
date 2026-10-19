// Decision wheel rules (feature decision-wheel, 2026-10-19) —
// couples/{coupleId}/decisions/{id}.
//
// Food / plans: id '{date}_eat' / '{date}_go', one per day, re-spin bumps
// `spins` by exactly 1. Custom: auto id, 2..12 options, result must be one of
// them. Members read; creator pinned; `lastPushAt` is CF-only; no delete.

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
  unauthedDb,
  seedDoc,
  seedActiveCouple,
  seedWaitingCouple,
  TS,
} = require('./helpers');

const DATE = '2026-10-21';
const EAT = `couples/c1/decisions/${DATE}_eat`;
const GO = `couples/c1/decisions/${DATE}_go`;
const CUSTOM = 'couples/c1/decisions/x1';

const eat = (uid, overrides = {}) => ({
  kind: 'eat',
  date: DATE,
  question: '',
  options: [],
  filter: 'tuy',
  result: 'Bún chả',
  resultId: 'bun_cha',
  spins: 1,
  byUserId: uid,
  createdBy: uid,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const custom = (uid, overrides = {}) => ({
  kind: 'custom',
  date: DATE,
  question: 'Ai rửa bát?',
  options: ['Anh', 'Em'],
  filter: '',
  result: 'Anh',
  resultId: '',
  spins: 1,
  byUserId: uid,
  createdBy: uid,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

// Stored doc (as if written earlier) for update tests.
const stored = (base) => ({
  ...base,
  createdAt: TS,
  updatedAt: TS,
});

const respin = (uid, overrides = {}) => ({
  result: 'Lẩu Thái',
  resultId: 'lau_thai',
  spins: 2,
  byUserId: uid,
  updatedAt: serverTimestamp(),
  ...overrides,
});

describe('firestore: decisions', () => {
  beforeEach(async () => {
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  // ---- read ----------------------------------------------------------------
  it('members read, outsiders and guests do not', async () => {
    await seedDoc(EAT, stored(eat('alice')));
    await assertSucceeds(getDoc(doc(authedDb('alice'), EAT)));
    await assertSucceeds(getDoc(doc(authedDb('bob'), EAT)));
    await assertFails(getDoc(doc(authedDb('dave'), EAT)));
    await assertFails(getDoc(doc(unauthedDb(), EAT)));
  });

  // ---- create: eat / go ----------------------------------------------------
  it('a member locks in today\'s food', async () => {
    await assertSucceeds(setDoc(doc(authedDb('alice'), EAT), eat('alice')));
  });

  it('a member locks in a plan', async () => {
    await assertSucceeds(
      setDoc(
        doc(authedDb('bob'), GO),
        eat('bob', {kind: 'go', result: 'Đi cà phê', resultId: 'ca_phe', filter: 'free'}),
      ),
    );
  });

  it('a solo member of a waiting couple can lock in too', async () => {
    await seedWaitingCouple('cw', 'carol');
    await assertSucceeds(
      setDoc(doc(authedDb('carol'), `couples/cw/decisions/${DATE}_eat`), eat('carol')),
    );
  });

  it('outsiders cannot create', async () => {
    await assertFails(setDoc(doc(authedDb('dave'), EAT), eat('dave')));
  });

  it('eat/go id must be {date}_{kind}', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, 'couples/c1/decisions/2026-10-20_eat'), eat('alice')));
    await assertFails(setDoc(doc(db, `couples/c1/decisions/${DATE}_go`), eat('alice')));
    await assertFails(setDoc(doc(db, 'couples/c1/decisions/random'), eat('alice')));
  });

  it('date must look like YYYY-MM-DD', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1/decisions/21-10-2026_eat'), eat('alice', {date: '21-10-2026'})),
    );
  });

  it('kind must be eat / go / custom', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), `couples/c1/decisions/${DATE}_drink`), eat('alice', {kind: 'drink'})),
    );
  });

  it('eat/go carry no options', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), EAT), eat('alice', {options: ['A', 'B']})));
  });

  it('result must be 1..40 characters', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, EAT), eat('alice', {result: ''})));
    await assertFails(setDoc(doc(db, EAT), eat('alice', {result: 'x'.repeat(41)})));
    await assertSucceeds(setDoc(doc(db, EAT), eat('alice', {result: 'x'.repeat(40)})));
  });

  it('createdAt must be the server time', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), EAT), eat('alice', {createdAt: TS})));
  });

  it('cannot fake createdBy or byUserId', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, EAT), eat('alice', {createdBy: 'bob'})));
    await assertFails(setDoc(doc(db, EAT), eat('alice', {byUserId: 'bob'})));
  });

  it('a new pick starts at spins 1', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), EAT), eat('alice', {spins: 5})));
  });

  it('client cannot write lastPushAt on create', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), EAT), eat('alice', {lastPushAt: serverTimestamp()})),
    );
  });

  it('rejects unexpected keys', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), EAT), eat('alice', {note: 'hi'})));
  });

  it('question over 60 characters is rejected', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), CUSTOM), custom('alice', {question: 'q'.repeat(61)})),
    );
  });

  it('a client without the optional keys can still create', async () => {
    // Only the required keys: no question/options/filter/resultId/updatedAt.
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), EAT), {
        kind: 'eat',
        date: DATE,
        result: 'Bún chả',
        spins: 1,
        byUserId: 'alice',
        createdBy: 'alice',
        createdAt: serverTimestamp(),
      }),
    );
  });

  // ---- create: custom ------------------------------------------------------
  it('a custom question with 2 options is fine', async () => {
    await assertSucceeds(setDoc(doc(authedDb('alice'), CUSTOM), custom('alice')));
  });

  it('custom needs 2..12 options', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, CUSTOM), custom('alice', {options: ['Anh'], result: 'Anh'})));
    const thirteen = Array.from({length: 13}, (_, i) => `o${i}`);
    await assertFails(setDoc(doc(db, CUSTOM), custom('alice', {options: thirteen, result: 'o0'})));
    const twelve = thirteen.slice(0, 12);
    await assertSucceeds(setDoc(doc(db, CUSTOM), custom('alice', {options: twelve, result: 'o0'})));
  });

  it('custom options over 480 characters in total are rejected', async () => {
    // 11 × 44 + 'A' = 485 > 480; 'A' is a valid result, only the total fails.
    const long = [...Array.from({length: 11}, (_, i) => `${'x'.repeat(42)}${String(i).padStart(2, '0')}`), 'A'];
    await assertFails(
      setDoc(doc(authedDb('alice'), CUSTOM), custom('alice', {options: long, result: 'A'})),
    );
  });

  it('custom result must be one of the options', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), CUSTOM), custom('alice', {result: 'Mèo'})));
  });

  // ---- update (re-spin) ----------------------------------------------------
  it('the partner re-spins: spins + 1, byUserId = them', async () => {
    await seedDoc(EAT, stored(eat('alice')));
    await assertSucceeds(updateDoc(doc(authedDb('bob'), EAT), respin('bob')));
  });

  it('spins must go up by exactly one', async () => {
    await seedDoc(EAT, stored(eat('alice')));
    const db = authedDb('bob');
    await assertFails(updateDoc(doc(db, EAT), respin('bob', {spins: 3})));
    await assertFails(updateDoc(doc(db, EAT), respin('bob', {spins: 1})));
  });

  it('re-spin cannot claim someone else as byUserId', async () => {
    await seedDoc(EAT, stored(eat('alice')));
    await assertFails(updateDoc(doc(authedDb('bob'), EAT), respin('bob', {byUserId: 'alice'})));
  });

  it('re-spin cannot change kind / options / createdBy / date', async () => {
    await seedDoc(EAT, stored(eat('alice')));
    const db = authedDb('bob');
    await assertFails(updateDoc(doc(db, EAT), {...respin('bob'), kind: 'go'}));
    await assertFails(updateDoc(doc(db, EAT), {...respin('bob'), options: ['A', 'B']}));
    await assertFails(updateDoc(doc(db, EAT), {...respin('bob'), createdBy: 'bob'}));
    await assertFails(updateDoc(doc(db, EAT), {...respin('bob'), date: '2026-10-22'}));
  });

  it('client cannot write lastPushAt on update', async () => {
    await seedDoc(EAT, stored(eat('alice')));
    await assertFails(
      updateDoc(doc(authedDb('bob'), EAT), {...respin('bob'), lastPushAt: serverTimestamp()}),
    );
  });

  it('a re-spin still works after the CF stamped lastPushAt', async () => {
    await seedDoc(EAT, {...stored(eat('alice')), lastPushAt: TS});
    await assertSucceeds(updateDoc(doc(authedDb('bob'), EAT), respin('bob')));
  });

  it('re-spin result keeps the 1..40 bound and needs server updatedAt', async () => {
    await seedDoc(EAT, stored(eat('alice')));
    const db = authedDb('bob');
    await assertFails(updateDoc(doc(db, EAT), respin('bob', {result: ''})));
    await assertFails(updateDoc(doc(db, EAT), respin('bob', {result: 'x'.repeat(41)})));
    await assertFails(updateDoc(doc(db, EAT), respin('bob', {updatedAt: TS})));
  });

  it('custom re-spin must stay inside the options', async () => {
    await seedDoc(CUSTOM, stored(custom('alice')));
    const db = authedDb('bob');
    await assertSucceeds(
      updateDoc(doc(db, CUSTOM), respin('bob', {result: 'Em', resultId: ''})),
    );
  });

  it('custom re-spin to a value outside the options is rejected', async () => {
    await seedDoc(CUSTOM, stored(custom('alice')));
    await assertFails(
      updateDoc(doc(authedDb('bob'), CUSTOM), respin('bob', {result: 'Mèo', resultId: ''})),
    );
  });

  it('outsiders cannot re-spin', async () => {
    await seedDoc(EAT, stored(eat('alice')));
    await assertFails(updateDoc(doc(authedDb('dave'), EAT), respin('dave')));
  });

  // ---- delete ----------------------------------------------------------------
  it('nobody deletes a pick', async () => {
    await seedDoc(EAT, stored(eat('alice')));
    await assertFails(deleteDoc(doc(authedDb('alice'), EAT)));
    await assertFails(deleteDoc(doc(authedDb('bob'), EAT)));
  });
});
