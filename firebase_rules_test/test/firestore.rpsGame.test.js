// Oẳn tù tì rules (feature rps-game) —
// couples/{coupleId}/games/{gameId} + .../moves/{uid}.
//
// The client may only: create an `invited` game (creator pinned), heartbeat
// its OWN presence key, and drive invited → playing / cancelled / expired.
// `finished`, `result`, `finishedAt`, `moved`, `lastNudgeAt` are
// Cloud-Function-only. A move is create-once, only while `playing` — with NO
// deadline since the 2026-09-14 rule change (no "skip turn": the round waits
// for both players); the partner's move stays unreadable until the game is
// `finished` (anti-cheat lives here, not in the UI), even though the parent's
// `moved` map says who has already thrown.

const {
  doc,
  collection,
  collectionGroup,
  query,
  getDocs,
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
  seedDoc,
  seedActiveCouple,
  seedWaitingCouple,
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

  it('rejects creating with the CF-only moved / lastNudgeAt fields', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {moved: {alice: serverTimestamp()}})),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), GAME), validGame('alice', {lastNudgeAt: serverTimestamp()})),
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

  it('rejects a presence value that is not the server clock (RPS-11)', async () => {
    await seedDoc(GAME, seededGame());
    // Backdated / pre-dated client timestamps.
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': new Date()}),
    );
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': new Date(Date.now() + 60 * 1000)}),
    );
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {'presence.alice': secondsAgo(30)}),
    );
    // Same on create.
    await assertFails(
      setDoc(doc(authedDb('bob'), 'couples/c1/games/g2'), validGame('bob', {
        presence: {bob: new Date()},
      })),
    );
  });

  it('rejects wiping the whole presence map (would drop the partner key)', async () => {
    await seedDoc(GAME, seededGame({presence: {alice: secondsAgo(1)}}));
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {presence: deleteField()}),
    );
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {presence: {bob: serverTimestamp()}}),
    );
  });

  // ---- invited → playing ---------------------------------------------------
  // Starting needs the PARTNER's presence on the doc, fresher than 10s by the
  // server clock (RPS-5 — no starting alone to farm timeout wins).
  it('lets a member start the game when the partner is present (fresh <10s)', async () => {
    await seedDoc(GAME, seededGame({presence: {alice: secondsAgo(2)}}));
    await assertSucceeds(
      updateDoc(doc(authedDb('bob'), GAME), {
        status: 'playing',
        startedAt: serverTimestamp(),
        'presence.bob': serverTimestamp(),
      }),
    );
  });

  it('rejects starting alone (partner never present on the game)', async () => {
    // alice created the game and is present; bob never opened it.
    await seedDoc(GAME, seededGame({presence: {alice: secondsAgo(1)}}));
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {
        status: 'playing',
        startedAt: serverTimestamp(),
        'presence.alice': serverTimestamp(),
      }),
    );
    // No presence map at all.
    const noPresence = seededGame();
    delete noPresence.presence;
    await seedDoc(GAME, noPresence);
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {
        status: 'playing',
        startedAt: serverTimestamp(),
      }),
    );
  });

  it('rejects starting when the partner presence is 11s old', async () => {
    await seedDoc(GAME, seededGame({presence: {alice: secondsAgo(11), bob: secondsAgo(1)}}));
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {
        status: 'playing',
        startedAt: serverTimestamp(),
        'presence.bob': serverTimestamp(),
      }),
    );
  });

  it('rejects starting a game in a 1-member (waiting) couple', async () => {
    await seedWaitingCouple('cw', 'carol');
    const WG = 'couples/cw/games/g1';
    // Creating is harmless (client blocks it — RPS-12) but can never start.
    await assertSucceeds(setDoc(doc(authedDb('carol'), WG), validGame('carol')));
    await assertFails(
      updateDoc(doc(authedDb('carol'), WG), {
        status: 'playing',
        startedAt: serverTimestamp(),
        'presence.carol': serverTimestamp(),
      }),
    );
  });

  it('rejects starting with a wrong or missing startedAt', async () => {
    await seedDoc(GAME, seededGame({presence: {alice: secondsAgo(1)}}));
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {status: 'playing', startedAt: TS}),
    );
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {status: 'playing'}),
    );
  });

  it('rejects starting when startedAt already exists', async () => {
    await seedDoc(GAME, seededGame({presence: {alice: secondsAgo(1)}, startedAt: TS}));
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

  it('rejects cancelledBy without the invited → cancelled transition (RPS-10)', async () => {
    await seedDoc(GAME, seededGame());
    // Partner planting their own uid on an invited game.
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {cancelledBy: 'bob'}),
    );
    // Even the creator can't set it without actually cancelling.
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {cancelledBy: 'alice'}),
    );
    // Nor piggy-back it on a heartbeat / on a playing game.
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {
        'presence.bob': serverTimestamp(),
        cancelledBy: 'bob',
      }),
    );
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: TS}));
    await assertFails(
      updateDoc(doc(authedDb('alice'), GAME), {cancelledBy: 'alice'}),
    );
  });

  it('keeps heartbeats working on a doc that already carries cancelledBy', async () => {
    await seedDoc(GAME, seededGame({status: 'cancelled', cancelledBy: 'alice'}));
    await assertSucceeds(
      updateDoc(doc(authedDb('bob'), GAME), {'presence.bob': serverTimestamp()}),
    );
    await assertFails(
      updateDoc(doc(authedDb('bob'), GAME), {cancelledBy: 'bob'}),
    );
  });

  it('lets the creator cancel without cancelledBy', async () => {
    await seedDoc(GAME, seededGame());
    await assertSucceeds(
      updateDoc(doc(authedDb('alice'), GAME), {status: 'cancelled', updatedAt: serverTimestamp()}),
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

  it('forbids clients adding moved / lastNudgeAt (2026-09-14)', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(30)}));
    const alice = doc(authedDb('alice'), GAME);
    await assertFails(updateDoc(alice, {moved: {alice: serverTimestamp()}}));
    await assertFails(updateDoc(alice, {'moved.alice': serverTimestamp()}));
    await assertFails(updateDoc(alice, {'moved.bob': serverTimestamp()}));
    await assertFails(updateDoc(alice, {lastNudgeAt: serverTimestamp()}));
    // Piggy-backed on a legit heartbeat: still denied.
    await assertFails(updateDoc(alice, {
      'presence.alice': serverTimestamp(),
      'moved.alice': serverTimestamp(),
    }));
    await assertFails(updateDoc(alice, {
      'presence.alice': serverTimestamp(),
      lastNudgeAt: serverTimestamp(),
    }));
  });

  it('forbids clients changing or dropping moved / lastNudgeAt written by the CF', async () => {
    await seedDoc(GAME, seededGame({
      status: 'playing',
      startedAt: secondsAgo(30),
      moved: {alice: TS},
      lastNudgeAt: TS,
    }));
    const alice = doc(authedDb('alice'), GAME);
    const bob = doc(authedDb('bob'), GAME);
    // bob pretends to have thrown / wipes alice's stamp
    await assertFails(updateDoc(bob, {'moved.bob': serverTimestamp()}));
    await assertFails(updateDoc(bob, {'moved.alice': deleteField()}));
    await assertFails(updateDoc(bob, {moved: deleteField()}));
    // alice resets the nudge cooldown
    await assertFails(updateDoc(alice, {lastNudgeAt: deleteField()}));
    await assertFails(updateDoc(alice, {lastNudgeAt: serverTimestamp()}));
    // …while a plain heartbeat carrying both fields through still works.
    await assertSucceeds(updateDoc(alice, {'presence.alice': serverTimestamp()}));
    await assertSucceeds(updateDoc(bob, {'presence.bob': serverTimestamp()}));
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

  it('lets a member submit a move while playing (just started)', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(1)}));
    await assertSucceeds(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove()));
    await assertSucceeds(setDoc(doc(authedDb('bob'), MOVE('bob')), validMove({choice: 'paper'})));
  });

  it('rejects a move while the game is still invited', async () => {
    await seedDoc(GAME, seededGame());
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove()));
  });

  it('accepts a move long after startedAt + 7s — no skip turn (2026-09-14)', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(10)}));
    await assertSucceeds(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove()));
  });

  it('accepts a move minutes later, after the partner has thrown', async () => {
    await seedDoc(GAME, seededGame({
      status: 'playing',
      startedAt: minutesAgo(5),
      moved: {alice: TS},
      lastNudgeAt: TS,
    }));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await assertSucceeds(setDoc(doc(authedDb('bob'), MOVE('bob')), validMove({choice: 'paper'})));
  });

  it('still rejects a late move on a game that is not playing', async () => {
    await seedDoc(GAME, seededGame({createdAt: minutesAgo(5)}));
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove()));
    await seedDoc(GAME, seededGame({status: 'expired', createdAt: minutesAgo(11)}));
    await assertFails(setDoc(doc(authedDb('alice'), MOVE('alice')), validMove()));
    await seedDoc(GAME, seededGame({status: 'cancelled', cancelledBy: 'alice'}));
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

  it('keeps the partner\'s move hidden while playing even when moved says they threw', async () => {
    await seedDoc(GAME, seededGame({
      status: 'playing',
      startedAt: minutesAgo(3),
      moved: {alice: TS, bob: TS},
    }));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await seedDoc(MOVE('bob'), {choice: 'paper', createdAt: TS});
    await assertFails(getDoc(doc(authedDb('alice'), MOVE('bob'))));
    await assertFails(getDoc(doc(authedDb('bob'), MOVE('alice'))));
    await assertFails(getDocs(collection(authedDb('alice'), `${GAME}/moves`)));
    await assertSucceeds(getDoc(doc(authedDb('alice'), MOVE('alice'))));
  });

  it('reveals both moves once the game is finished', async () => {
    await seedDoc(GAME, seededGame({status: 'finished', startedAt: TS, finishedAt: TS}));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await seedDoc(MOVE('bob'), {choice: 'paper', createdAt: TS});
    await assertSucceeds(getDoc(doc(authedDb('alice'), MOVE('bob'))));
    await assertSucceeds(getDoc(doc(authedDb('bob'), MOVE('alice'))));
  });

  it('forbids listing the moves subcollection while playing', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(1)}));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await seedDoc(MOVE('bob'), {choice: 'paper', createdAt: TS});
    await assertFails(getDocs(collection(authedDb('alice'), `${GAME}/moves`)));
    await assertFails(getDocs(collection(authedDb('bob'), `${GAME}/moves`)));
  });

  it('allows listing the moves of a finished game', async () => {
    await seedDoc(GAME, seededGame({status: 'finished', startedAt: TS, finishedAt: TS}));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await seedDoc(MOVE('bob'), {choice: 'paper', createdAt: TS});
    await assertSucceeds(getDocs(collection(authedDb('alice'), `${GAME}/moves`)));
  });

  it('forbids a collectionGroup query on moves (playing or finished)', async () => {
    await seedDoc(GAME, seededGame({status: 'playing', startedAt: secondsAgo(1)}));
    await seedDoc(MOVE('bob'), {choice: 'paper', createdAt: TS});
    await assertFails(getDocs(query(collectionGroup(authedDb('alice'), 'moves'))));
    await seedDoc(GAME, seededGame({status: 'finished', startedAt: TS, finishedAt: TS}));
    await assertFails(getDocs(query(collectionGroup(authedDb('alice'), 'moves'))));
  });

  it('forbids an outsider reading any move', async () => {
    await seedDoc(GAME, seededGame({status: 'finished', startedAt: TS, finishedAt: TS}));
    await seedDoc(MOVE('alice'), {choice: 'rock', createdAt: TS});
    await assertFails(getDoc(doc(authedDb('dave'), MOVE('alice'))));
  });
});
