// Mocha root hooks: one shared test environment for the whole run, with data
// cleared between tests so each `it` starts from a clean slate.
const { getTestEnv, cleanupTestEnv } = require('./helpers');

exports.mochaHooks = {
  async beforeAll() {
    this.timeout(60000); // first run may download emulator jars
    await getTestEnv();
  },
  async afterEach() {
    const env = await getTestEnv();
    await env.clearFirestore();
    await env.clearStorage();
  },
  async afterAll() {
    await cleanupTestEnv();
  },
};
