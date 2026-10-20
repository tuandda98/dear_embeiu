// Unit tests for the caro pieces of functions/index.js (feature caro-game) —
// same "lift the declaration verbatim" trick as index.test.js.

const test = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const SRC = fs.readFileSync(path.join(__dirname, "..", "index.js"), "utf8");

function declaration(head) {
  const start = SRC.indexOf(head);
  assert.notStrictEqual(start, -1, `"${head}" not found in index.js`);
  const close = SRC.indexOf("\n}", start);
  return SRC.slice(start, SRC.indexOf("\n", close + 1));
}

function load(name, heads, deps = {}) {
  const body = `${heads.map(declaration).join("\n")}\nreturn ${name};`;
  return new Function(...Object.keys(deps), body)(...Object.values(deps));
}

const N = 15;
const at = (r, c) => r * N + c;
const row = (r, cols) => cols.map((c) => at(r, c));
// X stones and O stones interleaved into play order (X first); the last
// array element is the move just played.
function seq(xs, os) {
  const out = [];
  for (let i = 0; i < Math.max(xs.length, os.length); i++) {
    if (i < xs.length) out.push(xs[i]);
    if (i < os.length) out.push(os[i]);
  }
  return out;
}

const caroWinner = load("caroWinner", ["function caroWinner"]);
const win = (cells, rule = "vn") => caroWinner(cells, N, rule);

// ---- caroWinner ------------------------------------------------------------

test("caro: five in a row wins horizontally, vertically and on both diagonals", () => {
  const filler = row(14, [0, 2, 4, 6]);
  const lines = {
    horizontal: row(7, [3, 4, 5, 6, 7]),
    vertical: [2, 3, 4, 5, 6].map((r) => at(r, 9)),
    diagonal: [0, 1, 2, 3, 4].map((i) => at(3 + i, 3 + i)),
    antiDiagonal: [0, 1, 2, 3, 4].map((i) => at(3 + i, 11 - i)),
  };
  for (const [name, xs] of Object.entries(lines)) {
    const r = win(seq(xs, filler));
    assert.strictEqual(r.winner, "x", name);
    assert.deepStrictEqual([...r.line].sort((a, b) => a - b), [...xs].sort((a, b) => a - b), name);
    assert.strictEqual(r.full, false, name);
  }
});

test("caro: the winning move may be in the middle of the run", () => {
  // X plays 3,4,6,7 then 5 → 3..7.
  const xs = row(7, [3, 4, 6, 7, 5]);
  const r = win(seq(xs, row(12, [0, 2, 4, 6])));
  assert.strictEqual(r.winner, "x");
  assert.deepStrictEqual(r.line, row(7, [3, 4, 5, 6, 7]));
});

test("caro: four in a row does not win", () => {
  assert.strictEqual(win(seq(row(7, [3, 4, 5, 6]), row(9, [1, 2, 3]))).winner, null);
});

test("caro vn: five blocked at both ends by the opponent does not win", () => {
  const cells = seq(row(7, [3, 4, 5, 6, 7]), [...row(7, [2, 8]), ...row(9, [1, 2])]);
  assert.strictEqual(win(cells, "vn").winner, null);
});

test("caro vn: five blocked at one end wins", () => {
  const cells = seq(row(7, [3, 4, 5, 6, 7]), [...row(7, [2]), ...row(9, [1, 2, 3])]);
  assert.strictEqual(win(cells, "vn").winner, "x");
});

test("caro vn: the board edge is not a block", () => {
  // X 0..4 on row 7, O right after at col 5: edge + opponent = still a win.
  const cells = seq(row(7, [0, 1, 2, 3, 4]), [...row(7, [5]), ...row(9, [1, 2, 3])]);
  assert.strictEqual(win(cells, "vn").winner, "x");
  // Corner diagonal: edge on one side, O on the other.
  const diag = [0, 1, 2, 3, 4].map((i) => at(i, i));
  assert.strictEqual(win(seq(diag, [at(5, 5), ...row(12, [0, 2, 4])]), "vn").winner, "x");
});

