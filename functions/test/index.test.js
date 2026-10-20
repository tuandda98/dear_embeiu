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
  assert.deepStrictEqual(f.calls, [
    "recursiveDelete couples/C/sleep/mallory",
    "recursiveDelete couples/C/arrival/mallory",
  ]);
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
  assert.deepStrictEqual(f.calls, [
    "recursiveDelete couples/C/sleep/alice",
    "recursiveDelete couples/C/arrival/alice",
    "set couples/C",
  ]);
});

test("account deletion: the only member leaves → the couple is torn down", async () => {
  const f = fakeCouple({memberIds: ["alice"], memberCount: 1, status: "waiting_partner"});
  await f.handle("C", "alice");
  assert.deepStrictEqual(f.calls, [
    "recursiveDelete couples/C/sleep/alice",
    "recursiveDelete couples/C/arrival/alice",
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

// ---- notifyDecision (feature decision-wheel, 2026-10-19) ---------------------

function fakeDecision({lastPushMs = 0, lastPushBy = ""} = {}) {
  const inbox = [];
  const pushes = [];
  const stamps = [];
  const ref = {path: "couples/C/decisions/D"};
  const process = load("processDecisionWrite", [
    "const DECISION_PUSH_COOLDOWN_MS",
    "function buildDecisionText",
    "async function processDecisionWrite",
  ], {
    db: {
      runTransaction: async (fn) => fn({
        get: async () => ({
          exists: true,
          get: (k) => ({lastPushAt: lastPushMs, lastPushBy})[k],
        }),
        update: (r, data) => stamps.push(Object.keys(data)),
      }),
    },
    admin: {firestore: {FieldValue: {serverTimestamp: () => "SERVER_TS"}}},
    logger: {warn: () => {}},
    rpsLoadMemberIds: async () => ["alice", "bob"],
    rpsLoadDisplayName: async (uid) => (uid === "alice" ? "Thảo" : "Tuấn"),
    rpsToMillis: (v) => v || 0,
    writeInboxNotifications: async (ids, payload) => inbox.push({ids, payload}),
    sendToRecipientDevices: async (ids, buildText, data, options) => {
      pushes.push({ids, vi: buildText("vi"), en: buildText("en"), data, options});
      return {deviceCount: 1, failures: []};
    },
  });
  return {process, inbox, pushes, stamps, ref};
}

const eatDoc = (over = {}) => ({
  kind: "eat", date: "2026-10-21", question: "", result: "Bún chả",
  resultId: "bun_cha", spins: 1, byUserId: "alice", ...over,
});

test("decision create: inbox + wake push to the partner only, slot stamped", async () => {
  const f = fakeDecision();
  await f.process("C", "2026-10-21_eat", null, eatDoc(), f.ref);
  assert.deepStrictEqual(f.inbox.map((i) => i.ids), [["bob"]]);
  assert.strictEqual(f.inbox[0].payload.type, "decision");
  assert.strictEqual(f.inbox[0].payload.respin, false);
  assert.strictEqual(f.pushes.length, 1);
  assert.deepStrictEqual(f.pushes[0].ids, ["bob"]);
  assert.deepStrictEqual(f.pushes[0].options, {wakeClients: true});
  assert.strictEqual(f.pushes[0].vi.body, "Thảo quay ra: hôm nay ăn Bún chả");
  assert.strictEqual(f.pushes[0].en.body, "Thảo spun: Bún chả today");
  const d = f.pushes[0].data;
  assert.deepStrictEqual(
    [d.type, d.kind, d.result, d.resultId, d.date, d.decisionId, d.actorName],
    ["decision", "eat", "Bún chả", "bun_cha", "2026-10-21", "2026-10-21_eat", "Thảo"],
  );
  assert.deepStrictEqual(f.stamps, [["lastPushAt", "lastPushBy"]]);
});

test("decision create by bob goes to alice", async () => {
  const f = fakeDecision();
  await f.process("C", "x", null, eatDoc({byUserId: "bob"}), f.ref);
  assert.deepStrictEqual(f.pushes[0].ids, ["alice"]);
  assert.deepStrictEqual(f.inbox[0].ids, ["alice"]);
});

test("decision: alice locks in, bob re-spins within 10' → alice still gets a push", async () => {
  const f = fakeDecision({lastPushMs: Date.now() - 2 * 60 * 1000, lastPushBy: "alice"});
  await f.process("C", "D", eatDoc(), eatDoc({result: "Lẩu Thái", byUserId: "bob", spins: 2}), f.ref);
  assert.strictEqual(f.inbox.length, 1);
  assert.strictEqual(f.inbox[0].payload.respin, true);
  assert.strictEqual(f.pushes.length, 1);
  assert.deepStrictEqual(f.pushes[0].ids, ["alice"]);
  assert.deepStrictEqual(f.pushes[0].options, {wakeClients: true});
  assert.strictEqual(f.pushes[0].vi.body, "Tuấn quay lại: Lẩu Thái");
  assert.deepStrictEqual(f.stamps, [["lastPushAt", "lastPushBy"]]);
});

test("decision: bob re-spins a 2nd time within 10' of his own push → inbox + silent wake, no banner", async () => {
  const f = fakeDecision({lastPushMs: Date.now() - 1 * 60 * 1000, lastPushBy: "bob"});
  const prev = eatDoc({result: "Lẩu Thái", byUserId: "bob", spins: 2});
  await f.process("C", "D", prev, eatDoc({result: "Phở", byUserId: "bob", spins: 3}), f.ref);
  assert.strictEqual(f.inbox.length, 1);
  assert.strictEqual(f.inbox[0].payload.respin, true);
  // DW-R2-2: no banner, but a silent data-only wake with the same contract so
  // alice's widget shows "Phở" (stamp untouched: the cooldown keeps running).
  assert.strictEqual(f.pushes.length, 1);
  assert.deepStrictEqual(f.pushes[0].ids, ["alice"]);
  assert.deepStrictEqual(f.pushes[0].options, {silent: true});
  const d = f.pushes[0].data;
  assert.deepStrictEqual(
    [d.type, d.kind, d.result, d.resultId, d.date, d.decisionId, d.actorName],
    ["decision", "eat", "Phở", "bun_cha", "2026-10-21", "D", "Tuấn"],
  );
  assert.deepStrictEqual(f.stamps, []);
});

test("decision re-spin after the cooldown pushes the re-spin copy", async () => {
  const f = fakeDecision({lastPushMs: Date.now() - 11 * 60 * 1000, lastPushBy: "bob"});
  await f.process("C", "D", eatDoc(), eatDoc({result: "Lẩu Thái", byUserId: "bob", spins: 2}), f.ref);
  assert.strictEqual(f.pushes.length, 1);
  assert.deepStrictEqual(f.pushes[0].ids, ["alice"]);
  assert.strictEqual(f.pushes[0].vi.body, "Tuấn quay lại: Lẩu Thái");
});

test("decision update without a new result (e.g. our lastPushAt stamp) does nothing", async () => {
  const f = fakeDecision();
  await f.process("C", "D", eatDoc(), {...eatDoc(), lastPushAt: "SERVER_TS"}, f.ref);
  assert.strictEqual(f.inbox.length, 0);
  assert.strictEqual(f.pushes.length, 0);
});

test("decision copy: go drops the extra verb in vi, custom quotes the question", async () => {
  const f = fakeDecision();
  await f.process("C", "g", null, eatDoc({kind: "go", result: "Đi cà phê"}), f.ref);
  assert.strictEqual(f.pushes[0].vi.body, "Thảo quay ra: Đi cà phê");
  const g = fakeDecision();
  await g.process("C", "g", null, eatDoc({kind: "go", result: "grab coffee"}), g.ref);
  assert.strictEqual(g.pushes[0].en.body, "Thảo spun: let's grab coffee");
  const c = fakeDecision();
  await c.process("C", "c", null, eatDoc({kind: "custom", question: "Ai rửa bát?", result: "Tuấn"}), c.ref);
  assert.strictEqual(c.pushes[0].vi.body, 'Thảo quay "Ai rửa bát?": Tuấn');
});

// ---- sendToRecipientDevices silent wake (DW-R2-2, 2026-10-20) ---------------

function fakeSend(devices) {
  const sent = [];
  const send = load("sendToRecipientDevices", [
    "const PUSH_TYPE_PREF_FIELD",
    "function langData",
    "async function sendToRecipientDevices",
  ], {
    db: {
      collection: () => ({doc: () => ({collection: (name) => ({
        where: () => (name === "notifications"
          ? {count: () => ({get: async () => ({data: () => ({count: 3})})})}
          : {get: async () => ({docs: devices.map((d) => ({
            ref: {delete: async () => null},
            get: (k) => d[k],
          }))})}),
      })})}),
    },
    admin: {messaging: () => ({sendEach: async (msgs) => {
      sent.push(...msgs);
      return {successCount: msgs.length, failureCount: 0, responses: msgs.map(() => ({success: true}))};
    }})},
  });
  return {send, sent};
}

const DEVICES = [
  {token: "ios1", platform: "ios", languageCode: "en", notificationsEnabled: true},
  {token: "and1", platform: "android", languageCode: "vi", notificationsEnabled: true},
];
const DATA = {type: "decision", kind: "eat", result: "Phở", resultId: "pho", date: "2026-10-21"};

test("silent: one data-only message per device, no title/body/alert/badge", async () => {
  const f = fakeSend(DEVICES);
  let built = 0;
  await f.send(["alice"], () => { built++; return {title: "T", body: "B"}; }, DATA, {silent: true});
  assert.strictEqual(built, 0);
  assert.strictEqual(f.sent.length, 2);
  for (const m of f.sent) {
    assert.strictEqual(m.notification, undefined);
    assert.strictEqual(m.data.title, undefined);
    assert.strictEqual(m.data.body, undefined);
    assert.strictEqual(m.data.result, "Phở");
  }
  const ios = f.sent.find((m) => m.token === "ios1");
  assert.deepStrictEqual(ios.apns, {
    headers: {"apns-priority": "5", "apns-push-type": "background"},
    payload: {aps: {contentAvailable: true}},
  });
  assert.strictEqual(ios.data.lang, "en");
  assert.strictEqual(f.sent.find((m) => m.token === "and1").data.lang, "vi");
});

test("default callers unchanged: alert per device + Android companion only with wakeClients", async () => {
  const plain = fakeSend(DEVICES);
  await plain.send(["alice"], () => ({title: "T", body: "B"}), DATA);
  assert.strictEqual(plain.sent.length, 2);
  assert.ok(plain.sent.every((m) => m.notification && m.notification.title === "T"));
  assert.strictEqual(plain.sent[0].apns.headers["apns-push-type"], "alert");
  assert.strictEqual(plain.sent[0].apns.payload.aps.contentAvailable, undefined);
  const wake = fakeSend(DEVICES);
  await wake.send(["alice"], () => ({title: "T", body: "B"}), DATA, {wakeClients: true});
  assert.strictEqual(wake.sent.length, 3);
  assert.strictEqual(wake.sent[2].token, "and1");
  assert.strictEqual(wake.sent[2].notification, undefined);
});

// ---- notifyArrival (arrival, đợt 2) -------------------------------------------

// `declaration()` runs to the first column-0 `}`, so this one head lifts every
// ARRIVAL_* constant through ARRIVAL_COPY.
const ARRIVAL_HEADS = [
  "const ARRIVAL_SLOTS",
  "function arrivalVnDateKey",
  "function arrivalEvent",
  "function arrivalPushPlan",
  "function arrivalClaim",
  "function buildArrivalText",
  "function rpsToMillis",
];

// `doc` = the stored arrival doc the transaction reads (bookkeeping);
// `couple` = the couple doc.
function fakeArrival({doc = {}, couple = {memberIds: ["alice", "bob"], status: "active"}} = {}) {
  const pushes = [];
  const stamps = [];
  const updates = [];
  const ref = {
    path: "couples/C/arrival/alice",
    update: async (data) => updates.push(data),
  };
  const process = load("processArrivalWrite", [
    ...ARRIVAL_HEADS,
    "async function processArrivalWrite",
  ], {
    db: {
      collection: () => ({doc: () => ({get: async () => ({
        exists: true,
        get: (k) => couple[k],
      })})}),
      runTransaction: async (fn) => fn({
        get: async () => ({exists: true, data: () => doc}),
        update: (r, data) => stamps.push(data),
      }),
    },
    admin: {firestore: {FieldValue: {serverTimestamp: () => "SERVER_TS", delete: () => "DELETE"}}},
    logger: {warn: () => {}},
    rpsLoadDisplayName: async (uid) => (uid === "alice" ? "Thảo" : ""),
    sendToRecipientDevices: async (ids, buildText, data, options) => {
      pushes.push({ids, vi: buildText("vi"), en: buildText("en"), data, options});
      return {deviceCount: 1, failures: []};
    },
  });
  return {process, pushes, stamps, updates, ref};
}

const MINUTE = 60 * 1000;
const arrivalDoc = (last = {}, over = {}) => ({
  share: true,
  auto: true,
  last: {place: "home", type: "enter", at: Date.now() - MINUTE, battery: 60, source: "auto", ...last},
  ...over,
});

test("arrival: Home enter → one wake push to the partner, slot stamped, no inbox", async () => {
  const f = fakeArrival();
  const out = await f.process("C", "alice", null, arrivalDoc(), f.ref);
  assert.strictEqual(out.pushed, true);
  assert.strictEqual(f.pushes.length, 1);
  const p = f.pushes[0];
  assert.deepStrictEqual(p.ids, ["bob"]);
  assert.deepStrictEqual(p.vi, {title: "Thảo đã về đến nhà", body: "Nhắn một câu hỏi thăm nhé"});
  assert.deepStrictEqual(p.en, {title: "Thảo got home", body: "Send a quick hello"});
  assert.deepStrictEqual(p.options, {wakeClients: true, collapseId: "arrival_alice"});
  assert.strictEqual(p.data.type, "arrival");
  assert.strictEqual(p.data.place, "home");
  assert.strictEqual(p.data.battery, "60"); // FCM data values are strings
  assert.strictEqual(p.data.actorName, "Thảo");
  assert.match(p.data.date, /^\d{4}-\d{2}-\d{2}$/);
  assert.strictEqual(p.data.placeName, undefined);
  assert.strictEqual(f.stamps.length, 1);
  assert.strictEqual(f.stamps[0]["lastPushAt.home"], "SERVER_TS");
  assert.strictEqual(f.stamps[0].pushCount, 1);
});

test("arrival: custom place uses its name verbatim + low battery line", async () => {
  const f = fakeArrival();
  await f.process("C", "alice", null,
    arrivalDoc({place: "p2", name: "Phòng gym", icon: "gym", battery: 15}), f.ref);
  assert.deepStrictEqual(f.pushes[0].vi, {title: "Thảo đã đến Phòng gym", body: "Pin còn 15%"});
  assert.deepStrictEqual(f.pushes[0].en, {title: "Thảo arrived at Phòng gym", body: "Battery at 15%"});
  assert.strictEqual(f.pushes[0].data.placeName, "Phòng gym");
  assert.strictEqual(f.pushes[0].data.icon, "gym");
  const edge = fakeArrival();
  await edge.process("C", "alice", null, arrivalDoc({battery: 20}), edge.ref);
  assert.strictEqual(edge.pushes[0].vi.body, "Pin còn 20%");
  const none = fakeArrival();
  const noBattery = arrivalDoc();
  delete noBattery.last.battery;
  await none.process("C", "alice", null, noBattery, none.ref);
  assert.strictEqual(none.pushes[0].vi.body, "Nhắn một câu hỏi thăm nhé");
  assert.strictEqual(none.pushes[0].data.battery, undefined);
});

test("arrival: no display name → fallback in the recipient's language", () => {
  const text = load("buildArrivalText", ARRIVAL_HEADS);
  const ev = {place: "home", name: "", battery: null};
  assert.strictEqual(text("vi", "", ev).title, "Người ấy đã về đến nhà");
  assert.strictEqual(text("en", " ", ev).title, "Your partner got home");
  assert.strictEqual(text("fr", "Tuấn", ev).title, "Tuấn đã về đến nhà");
});

test("arrival: exit, bounce, stale, not shared, unchanged → no push", async () => {
  const cases = [
    [null, arrivalDoc({type: "exit"}), "exit"],
    [null, arrivalDoc({bounce: true}), "bounce"],
    [null, arrivalDoc({at: Date.now() - 31 * MINUTE}), "stale"],
    [null, {share: false}, "not_shared"],
    [null, null, "deleted"],
  ];
  for (const [before, after, reason] of cases) {
    const f = fakeArrival();
    const out = await f.process("C", "alice", before, after, f.ref);
    assert.strictEqual(out.skipped, reason, reason);
    assert.strictEqual(f.pushes.length, 0, reason);
  }
  // Our own bookkeeping write re-triggers with the same `last`.
  const doc = arrivalDoc();
  const f = fakeArrival();
  const out = await f.process("C", "alice", doc, {...doc, pushCount: 1}, f.ref);
  assert.strictEqual(out.skipped, "unchanged");
});

test("arrival: same place within 30' → cooldown; another place still pushes", async () => {
  const doc = {lastPushAt: {home: Date.now() - 29 * MINUTE}};
  const f = fakeArrival({doc});
  assert.strictEqual((await f.process("C", "alice", null, arrivalDoc(), f.ref)).skipped, "cooldown");
  const g = fakeArrival({doc});
  await g.process("C", "alice", null, arrivalDoc({place: "p1", name: "Công ty", icon: "work"}), g.ref);
  assert.strictEqual(g.pushes.length, 1);
  const later = fakeArrival({doc: {lastPushAt: {home: Date.now() - 31 * MINUTE}}});
  await later.process("C", "alice", null, arrivalDoc(), later.ref);
  assert.strictEqual(later.pushes.length, 1);
});

test("arrival: at most 6 pushes a day; the count resets on a new day", async () => {
  const today = load("arrivalVnDateKey", ARRIVAL_HEADS)(Date.now());
  const full = fakeArrival({doc: {pushDay: today, pushCount: 6}});
  assert.strictEqual((await full.process("C", "alice", null, arrivalDoc(), full.ref)).skipped, "daily_cap");
  const fifth = fakeArrival({doc: {pushDay: today, pushCount: 5}});
  await fifth.process("C", "alice", null, arrivalDoc(), fifth.ref);
  assert.strictEqual(fifth.stamps[0].pushCount, 6);
  const yesterday = fakeArrival({doc: {pushDay: "2000-01-01", pushCount: 6}});
  await yesterday.process("C", "alice", null, arrivalDoc(), yesterday.ref);
  assert.strictEqual(yesterday.stamps[0].pushCount, 1);
  assert.strictEqual(yesterday.stamps[0].pushDay, today);
});

test("arrival: day bucket is Vietnam time", () => {
  const key = load("arrivalVnDateKey", ARRIVAL_HEADS);
  assert.strictEqual(key(Date.UTC(2026, 9, 20, 16, 59)), "2026-10-20"); // 23:59 VN
  assert.strictEqual(key(Date.UTC(2026, 9, 20, 17, 0)), "2026-10-21"); // 00:00 VN
});

test("arrival: waiting couple / ex-member / never to the sender", async () => {
  const waiting = fakeArrival({couple: {memberIds: ["alice"], status: "waiting_partner"}});
  assert.strictEqual((await waiting.process("C", "alice", null, arrivalDoc(), waiting.ref)).skipped, "inactive");
  const left = fakeArrival({couple: {memberIds: ["bob", "carol"], status: "active"}});
  assert.strictEqual((await left.process("C", "alice", null, arrivalDoc(), left.ref)).skipped, "inactive");
  assert.strictEqual(waiting.pushes.length + left.pushes.length, 0);
});

test("arrival: sharing off drops the push times the partner could read", async () => {
  const f = fakeArrival();
  const out = await f.process("C", "alice", arrivalDoc(), {share: false, lastPushAt: {home: 1}}, f.ref);
  assert.strictEqual(out.skipped, "not_shared");
  assert.deepStrictEqual(f.updates, [{lastPushAt: "DELETE"}]);
  assert.strictEqual(f.pushes.length, 0);
});

test("arrival: pushArrival mutes only arrival pushes on that device", async () => {
  const muted = [
    {token: "a", platform: "ios", languageCode: "vi", notificationsEnabled: true, pushArrival: false},
    {token: "b", platform: "ios", languageCode: "vi", notificationsEnabled: true},
  ];
  const f = fakeSend(muted);
  await f.send(["bob"], () => ({title: "T", body: "B"}), {type: "arrival"});
  assert.deepStrictEqual(f.sent.map((m) => m.token), ["b"]);
  const g = fakeSend(muted);
  await g.send(["bob"], () => ({title: "T", body: "B"}), {type: "partner_mood"});
  assert.deepStrictEqual(g.sent.map((m) => m.token), ["a", "b"]);
});

test("arrival: partner left → leaver's doc deleted, the one who stays stops sharing", () => {
  const start = SRC.indexOf("// ── arrival (đợt 2) ── the leaver's doc goes");
  assert.notStrictEqual(start, -1);
  const chunk = SRC.slice(start, SRC.indexOf("// Leaver display name", start));
  assert.match(chunk, /recursiveDelete\(arrivalRef\.doc\(leaverUid\)\)/);
  assert.match(chunk, /share: false/);
  assert.match(chunk, /last: admin\.firestore\.FieldValue\.delete\(\)/);
  assert.match(chunk, /lastPushAt: admin\.firestore\.FieldValue\.delete\(\)/);
  const teardown = declaration("async function deleteCoupleCompletely");
  assert.match(teardown, /recursiveDelete\(coupleRef\.collection\("arrival"\)\)/);
});
