// Unit tests for plain pieces of functions/index.js — `npm test` (node:test,
// no emulator, no extra dependency).
//
// index.js can't be required here: it boots firebase-admin, and anything it
// exports becomes a Cloud Function. So each test lifts the declarations it
// needs out of the source verbatim and runs them against small fakes.

const test = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const SRC = fs.readFileSync(path.join(__dirname, "..", "index.js"), "utf8");

// One top-level declaration, verbatim: from `head` to the first line that
// closes at column 0 (`}` or `};`).
function declaration(head) {
  const start = SRC.indexOf(head);
  assert.notStrictEqual(start, -1, `"${head}" not found in index.js`);
  const close = SRC.indexOf("\n}", start);
  return SRC.slice(start, SRC.indexOf("\n", close + 1));
}

// Evaluates [heads] with [deps] in scope and returns the declaration `name`.
function load(name, heads, deps = {}) {
  const body = `${heads.map(declaration).join("\n")}\nreturn ${name};`;
  return new Function(...Object.keys(deps), body)(...Object.values(deps));
}

// ---- handleCoupleOnAccountDeletion (audit 2026-10-12, BE1) -------------------

// In-memory Firestore: just the calls the function makes. `calls` records
// every write / delete in order.
function fakeCouple(couple) {
  const store = new Map([["couples/C", couple]]);
  const calls = [];
  const ref = (p) => ({
    path: p,
    collection: (name) => ({doc: (id) => ref(`${p}/${name}/${id}`)}),
    get: async () => ({exists: store.has(p), data: () => store.get(p)}),
    set: async (data) => {
      calls.push(`set ${p}`);
      store.set(p, {...store.get(p), ...data});
    },
  });
  const handle = load("handleCoupleOnAccountDeletion", [
    "function isDocId",
    "async function handleCoupleOnAccountDeletion",
  ], {
    db: {
      collection: (name) => ({doc: (id) => ref(`${name}/${id}`)}),
      recursiveDelete: async (r) => calls.push(`recursiveDelete ${r.path}`),
    },
    admin: {firestore: {FieldValue: {serverTimestamp: () => "SERVER_TS"}}},
    logger: {warn: () => {}},
    deleteCoupleCompletely: async (r) => calls.push(`deleteCoupleCompletely ${r.path}`),
  });
  return {handle, calls, couple: () => store.get("couples/C")};
}

test("account deletion: an outsider pointing at a couple only loses their own sleep doc", async () => {
  const active = {memberIds: ["alice", "bob"], memberCount: 2, status: "active"};
  const f = fakeCouple({...active});
  await f.handle("C", "mallory");
  assert.deepStrictEqual(f.couple(), active);
  assert.deepStrictEqual(f.calls, ["recursiveDelete couples/C/sleep/mallory"]);
});

test("account deletion: one of two members leaves → partner waits, leaver's sleep goes", async () => {
  const f = fakeCouple({memberIds: ["alice", "bob"], memberCount: 2, status: "active"});
  await f.handle("C", "alice");
  assert.deepStrictEqual(f.couple(), {
    memberIds: ["bob"],
    memberCount: 1,
    status: "waiting_partner",
    updatedAt: "SERVER_TS",
  });
  assert.deepStrictEqual(f.calls, ["recursiveDelete couples/C/sleep/alice", "set couples/C"]);
});

test("account deletion: the only member leaves → the couple is torn down", async () => {
  const f = fakeCouple({memberIds: ["alice"], memberCount: 1, status: "waiting_partner"});
  await f.handle("C", "alice");
  assert.deepStrictEqual(f.calls, [
    "recursiveDelete couples/C/sleep/alice",
    "deleteCoupleCompletely couples/C",
  ]);
});

// ---- callableErrorCopy (BE6) --------------------------------------------------

