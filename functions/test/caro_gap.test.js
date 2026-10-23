// Gap tests for caro-game (test-cases.md "chưa phủ → đề xuất unit"): the
// callable wrapper `caroAction`, cross-couple isolation, teardown, push
// suppression. Same "lift the declaration verbatim" trick as caro.test.js.

const test = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const SRC = fs.readFileSync(path.join(__dirname, "..", "index.js"), "utf8");
const MIN = 60 * 1000;
const N = 15;
const at = (r, c) => r * N + c;

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
function callable(name, deps) {
  const start = SRC.indexOf(`exports.${name} = onCall(`);
  assert.notStrictEqual(start, -1, `${name} not found in index.js`);
  const end = SRC.indexOf("\n);", start);
  const body = `const exports = {};\n${SRC.slice(start, end + 3)}\nreturn exports.${name};`;
  return new Function(...Object.keys(deps), body)(...Object.values(deps));
}
// `const NAME = <literal>;` up to the first "\n};" or ";\n".
function constant(name) {
  const start = SRC.indexOf(`const ${name} =`);
  assert.notStrictEqual(start, -1, `${name} not found`);
  const end = SRC.indexOf(";\n", start);
  return SRC.slice(start, end + 2);
}

class HttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}
const quietLogger = {warn() {}, info() {}, error() {}};
const rpsToMillis = load("rpsToMillis", ["function rpsToMillis"]);

// ---- in-memory Firestore (serialised transactions, TS = fake clock) --------

function fakeDb(docs, clock) {
  const store = new Map(Object.entries(docs));
  let chain = Promise.resolve();
  const INC = Symbol("inc");
  const resolve = (v) => (v === "TS" ? clock.now : v);
  const merge = (prev, data) => {
    const out = {...(prev || {})};
    for (const [k, v] of Object.entries(data)) {
      if (v && v[INC] !== undefined) out[k] = (out[k] || 0) + v[INC];
      else if (v && typeof v === "object" && !Array.isArray(v)) out[k] = merge(out[k], v);
      else out[k] = resolve(v);
    }
    return out;
  };
  const snap = (p) => ({
    id: p.split("/").pop(), exists: store.has(p), data: () => store.get(p), get: (f) => (store.get(p) || {})[f],
  });
  let auto = 0;
  const reads = [];
  const ref = (p) => ({
    path: p, id: p.split("/").pop(),
    collection: (n) => col(`${p}/${n}`),
    get: async () => (reads.push(p), snap(p)),
    update: async (d) => store.set(p, merge(store.get(p), d)),
  });
  const col = (p) => ({doc: (id) => ref(`${p}/${id || `auto${++auto}`}`)});
  const db = {
    collection: (n) => col(n),
    runTransaction: (fn) => {
      const run = chain.then(() => fn({
        get: async (r) => (reads.push(r.path), snap(r.path)),
        set: (r, d, o) => store.set(r.path, o && o.merge ? merge(store.get(r.path), d) : merge({}, d)),
        update: (r, d) => store.set(r.path, merge(store.get(r.path), d)),
      }));
      chain = run.catch(() => null);
      return run;
    },
  };
  const admin = {firestore: {FieldValue: {
    serverTimestamp: () => "TS", increment: (n) => ({[INC]: n}), delete: () => undefined,
  }}};
  return {store, db, admin, reads};
}

const CARO_HEADS = [
  "function isDocId", "function caroWinner", "function caroCell", "function caroGameParts",
  "function caroMoveError", "function caroNudgeWaitMs", "function caroShouldWake",
  "function caroPresenceFresh", "function caroGamesRef", "function caroStateRef",
  "function caroEndedWake", "async function caroRunOp",
];