test("caro vn: six in a row wins when not blocked at both ends", () => {
  const cells = seq(row(7, [2, 3, 4, 5, 6, 7]), [...row(7, [1]), ...row(9, [1, 3, 5, 7])]);
  const r = win(cells, "vn");
  assert.strictEqual(r.winner, "x");
  assert.strictEqual(r.line.length, 6);
});

test("caro vn: six in a row blocked at both ends does not win", () => {
  const cells = seq(row(7, [2, 3, 4, 5, 6, 7]), [...row(7, [1, 8]), ...row(9, [1, 3, 5])]);
  assert.strictEqual(win(cells, "vn").winner, null);
});

test("caro free: five blocked at both ends still wins", () => {
  const cells = seq(row(7, [3, 4, 5, 6, 7]), [...row(7, [2, 8]), ...row(9, [1, 2])]);
  assert.strictEqual(win(cells, "free").winner, "x");
});

test("caro: O wins on an odd move", () => {
  const cells = seq(row(0, [0, 2, 4, 6, 8, 10]), row(5, [5, 6, 7, 8, 9]));
  assert.strictEqual(cells.length, 11);
  // Last move is X's 6th stone at (0,10) — no win; drop it so O moves last.
  const r = win(cells.slice(0, 10));
  assert.strictEqual(r.winner, "o");
});

test("caro: only lines through the last move count", () => {
  // X has five on row 7 (unseen: game would have ended), last move is O far away.
  const cells = [...seq(row(7, [3, 4, 5, 6, 7]), row(9, [1, 3, 5, 7])), at(12, 12)];
  assert.strictEqual(cells.length % 2, 0); // last = O
  assert.strictEqual(win(cells).winner, null);
});

test("caro: a full board without five is a draw (both rules)", () => {
  // Pairs "XXOO…" per row, each row shifted (found by a small search) so no
  // column or diagonal holds five either. 113 X + 112 O.
  const shift = [0, 0, 0, 0, 2, 0, 0, 0, 1, 2, 1, 0, 1, 1, 2];
  const xs = [];
  const os = [];
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      (Math.floor((c + shift[r]) / 2) % 2 === 0 ? xs : os).push(at(r, c));
    }
  }
  assert.deepStrictEqual([xs.length, os.length], [113, 112]);
  const cells = seq(xs, os);
  assert.strictEqual(cells.length, N * N);
  // Guard the fixture: no prefix ends a game (else the draw would be moot).
  for (let i = 1; i <= cells.length; i++) {
    assert.strictEqual(caroWinner(cells.slice(0, i), N, "free").winner, null, `move ${i}`);
  }
  for (const rule of ["vn", "free"]) {
    const r = win(cells, rule);
    assert.strictEqual(r.winner, null, rule);
    assert.strictEqual(r.full, true, rule);
  }
  assert.strictEqual(win(cells.slice(0, 100)).full, false);
});

test("caro: empty board", () => {
  assert.deepStrictEqual(win([]), {winner: null, line: [], full: false});
});

// ---- caroMoveError ------------------------------------------------------------

const caroMoveError = load("caroMoveError", ["function caroGameParts", "function caroMoveError"]);

test("caro move: legal move, then every refusal reason", () => {
  const members = ["alice", "bob"];
  const game = {
    type: "caro",
    status: "playing",
    players: {x: "alice", o: "bob"},
    cells: [at(7, 7)],
    turnUid: "bob",
  };
  assert.strictEqual(caroMoveError(game, members, "bob", at(7, 8), 1), null);
  assert.strictEqual(caroMoveError(game, members, "alice", at(7, 8), 1), "not_your_turn");
  assert.strictEqual(caroMoveError(game, members, "mallory", at(7, 8), 1), "not_player");
  assert.strictEqual(caroMoveError(game, members, "bob", at(7, 8), 0), "stale");
  assert.strictEqual(caroMoveError(game, members, "bob", at(7, 8), 2), "stale");
  assert.strictEqual(caroMoveError(game, members, "bob", null, 1), "out_of_range");
  assert.strictEqual(caroMoveError(game, members, "bob", at(7, 7), 1), "occupied");
  assert.strictEqual(caroMoveError({...game, status: "finished"}, members, "bob", at(7, 8), 1), "not_playing");
  assert.strictEqual(caroMoveError({...game, type: "rps"}, members, "bob", at(7, 8), 1), "not_playing");
  // A player left the couple: the game is dead.
  assert.strictEqual(caroMoveError(game, ["bob", "carol"], "bob", at(7, 8), 1), "not_playing");
});