test("callable errors: region tags read as English, odd keys fall back to Vietnamese", () => {
  const copyFor = load("callableErrorCopy", ["const CALLABLE_ERROR_COPY", "function callableErrorCopy"]);
  const en = copyFor({data: {lang: "en"}});
  const vi = copyFor({data: {}});
  assert.match(en.signInToDelete, /sign in/);
  assert.match(vi.signInToDelete, /đăng nhập/);
  for (const lang of ["en-US", "en_US", " EN "]) {
    assert.strictEqual(copyFor({data: {lang}}), en, lang);
  }
  assert.strictEqual(copyFor({data: {languageCode: "en-GB"}}), en);
  for (const lang of ["constructor", "__proto__", "toString", "fr"]) {
    assert.strictEqual(copyFor({data: {lang}}), vi, lang);
  }
  assert.strictEqual(copyFor({}), vi);
});

// ---- buildPartnerMoodText (BE5) -----------------------------------------------

test("mood push: English reads naturally, Vietnamese unchanged", () => {
  const moodText = load("buildPartnerMoodText", [
    "const PARTNER_MOOD_COPY",
    "const MOOD_LABELS",
    "function buildPartnerMoodText",
  ]);
  assert.strictEqual(moodText("en", "Tuan", "missing").body, "Tuan is missing you");
  assert.strictEqual(moodText("en", "Tuan", "happy").body, "Tuan is feeling happy");
  assert.strictEqual(moodText("vi", "Tuấn", "missing").body, "Tuấn đang thấy nhớ bạn");
  assert.strictEqual(moodText("vi", "Tuấn", "happy").body, "Tuấn đang thấy vui");
  // A key the partner made up — never a prototype member as the "mood".
  assert.strictEqual(
    moodText("en", "Tuan", "constructor").body,
    "Tuan just shared how they feel today — take a peek",
  );
});

// ---- client strings as paths / delete targets (audit 2026-10-12, N1 + N2) ----

// In-memory backend with the Admin SDK's path rules: `.doc("M/noteHistory/C")`
// is the nested doc couples/M/noteHistory/C and its `.id` is "C". `log` lists
// every write / delete (Firestore, Storage, Auth) in order.
function fakeBackend(docs) {
  const store = new Map(Object.entries(docs));
  const log = [];
  const snap = (p) => ({
    id: p.split("/").pop(),
    exists: store.has(p),
    data: () => store.get(p),
    get: (field) => (store.get(p) || {})[field],
  });
  const ref = (p) => ({
    path: p,
    id: p.split("/").pop(),
    collection: (name) => col(`${p}/${name}`),
    get: async () => snap(p),
    set: async (data) => {
      log.push(`set ${p}`);
      store.set(p, {...store.get(p), ...data});
    },
    delete: async () => {
      log.push(`delete ${p}`);
      store.delete(p);
    },
  });
  const col = (p) => ({
    path: p,
    doc: (id) => {
      // Like the SDK: an odd number of segments is not a document path.
      if (`${p}/${id}`.split("/").length % 2) throw new Error(`${p}/${id} is not a document`);
      return ref(`${p}/${id}`);
    },
    get: async () => ({
      docs: [...store.keys()]
        .filter((k) => k.startsWith(`${p}/`) && !k.slice(p.length + 1).includes("/"))
        .map((k) => ({...snap(k), ref: ref(k)})),
    }),
  });
  const db = {
    collection: (name) => col(name),
    recursiveDelete: async (r) => log.push(`recursiveDelete ${r.path}`),
  };
  const admin = {
    firestore: {FieldValue: {serverTimestamp: () => "SERVER_TS"}},
    storage: () => ({
      bucket: () => ({
        file: (p) => ({delete: async () => log.push(`storage delete ${p}`)}),
        deleteFiles: async ({prefix}) => log.push(`storage sweep ${prefix}`),
      }),
    }),
    auth: () => ({deleteUser: async (uid) => log.push(`auth delete ${uid}`)}),
  };
  return {store, log, db, admin};
}

const quietLogger = {warn: () => {}, info: () => {}, error: () => {}};

class HttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