function harness(docs) {
  const clock = {now: 1_000_000_000_000};
  const f = fakeDb(docs, clock);
  const consts = {
    CARO_SIZE: 15, CARO_STALE_MS: 7 * 24 * 60 * MIN, CARO_NUDGE_COOLDOWN_MS: 30 * MIN,
    CARO_WAKE_EVERY_MS: 30 * MIN, CARO_PRESENCE_FRESH_MS: 45 * 1000, CARO_INVITE_QUIET_MS: 2 * MIN,
  };
  const deps = {
    db: f.db, admin: f.admin, ...consts, rpsToMillis,
    rpsPresenceMillis: (p, uid) => (p && typeof p === "object" ? rpsToMillis(p[uid]) : null),
  };
  const caroRunOp = load("caroRunOp", CARO_HEADS, deps);
  const op = async (name, ctx) => {
    const real = Date.now;
    Date.now = () => clock.now;
    try {
      return await caroRunOp(name, {coupleId: "C", cell: null, moveNo: -1, rule: "vn", rematchOf: "", gameId: "", ...ctx});
    } finally {
      Date.now = real;
    }
  };
  // The callable, over the same fake store; pushes are captured.
  const pushes = [];
  const CALLABLE_ERROR_COPY = load("CALLABLE_ERROR_COPY", ["const CALLABLE_ERROR_COPY"]);
  const handler = callable("caroAction", {
    onCall: (o, h) => h, HttpsError, logger: quietLogger,
    callableErrorCopy: load("callableErrorCopy", ["function callableErrorCopy"], {CALLABLE_ERROR_COPY}),
    CALLABLE_ERROR_COPY,
    CARO_ERROR_COPY: load("CARO_ERROR_COPY", ["const CARO_ERROR_COPY"]),
    CARO_OPS: ["start", "move", "resign", "cancel", "expire", "nudge"],
    CARO_RULES: ["vn", "free"],
    isDocId: load("isDocId", ["function isDocId"]),
    caroCell: load("caroCell", ["function caroCell"], {CARO_SIZE: 15}),
    rpsLoadMemberIds: load("rpsLoadMemberIds", ["async function rpsLoadMemberIds"], {db: f.db}),
    caroRunOp: async (o, c) => {
      const real = Date.now;
      Date.now = () => clock.now;
      try {
        return await caroRunOp(o, c);
      } finally {
        Date.now = real;
      }
    },
    caroQuietIfSeen: async (c, g, p, push) => push,
    sendCaroPush: async (c, g, push) => pushes.push(push),
  });
  return {op, handler, pushes, ...f, clock};
}

const COUPLE = {"couples/C": {memberIds: ["alice", "bob"]}};
const gameDoc = (s, id) => s.get(`couples/C/games/${id}`);
const state = (s) => s.get("couples/C/caroState/main") || {};
function fiveSoon(extra = {}) {
  const cells = [at(7, 3), at(0, 0), at(7, 4), at(0, 2), at(7, 5), at(0, 4), at(7, 6), at(0, 6)];
  return {
    ...COUPLE,
    "couples/C/caroState/main": {openGameId: "g", wins: {alice: 2}, draws: 1},
    "couples/C/games/g": {type: "caro", rule: "vn", status: "playing", players: {x: "alice", o: "bob"},
      cells, turnUid: "alice", lastMoveAt: 1_000_000_000_000 - MIN, ...extra},
  };
}

// ---- SEC-27..32: the callable layer ----------------------------------------

test("SEC-27 caroAction: no auth → unauthenticated, in the caller's language", async () => {
  const h = harness(COUPLE);
  await assert.rejects(h.handler({auth: null, data: {coupleId: "C", op: "start"}}), {code: "unauthenticated", message: /đăng nhập/});
  await assert.rejects(h.handler({data: {coupleId: "C", op: "start", lang: "en"}}), {code: "unauthenticated", message: /sign in/i});
});

test("SEC-28 caroAction: junk coupleId / gameId → invalid-argument, Firestore untouched", async () => {
  const h = harness(COUPLE);
  const bad = ["C/games/g", "x".repeat(129), "a b", "", "..", {}];
  for (const id of bad) {
    await assert.rejects(h.handler({auth: {uid: "alice"}, data: {coupleId: id, op: "start", cell: 112}}), {code: "invalid-argument"}, `couple ${JSON.stringify(id)}`);
    await assert.rejects(h.handler({auth: {uid: "alice"}, data: {coupleId: "C", op: "move", gameId: id}}), {code: "invalid-argument"}, `game ${JSON.stringify(id)}`);
  }
  assert.deepStrictEqual(h.reads, []);
});

test("SEC-29 caroAction: unknown / missing op → invalid-argument", async () => {
  const h = harness(COUPLE);
  for (const op of ["delete", "setRule", "", undefined, "START"]) {
    await assert.rejects(h.handler({auth: {uid: "alice"}, data: {coupleId: "C", op, gameId: "g"}}), {code: "invalid-argument"}, String(op));
  }
  assert.deepStrictEqual(h.reads, []);
});

test("SEC-30 caroAction: a stranger → permission-denied; missing couple → not-found", async () => {
  const h = harness(fiveSoon());
  await assert.rejects(h.handler({auth: {uid: "mallory"}, data: {coupleId: "C", op: "resign", gameId: "g"}}), {code: "permission-denied"});
  await assert.rejects(h.handler({auth: {uid: "alice"}, data: {coupleId: "Z", op: "resign", gameId: "g"}}), {code: "not-found"});
  assert.strictEqual(gameDoc(h.store, "g").status, "playing");
  assert.deepStrictEqual(h.pushes, []);
});