test("caro cell: only integers on the 15×15 board", () => {
  const caroCell = load("caroCell", ["function caroCell"], {CARO_SIZE: 15});
  assert.strictEqual(caroCell(0), 0);
  assert.strictEqual(caroCell(224), 224);
  for (const bad of [-1, 225, 1.5, "7", null, undefined, NaN]) {
    assert.strictEqual(caroCell(bad), null, String(bad));
  }
});

// ---- cooldowns -------------------------------------------------------------------

const rpsToMillis = load("rpsToMillis", ["function rpsToMillis"]);
const MIN = 60 * 1000;

test("caro nudge: 30' after the later of my last move and the last nudge", () => {
  const wait = load("caroNudgeWaitMs", ["function caroNudgeWaitMs"], {
    rpsToMillis,
    CARO_NUDGE_COOLDOWN_MS: 30 * MIN,
  });
  const now = 1_000_000_000;
  assert.strictEqual(wait({lastMoveAt: now - 10 * MIN}, now), 20 * MIN);
  assert.strictEqual(wait({lastMoveAt: now - 31 * MIN}, now), 0);
  assert.strictEqual(wait({lastMoveAt: now - 60 * MIN, lastNudgeAt: now - 5 * MIN}, now), 25 * MIN);
  assert.strictEqual(wait({lastMoveAt: now - 5 * MIN, lastNudgeAt: now - 60 * MIN}, now), 25 * MIN);
});

test("caro wake: at most once per 30' per recipient", () => {
  const shouldWake = load("caroShouldWake", ["function caroShouldWake"], {
    rpsToMillis,
    CARO_WAKE_EVERY_MS: 30 * MIN,
  });
  const now = 1_000_000_000;
  assert.strictEqual(shouldWake({}, "bob", now), true);
  assert.strictEqual(shouldWake(undefined, "bob", now), true);
  assert.strictEqual(shouldWake({bob: now - 10 * MIN}, "bob", now), false);
  assert.strictEqual(shouldWake({bob: now - 30 * MIN}, "bob", now), true);
  assert.strictEqual(shouldWake({alice: now}, "bob", now), true);
});

// ---- copy ---------------------------------------------------------------------------

test("caro push copy: vi / en, name fallback per recipient language", () => {
  const text = load("buildCaroText", ["const CARO_COPY", "function buildCaroText"]);
  assert.deepStrictEqual(text("vi", "turn", "Tuấn", 14), {
    title: "Tuấn vừa đi một nước",
    body: "Đến lượt bạn. Ván đang ở nước 14.",
  });
  assert.deepStrictEqual(text("en", "won", "Thao", 31), {
    title: "Thao won the caro game",
    body: "Five in a row on move 31. Rematch?",
  });
  assert.strictEqual(text("en-US", "invite", "", 1).title, "Your partner started a game of caro");
  assert.strictEqual(text("fr", "nudge", "", 9).title, "Người ấy đang đợi bạn đi");
  assert.strictEqual(text("__proto__", "draw", "x", 225).title, "Ván caro hoà");
  for (const kind of ["invite", "turn", "nudge", "won", "resigned", "draw"]) {
    for (const lang of ["vi", "en"]) {
      const t = text(lang, kind, "A", 3);
      assert.ok(t.title && t.body, `${lang}/${kind}`);
    }
  }
});

// ---- caroRunOp transaction on an in-memory Firestore (review 2026-10-20 #2) ----

