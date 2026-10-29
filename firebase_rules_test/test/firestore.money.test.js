// Sổ tiền rules (feature expenses, 2026-10-20).
//   own book    users/{uid}/moneyWallets|moneyTx|moneyBudgets|moneyMeta
//   shared book couples/{id}/moneyWallets|moneyTx|moneyBudgets|moneyMeta
// Own book: owner only, shared keys refused. Shared book: wallets + entries
// pin `memberUids` (the couple's memberIds when written); reading needs
// membership AND a name in it, so a partner who joins later never sees the
// previous pair's money. Entries 1..10 tỷ, wallets −10..100 tỷ, editCount
// +1 per edit, linkId entries only change money with their creator,
// `alerted` / `goalReachedAt` are CF-only, wallets are never deleted.

const {
  doc,
  setDoc,
  getDoc,
  getDocs,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  serverTimestamp,
  getAggregateFromServer,
  sum,
} = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  seedDoc,
  seedActiveCouple,
  seedWaitingCouple,
  validCouple,
  TS,
} = require('./helpers');

const PAIR = ['alice', 'bob'];
const OWN = (uid, coll, id) => `users/${uid}/${coll}/${id}`;
const SH = (coll, id) => `couples/c1/${coll}/${id}`;

const wallet = (uid, overrides = {}) => ({
  name: 'MoMo',
  type: 'ewallet',
  emoji: '📱',
  color: 'rose',
  openingBalance: 1500000,
  includeInTotal: true,
  archived: false,
  order: 0,
  createdBy: uid,
  createdAt: serverTimestamp(),
  ...overrides,
});

const sharedWallet = (uid, overrides = {}) =>
  wallet(uid, {name: 'Ví chung', type: 'cash', memberUids: PAIR, ...overrides});

const expense = (uid, overrides = {}) => ({
  type: 'expense',
  amount: 120000,
  outWalletId: 'momo',
  inWalletId: '',
  date: '2026-10-20',
  categoryId: 'food_out',
  note: 'Cơm trưa',
  createdBy: uid,
  createdAt: serverTimestamp(),
  ...overrides,
});

const sharedExpense = (uid, overrides = {}) =>
  expense(uid, {
    outWalletId: '',
    payer: uid,
    memberUids: PAIR,
    ...overrides,
  });

// As stored by an earlier write (timestamps resolved).
const stored = (d) => ({...d, createdAt: TS});

const edit = (uid, overrides = {}) => ({
  updatedBy: uid,
  updatedAt: serverTimestamp(),
  editCount: 1,
  ...overrides,
});

const challenge = (uid, overrides = {}) => ({
  title: '7 ngày không trà sữa',
  kind: 'noSpend',
  categoryIds: ['food_coffee'],
  limit: 0,
  startDate: '2026-10-25',
  days: 7,
  templateId: 'no_coffee_7',
  cancelled: false,
  createdBy: uid,
  createdAt: serverTimestamp(),
  ...overrides,
});

const budget = (uid, overrides = {}) => ({
  categoryId: '',
  amount: 5000000,
  createdBy: uid,
  createdAt: serverTimestamp(),
  ...overrides,
});

