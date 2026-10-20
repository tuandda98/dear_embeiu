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

// ---- notifyMoney (feature expenses, 2026-10-20) ------------------------------

class MoneyFieldPath {
  constructor(...segments) {
    this.segments = segments;
  }
}

// In-memory couple C = [alice, bob] with whatever money docs the test needs.
function fakeMoney(docs) {
  const store = new Map(Object.entries({"couples/C": {memberIds: ["alice", "bob"]}, ...docs}));
  const inbox = [];
  const pushes = [];
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  const snap = (p) => ({exists: store.has(p), data: () => store.get(p), get: (f) => (store.get(p) || {})[f]});
  const query = (p, filters = [], lim = Infinity) => ({
    where: (f, op, v) => query(p, [...filters, [f, op, v]], lim),
    limit: (n) => query(p, filters, n),
    rows() {
      return [...store.entries()]
        .filter(([k]) => k.startsWith(`${p}/`) && !k.slice(p.length + 1).includes("/"))
        .filter(([, d]) => filters.every(([f, op, v]) =>
          op === "==" ? same(d[f], v) : op === ">=" ? d[f] >= v : d[f] <= v))
        .slice(0, lim);
    },
    async get() {
      const docs = this.rows().map(([k]) => ({...snap(k), ref: ref(k)}));
      return {empty: docs.length === 0, docs};
    },
    aggregate() {
      const rows = this.rows();
      return {get: async () => ({data: () => ({total: rows.reduce((s, [, d]) => s + d.amount, 0)})})};
    },
  });
  const ref = (p) => ({
    path: p,
    id: p.split("/").pop(),
    get: async () => snap(p),
    collection: (name) => ({...query(`${p}/${name}`), doc: (id) => ref(`${p}/${name}/${id}`)}),
  });
  const db = {
    collection: (name) => ({doc: (id) => ref(`${name}/${id}`)}),
    runTransaction: async (fn) => fn({
      get: (r) => r.get(),
      update: (r, a, b) => {
        const d = {...store.get(r.path)};
        if (a instanceof MoneyFieldPath) {
          d[a.segments[0]] = {...(d[a.segments[0]] || {}), [a.segments[1]]: b};
        } else {
          Object.assign(d, a);
        }
        store.set(r.path, d);
      },
    }),
  };
  const process = load("processMoneyTxWrite", [
    "function isDocId",
    "const MONEY_COPY",
    "function buildMoneyText",
    "function moneyBudgetLevel",
    "function moneyMonthNow",
    "async function moneySum",
    "async function moneyGoalUpdate",
    "async function moneyBudgetUpdate",
    "async function processMoneyTxWrite",
  ], {
    db,
    admin: {firestore: {
      FieldValue: {serverTimestamp: () => "SERVER_TS"},
      AggregateField: {sum: (f) => ({sum: f})},
      FieldPath: MoneyFieldPath,
    }},
    rpsLoadMemberIds: async (id) => (store.get(`couples/${id}`) || {}).memberIds || null,
    rpsLoadDisplayName: async (uid) => ({alice: "Tuấn", bob: "Thảo"})[uid] || "",
    writeInboxNotifications: async (ids, payload) => inbox.push({ids, ...payload}),
    sendToRecipientDevices: async (ids, buildText, data) => {
      pushes.push({ids, vi: buildText("vi"), en: buildText("en"), data});
      return {deviceCount: ids.length, failures: []};
    },
  });
  // Writes the entry, then runs the trigger the way Firestore would.
  const write = async (id, data, nowMs = MONEY_OCT_20) => {
    const p = `couples/C/moneyTx/${id}`;
    const before = store.get(p) || null;
    store.set(p, data);
    return process("C", before, data, nowMs);
  };
  return {store, inbox, pushes, write, process};
}

const MONEY_OCT_20 = Date.UTC(2026, 9, 20, 5); // 12:00 in Vietnam
const MONEY_PAIR = ["alice", "bob"];
const moneyContribution = (payer, amount, extra = {}) => ({
  type: "contribution", amount, inWalletId: "dalat", outWalletId: "", payer, memberUids: MONEY_PAIR,
  date: "2026-10-20", createdBy: payer, ...extra,
});
const moneySpend = (by, amount, extra = {}) => ({
  type: "expense", amount, inWalletId: "", outWalletId: "", payer: by, memberUids: MONEY_PAIR,
  date: "2026-10-20", createdBy: by, splitMode: "equal", payerShare: Math.ceil(amount / 2), ...extra,
});
const MONEY_DALAT = {"couples/C/moneyWallets/dalat": {
  type: "goal", name: "Quỹ Đà Lạt", emoji: "🏔️", goalTarget: 5000000, openingBalance: 0, memberUids: MONEY_PAIR,
}};