// Serialised transactions (what Firestore's retry gives two racing calls),
// `serverTimestamp` = the fake clock, `increment` applied on merge.
function caroFakeDb(docs, clock) {
  const store = new Map(Object.entries(docs));
  let chain = Promise.resolve();
  const INC = Symbol("inc");
  const resolve = (v) => (v === "TS" ? clock.now : v);
  const merge = (prev, data) => {
    const out = {...(prev || {})};
    for (const [k, v] of Object.entries(data)) {
      if (v && v[INC] !== undefined) {
        out[k] = (out[k] || 0) + v[INC];
      } else if (v && typeof v === "object" && !Array.isArray(v)) {
        out[k] = merge(out[k], v);
      } else {
        out[k] = resolve(v);
      }
    }
    return out;
  };
  const snap = (p) => ({
    id: p.split("/").pop(),
    exists: store.has(p),
    data: () => store.get(p),
    get: (f) => (store.get(p) || {})[f],
  });
  let auto = 0;
  const ref = (p) => ({path: p, id: p.split("/").pop(), collection: (n) => col(`${p}/${n}`), get: async () => snap(p)});
  const col = (p) => ({doc: (id) => ref(`${p}/${id || `auto${++auto}`}`)});
  const db = {
    collection: (n) => col(n),
    runTransaction: (fn) => {
      const run = chain.then(() => fn({
        get: async (r) => snap(r.path),
        set: (r, data, opts) => store.set(r.path, opts && opts.merge ? merge(store.get(r.path), data) : merge({}, data)),
        update: (r, data) => store.set(r.path, merge(store.get(r.path), data)),
      }));
      chain = run.catch(() => null);
      return run;
    },
  };
  const admin = {firestore: {FieldValue: {
    serverTimestamp: () => "TS",
    increment: (n) => ({[INC]: n}),
  }}};
  return {store, db, admin};
}

function caroOps(docs) {
  const clock = {now: 1_000_000_000_000};
  const f = caroFakeDb(docs, clock);
  const deps = {
    db: f.db,
    admin: f.admin,
    CARO_SIZE: 15,
    CARO_STALE_MS: 7 * 24 * 60 * MIN,
    CARO_NUDGE_COOLDOWN_MS: 30 * MIN,
    CARO_WAKE_EVERY_MS: 30 * MIN,
    CARO_PRESENCE_FRESH_MS: 45 * 1000,
    rpsToMillis,
    rpsPresenceMillis: (p, uid) => (p && typeof p === "object" ? rpsToMillis(p[uid]) : null),
  };
  const realNow = Date.now;
  const run = load("caroRunOp", [
    "function isDocId",
    "function caroWinner",
    "function caroGameParts",
    "function caroMoveError",
    "function caroNudgeWaitMs",
    "function caroShouldWake",
    "function caroPresenceFresh",
    "function caroGamesRef",
    "function caroStateRef",
    "async function caroRunOp",
  ], deps);
  const op = async (name, ctx) => {
    Date.now = () => clock.now;
    try {
      return await run(name, {coupleId: "C", cell: null, moveNo: -1, rule: "vn", rematchOf: "", gameId: "", ...ctx});
    } finally {
      Date.now = realNow;
    }
  };
  return {op, store: f.store, clock};
}

const COUPLE = {"couples/C": {memberIds: ["alice", "bob"]}};
const state = (s) => s.get("couples/C/caroState/main") || {};
const gameDoc = (s, id) => s.get(`couples/C/games/${id}`);

test("caroRunOp start: two at once → one game, the other gets already_open", async () => {
  const t = caroOps(COUPLE);
  const [a, b] = await Promise.all([
    t.op("start", {uid: "alice", cell: 112}),
    t.op("start", {uid: "bob", cell: 100}),
  ]);
  assert.strictEqual(a.reply.ok, true);
  assert.deepStrictEqual(b.reply, {ok: false, reason: "already_open", gameId: a.reply.gameId});
  assert.strictEqual(state(t.store).openGameId, a.reply.gameId);
  assert.deepStrictEqual(state(t.store).wins, {});
  const g = gameDoc(t.store, a.reply.gameId);
  assert.deepStrictEqual(g.players, {x: "alice", o: "bob"});
  assert.strictEqual(g.turnUid, "bob");
  assert.strictEqual(a.push.type, "caro_invite");
  assert.strictEqual(a.push.wake, true);
});

