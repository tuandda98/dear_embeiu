// Shared helpers for the Firestore + Storage rules unit tests.
//
// All tests run against the Firebase emulator (booted by
// `firebase emulators:exec`). `@firebase/rules-unit-testing` mints local auth
// tokens — no real Firebase project or credentials are needed; the project id
// is intentionally `demo-*` so the SDK stays fully offline.

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');

// repo root is two levels up from this file (firebase_rules_test/test/).
const REPO_ROOT = path.resolve(__dirname, '..', '..');

let testEnv = null;

async function getTestEnv() {
  if (!testEnv) {
    testEnv = await initializeTestEnvironment({
      projectId: 'demo-dear-embeiu',
      firestore: {
        rules: fs.readFileSync(path.join(REPO_ROOT, 'firestore.rules'), 'utf8'),
      },
      storage: {
        rules: fs.readFileSync(path.join(REPO_ROOT, 'storage.rules'), 'utf8'),
      },
    });
  }
  return testEnv;
}

async function cleanupTestEnv() {
  if (testEnv) {
    await testEnv.cleanup();
    testEnv = null;
  }
}

// ---- auth context shortcuts -------------------------------------------------

function authedDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauthedDb() {
  return testEnv.unauthenticatedContext().firestore();
}

function authedStorage(uid) {
  return testEnv.authenticatedContext(uid).storage();
}

function unauthedStorage() {
  return testEnv.unauthenticatedContext().storage();
}

// ---- seeding (bypasses rules) ----------------------------------------------

// Write arbitrary docs with rules disabled, to set up preconditions.
async function seed(writer) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await writer(ctx.firestore());
  });
}

async function seedDoc(p, data) {
  await seed(async (db) => {
    await setDoc(doc(db, p), data);
  });
}

// ---- document factories (match the rules' required shapes) -----------------
//
// A fixed timestamp keeps the tests deterministic. Rules only check
// `is timestamp`, never the value, so any concrete timestamp works.
const TS = new Date('2026-01-01T00:00:00Z');

function validUser(overrides = {}) {
  return {
    email: 'alice@example.com',
    displayName: 'Alice',
    avatarUrl: null,
    coupleId: null,
    inviteCode: 'ABC123',
    status: 'single',
    createdAt: TS,
    updatedAt: TS,
    lastSeenAt: null,
    ...overrides,
  };
}

function validDevice(overrides = {}) {
  return {
    token: 'fcm-token-123',
    platform: 'android',
    notificationsEnabled: true,
    languageCode: 'vi',
    updatedAt: TS,
    ...overrides,
  };
}

function validInviteCode(uid, overrides = {}) {
  return {
    userId: uid,
    displayName: 'Alice',
    coupleId: null,
    createdAt: TS,
    updatedAt: TS,
    ...overrides,
  };
}

function validCouple(overrides = {}) {
  const memberIds = overrides.memberIds || ['alice'];
  return {
    person1Name: 'Alice',
    person2Name: 'Bob',
    anniversaryDate: TS,
    couplePhotoPath: null,
    couplePhotoUrl: null,
    couplePhotoStoragePath: null,
    inviteCode: 'ABC123',
    coupleCode: null,
    memberIds,
    memberCount: memberIds.length,
    createdByUserId: memberIds[0],
    status: memberIds.length >= 2 ? 'active' : 'waiting_partner',
    createdAt: TS,
    updatedAt: TS,
    ...overrides,
  };
}

function validPhoto(coupleId, authorUid, overrides = {}) {
  return {
    path: null,
    remoteUrl: 'https://example.com/p.jpg',
    storagePath: `couple_photos/${coupleId}/p.jpg`,
    coupleId,
    authorUserId: authorUid,
    authorName: 'Alice',
    uploadDate: TS,
    caption: 'hi',
    updatedAt: TS,
    ...overrides,
  };
}

// ---- shared fixtures --------------------------------------------------------
//
// ACTIVE couple `c1` = {alice, bob}; WAITING couple `cw` = {carol} only.
async function seedActiveCouple(id = 'c1', a = 'alice', b = 'bob') {
  await seedDoc(`couples/${id}`, validCouple({ memberIds: [a, b], createdByUserId: a }));
}

async function seedWaitingCouple(id = 'cw', a = 'carol') {
  await seedDoc(`couples/${id}`, validCouple({ memberIds: [a], createdByUserId: a }));
}

module.exports = {
  getTestEnv,
  cleanupTestEnv,
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  authedStorage,
  unauthedStorage,
  seed,
  seedDoc,
  seedActiveCouple,
  seedWaitingCouple,
  validUser,
  validDevice,
  validInviteCode,
  validCouple,
  validPhoto,
  TS,
};