// The real teardown chain (shared by deleteAccount + leaveCoupleCleanup).
function teardownChain(b) {
  return load("{isDocId, handleCoupleOnAccountDeletion, deleteCoupleCompletely}", [
    "function isDocId",
    "async function handleCoupleOnAccountDeletion",
    "async function deleteCoupleCompletely",
    "async function deleteStoragePrefix",
  ], {db: b.db, admin: b.admin, logger: quietLogger});
}

// `exports.<name> = onCall(opts, handler)` verbatim → the handler.
function callable(name, deps) {
  const start = SRC.indexOf(`exports.${name} = onCall(`);
  assert.notStrictEqual(start, -1, `${name} not found in index.js`);
  const end = SRC.indexOf("\n);", start);
  const body = `const exports = {};\n${SRC.slice(start, end + 3)}\nreturn exports.${name};`;
  const scope = {onCall: (opts, handler) => handler, HttpsError, logger: quietLogger, ...deps};
  return new Function(...Object.keys(scope), body)(...Object.values(scope));
}

// Victim couple C (2 people, photos on Storage) + attacker Mallory, the only
// member of her own couple M. What Mallory can write through the rules: a
// noteHistory entry with any id and any extra fields (the bait "couple"), her
// own profile's coupleId, and her couple's coupleCode / cover path / photo
// storagePath — all pointed at the victim.
function attackScene() {
  return fakeBackend({
    "couples/C": {memberIds: ["alice", "bob"], memberCount: 2, status: "active", coupleCode: "VCODE1"},
    "couple_codes/VCODE1": {coupleId: "C"},
    "couples/M": {
      memberIds: ["mallory"], memberCount: 1, status: "waiting_partner",
      coupleCode: "VCODE1", couplePhotoStoragePath: "couple_photos/C/cover_C.jpg",
    },
    "couples/M/photos/p1": {storagePath: "couple_photos/C/photo1.jpg", coupleId: "M"},
    "couples/M/noteHistory/C": {
      authorUserId: "mallory", text: "x", memberIds: ["mallory"],
      coupleCode: "VCODE1", couplePhotoStoragePath: "couple_photos/C/cover_C.jpg",
    },
    "users/mallory": {coupleId: "M/noteHistory/C", inviteCode: "MAL001"},
    "invite_codes/MAL001": {userId: "mallory"},
  });
}

const touchesVictim = (log) => log.filter((l) => /couple_photos\/C\/|couple_codes\/VCODE1|couples\/C\b/.test(l));

test("ids: app-made couple ids pass, paths and junk don't", () => {
  const isDocId = load("isDocId", ["function isDocId"]);
  for (const ok of ["aB3dE5fG7hJ9kL1mN2pQ", "3f2b8c1e-9a4d-4e6f-8b2a-1c3d5e7f9a0b", "test_couple_dev", "VCODE1"]) {
    assert.strictEqual(isDocId(ok), true, ok);
  }
  for (const bad of ["", "M/noteHistory/C", "C/", "/C", "..", "a b", "C\n", "x".repeat(129), null, undefined, 7, {}]) {
    assert.strictEqual(isDocId(bad), false, JSON.stringify(bad));
  }
});