test("caroRunOp start: open game of an earlier pair is expired, new one made", async () => {
  const t = caroOps({
    ...COUPLE,
    "couples/C/caroState/main": {openGameId: "old", wins: {}, draws: 0},
    "couples/C/games/old": {type: "caro", status: "playing", players: {x: "alice", o: "eve"}, cells: [1], turnUid: "eve"},
  });
  const r = await t.op("start", {uid: "alice", cell: 112});
  assert.strictEqual(r.reply.ok, true);
  assert.strictEqual(gameDoc(t.store, "old").status, "expired");
  assert.strictEqual(state(t.store).openGameId, r.reply.gameId);
});

test("caroRunOp rematch while the partner watches the result: inbox only, no wake", async () => {
  const t = caroOps({
    ...COUPLE,
    "couples/C/games/g1": {type: "caro", status: "finished", players: {x: "alice", o: "bob"}, cells: [1, 2],
      presence: {bob: 1_000_000_000_000 - 5000}},
  });
  const r = await t.op("start", {uid: "alice", cell: 112, rematchOf: "g1"});
  assert.strictEqual(r.push.inboxOnly, true);
  assert.strictEqual(r.push.wake, false);
  assert.strictEqual(gameDoc(t.store, r.reply.gameId).rematchOf, "g1");
});

function fiveSoon(extra = {}) {
  // alice (X) has 4 on row 7, cols 3..6; O stones elsewhere; alice to move.
  const cells = [at(7, 3), at(0, 0), at(7, 4), at(0, 2), at(7, 5), at(0, 4), at(7, 6), at(0, 6)];
  return {
    ...COUPLE,
    "couples/C/caroState/main": {openGameId: "g", wins: {alice: 2}, draws: 1},
    "couples/C/games/g": {type: "caro", rule: "vn", status: "playing", players: {x: "alice", o: "bob"},
      cells, turnUid: "alice", lastMoveAt: 1_000_000_000_000 - MIN, ...extra},
  };
}

test("caroRunOp move: five wins, wins++ and the pointer is cleared", async () => {
  const t = caroOps(fiveSoon());
  const stale = await t.op("move", {uid: "alice", gameId: "g", cell: at(7, 7), moveNo: 7});
  assert.deepStrictEqual(stale.reply, {ok: false, reason: "stale"});
  const r = await t.op("move", {uid: "alice", gameId: "g", cell: at(7, 7), moveNo: 8});
  assert.strictEqual(r.reply.status, "finished");
  const g = gameDoc(t.store, "g");
  assert.strictEqual(g.result.winnerUid, "alice");
  assert.deepStrictEqual(g.result.line, row(7, [3, 4, 5, 6, 7]));
  assert.strictEqual(state(t.store).wins.alice, 3);
  assert.strictEqual(state(t.store).openGameId, null);
  assert.strictEqual(r.push.type, "caro_result");
});

test("caroRunOp move: full board counts a draw", async () => {
  const shift = [0, 0, 0, 0, 2, 0, 0, 0, 1, 2, 1, 0, 1, 1, 2]; // same fixture as above
  const xs = [];
  const os = [];
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      (Math.floor((c + shift[r]) / 2) % 2 === 0 ? xs : os).push(at(r, c));
    }
  }
  const order = seq(xs, os);
  const last = order.pop();
  const t = caroOps({
    ...COUPLE,
    "couples/C/caroState/main": {openGameId: "g", wins: {}, draws: 0},
    "couples/C/games/g": {type: "caro", rule: "vn", status: "playing", players: {x: "alice", o: "bob"},
      cells: order, turnUid: "alice"},
  });
  const r = await t.op("move", {uid: "alice", gameId: "g", cell: last, moveNo: 224});
  assert.strictEqual(r.reply.status, "finished");
  assert.deepStrictEqual(gameDoc(t.store, "g").result, {winnerUid: null, reason: "full", line: []});
  assert.strictEqual(state(t.store).draws, 1);
  assert.strictEqual(r.push.kind, "draw");
});