test("SEC-31 a gameId of another couple is not found (read under the caller's couple path)", async () => {
  const h = harness({
    ...COUPLE,
    "couples/D": {memberIds: ["eve", "dan"]},
    "couples/D/games/gd": {type: "caro", rule: "vn", status: "playing", players: {x: "eve", o: "dan"},
      cells: [1], turnUid: "dan"},
  });
  for (const op of ["resign", "move", "nudge", "cancel", "expire"]) {
    const r = await h.handler({auth: {uid: "alice"}, data: {coupleId: "C", op, gameId: "gd", cell: 5, moveNo: 1}});
    assert.deepStrictEqual(r, {ok: false, reason: "not_playing"}, op);
  }
  assert.strictEqual(h.store.get("couples/D/games/gd").status, "playing");
  assert.ok(!h.reads.some((p) => p.startsWith("couples/D/")), h.reads.join(","));
});

test("SEC-32 start with a foreign / path-like rematchOf: no crash, nothing foreign read", async () => {
  const h = harness({...COUPLE, "couples/D/games/gd": {type: "caro", status: "finished"}});
  const pathLike = await h.op("start", {uid: "alice", cell: 112, rematchOf: "../D/games/gd"});
  assert.strictEqual(pathLike.reply.ok, true);
  assert.strictEqual(gameDoc(h.store, pathLike.reply.gameId).rematchOf, undefined);
  assert.ok(!h.reads.some((p) => p.includes("couples/D")));
  // Plain id that only exists in another couple: read under OUR path → missing → no presence, no crash.
  const h2 = harness({...COUPLE, "couples/D/games/gd": {type: "caro", status: "finished", presence: {bob: 1_000_000_000_000}}});
  const r = await h2.op("start", {uid: "alice", cell: 112, rematchOf: "gd"});
  assert.strictEqual(r.reply.ok, true);
  assert.strictEqual(r.push.inboxOnly, false);
  assert.ok(!h2.reads.some((p) => p.startsWith("couples/D/")));
});

// ---- RS-01 / RS-04 ----------------------------------------------------------

test("RS-04 caroAction: start with rule 'abc' (or none) falls back to vn; 'free' is kept", async () => {
  for (const [rule, want] of [["abc", "vn"], [undefined, "vn"], [7, "vn"], ["free", "free"], ["vn", "vn"]]) {
    const h = harness(COUPLE);
    const r = await h.handler({auth: {uid: "alice"}, data: {coupleId: "C", op: "start", cell: 112, rule}});
    assert.strictEqual(r.ok, true);
    assert.strictEqual(gameDoc(h.store, r.gameId).rule, want, String(rule));
  }
});

test("RS-01 the rule is locked per game: no op rewrites `rule`, a rule sent with move/resign is ignored", async () => {
  const h = harness(fiveSoon({rule: "free"}));
  const r = await h.handler({auth: {uid: "alice"}, data: {coupleId: "C", op: "move", gameId: "g", cell: at(10, 10), moveNo: 8, rule: "vn"}});
  assert.strictEqual(r.ok, true);
  assert.strictEqual(gameDoc(h.store, "g").rule, "free");
  await h.handler({auth: {uid: "bob"}, data: {coupleId: "C", op: "resign", gameId: "g", rule: "vn"}});
  assert.strictEqual(gameDoc(h.store, "g").rule, "free");
  assert.ok(!/CARO_OPS = \[[^\]]*rule/i.test(SRC));
});

// ---- SEC-34 / RACE-11 / NOTI-11 ---------------------------------------------

test("SEC-34 move after the game finished → not_playing, score not counted twice", async () => {
  const h = harness(fiveSoon());
  const win = await h.op("move", {uid: "alice", gameId: "g", cell: at(7, 7), moveNo: 8});
  assert.strictEqual(win.reply.status, "finished");
  assert.strictEqual(state(h.store).wins.alice, 3);
  const again = await h.op("move", {uid: "bob", gameId: "g", cell: at(9, 9), moveNo: 9});
  assert.deepStrictEqual(again.reply, {ok: false, reason: "not_playing"});
  const again2 = await h.op("move", {uid: "alice", gameId: "g", cell: at(7, 8), moveNo: 9});
  assert.deepStrictEqual(again2.reply, {ok: false, reason: "not_playing"});
  assert.strictEqual(state(h.store).wins.alice, 3);
  assert.strictEqual(gameDoc(h.store, "g").cells.length, 9);
});