describe('firestore: money — own book', () => {
  const W = OWN('alice', 'moneyWallets', 'momo');
  const T = OWN('alice', 'moneyTx', 't1');

  it('the owner creates and reads a wallet; partner, outsider, guest cannot read', async () => {
    await seedActiveCouple('c1', 'alice', 'bob');
    await assertSucceeds(setDoc(doc(authedDb('alice'), W), wallet('alice')));
    await assertSucceeds(getDoc(doc(authedDb('alice'), W)));
    await assertFails(getDoc(doc(authedDb('bob'), W)));
    await assertFails(getDoc(doc(authedDb('dave'), W)));
    await assertFails(getDoc(doc(unauthedDb(), W)));
  });

  it('nobody else can write into my book', async () => {
    await assertFails(setDoc(doc(authedDb('bob'), W), wallet('bob')));
    await assertFails(setDoc(doc(authedDb('bob'), T), expense('bob')));
  });

  it('partner cannot read or list my entries', async () => {
    await seedDoc(T, stored(expense('alice')));
    await assertFails(getDoc(doc(authedDb('bob'), T)));
    await assertFails(getDocs(collection(authedDb('bob'), 'users/alice/moneyTx')));
    await assertSucceeds(getDocs(collection(authedDb('alice'), 'users/alice/moneyTx')));
  });

  it('a wallet with only required keys is fine (optional keys absent)', async () => {
    await assertSucceeds(setDoc(doc(authedDb('alice'), W), wallet('alice')));
  });

  it('credit card may open at −2.000.000; out of range opening is refused', async () => {
    await assertSucceeds(setDoc(doc(authedDb('alice'), W),
      wallet('alice', {type: 'credit', openingBalance: -2000000})));
    await assertFails(setDoc(doc(authedDb('alice'), OWN('alice', 'moneyWallets', 'x')),
      wallet('alice', {openingBalance: 100000000001})));
    await assertFails(setDoc(doc(authedDb('alice'), OWN('alice', 'moneyWallets', 'y')),
      wallet('alice', {openingBalance: -10000000001})));
    await assertFails(setDoc(doc(authedDb('alice'), OWN('alice', 'moneyWallets', 'z')),
      wallet('alice', {openingBalance: 1.5})));
  });

  it('wallet name 31 chars, bad type, currency USD are refused', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), W), wallet('alice', {name: 'x'.repeat(31)})));
    await assertFails(setDoc(doc(authedDb('alice'), W), wallet('alice', {name: ''})));
    await assertFails(setDoc(doc(authedDb('alice'), W), wallet('alice', {type: 'crypto'})));
    await assertFails(setDoc(doc(authedDb('alice'), W), wallet('alice', {currency: 'USD'})));
    await assertSucceeds(setDoc(doc(authedDb('alice'), W), wallet('alice', {currency: 'VND'})));
  });

  it('goal fields only on a goal wallet, target 1..100 tỷ', async () => {
    await assertSucceeds(setDoc(doc(authedDb('alice'), W),
      wallet('alice', {type: 'goal', goalTarget: 25000000, goalDeadline: '2027-03-31'})));
    await assertFails(setDoc(doc(authedDb('alice'), OWN('alice', 'moneyWallets', 'b')),
      wallet('alice', {goalTarget: 25000000})));
    await assertFails(setDoc(doc(authedDb('alice'), OWN('alice', 'moneyWallets', 'c')),
      wallet('alice', {type: 'goal', goalTarget: 100000000001})));
    await assertFails(setDoc(doc(authedDb('alice'), OWN('alice', 'moneyWallets', 'd')),
      wallet('alice', {type: 'goal', goalTarget: 1000, goalDeadline: '31/03/2027'})));
  });

  it('createdAt must be the server time, createdBy must be me', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), W), wallet('alice', {createdAt: TS})));
    await assertFails(setDoc(doc(authedDb('alice'), W), wallet('bob')));
  });

  it('own wallets refuse shared keys', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), W), wallet('alice', {memberUids: PAIR})));
  });

  it('wallets are archived, never deleted; type is immutable', async () => {
    await seedDoc(W, stored(wallet('alice')));
    await assertSucceeds(updateDoc(doc(authedDb('alice'), W),
      {archived: true, updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(doc(authedDb('alice'), W),
      {type: 'bank', updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(doc(authedDb('alice'), W), {name: 'Ví', updatedAt: TS}));
    await assertFails(deleteDoc(doc(authedDb('alice'), W)));
  });

  it('own goal wallet may record goalReachedAt itself', async () => {
    await seedDoc(W, stored(wallet('alice', {type: 'goal', goalTarget: 100})));
    await assertSucceeds(updateDoc(doc(authedDb('alice'), W),
      {goalReachedAt: serverTimestamp(), updatedAt: serverTimestamp()}));
  });

  it('expense / transfer / adjust / contribution shapes; income is gone (D34)', async () => {
    const db = authedDb('alice');
    const p = (id) => doc(db, OWN('alice', 'moneyTx', id));
    await assertSucceeds(setDoc(p('e'), expense('alice')));
    await assertFails(setDoc(p('i'), expense('alice',
      {type: 'income', outWalletId: '', inWalletId: 'tcb', categoryId: 'salary', amount: 15000000})));
    await assertSucceeds(setDoc(p('t'), expense('alice',
      {type: 'transfer', outWalletId: 'tcb', inWalletId: 'cash', categoryId: ''})));
    await assertSucceeds(setDoc(p('a'), expense('alice',
      {type: 'adjust', categoryId: '', amount: 380000})));
    await assertSucceeds(setDoc(p('c'), expense('alice',
      {type: 'contribution', categoryId: '', linkId: 'L5'})));
  });

  it('expense needs a wallet in the own book', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, T), expense('alice', {outWalletId: ''})));
  });

  it('transfer into the same wallet is refused', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), T),
      expense('alice', {type: 'transfer', outWalletId: 'tcb', inWalletId: 'tcb'})));
  });

  it('adjust touching both wallets is refused', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), T),
      expense('alice', {type: 'adjust', outWalletId: 'tcb', inWalletId: 'cash'})));
  });

  it('settle is gone (D34)', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), T),
      expense('alice', {type: 'settle', outWalletId: '', categoryId: ''})));
  });

  it('amount: 0, negative, 10.000.000.001, float, string are refused; 10 tỷ is fine', async () => {
    const db = authedDb('alice');
    for (const amount of [0, -1, 10000000001, 1.5, '120000']) {
      await assertFails(setDoc(doc(db, T), expense('alice', {amount})));
    }
    await assertSucceeds(setDoc(doc(db, T), expense('alice', {amount: 10000000000})));
  });

  it('note 201 chars, bad date, long ids are refused', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, T), expense('alice', {note: 'x'.repeat(201)})));
    await assertSucceeds(setDoc(doc(db, T), expense('alice', {note: 'x'.repeat(200)})));
    await assertFails(setDoc(doc(db, 'users/alice/moneyTx/t2'), expense('alice', {date: '20/10/2026'})));
    await assertFails(setDoc(doc(db, 'users/alice/moneyTx/t3'), expense('alice', {outWalletId: 'w'.repeat(41)})));
    await assertFails(setDoc(doc(db, 'users/alice/moneyTx/t4'), expense('alice', {source: 'bank'})));
  });

  it('own entries refuse payer / splitMode / payerShare / memberUids', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, T), expense('alice', {payer: 'alice'})));
    await assertFails(setDoc(doc(db, T), expense('alice', {splitMode: 'none'})));
    await assertFails(setDoc(doc(db, T), expense('alice', {payerShare: 0})));
    await assertFails(setDoc(doc(db, T), expense('alice', {memberUids: PAIR})));
  });

  it('create with a forged createdAt / createdBy / editCount is refused', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, T), expense('alice', {createdAt: TS})));
    await assertFails(setDoc(doc(db, T), expense('bob')));
    await assertFails(setDoc(doc(db, T), expense('alice', {editCount: 3})));
  });

  it('edit: author + server time + editCount + 1; type / createdAt / linkId pinned', async () => {
    await seedDoc(T, stored(expense('alice', {linkId: 'L1'})));
    const db = authedDb('alice');
    await assertSucceeds(updateDoc(doc(db, T), edit('alice', {amount: 48000})));
    await assertFails(updateDoc(doc(db, T), edit('alice', {amount: 1, editCount: 1})));
    await assertFails(updateDoc(doc(db, T), edit('alice', {editCount: 3})));
    await assertFails(updateDoc(doc(db, T), edit('alice', {editCount: 2, type: 'income', inWalletId: 'x', outWalletId: ''})));
    await assertFails(updateDoc(doc(db, T), edit('alice', {editCount: 2, linkId: 'L9'})));
    await assertFails(updateDoc(doc(db, T), edit('alice', {editCount: 2, createdAt: new Date('2025-01-01T00:00:00Z')})));
  });

  it('the owner deletes an entry', async () => {
    await seedDoc(T, stored(expense('alice')));
    await assertFails(deleteDoc(doc(authedDb('bob'), T)));
    await assertSucceeds(deleteDoc(doc(authedDb('alice'), T)));
  });

  it('budgets: 1..10 tỷ, no client `alerted`', async () => {
    const db = authedDb('alice');
    const B = OWN('alice', 'moneyBudgets', 'food');
    await assertSucceeds(setDoc(doc(db, B), budget('alice', {categoryId: 'food', amount: 2000000})));
    await assertFails(setDoc(doc(db, OWN('alice', 'moneyBudgets', 'total')), budget('alice', {amount: 0})));
    await assertFails(setDoc(doc(db, OWN('alice', 'moneyBudgets', 'total')), budget('alice', {alerted: {'2026-10': 80}})));
    await assertFails(getDoc(doc(authedDb('bob'), B)));
  });

  it('budget id is fixed: `total` for the whole book, else the category id', async () => {
    const db = authedDb('alice');
    await assertSucceeds(setDoc(doc(db, OWN('alice', 'moneyBudgets', 'total')), budget('alice')));
    await assertFails(setDoc(doc(db, OWN('alice', 'moneyBudgets', 'auto1')), budget('alice')));
    await assertFails(setDoc(doc(db, OWN('alice', 'moneyBudgets', 'total')),
      budget('alice', {categoryId: 'food'})));
    await assertFails(setDoc(doc(db, OWN('alice', 'moneyBudgets', 'auto2')),
      budget('alice', {categoryId: 'food'})));
    // An existing budget cannot be moved to another category.
    const F = OWN('alice', 'moneyBudgets', 'food');
    await seedDoc(F, stored(budget('alice', {categoryId: 'food'})));
    await assertFails(updateDoc(doc(db, F), {categoryId: 'edu', updatedAt: serverTimestamp()}));
    await assertSucceeds(updateDoc(doc(db, F), {amount: 3000000, updatedAt: serverTimestamp()}));
  });

  it('own budget: `alerted` cannot be added later; default wallet id ≤40', async () => {
    const B = OWN('alice', 'moneyBudgets', 'total');
    await seedDoc(B, stored(budget('alice')));
    await assertFails(updateDoc(doc(authedDb('alice'), B), {alerted: {'2026-10': 80}, updatedAt: serverTimestamp()}));
    await assertFails(setDoc(doc(authedDb('alice'), OWN('alice', 'moneyMeta', 'main')),
      {defaultWalletId: 'w'.repeat(41), updatedAt: serverTimestamp()}));
  });

  it('meta: only doc `main`, ≤80 custom categories, ≤120 hidden', async () => {
    const db = authedDb('alice');
    const ok = {customCategories: [], hiddenCategoryIds: ['edu'], updatedAt: serverTimestamp()};
    await assertSucceeds(setDoc(doc(db, OWN('alice', 'moneyMeta', 'main')), ok));
    await assertFails(setDoc(doc(db, OWN('alice', 'moneyMeta', 'other')), ok));
    await assertFails(setDoc(doc(db, OWN('alice', 'moneyMeta', 'main')),
      {...ok, customCategories: Array.from({length: 81}, (_, i) => ({id: `c${i}`}))}));
    await assertFails(setDoc(doc(db, OWN('alice', 'moneyMeta', 'main')),
      {...ok, hiddenCategoryIds: Array.from({length: 121}, (_, i) => `h${i}`)}));
    await assertFails(setDoc(doc(db, OWN('alice', 'moneyMeta', 'main')), {...ok, updatedAt: TS}));
    await assertFails(getDoc(doc(authedDb('bob'), OWN('alice', 'moneyMeta', 'main'))));
  });

  it('meta: currency is one of the listed ISO codes (D31)', async () => {
    const db = authedDb('alice');
    const M = OWN('alice', 'moneyMeta', 'main');
    for (const c of ['VND', 'USD', 'EUR', 'JPY', 'KRW', 'THB']) {
      await assertSucceeds(setDoc(doc(db, M), {currency: c, updatedAt: serverTimestamp()}, {merge: true}));
    }
    for (const c of ['usd', 'BTC', '', 1, null]) {
      await assertFails(setDoc(doc(db, M), {currency: c, updatedAt: serverTimestamp()}, {merge: true}));
    }
    await assertFails(setDoc(doc(authedDb('bob'), M), {currency: 'USD', updatedAt: serverTimestamp()}));
  });
});