test("money: a contribution pushes the other one the fund %, never the amount", async () => {
  const f = fakeMoney(MONEY_DALAT);
  const out = await f.write("c1", moneyContribution("alice", 2000000));
  assert.deepStrictEqual(out.goal, {pushed: "goal", recipientIds: ["bob"], percent: 40});
  assert.strictEqual(f.pushes.length, 1);
  assert.deepStrictEqual(f.pushes[0].vi, {title: "🏔️ Quỹ Đà Lạt", body: "Tuấn vừa góp vào quỹ, giờ được 40%"});
  assert.deepStrictEqual(f.pushes[0].en, {title: "🏔️ Quỹ Đà Lạt", body: "Tuấn just chipped in, the fund is at 40%"});
  assert.doesNotMatch(JSON.stringify(f.pushes), /2[.,]?000[.,]?000|2tr|2M/);
  assert.strictEqual(f.inbox[0].type, "money_goal");
  assert.deepStrictEqual(f.inbox[0].ids, ["bob"]);
  assert.strictEqual(f.pushes[0].data.type, "money_goal");
});

test("money: reaching 100 % tells both, exactly once", async () => {
  const f = fakeMoney(MONEY_DALAT);
  await f.write("c1", moneyContribution("alice", 2000000));
  const out = await f.write("c2", moneyContribution("bob", 3000000));
  assert.deepStrictEqual(out.goal, {pushed: "reached", recipientIds: MONEY_PAIR});
  assert.strictEqual(f.store.get("couples/C/moneyWallets/dalat").goalReachedAt, "SERVER_TS");
  assert.deepStrictEqual(f.pushes[1].vi, {title: "🏔️ Quỹ Đà Lạt đủ rồi!", body: "Chúng mình góp đủ mục tiêu rồi. Lên lịch đi thôi."});
  assert.strictEqual(f.inbox[1].type, "money_goal_reached");
  // Later top-ups are plain contribution pushes again, no second "đủ rồi".
  const again = await f.write("c3", moneyContribution("alice", 100000));
  assert.strictEqual(again.goal.pushed, "goal");
  assert.strictEqual(f.pushes.filter((p) => p.data.type === "money_goal_reached").length, 1);
});

test("money: plain entries never push (no budget, not a goal, edits of a contribution)", async () => {
  const f = fakeMoney({...MONEY_DALAT, "couples/C/moneyWallets/joint": {type: "cash", name: "Ví chung", memberUids: MONEY_PAIR}});
  await f.write("e1", moneySpend("alice", 480000));
  await f.write("j1", moneyContribution("bob", 1000000, {inWalletId: "joint"}));
  await f.write("c1", moneyContribution("alice", 1000000));
  await f.write("c1", moneyContribution("alice", 1500000)); // edit
  assert.strictEqual(f.pushes.length, 1); // only the create of c1
  assert.deepStrictEqual(await f.process("C", moneySpend("alice", 1), null, MONEY_OCT_20), {skipped: "deleted"});
});

test("money: budget 80 % then 100 %, once each per month, never to the one who logged it", async () => {
  const f = fakeMoney({"couples/C/moneyBudgets/b": {categoryId: "", amount: 5000000}});
  assert.deepStrictEqual((await f.write("e1", moneySpend("alice", 3900000))).budget, {skipped: "under_80"});
  const at80 = await f.write("e2", moneySpend("alice", 100000));
  assert.deepStrictEqual(at80.budget, {pushed: "budget", level: 80, recipientIds: ["bob"]});
  assert.deepStrictEqual(f.pushes[0].vi, {title: "Tháng này chúng mình đã tiêu 80% ngân sách", body: "Mở sổ chung xem còn lại bao nhiêu nhé."});
  assert.deepStrictEqual((await f.write("e3", moneySpend("bob", 500000))).budget, {skipped: "already_alerted", level: 80});
  const at100 = await f.write("e4", moneySpend("bob", 500000));
  assert.deepStrictEqual(at100.budget, {pushed: "budget", level: 100, recipientIds: ["alice"]});
  assert.deepStrictEqual(f.pushes[1].vi, {title: "Tháng này chúng mình tiêu hết ngân sách rồi", body: "Chậm lại chút nhé, còn 11 ngày nữa mới sang tháng."});
  assert.strictEqual(f.pushes[1].en.body, "Let's slow down a little. 11 days to go this month.");
  assert.deepStrictEqual((await f.write("e5", moneySpend("bob", 1))).budget, {skipped: "already_alerted", level: 100});
  assert.deepStrictEqual(f.store.get("couples/C/moneyBudgets/b").alerted, {"2026-10": 100});
  assert.strictEqual(f.inbox.filter((i) => i.type === "money_budget").length, 2);
  assert.doesNotMatch(JSON.stringify(f.pushes), /5[.,]?000[.,]?000|5tr/);
  // An edit by bob that pushes it over counts bob as the actor.
  const g = fakeMoney({"couples/C/moneyBudgets/b": {categoryId: "", amount: 1000000}});
  await g.write("e1", moneySpend("alice", 100000));
  const edited = await g.write("e1", moneySpend("alice", 900000, {updatedBy: "bob"}));
  assert.deepStrictEqual(edited.budget.recipientIds, ["alice"]);
});