test("caroRunOp cancel with two stones → stale; nudge by turnUid → stale", async () => {
  const t = caroOps(fiveSoon());
  assert.deepStrictEqual((await t.op("cancel", {uid: "bob", gameId: "g"})).reply, {ok: false, reason: "stale"});
  assert.deepStrictEqual((await t.op("nudge", {uid: "alice", gameId: "g"})).reply, {ok: false, reason: "stale"});
  const early = await t.op("nudge", {uid: "bob", gameId: "g"});
  assert.strictEqual(early.reply.reason, "cooldown");
  assert.strictEqual(early.reply.retryAfterMs, 29 * MIN);
});

test("caroRunOp expire: too early with retryAfterMs, then ok after 7 days; createdAt fallback", async () => {
  const t = caroOps(fiveSoon());
  const early = await t.op("expire", {uid: "bob", gameId: "g"});
  assert.strictEqual(early.reply.reason, "too_early");
  assert.ok(early.reply.retryAfterMs > 0);
  t.clock.now += 8 * 24 * 60 * MIN;
  const ok = await t.op("expire", {uid: "bob", gameId: "g"});
  assert.strictEqual(ok.reply.status, "expired");
  assert.strictEqual(state(t.store).openGameId, null);

  const noMove = caroOps(fiveSoon({lastMoveAt: null, createdAt: 1_000_000_000_000 - MIN}));
  assert.strictEqual((await noMove.op("expire", {uid: "bob", gameId: "g"})).reply.reason, "too_early");
});

test("caroRunOp: ops on a game of an earlier pair → not_playing; resign counts for the other", async () => {
  const t = caroOps({
    ...COUPLE,
    "couples/C/games/x": {type: "caro", status: "playing", players: {x: "alice", o: "eve"}, cells: [1], turnUid: "eve"},
  });
  for (const name of ["resign", "cancel", "expire", "nudge"]) {
    assert.deepStrictEqual((await t.op(name, {uid: "alice", gameId: "x"})).reply, {ok: false, reason: "not_playing"}, name);
  }
  const r = caroOps(fiveSoon());
  await r.op("resign", {uid: "alice", gameId: "g"});
  assert.strictEqual(state(r.store).wins.bob, 1);
  assert.strictEqual(gameDoc(r.store, "g").result.reason, "resign");
});

test("caroRunOp: a couple of one → no_partner", async () => {
  const t = caroOps({"couples/C": {memberIds: ["alice"]}});
  assert.deepStrictEqual((await t.op("start", {uid: "alice", cell: 112})).reply, {ok: false, reason: "no_partner"});
});

test("sendCaroPush: collapseId per game, inbox for invites, inboxOnly skips the phone", async () => {
  const inbox = [];
  const pushes = [];
  const send = load("sendCaroPush", ["async function sendCaroPush"], {
    rpsLoadDisplayName: async () => "Tuấn",
    writeInboxNotifications: async (ids, payload) => inbox.push({ids, payload}),
    sendToRecipientDevices: async (ids, build, data, options) => {
      pushes.push({ids, data, options, vi: build("vi")});
      return {failures: [], deviceCount: 1, successCount: 1};
    },
    buildCaroText: (lang, kind, name, n) => ({title: `${name} ${kind}`, body: `${n}`}),
    logger: {warn: () => {}, info: () => {}, error: () => {}},
  });
  await send("C", "g9", {type: "caro_turn", kind: "turn", actorUid: "alice", recipientId: "bob", moveNo: 14, wake: true});
  assert.strictEqual(inbox.length, 0);
  assert.deepStrictEqual(pushes[0].options, {collapseId: "caro_g9", wakeClients: true});
  assert.deepStrictEqual(pushes[0].data, {type: "caro_turn", coupleId: "C", gameId: "g9", moveNo: "14", actorName: "Tuấn"});
  await send("C", "g9", {type: "caro_invite", kind: "invite", actorUid: "alice", recipientId: "bob", moveNo: 1, inboxOnly: true});
  assert.strictEqual(inbox.length, 1);
  assert.strictEqual(inbox[0].payload.gameId, "g9");
  assert.strictEqual(pushes.length, 1);
});