describe('firestore: money — challenges (D34)', () => {
  beforeEach(async () => {
    await seedDoc('couples/c1', validCouple({memberIds: PAIR, createdByUserId: 'alice'}));
  });

  it('own: owner creates a valid challenge; shape is checked', async () => {
    const db = authedDb('alice');
    const C = (id) => doc(db, OWN('alice', 'moneyChallenges', id));
    await assertSucceeds(setDoc(C('a'), challenge('alice')));
    await assertSucceeds(setDoc(C('b'), challenge('alice', {kind: 'cap', categoryIds: [], limit: 500000})));
    await assertFails(setDoc(C('c'), challenge('alice', {kind: 'cap', limit: 0})));
    await assertFails(setDoc(C('d'), challenge('alice', {limit: 5})));
    await assertFails(setDoc(C('e'), challenge('alice', {days: 10})));
    await assertFails(setDoc(C('f'), challenge('alice', {title: ''})));
    await assertFails(setDoc(C('g'), challenge('alice', {title: 'x'.repeat(41)})));
    await assertFails(setDoc(C('h'), challenge('alice', {categoryIds: Array.from({length: 13}, (_, i) => `c${i}`)})));
    await assertFails(setDoc(C('i'), challenge('alice', {cancelled: true})));
    await assertFails(setDoc(C('j'), challenge('alice', {createdAt: TS})));
    await assertFails(setDoc(C('k'), challenge('bob')));
    await assertFails(setDoc(C('l'), challenge('alice', {kind: 'streak'})));
    await assertFails(setDoc(doc(authedDb('bob'), OWN('alice', 'moneyChallenges', 'm')), challenge('bob')));
    await assertFails(getDoc(doc(authedDb('bob'), OWN('alice', 'moneyChallenges', 'a'))));
  });

  it('own: only cancelling is an allowed edit; no delete', async () => {
    const P = OWN('alice', 'moneyChallenges', 'x');
    await seedDoc(P, stored(challenge('alice')));
    const db = authedDb('alice');
    await assertFails(updateDoc(doc(db, P), {days: 30, updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(doc(db, P), {cancelled: true, updatedAt: TS}));
    await assertSucceeds(updateDoc(doc(db, P), {cancelled: true, updatedAt: serverTimestamp()}));
    await assertFails(deleteDoc(doc(db, P)));
  });

  it('shared: both members create / read / cancel; others cannot', async () => {
    const P = SH('moneyChallenges', 's1');
    await assertSucceeds(setDoc(doc(authedDb('bob'), P), challenge('bob')));
    await assertSucceeds(getDoc(doc(authedDb('alice'), P)));
    await assertFails(getDoc(doc(authedDb('dave'), P)));
    await assertFails(setDoc(doc(authedDb('dave'), SH('moneyChallenges', 's2')), challenge('dave')));
    await assertSucceeds(updateDoc(doc(authedDb('alice'), P), {cancelled: true, updatedAt: serverTimestamp()}));
    await assertFails(deleteDoc(doc(authedDb('alice'), P)));
  });
});

describe('firestore: money — shared book', () => {
  beforeEach(async () => {
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  const W = SH('moneyWallets', 'joint');
  const T = SH('moneyTx', 's1');

  it('both members create + read; outsiders cannot', async () => {
    await assertSucceeds(setDoc(doc(authedDb('alice'), W), sharedWallet('alice')));
    await assertSucceeds(getDoc(doc(authedDb('bob'), W)));
    await assertFails(getDoc(doc(authedDb('dave'), W)));
    await assertSucceeds(setDoc(doc(authedDb('bob'), T), sharedExpense('bob')));
    await assertSucceeds(getDoc(doc(authedDb('alice'), T)));
    await assertFails(getDoc(doc(authedDb('dave'), T)));
    await assertFails(setDoc(doc(authedDb('dave'), SH('moneyTx', 'x')), sharedExpense('dave')));
  });

  it('memberUids must be the couple, in order, exactly 2', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, T), sharedExpense('alice', {memberUids: ['bob', 'alice']})));
    await assertFails(setDoc(doc(db, T), sharedExpense('alice', {memberUids: ['alice']})));
    await assertFails(setDoc(doc(db, T), sharedExpense('alice', {memberUids: ['alice', 'bob', 'dave']})));
    await assertFails(setDoc(doc(db, T), sharedExpense('alice', {memberUids: ['alice', 'dave']})));
    await assertFails(setDoc(doc(db, W), sharedWallet('alice', {memberUids: ['alice', 'dave']})));
  });

  it('a waiting couple has no shared book', async () => {
    await seedWaitingCouple('cw', 'carol');
    await assertFails(setDoc(doc(authedDb('carol'), 'couples/cw/moneyTx/x'),
      sharedExpense('carol', {memberUids: ['carol']})));
    await assertFails(setDoc(doc(authedDb('carol'), 'couples/cw/moneyBudgets/b'), budget('carol')));
  });

  it('the pair query (memberUids ==) works for members', async () => {
    await seedDoc(T, stored(sharedExpense('alice')));
    const q = query(collection(authedDb('bob'), 'couples/c1/moneyTx'),
      where('memberUids', '==', PAIR), where('date', '>=', '2026-10-01'));
    await assertSucceeds(getDocs(q));
    await assertFails(getDocs(collection(authedDb('dave'), 'couples/c1/moneyTx')));
  });

  it('the wallet sums (aggregate) work for the pair only', async () => {
    await seedDoc(T, stored(sharedExpense('alice', {payer: 'wallet', outWalletId: 'joint', amount: 480000})));
    const sums = (db) => getAggregateFromServer(query(collection(db, 'couples/c1/moneyTx'),
      where('memberUids', '==', PAIR), where('outWalletId', '==', 'joint')), {t: sum('amount')});
    const r = await assertSucceeds(sums(authedDb('bob')));
    if (r.data().t !== 480000) throw new Error(`joint sums ${JSON.stringify(r.data())}`);
    await assertFails(sums(authedDb('dave')));
    // Without the pair filter the rules cannot prove access.
    await assertFails(getAggregateFromServer(query(collection(authedDb('alice'), 'couples/c1/moneyTx'),
      where('payer', '==', 'alice')), {t: sum('amount')}));
  });

  it('someone who joins later cannot read the old pair\'s money; the one who stayed can', async () => {
    await seedDoc(T, stored(sharedExpense('alice')));
    await seedDoc(W, stored(sharedWallet('alice')));
    // bob leaves, dave joins alice's couple.
    await seedDoc('couples/c1', validCouple({memberIds: ['alice', 'dave'], createdByUserId: 'alice'}));
    await assertFails(getDoc(doc(authedDb('dave'), T)));
    await assertFails(getDoc(doc(authedDb('dave'), W)));
    await assertFails(getDocs(query(collection(authedDb('dave'), 'couples/c1/moneyTx'),
      where('memberUids', '==', PAIR))));
    await assertSucceeds(getDoc(doc(authedDb('alice'), T)));
    await assertFails(getDoc(doc(authedDb('bob'), T)));
    await assertFails(updateDoc(doc(authedDb('dave'), T), edit('dave', {note: 'x'})));
    await assertFails(deleteDoc(doc(authedDb('dave'), T)));
  });

  it('payer is a member or the shared wallet (which needs outWalletId)', async () => {
    const db = authedDb('alice');
    await assertSucceeds(setDoc(doc(db, T), sharedExpense('alice', {payer: 'bob'})));
    await assertFails(setDoc(doc(db, SH('moneyTx', 'a')), sharedExpense('alice', {payer: 'dave'})));
    await assertFails(setDoc(doc(db, SH('moneyTx', 'b')),
      sharedExpense('alice', {payer: 'wallet'})));
    await assertSucceeds(setDoc(doc(db, SH('moneyTx', 'c')),
      sharedExpense('alice', {payer: 'wallet', outWalletId: 'joint'})));
  });

  it('a person paid ⇒ no shared wallet pays too (no double count)', async () => {
    const db = authedDb('alice');
    // alice paid AND the shared wallet paid: wallet −120k + couple balance +60k.
    await assertFails(setDoc(doc(db, SH('moneyTx', 'd1')), sharedExpense('alice', {outWalletId: 'joint'})));
    await assertFails(setDoc(doc(db, SH('moneyTx', 'd2')), sharedExpense('alice', {payer: 'bob', outWalletId: 'joint'})));
    await assertFails(setDoc(doc(db, SH('moneyTx', 'd3')), sharedExpense('alice',
      {type: 'transfer', categoryId: '', outWalletId: 'joint', inWalletId: 'dalat'})));
    await assertSucceeds(setDoc(doc(db, SH('moneyTx', 'd4')), sharedExpense('alice',
      {type: 'transfer', categoryId: '', payer: 'wallet', outWalletId: 'joint', inWalletId: 'dalat'})));
    // Editing a person-paid entry onto the shared wallet must switch the payer.
    const T2 = SH('moneyTx', 'd5');
    await seedDoc(T2, stored(sharedExpense('alice')));
    await assertFails(updateDoc(doc(db, T2), edit('alice', {outWalletId: 'joint'})));
    await assertSucceeds(updateDoc(doc(db, T2),
      edit('alice', {outWalletId: 'joint', payer: 'wallet'})));
  });

  it('splitMode / payerShare are gone (D34)', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, T), sharedExpense('alice', {payerShare: 60000})));
    await assertFails(setDoc(doc(db, T), sharedExpense('alice', {splitMode: 'equal'})));
    await assertSucceeds(setDoc(doc(db, T), sharedExpense('alice')));
  });

  it('shared entries need their shared keys', async () => {
    const plain = expense('alice', {outWalletId: '', memberUids: PAIR});
    await assertFails(setDoc(doc(authedDb('alice'), T), plain));
  });

  it('settle is gone from the shared book too (D34)', async () => {
    await assertFails(setDoc(doc(authedDb('bob'), T),
      sharedExpense('bob', {type: 'settle', categoryId: '', amount: 170000})));
  });

  it('contribution goes INTO a shared wallet, paid by a person', async () => {
    const db = authedDb('alice');
    const c = sharedExpense('alice', {type: 'contribution', inWalletId: 'dalat', categoryId: '',
      amount: 2000000, linkId: 'L5'});
    await assertSucceeds(setDoc(doc(db, T), c));
    // em ghi hộ "anh góp" is allowed: payer = the partner.
    await assertSucceeds(setDoc(doc(db, SH('moneyTx', 'a')), {...c, payer: 'bob'}));
    await assertFails(setDoc(doc(db, SH('moneyTx', 'b')), {...c, inWalletId: '', outWalletId: 'dalat'}));
  });

  it('both members edit any entry; a forged updatedBy or a skipped editCount is refused', async () => {
    await seedDoc(T, stored(sharedExpense('alice')));
    await assertFails(updateDoc(doc(authedDb('bob'), T), edit('alice', {note: 'Lẩu'})));
    await assertFails(updateDoc(doc(authedDb('bob'), T), edit('bob', {note: 'Lẩu', editCount: 2})));
    await assertSucceeds(updateDoc(doc(authedDb('bob'), T), edit('bob', {note: 'Lẩu'})));
  });

  it('two edits from the same starting point: the second is refused', async () => {
    await seedDoc(T, stored(sharedExpense('alice')));
    await assertSucceeds(updateDoc(doc(authedDb('alice'), T), edit('alice', {amount: 480000})));
    await assertFails(updateDoc(doc(authedDb('bob'), T), edit('bob', {note: 'stale', editCount: 1})));
  });

  it('memberUids / createdBy / type are immutable', async () => {
    await seedDoc(T, stored(sharedExpense('alice')));
    const db = authedDb('alice');
    await assertFails(updateDoc(doc(db, T), edit('alice', {memberUids: ['bob', 'alice']})));
    await assertFails(updateDoc(doc(db, T), edit('alice', {createdBy: 'bob'})));
    await assertFails(updateDoc(doc(db, T), edit('alice', {type: 'contribution', categoryId: ''})));
  });

  it('a linked entry: the partner edits note/category/date but not the money', async () => {
    await seedDoc(T, stored(sharedExpense('alice', {linkId: 'L2', amount: 480000})));
    const bob = authedDb('bob');
    await assertSucceeds(updateDoc(doc(bob, T), edit('bob', {note: 'Lẩu Thái', categoryId: 'food_market', date: '2026-10-19'})));
    for (const change of [{amount: 48000}, {payer: 'bob'}, {outWalletId: 'joint', payer: 'wallet'}]) {
      await assertFails(updateDoc(doc(bob, T), edit('bob', {...change, editCount: 2})));
    }
    await assertSucceeds(updateDoc(doc(authedDb('alice'), T), edit('alice', {amount: 520000, editCount: 2})));
  });

  it('a linked entry is deleted only by its creator; plain ones by either member', async () => {
    await seedDoc(T, stored(sharedExpense('alice', {linkId: 'L2'})));
    await seedDoc(SH('moneyTx', 'plain'), stored(sharedExpense('alice')));
    await assertFails(deleteDoc(doc(authedDb('bob'), T)));
    await assertSucceeds(deleteDoc(doc(authedDb('alice'), T)));
    await assertSucceeds(deleteDoc(doc(authedDb('bob'), SH('moneyTx', 'plain'))));
  });

  it('shared wallets: no delete, no client goalReachedAt', async () => {
    const db = authedDb('alice');
    const G = SH('moneyWallets', 'dalat');
    await assertFails(setDoc(doc(db, G), sharedWallet('alice',
      {type: 'goal', goalTarget: 5000000, goalReachedAt: serverTimestamp()})));
    await seedDoc(G, stored(sharedWallet('alice', {type: 'goal', goalTarget: 5000000})));
    await assertFails(updateDoc(doc(db, G), {goalReachedAt: serverTimestamp(), updatedAt: serverTimestamp()}));
    await assertSucceeds(updateDoc(doc(authedDb('bob'), G), {name: 'Quỹ Đà Lạt', updatedAt: serverTimestamp()}));
    await assertFails(deleteDoc(doc(db, G)));
  });

  it('a CF-stamped goalReachedAt survives other edits', async () => {
    const G = SH('moneyWallets', 'dalat');
    await seedDoc(G, stored(sharedWallet('alice', {type: 'goal', goalTarget: 5000000, goalReachedAt: TS})));
    await assertSucceeds(updateDoc(doc(authedDb('alice'), G), {archived: true, updatedAt: serverTimestamp()}));
  });

  it('budgets: members read/write, `alerted` is CF-only', async () => {
    const B = SH('moneyBudgets', 'total');
    await assertSucceeds(setDoc(doc(authedDb('alice'), B), budget('alice')));
    await assertSucceeds(getDoc(doc(authedDb('bob'), B)));
    await assertFails(getDoc(doc(authedDb('dave'), B)));
    await assertFails(setDoc(doc(authedDb('alice'), SH('moneyBudgets', 'x')), budget('alice', {alerted: {}})));
    await assertFails(setDoc(doc(authedDb('alice'), SH('moneyBudgets', 'auto')), budget('alice')));
    await assertSucceeds(setDoc(doc(authedDb('bob'), SH('moneyBudgets', 'food')), budget('bob', {categoryId: 'food'})));
    await seedDoc(B, stored(budget('alice', {alerted: {'2026-10': 80}})));
    await assertFails(updateDoc(doc(authedDb('bob'), B), {'alerted.2026-10': 100, updatedAt: serverTimestamp()}));
    await assertSucceeds(updateDoc(doc(authedDb('bob'), B), {amount: 6000000, updatedAt: serverTimestamp()}));
    await assertSucceeds(deleteDoc(doc(authedDb('bob'), B)));
  });

  it('meta: members read/write `main`', async () => {
    const M = SH('moneyMeta', 'main');
    await assertSucceeds(setDoc(doc(authedDb('bob'), M), {overrides: {food_coffee: {name: 'Trà sữa', emoji: ''}}, updatedAt: serverTimestamp()}));
    await assertSucceeds(getDoc(doc(authedDb('alice'), M)));
    await assertFails(getDoc(doc(authedDb('dave'), M)));
    await assertFails(setDoc(doc(authedDb('dave'), M), {updatedAt: serverTimestamp()}));
    await assertSucceeds(setDoc(doc(authedDb('alice'), M), {currency: 'USD', updatedAt: serverTimestamp()}, {merge: true}));
    await assertFails(setDoc(doc(authedDb('alice'), M), {currency: 'XYZ', updatedAt: serverTimestamp()}, {merge: true}));
    await assertFails(setDoc(doc(authedDb('dave'), M), {currency: 'USD', updatedAt: serverTimestamp()}));
  });

  it('guests cannot touch either book', async () => {
    await assertFails(setDoc(doc(unauthedDb(), T), sharedExpense('alice')));
    await assertFails(setDoc(doc(unauthedDb(), OWN('alice', 'moneyTx', 'x')), expense('alice')));
    await assertFails(getDocs(collection(unauthedDb(), 'couples/c1/moneyWallets')));
  });

  it('shared wallet: shared keys required, 31-char name refused', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, W), wallet('alice', {name: 'Ví chung'})));
    await assertFails(setDoc(doc(db, W), sharedWallet('alice', {name: 'x'.repeat(31)})));
    await assertFails(setDoc(doc(db, W), sharedWallet('alice', {createdAt: TS})));
  });

  it('old collections are untouched (decisions still work next to money)', async () => {
    await assertSucceeds(setDoc(doc(authedDb('alice'), 'couples/c1/decisions/2026-10-21_eat'), {
      kind: 'eat', date: '2026-10-21', question: '', options: [], filter: 'tuy', result: 'Bún chả',
      resultId: 'bun_cha', spins: 1, byUserId: 'alice', createdBy: 'alice',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
  });
});