test("N1 deleteAccount: users/{uid}.coupleId as a path deletes the account, never a couple", async () => {
  const b = attackScene();
  const chain = teardownChain(b);
  const deleteAccount = callable("deleteAccount", {
    db: b.db,
    admin: b.admin,
    isDocId: chain.isDocId,
    handleCoupleOnAccountDeletion: chain.handleCoupleOnAccountDeletion,
    callableErrorCopy: load("callableErrorCopy", ["const CALLABLE_ERROR_COPY", "function callableErrorCopy"]),
  });
  assert.deepStrictEqual(await deleteAccount({auth: {uid: "mallory"}, data: {}}), {success: true});
  assert.deepStrictEqual(touchesVictim(b.log), []);
  assert.deepStrictEqual(b.log.filter((l) => /couples\//.test(l) || l.startsWith("storage")), []);
  assert.ok(b.log.includes("auth delete mallory"));
  assert.ok(b.log.includes("delete users/mallory"));
  assert.ok(b.log.includes("delete invite_codes/MAL001"));
});

test("deleteAccount: a profile with a malformed inviteCode can still be deleted", async () => {
  const b = fakeBackend({"users/u": {inviteCode: "AB/CD"}});
  const chain = teardownChain(b);
  const deleteAccount = callable("deleteAccount", {
    db: b.db,
    admin: b.admin,
    isDocId: chain.isDocId,
    handleCoupleOnAccountDeletion: chain.handleCoupleOnAccountDeletion,
    callableErrorCopy: load("callableErrorCopy", ["const CALLABLE_ERROR_COPY", "function callableErrorCopy"]),
  });
  assert.deepStrictEqual(await deleteAccount({auth: {uid: "u"}, data: {}}), {success: true});
  assert.ok(b.log.includes("auth delete u"));
});

test("N1 leaveCoupleCleanup: a path as coupleId is rejected before anything is read", async () => {
  const b = attackScene();
  const chain = teardownChain(b);
  const leave = callable("leaveCoupleCleanup", {
    db: b.db,
    isDocId: chain.isDocId,
    handleCoupleOnAccountDeletion: chain.handleCoupleOnAccountDeletion,
  });
  await assert.rejects(
    leave({auth: {uid: "mallory"}, data: {coupleId: "M/noteHistory/C"}}),
    {code: "invalid-argument"},
  );
  assert.deepStrictEqual(b.log, []);
});

test("N1 other callables: a path as coupleId / gameId is invalid-argument", async () => {
  const isDocId = load("isDocId", ["function isDocId"]);
  // Any Firestore access at all fails the test.
  const db = new Proxy({}, {get: (_, k) => assert.fail(`db.${String(k)} touched`)});
  const cases = [
    ["migrateLoveNotesToChat", {coupleId: "M/noteHistory/C"}],
    ["nudgeRpsPlayer", {coupleId: "M/noteHistory/C", gameId: "G"}],
    ["nudgeRpsPlayer", {coupleId: "M", gameId: "G/moves/alice"}],
    ["generateDailyQuestion", {coupleId: "M/noteHistory/C", date: new Date().toISOString().slice(0, 10)}],
  ];
  for (const [name, data] of cases) {
    const handler = callable(name, {db, isDocId, ANTHROPIC_API_KEY: {}});
    await assert.rejects(handler({auth: {uid: "mallory"}, data}), {code: "invalid-argument"}, name);
  }
});

test("N2 teardown: the sole member leaving only clears her own couple's folder and code", async () => {
  const b = attackScene();
  const chain = teardownChain(b);
  const leave = callable("leaveCoupleCleanup", {
    db: b.db,
    isDocId: chain.isDocId,
    handleCoupleOnAccountDeletion: chain.handleCoupleOnAccountDeletion,
  });
  assert.deepStrictEqual(await leave({auth: {uid: "mallory"}, data: {coupleId: "M"}}), {success: true});
  // Her cover path / photo storagePath / coupleCode all name the victim's.
  assert.deepStrictEqual(touchesVictim(b.log), []);
  assert.deepStrictEqual(b.log.filter((l) => l.startsWith("storage")), ["storage sweep couple_photos/M/"]);
  assert.ok(b.store.has("couple_codes/VCODE1"));
  assert.ok(b.log.includes("delete couples/M"));
});

test("N2 teardown: the couple's own code pointer is still removed", async () => {
  const b = fakeBackend({
    "couples/M": {memberIds: ["mallory"], memberCount: 1, coupleCode: "MCODE1"},
    "couple_codes/MCODE1": {coupleId: "M"},
  });
  const {deleteCoupleCompletely} = teardownChain(b);
  await deleteCoupleCompletely(b.db.collection("couples").doc("M"), b.store.get("couples/M"));
  assert.ok(b.log.includes("delete couple_codes/MCODE1"));
  assert.ok(!b.store.has("couple_codes/MCODE1"));
});
