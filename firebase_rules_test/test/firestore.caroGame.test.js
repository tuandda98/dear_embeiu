// Cờ caro rules (feature caro-game, overview §6.1) —
// couples/{coupleId}/games/{gameId} with type 'caro' + caroState/{docId}.
//
// Only the `caroAction` callable (Admin SDK) creates or changes a caro game;
// a member may only heartbeat / clear their OWN presence key. caroState is
// read-only for members. The rps branch keeps working exactly as before
// (firestore.rpsGame.test.js) and can never be used to edit a caro doc.

const {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  deleteField,
  serverTimestamp,
} = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  seedDoc,
  seedActiveCouple,
  TS,
} = require('./helpers');

const GAME = 'couples/c1/games/k1';
const STATE = 'couples/c1/caroState/main';
const RPS = 'couples/c1/games/r1';

const caroGame = (overrides = {}) => ({
  type: 'caro',
  rule: 'vn',
  size: 15,
  createdBy: 'alice',
  createdAt: TS,
  players: {x: 'alice', o: 'bob'},
  status: 'playing',
  cells: [112],
  turnUid: 'bob',
  lastMoveAt: TS,
  lastMoveBy: 'alice',
  presence: {alice: TS},
  updatedAt: TS,
  ...overrides,
});

describe('firestore: caro game', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  // ---- read ----------------------------------------------------------------
  it('lets members read a caro game; outsiders and guests cannot', async () => {
    await seedDoc(GAME, caroGame());
    await assertSucceeds(getDoc(doc(authedDb('alice'), GAME)));
    await assertSucceeds(getDoc(doc(authedDb('bob'), GAME)));
    await assertFails(getDoc(doc(authedDb('dave'), GAME)));
    await assertFails(getDoc(doc(unauthedDb(), GAME)));
  });

  it('lets members read caroState; outsiders cannot', async () => {
    await seedDoc(STATE, {openGameId: 'k1', wins: {alice: 2}, draws: 0, updatedAt: TS});
    await assertSucceeds(getDoc(doc(authedDb('alice'), STATE)));
    await assertSucceeds(getDoc(doc(authedDb('bob'), STATE)));
    await assertFails(getDoc(doc(authedDb('dave'), STATE)));
  });

  // ---- create ----------------------------------------------------------------
  it('forbids a client creating a caro game (callable only)', async () => {
    const data = caroGame({createdAt: serverTimestamp(), presence: {alice: serverTimestamp()}});
    await assertFails(setDoc(doc(authedDb('alice'), GAME), data));
    // Not even with the rps create shape.
    await assertFails(setDoc(doc(authedDb('alice'), GAME), {
      type: 'caro',
      createdBy: 'alice',
      status: 'invited',
      createdAt: serverTimestamp(),
    }));
  });

  // ---- presence ------------------------------------------------------------
  it('lets each player heartbeat their own presence key', async () => {
    await seedDoc(GAME, caroGame());
    await assertSucceeds(updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': serverTimestamp()}));
    await assertSucceeds(updateDoc(doc(authedDb('alice'), GAME), {'presence.alice': serverTimestamp()}));
  });

  it('lets a player clear their own presence key', async () => {
    await seedDoc(GAME, caroGame({presence: {alice: TS, bob: TS}}));
    await assertSucceeds(updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': deleteField()}));
  });

  it('allows a heartbeat on a finished game (result screen)', async () => {
    await seedDoc(GAME, caroGame({
      status: 'finished',
      result: {winnerUid: 'alice', reason: 'five', line: [0, 1, 2, 3, 4]},
      finishedAt: TS,
    }));
    await assertSucceeds(updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': serverTimestamp()}));
  });

  it('rejects writing the partner\'s presence key', async () => {
    await seedDoc(GAME, caroGame());
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {'presence.alice': serverTimestamp()}));
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {'presence.alice': deleteField(), 'presence.bob': serverTimestamp()}));
  });

  it('rejects wiping or overwriting the whole presence map', async () => {
    await seedDoc(GAME, caroGame());
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {presence: deleteField()}));
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {presence: {bob: serverTimestamp()}}));
  });

  it('rejects a presence value that is not the server clock', async () => {
    await seedDoc(GAME, caroGame());
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': new Date()}));
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': 'now'}));
  });

  it('forbids an outsider touching presence', async () => {
    await seedDoc(GAME, caroGame());
    await assertFails(updateDoc(doc(authedDb('dave'), GAME), {'presence.dave': serverTimestamp()}));
  });

  // ---- CF-only fields --------------------------------------------------------
  it('rejects a client placing a stone (cells) — alone or with a heartbeat', async () => {
    await seedDoc(GAME, caroGame());
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {cells: [112, 113]}));
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {
      cells: [112, 113],
      'presence.bob': serverTimestamp(),
    }));
    // Rewriting an old move.
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {cells: [0]}));
  });

  it('rejects a client changing turnUid / status / players', async () => {
    await seedDoc(GAME, caroGame());
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {turnUid: 'alice'}));
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {status: 'cancelled'}));
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {players: {x: 'bob', o: 'alice'}}));
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {rule: 'free'}));
  });

  it('rejects a client declaring a result', async () => {
    await seedDoc(GAME, caroGame());
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {
      status: 'finished',
      result: {winnerUid: 'bob', reason: 'five', line: [0, 1, 2, 3, 4]},
      finishedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {
      result: {winnerUid: 'bob', reason: 'resign', line: []},
    }));
  });

  it('rejects a client touching the cooldown fields (lastNudgeAt / lastWakeAt)', async () => {
    await seedDoc(GAME, caroGame({lastNudgeAt: TS, lastWakeAt: {bob: TS}}));
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {lastNudgeAt: deleteField()}));
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {lastNudgeAt: serverTimestamp()}));
    await assertFails(updateDoc(doc(authedDb('bob'), GAME), {lastWakeAt: {bob: serverTimestamp()}}));
  });

  it('forbids deleting a caro game', async () => {
    await seedDoc(GAME, caroGame());
    await assertFails(deleteDoc(doc(authedDb('alice'), GAME)));
  });

  // ---- moves / caroState -------------------------------------------------------
  it('forbids a moves doc under a caro game (even one with startedAt)', async () => {
    await seedDoc(GAME, caroGame({startedAt: TS}));
    await assertFails(setDoc(doc(authedDb('bob'), `${GAME}/moves/bob`), {
      choice: 'rock',
      createdAt: serverTimestamp(),
    }));
  });

  it('forbids any client write to caroState', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), STATE), {openGameId: null, wins: {alice: 99}}));
    await seedDoc(STATE, {openGameId: 'k1', wins: {alice: 2}, draws: 0, updatedAt: TS});
    await assertFails(updateDoc(doc(authedDb('alice'), STATE), {'wins.alice': 3}));
    await assertFails(deleteDoc(doc(authedDb('bob'), STATE)));
  });

  // ---- rps unaffected (app 1.11.0) ---------------------------------------------
  it('keeps the rps flow working next to a caro game', async () => {
    await seedDoc(GAME, caroGame());
    await assertSucceeds(setDoc(doc(authedDb('alice'), RPS), {
      type: 'rps',
      createdBy: 'alice',
      status: 'invited',
      createdAt: serverTimestamp(),
      presence: {alice: serverTimestamp()},
    }));
    await assertSucceeds(updateDoc(doc(authedDb('bob'), RPS), {'presence.bob': serverTimestamp()}));
    await assertSucceeds(updateDoc(doc(authedDb('alice'), RPS), {
      status: 'cancelled',
      cancelledBy: 'alice',
      updatedAt: serverTimestamp(),
    }));
  });

  it('never lets the rps update branch edit a caro doc', async () => {
    // A caro doc trimmed to rps-only keys would pass the rps hasOnly list;
    // the type guard still sends it to the caro branch (presence only).
    await seedDoc(GAME, {
      type: 'caro',
      createdBy: 'alice',
      status: 'invited',
      createdAt: TS,
      presence: {alice: TS},
    });
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {
      status: 'cancelled',
      cancelledBy: 'alice',
    }));
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {updatedAt: serverTimestamp()}));
  });
});