test("RACE-11 rpsRecordMoveInTransaction / nudgeRpsPlayer on a caro game → not_playing, nothing written", async () => {
  const docs = {
    ...COUPLE,
    "couples/C/games/g": {type: "caro", status: "playing", players: {x: "alice", o: "bob"}, cells: [1], turnUid: "bob"},
  };
  const h = harness(docs);
  const gameRef = h.db.collection("couples").doc("C").collection("games").doc("g");
  const record = load("rpsRecordMoveInTransaction", ["async function rpsRecordMoveInTransaction"], {
    db: h.db, admin: h.admin,
  });
  assert.deepStrictEqual(await record(gameRef, ["alice", "bob"]), {ok: false, reason: "not_playing"});
  const nudge = callable("nudgeRpsPlayer", {
    onCall: (o, fn) => fn, HttpsError, logger: quietLogger, db: h.db,
    isDocId: load("isDocId", ["function isDocId"]),
    rpsLoadMemberIds: load("rpsLoadMemberIds", ["async function rpsLoadMemberIds"], {db: h.db}),
    rpsToMillis, rpsMovedMap: () => ({}), RPS_NUDGE_COOLDOWN_MS: 60_000, admin: h.admin,
  });
  assert.deepStrictEqual(await nudge({auth: {uid: "alice"}, data: {coupleId: "C", gameId: "g"}}), {ok: false, reason: "not_playing"});
  assert.deepStrictEqual(h.store.get("couples/C/games/g").cells, [1]);
});

test("NOTI-11 move while the recipient watches (presence < 45 s) → no push; stale presence → push", async () => {
  const now = 1_000_000_000_000;
  const watching = harness(fiveSoon({presence: {bob: now - 10_000}}));
  const a = await watching.op("move", {uid: "alice", gameId: "g", cell: at(10, 10), moveNo: 8});
  assert.strictEqual(a.reply.ok, true);
  assert.strictEqual(a.push, null);
  const away = harness(fiveSoon({presence: {bob: now - 60_000}}));
  const b = await away.op("move", {uid: "alice", gameId: "g", cell: at(10, 10), moveNo: 8});
  assert.strictEqual(b.push.type, "caro_turn");
  assert.strictEqual(b.push.recipientId, "bob");
});

// ---- END-17 / END-20 / SEC-35 -----------------------------------------------

test("END-17 caroCleanupOnLeave: expiring the open game fails → state doc is still deleted", async () => {
  const log = [];
  const gameRef = {
    get: async () => ({exists: true, get: (k) => ({type: "caro", status: "playing"})[k]}),
    update: async () => {
      throw new Error("boom");
    },
  };
  const stateRef = {
    get: async () => ({exists: true, get: (k) => ({openGameId: "g"})[k]}),
    delete: async () => log.push("state deleted"),
  };
  const run = load("caroCleanupOnLeave", ["async function caroCleanupOnLeave"], {
    caroStateRef: () => stateRef,
    caroGamesRef: () => ({doc: () => gameRef}),
    isDocId: load("isDocId", ["function isDocId"]),
    logger: {warn: () => log.push("warned"), info() {}, error() {}},
    admin: {firestore: {FieldValue: {serverTimestamp: () => "TS"}}},
  });
  await run("C");
  assert.deepStrictEqual(log, ["warned", "state deleted"]);
});

test("END-20 / SEC-35 deleteCoupleCompletely sweeps games and caroState", async () => {
  const log = [];
  const col = (p) => ({path: p, get: async () => ({docs: []}), doc: (id) => ref(`${p}/${id}`)});
  const ref = (p) => ({
    path: p, id: p.split("/").pop(),
    collection: (n) => col(`${p}/${n}`),
    get: async () => ({exists: false, get: () => undefined}),
    delete: async () => log.push(`delete ${p}`),
  });
  const db = {collection: (n) => col(n), recursiveDelete: async (r) => log.push(`recursiveDelete ${r.path}`)};
  const fn = load("deleteCoupleCompletely", ["async function deleteCoupleCompletely", "async function deleteStoragePrefix"], {
    db, logger: quietLogger, isDocId: load("isDocId", ["function isDocId"]),
    admin: {storage: () => ({bucket: () => ({deleteFiles: async ({prefix}) => log.push(`sweep ${prefix}`)})})},
  });
  await fn(ref("couples/C"), {memberIds: ["alice", "bob"]});
  assert.ok(log.includes("recursiveDelete couples/C/games"), log.join("\n"));
  assert.ok(log.includes("recursiveDelete couples/C/caroState"), log.join("\n"));
  assert.ok(log.includes("delete couples/C"));
});