test("money: a new month starts over; old months and category budgets stay quiet", async () => {
  const f = fakeMoney({
    "couples/C/moneyBudgets/b": {categoryId: "", amount: 1000000, alerted: {"2026-09": 100}},
    "couples/C/moneyBudgets/food": {categoryId: "food", amount: 1},
  });
  assert.deepStrictEqual((await f.write("old", moneySpend("alice", 2000000, {date: "2026-09-30"}))).budget, {skipped: "other_month"});
  assert.strictEqual((await f.write("new", moneySpend("alice", 900000))).budget.level, 80);
});

test("money: an old pair's entry (partner left, someone new joined) notifies nobody", async () => {
  const f = fakeMoney({...MONEY_DALAT, "couples/C": {memberIds: ["alice", "dave"]}});
  assert.deepStrictEqual(await f.write("c1", moneyContribution("alice", 5000000)), {skipped: "not_current_pair"});
  const g = fakeMoney({"couples/C": {memberIds: ["alice"]}});
  assert.deepStrictEqual(await g.write("c1", moneyContribution("alice", 1)), {skipped: "not_current_pair"});
  assert.strictEqual(f.pushes.length + g.pushes.length, 0);
});

test("money: month / days left follow Vietnam time", () => {
  const monthNow = load("moneyMonthNow", ["function moneyMonthNow"]);
  assert.deepStrictEqual(monthNow(Date.UTC(2026, 9, 31, 18)), {month: "2026-11", daysLeft: 29});
  assert.deepStrictEqual(monthNow(Date.UTC(2026, 1, 1, 0)), {month: "2026-02", daysLeft: 27});
  const level = load("moneyBudgetLevel", ["function moneyBudgetLevel"]);
  assert.deepStrictEqual([level(3999999, 5e6), level(4e6, 5e6), level(5e6, 5e6), level(1, 0)], [0, 80, 100, 0]);
});

test("money cleanup: account deletion erases the own book, couple teardown the shared one", async () => {
  const b = fakeBackend({"users/u": {}, "couples/M": {memberIds: ["u"], memberCount: 1}});
  const chain = teardownChain(b);
  const deleteAccount = callable("deleteAccount", {
    db: b.db,
    admin: b.admin,
    isDocId: chain.isDocId,
    handleCoupleOnAccountDeletion: chain.handleCoupleOnAccountDeletion,
    callableErrorCopy: load("callableErrorCopy", ["const CALLABLE_ERROR_COPY", "function callableErrorCopy"]),
  });
  await deleteAccount({auth: {uid: "u"}, data: {}});
  for (const c of ["moneyWallets", "moneyTx", "moneyBudgets", "moneyMeta", "moneyRecurring", "moneyDebts"]) {
    assert.ok(b.log.includes(`recursiveDelete users/u/${c}`), c);
  }
  await chain.deleteCoupleCompletely(b.db.collection("couples").doc("M"), b.store.get("couples/M"));
  for (const c of ["moneyWallets", "moneyTx", "moneyBudgets", "moneyMeta", "moneyRecurring"]) {
    assert.ok(b.log.includes(`recursiveDelete couples/M/${c}`), c);
  }
  // A member leaving a 2-person couple leaves the shared book for the partner.
  const k = fakeBackend({"couples/K": {memberIds: ["u", "p"], memberCount: 2}});
  await teardownChain(k).handleCoupleOnAccountDeletion("K", "u");
  assert.deepStrictEqual(k.log.filter((l) => /money/.test(l)), []);
});
