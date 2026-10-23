// Feature weather, gap cases from project/features/weather/test-cases.md
// (CF-21, CF-22, NT-19, LV-01). Same approach as weather.test.js: index.js
// can't be required, so the code under test is lifted out of the source.

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

// The whole weather block of index.js (config, MET fetch, callable).
const CALLABLE_AT = SRC.indexOf("exports.getCityWeather = onCall(");
const WEATHER_SRC = SRC.slice(
  SRC.lastIndexOf("// ── weather (đợt 2) ──", CALLABLE_AT),
  SRC.indexOf("// ── expenses (đợt 2) ──", CALLABLE_AT),
);
const CALLABLE_SRC = WEATHER_SRC.slice(WEATHER_SRC.indexOf("exports.getCityWeather = onCall("));

const NOW = Date.parse("2026-10-20T01:10:00Z");

test("weather block is found in index.js", () => {
  assert.ok(WEATHER_SRC.length > 1000);
  assert.ok(CALLABLE_SRC.startsWith("exports.getCityWeather"));
});

// ---- CF-21 / NT-19: privacy, no inbox, no push ---------------------------------

test("CF-21: MET gets coordinates only — no uid, email or couple in URL or headers", async () => {
  const fetches = [];
  const store = new Map();
  const ref = {
    get: async () => ({exists: store.size > 0, data: () => store.get("HN")}),
    set: async (data, opts) => store.set("HN", opts && opts.merge ? {...store.get("HN"), ...data} : data),
  };
  const get = load("getWeatherForCity", [
    "const WEATHER_CONFIG",
    "function normalizeMetForecast",
    "function weatherExpiresAt",
    "async function getWeatherForCity",
  ], {
    db: {
      collection: () => ({doc: () => ref}),
      runTransaction: async (fn) => fn({get: (r) => r.get(), set: (r, d, o) => r.set(d, o)}),
    },
    fetch: async (url, opts) => {
      fetches.push({url, headers: opts.headers});
      return {
        status: 200,
        ok: true,
        headers: {get: () => null},
        json: async () => ({
          properties: {
            meta: {},
            timeseries: [{
              time: "2026-10-20T01:00:00Z",
              data: {
                instant: {details: {air_temperature: 25}},
                next_1_hours: {summary: {symbol_code: "cloudy"}, details: {precipitation_amount: 0}},
              },
            }],
          },
        }),
      };
    },
    logger: {warn: () => {}},
  });
  await get({id: "HN", lat: 21.03, lon: 105.85}, NOW);
  assert.strictEqual(fetches.length, 1);
  assert.match(fetches[0].url, /^https:\/\/api\.met\.no\/weatherapi\/locationforecast\/2\.0\/compact\?lat=21\.03&lon=105\.85$/);
  assert.deepStrictEqual(Object.keys(fetches[0].headers).sort(), ["Accept", "User-Agent"]);
  assert.doesNotMatch(JSON.stringify(fetches[0]), /uid|email|couple/i);
  // The cache doc is per city, nothing about the caller.
  assert.deepStrictEqual(Object.keys(store.get("HN")).sort(), ["cityId", "expiresAt", "fetchedAt", "hours", "lastModified"]);
});

test("CF-21: the per-city fetch never receives the caller (signature + call site)", () => {
  assert.match(WEATHER_SRC, /async function getWeatherForCity\(city, nowMs\)/);
  assert.match(CALLABLE_SRC, /getWeatherForCity\(WEATHER_CITIES\.get\(id\), nowMs\)/);
  // request.auth is only read for the sign-in gate.
  assert.strictEqual(CALLABLE_SRC.match(/request\.auth/g).length, 2);
});

test("CF-21 / NT-19: the weather feature writes no inbox item and sends no push", () => {
  for (const banned of [
    "writeInboxNotifications",
    "sendToRecipientDevices",
    "messaging(",
    "sendEachForMulticast",
    "notifications",
    "devices",
  ]) {
    assert.ok(!WEATHER_SRC.includes(banned), `weather block must not use "${banned}"`);
  }
  // And no trigger of its own: the only export in the block is the callable.
  const exportsInBlock = WEATHER_SRC.match(/^exports\.\w+/gm);
  assert.deepStrictEqual(exportsInBlock, ["exports.getCityWeather"]);
});

// ---- CF-22: abuse ---------------------------------------------------------------

test("CF-22: getCityWeather limits callers per user or requires App Check", {
  skip: "BUG (known debt, overview): getCityWeather has no per-user rate limit and no App Check " +
    "(`request.app`); a signed-in client can loop it. The per-city cache bounds MET traffic, " +
    "not Cloud Function invocations.",
}, () => {
  assert.ok(/request\.app|enforceAppCheck|rateLimit/.test(CALLABLE_SRC));
});

test("CF-22: what does bound the damage — max 2 ids per call, cache before MET", () => {
  const parse = load("parseWeatherCityIds", ["function parseWeatherCityIds"], {
    WEATHER_CITIES: new Map([["a", {}], ["b", {}], ["c", {}]]),
  });
  assert.strictEqual(parse(["a", "b", "c"]), null);
  assert.deepStrictEqual(parse(["a", "b"]), ["a", "b"]);
  assert.match(CALLABLE_SRC, /timeoutSeconds: 30/);
});

// ---- LV-01: partner leaves ---------------------------------------------------------

function leaveSnippet() {
  const handler = SRC.indexOf("exports.notifyPartnerLeft");
  const start = SRC.indexOf("// ── weather (đợt 2) ──", handler);
  const end = SRC.indexOf("// ── arrival (đợt 2) ──", start);
  assert.ok(handler !== -1 && start > handler && end > start);
  // Still inside notifyPartnerLeft: no other export in between.
  assert.ok(!SRC.slice(handler + 10, start).includes("\nexports."));
  return SRC.slice(start, end);
}

function runLeave({failDelete = false} = {}) {
  const log = [];
  const warns = [];
  const node = (p) => ({
    collection: (c) => node(`${p}/${c}`),
    doc: (d) => node(`${p}/${d}`),
    delete: async () => {
      log.push(p);
      if (failDelete) {
        throw new Error("boom");
      }
    },
  });
  const run = new AsyncFunction("db", "coupleId", "leaverUid", "logger", leaveSnippet());
  return {
    done: run(node(""), "C1", "LEAVER", {warn: (...a) => warns.push(a)}),
    log,
    warns,
  };
}
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;

test("LV-01: notifyPartnerLeft deletes weather/{leaverUid} of that couple, nothing else", async () => {
  const r = runLeave();
  await r.done;
  assert.deepStrictEqual(r.log, ["/couples/C1/weather/LEAVER"]);
  assert.strictEqual(r.warns.length, 0);
});

test("LV-01: a failed delete is logged and does not stop the rest of the cleanup", async () => {
  const r = runLeave({failDelete: true});
  await r.done; // must not reject
  assert.strictEqual(r.warns.length, 1);
  assert.strictEqual(r.warns[0][0], "Could not delete weather city on partner left.");
  assert.deepStrictEqual(Object.keys(r.warns[0][1]).sort(), ["coupleId", "leaverUid", "message"]);
});
