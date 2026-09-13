// Oẳn tù tì rules (feature rps-game) —
// couples/{coupleId}/games/{gameId} + .../moves/{uid}.
//
// The client may only: create an `invited` game (creator pinned), heartbeat
// its OWN presence key, and drive invited → playing / cancelled / expired.
// `finished`, `result`, `finishedAt` are Cloud-Function-only. A move is
// create-once, only while `playing` and within startedAt + 7s; the partner's
// move stays unreadable until the game is `finished` (anti-cheat lives here,
// not in the UI).

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

const GAME = 'couples/c1/games/g1';
const MOVE = (uid) => `${GAME}/moves/${uid}`;

const minutesAgo = (m) => new Date(Date.now() - m * 60 * 1000);
const secondsAgo = (s) => new Date(Date.now() - s * 1000);

describe('firestore: rps game', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  const validGame = (uid, overrides = {}) => ({
    type: 'rps',
    createdBy: uid,
    status: 'invited',
    createdAt: serverTimestamp(),
    presence: {[uid]: serverTimestamp()},
    ...overrides,
  });

  const seededGame = (overrides = {}) => ({
    type: 'rps',
    createdBy: 'alice',
    status: 'invited',
    createdAt: TS,
    presence: {alice: TS},
    ...overrides,
  });

  // ---- create --------------------------------------------------------------
  it('lets a member create an invited game (own presence, rematchOf, updatedAt)', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {
        rematchOf: 'g0',
        updatedAt: serverTimestamp(),
      })),
    );
  });

  it('lets a member create a game without presence', async () => {
    const data = validGame('bob');
    delete data.presence;
    await assertSucceeds(setDoc(doc(authedDb('bob'), GAME), data));
  });

  it('rejects creating with a status other than invited', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {status: 'playing'})),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {status: 'finished'})),
    );
  });

  it('rejects spoofing createdBy to the partner', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {createdBy: 'bob'})),
    );
  });

  it('rejects a missing or non-rps type', async () => {
    const noType = validGame('alice');
    delete noType.type;
    await assertFails(setDoc(doc(authedDb('alice'), GAME), noType));
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {type: 'tictactoe'})),
    );
  });

  it('rejects a client-chosen createdAt and unexpected keys', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {createdAt: TS})),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {result: {winnerUid: 'alice'}})),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {startedAt: serverTimestamp()})),
    );
  });

  it('rejects creating with the partner\'s presence key', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {
        presence: {alice: serverTimestamp(), bob: serverTimestamp()},
      })),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {
        presence: {bob: serverTimestamp()},
      })),
    );
  });

  it('forbids an outsider creating a game', async () => {
    await assertFails(
      setDoc(doc(authedDb('dave'), GAME), validGame('dave')),
    );
  });

  // ---- read ----------------------------------------------------------------
  it('lets both members read a game, outsider cannot', async () => {
    await seedDoc(GAME, seededGame());
    await assertSucceeds(getDoc(doc(authedDb('alice'), GAME)));
    await assertSucceeds(getDoc(doc(authedDb('bob'), GAME)));
    await assertFails(getDoc(doc(authedDb('dave'), GAME)));
  });

  // ---- presence ------------------------------------------------------------
  it('lets each member heartbeat only their own presence key', async () => {
    await seedDoc(GAME, seededGame());
    await assertSucceeds(
      updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': serverTimestamp()}),
    );
    await assertSucceeds(
      updateDoc(doc(authedDb('alice'), GAME), {'presence.alice': serverTimestamp()}),
    );
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {'presence.bob': serverTimestamp()}),
    );
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {
        presence: {alice: serverTimestamp(), bob: serverTimestamp()},
      }),
    );
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': 'now'}),
    );
  });

  it('still allows a presence heartbeat on a finished game (result untouched)', async () => {
    await seedDoc(GAME, seededGame({
      status: 'finished',
      startedAt: TS,
      finishedAt: TS,
      result: {winnerUid: 'alice', choices: {alice: 'rock', bob: 'scissors'}, reason: 'normal'},
    }));
    await assertSucceeds(
      updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': serverTimestamp()}),
    );
  });

  // ---- invited → playing ---------------------------------------------------
  it('lets a member start the game with a server-stamped startedAt', async () => {
    await seedDoc(GAME, seededGame());
    await assertSucceeds(
      updateDoc(doc(authedDb('bob'), GAME), {
        status: 'playing',
        startedAt: serverTimestamp(),
        'presence.bob': serverTimestamp(),
      }),
    );
  });

  it('rejects starting with a wrong or missing startedAt', async () => {
    await seedDoc(GAME, seededGame());
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {status: 'playing', startedAt: TS}),
    );
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {status: 'playing'}),
    );
  });

  it('rejects starting when startedAt already exists', async () => {
    await seedDoc(GAME, seededGame({startedAt: TS}));
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {status: 'playing', startedAt: serverTimestamp()}),
    );
  });

  it('rejects startedAt changes without a status transition', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: TS}));
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {startedAt: serverTimestamp()}),
    );
  });

  // ---- invited → cancelled / expired --------------------------------------
  it('lets only the creator cancel an invited game', async () => {
    await seedDoc(GAME, seededGame());
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {status: 'cancelled', cancelledBy: 'bob'}),
    );
    await assertSucceeds(
      updateDoc(doc(authedDb('alice'), GAME), {status: 'cancelled', cancelledBy: 'alice'}),
    );
  });

  it('rejects cancelledBy pointing at someone else', async () => {
    await seedDoc(GAME, seededGame());
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {status: 'cancelled', cancelledBy: 'bob'}),
    );
  });

  it('rejects expiring a game younger than 10 minutes', async () => {
    await seedDoc(GAME, seededGame({createdAt: minutesAgo(3)}));
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {status: 'expired'}),
    );
  });

  it('lets either member expire a game older than 10 minutes', async () => {
    await seedDoc(GAME, seededGame({createdAt: minutesAgo(11)}));
    await assertSucceeds(
      updateDoc(doc(authedDb('bob'), GAME), {status: 'expired'}),
    );
  });

  it('rejects cancelling / expiring a game that is already playing', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: TS, createdAt: minutesAgo(11)}));
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {status: 'cancelled'}),
    );
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {status: 'expired'}),
    );
  });

  // ---- CF-only fields ------------------------------------------------------
  it('forbids clients finishing a game or writing result / finishedAt', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: TS}));
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {status: 'finished'}),
    );
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {
        result: {winnerUid: 'alice', choices: {alice: 'rock', bob: 'none'}, reason: 'timeout'},
      }),
    );
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {finishedAt: serverTimestamp()}),
    );
  });

  it('forbids tampering with a stored result', async () => {
    await seedDoc(GAME, seededGame({
      status: 'finished',
      startedAt: TS,
      finishedAt: TS,
      result: {winnerUid: 'alice', choices: {alice: 'rock', bob: 'scissors'}, reason: 'normal'},
    }));
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {'result.winnerUid': 'bob'}),
    );
  });

  it('forbids changing type / createdBy / createdAt / rematchOf', async () => {
    await seedDoc(GAME, seededGame({rematchOf: 'g0'}));
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {type: 'other'}));
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {createdBy: 'bob'}));
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {createdAt: serverTimestamp()}));
    await assertFails(updateDoc(doc(authedDb('alice'), GAME), {rematchOf: 'g9'}));
  });

  it('forbids deleting a game and any outsider update', async () => {
    await seedDoc(GAME, seededGame());
    await assertFails(deleteDoc(doc(authedDb('alice'), GAME)));
    await assertFails(
      updateDoc(doc(authedDb('dave'), GAME), {'presence.dave': serverTimestamp()}),
    );
  });

  // ---- moves ---------------------------------------------------------------
  const validMove = (overrides = {}) => ({
    choice: 'rock',
    createdAt: serverTimestamp(),
    ...overrides,
  });

  it('lets a member submit a move while playing and within 7s', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(1)}));
    await assertSucceeds(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove()));
    await assertSucceeds(setDoc(doc(authedDb('bob'), MOVE('bob')), validMove({choice: 'paper'})));
  });

  it('rejects a move while the game is still invited', async () => {
    await seedDoc(GAME, seededGame());
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove()));
  });

  it('rejects a move after startedAt + 7s', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(10)}));
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove()));
  });

  it('rejects a move on a finished game', async () => {
    await seedDoc(GAME, seededGame({status: 'finished', startedAt: secondsAgo(1), finishedAt: TS}));
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove()));
  });

  it('rejects an unknown choice, extra fields and a client-chosen createdAt', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(1)}));
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove({choice: 'lizard'})));
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove({note: 'x'})));
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove({createdAt: TS})));
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), {choice: 'rock'}));
  });

  it('rejects writing a move on behalf of the partner or as an outsider', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(1)}));
    await assertFails(setDoc(doc(authedDb('bob'), MOVE('alice')), validMove()));
    await assertFails(setDoc(doc(authedDb('dave'), MOVE('dave')), validMove()));
  });

  it('forbids changing or deleting a submitted move', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(1)}));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await assertFails(updateDoc(doc(authedDb('alice'), MOVE('alice')), {choice: 'paper'}));
    await assertFails(
      setDoc(doc(authedDb('alice'), MOVE('alice')), validMove({choice: 'paper'})),
    );
    await assertFails(deleteDoc(doc(authedDb('alice'), MOVE('alice'))));
  });

  it('hides the partner\'s move until the game is finished', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(1)}));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await seedDoc(MOVE('bob'), {choice: 'paper', createdAt: TS});
    // own move: always readable
    await assertSucceeds(getDoc(doc(authedDb('alice'), MOVE('alice'))));
    await assertSucceeds(getDoc(doc(authedDb('bob'), MOVE('bob'))));
    // partner's move: hidden while playing
    await assertFails(getDoc(doc(authedDb('alice'), MOVE('bob'))));
    await assertFails(getDoc(doc(authedDb('bob'), MOVE('alice'))));
  });

  it('reveals both moves once the game is finished', async () => {
    await seedDoc(GAME, seededGame({status: 'finished', startedAt: TS, finishedAt: TS}));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await seedDoc(MOVE('bob'), {choice: 'paper', createdAt: TS});
    await assertSucceeds(getDoc(doc(authedDb('alice'), MOVE('bob'))));
    await assertSucceeds(getDoc(doc(authedDb('bob'), MOVE('alice'))));
  });

  it('forbids an outsider reading any move', async () => {
    await seedDoc(GAME, seededGame({status: 'finished', startedAt: TS, finishedAt: TS}));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await assertFails(getDoc(doc(authedDb('dave'), MOVE('alice'))));
  });
});
