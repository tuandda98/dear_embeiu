// Feature weather (overview §5.3): the plain pieces of getCityWeather —
// `npm test` (node:test, no emulator, no network). Same approach as
// index.test.js: index.js can't be required, so each test lifts the
// declarations it needs out of the source verbatim.

const test = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const SRC = fs.readFileSync(path.join(__dirname, "..", "index.js"), "utf8");
const CITIES = require("../weather_cities.json");

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

const HOUR = 3600000;
// 2026-10-20 01:10 UTC = 08:10 in Vietnam, the design's sample morning.
const NOW = Date.parse("2026-10-20T01:10:00Z");

// A hand-written MET /compact body: one past hour, hourly steps, then the
// 6-hour steps MET switches to further out.
function metBody({hourly = 40, sixHourly = 3} = {}) {
  const timeseries = [];
  const start = Date.parse("2026-10-20T00:00:00Z");
  for (let i = 0; i < hourly; i++) {
    timeseries.push({
      time: new Date(start + i * HOUR).toISOString().replace(".000", ""),
      data: {
        instant: {details: {air_temperature: 24 + i / 10, relative_humidity: 80}},
        next_1_hours: {
          summary: {symbol_code: i === 5 ? "rainshowers_day" : "cloudy"},
          details: {precipitation_amount: i === 5 ? 1.4 : 0},
        },
        next_6_hours: {summary: {symbol_code: "cloudy"}, details: {precipitation_amount: 0}},
      },
    });
  }
  for (let i = 0; i < sixHourly; i++) {
    timeseries.push({
      time: new Date(start + (hourly + i * 6) * HOUR).toISOString(),
      data: {
        instant: {details: {air_temperature: 20}},
        next_6_hours: {summary: {symbol_code: "lightrain"}, details: {precipitation_amount: 3}},
      },
    });
  }
  return {type: "Feature", properties: {meta: {updated_at: "2026-10-20T00:30:00Z"}, timeseries}};
}

const normalize = () => load("normalizeMetForecast", [
  "const WEATHER_CONFIG",
  "function normalizeMetForecast",
]);

// ---- normalizeMetForecast -----------------------------------------------------

test("MET → 36 hours from the current hour, raw numbers only", () => {
  const hours = normalize()(metBody(), NOW);
  assert.strictEqual(hours.length, 36);
  // 00:00 UTC is over (it ended at 01:00); 01:00 is the current hour.
  assert.strictEqual(hours[0].t, Date.parse("2026-10-20T01:00:00Z"));
  assert.deepStrictEqual(Object.keys(hours[0]).sort(), ["rain", "symbol", "t", "temp"]);
  assert.strictEqual(hours[0].temp, 24.1);
  assert.strictEqual(hours[0].symbol, "cloudy");
  assert.strictEqual(hours[0].rain, 0);
  const rainy = hours.find((h) => h.t === Date.parse("2026-10-20T05:00:00Z"));
  assert.deepStrictEqual([rainy.symbol, rainy.rain], ["rainshowers_day", 1.4]);
  assert.ok(hours.every((h, i) => i === 0 || h.t > hours[i - 1].t));
});

test("MET 6-hour steps: keep the symbol, spread the rain per hour", () => {
  const hours = normalize()(metBody({hourly: 10, sixHourly: 3}), NOW);
  const six = hours.filter((h) => h.symbol === "lightrain");
  assert.strictEqual(six.length, 3);
  assert.ok(six.every((h) => h.rain === 0.5));
  assert.strictEqual(hours.length, 9 + 3);
});

test("MET: steps past 36 hours are dropped even when sparse", () => {
  const hours = normalize()(metBody({hourly: 2, sixHourly: 12}), NOW);
  assert.ok(hours.every((h) => h.t < NOW + 36 * HOUR));
});

test("MET: broken steps and bodies don't throw", () => {
  const n = normalize();
  assert.deepStrictEqual(n(null, NOW), []);
  assert.deepStrictEqual(n({properties: {}}, NOW), []);
  const body = metBody({hourly: 3, sixHourly: 0});
  body.properties.timeseries[1].data.instant.details.air_temperature = "warm";
  body.properties.timeseries[2].time = "not a date";
  assert.strictEqual(n(body, NOW).length, 0);
});

// ---- expiry, ids, error copy -------------------------------------------------

test("expiresAt follows MET's Expires, never sooner than 30 minutes", () => {
  const expiresAt = load("weatherExpiresAt", ["const WEATHER_CONFIG", "function weatherExpiresAt"]);
  const later = new Date(NOW + 2 * HOUR).toUTCString();
  assert.strictEqual(expiresAt(later, NOW), Math.floor((NOW + 2 * HOUR) / 1000) * 1000);
  assert.strictEqual(expiresAt(new Date(NOW + 60000).toUTCString(), NOW), NOW + 30 * 60000);
  assert.strictEqual(expiresAt(null, NOW), NOW + 30 * 60000);
  assert.strictEqual(expiresAt("garbage", NOW), NOW + 30 * 60000);
});

test("cityIds: 1–2 ids from the bundled list only (D9)", () => {
  const parse = load("parseWeatherCityIds", ["function parseWeatherCityIds"], {
    WEATHER_CITIES: new Map(CITIES.map((c) => [c.id, c])),
  });
  assert.deepStrictEqual(parse(["vn-ha-noi"]), ["vn-ha-noi"]);
  assert.deepStrictEqual(parse(["vn-ha-noi", "vn-tp-hcm"]), ["vn-ha-noi", "vn-tp-hcm"]);
  assert.deepStrictEqual(parse(["vn-hue", "vn-hue"]), ["vn-hue"]);
  for (const bad of [
    ["fake"], ["vn-ha-noi", "fake"], ["vn-ha-noi", "vn-hue", "vn-tp-hcm"], [], "vn-ha-noi",
    undefined, [42], ["__proto__"], ["constructor"],
  ]) {
    assert.strictEqual(parse(bad), null, JSON.stringify(bad));
  }
});

test("weather errors speak the caller's language", () => {
  const copyFor = load("weatherErrorCopy", [
    "const CALLABLE_ERROR_COPY",
    "function callableErrorCopy",
    "const WEATHER_ERROR_COPY",
    "function weatherErrorCopy",
  ]);
  assert.match(copyFor({data: {lang: "en"}}).badCities, /isn't on the list/);
  assert.match(copyFor({data: {lang: "en-US"}}).signIn, /sign in/);
  assert.match(copyFor({data: {}}).badCities, /chưa có trong danh sách/);
  assert.match(copyFor({}).unavailable, /Chưa tải được/);
});

// ---- getWeatherForCity: cache, 304, failures ---------------------------------

// weatherCache in memory + a scripted fetch. `fetches` records each MET call.
function harness(cache, replies) {
  const store = new Map(cache ? [["HN", cache]] : []);
  const fetches = [];
  const ref = (id) => ({
    get: async () => ({
      exists: store.has(id),
      data: () => store.get(id),
      get: (f) => (store.get(id) || {})[f],
    }),
    set: async (data, opts) => {
      store.set(id, opts && opts.merge ? {...store.get(id), ...data} : data);
    },
  });
  const fetchFake = async (url, opts) => {
    fetches.push({url, headers: opts.headers});
    const reply = replies.shift();
    if (reply instanceof Error) {
      throw reply;
    }
    return {
      status: reply.status,
      ok: reply.status >= 200 && reply.status < 300,
      headers: {get: (k) => (reply.headers || {})[k.toLowerCase()] || null},
      json: async () => reply.body,
    };
  };
  const get = load("getWeatherForCity", [
    "const WEATHER_CONFIG",
    "function normalizeMetForecast",
    "function weatherExpiresAt",
    "async function getWeatherForCity",
  ], {
    db: {
      collection: (name) => {
        assert.strictEqual(name, "weatherCache");
        return {doc: ref};
      },
      runTransaction: async (fn) => fn({get: (r) => r.get(), set: (r, d, o) => r.set(d, o)}),
    },
    fetch: fetchFake,
    logger: {warn: () => {}},
  });
  return {get: (now = NOW) => get({id: "HN", lat: 21.03, lon: 105.85}, now), store, fetches, replies};
}

const oldCache = () => ({
  cityId: "HN",
  fetchedAt: NOW - 2 * HOUR,
  expiresAt: NOW - 60000,
  lastModified: "Tue, 20 Oct 2026 00:00:00 GMT",
  hours: [{t: NOW - HOUR, temp: 23, symbol: "cloudy", rain: 0}],
});

test("cache still valid → no MET call", async () => {
  const h = harness({...oldCache(), expiresAt: NOW + 60000}, []);
  const out = await h.get();
  assert.deepStrictEqual([out.stale, out.fetchedAt], [false, NOW - 2 * HOUR]);
  assert.strictEqual(h.fetches.length, 0);
});

test("expired → MET with User-Agent + If-Modified-Since → cache rewritten", async () => {
  const h = harness(oldCache(), [{
    status: 200,
    headers: {"expires": new Date(NOW + HOUR).toUTCString(), "last-modified": "Tue, 20 Oct 2026 01:00:00 GMT"},
    body: metBody(),
  }]);
  const out = await h.get();
  assert.strictEqual(h.fetches.length, 1);
  assert.strictEqual(h.fetches[0].url,
    "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=21.03&lon=105.85");
  assert.match(h.fetches[0].headers["User-Agent"], /^DearEmbeiu\/\S+ \(https:\/\/dearembeiu\.com\)$/);
  assert.strictEqual(h.fetches[0].headers["If-Modified-Since"], "Tue, 20 Oct 2026 00:00:00 GMT");
  assert.deepStrictEqual([out.stale, out.fetchedAt, out.hours.length], [false, NOW, 36]);
  const saved = h.store.get("HN");
  assert.strictEqual(saved.lastModified, "Tue, 20 Oct 2026 01:00:00 GMT");
  assert.strictEqual(saved.expiresAt, Math.floor((NOW + HOUR) / 1000) * 1000);
  assert.strictEqual(saved.retryAt, undefined);
});

test("first fetch sends no If-Modified-Since", async () => {
  const h = harness(null, [{status: 200, headers: {}, body: metBody()}]);
  const out = await h.get();
  assert.strictEqual(h.fetches[0].headers["If-Modified-Since"], undefined);
  assert.strictEqual(out.stale, false);
  assert.strictEqual(h.store.get("HN").expiresAt, NOW + 30 * 60000);
});

test("304 → only expiresAt moves, the cached hours are served", async () => {
  const h = harness(oldCache(), [{status: 304, headers: {}}]);
  const out = await h.get();
  assert.deepStrictEqual([out.stale, out.fetchedAt], [false, NOW - 2 * HOUR]);
  const saved = h.store.get("HN");
  assert.strictEqual(saved.expiresAt, NOW + 30 * 60000);
  assert.strictEqual(saved.fetchedAt, NOW - 2 * HOUR);
  assert.strictEqual(saved.hours.length, 1);
});

test("MET down → old cache marked stale, no new call for 10 minutes", async () => {
  const h = harness(oldCache(), [new Error("timeout"), {status: 200, headers: {}, body: metBody()}]);
  const first = await h.get();
  assert.deepStrictEqual([first.stale, first.fetchedAt], [true, NOW - 2 * HOUR]);
  const again = await h.get(NOW + 5 * 60000);
  assert.strictEqual(again.stale, true);
  assert.strictEqual(h.fetches.length, 1);
  const later = await h.get(NOW + 11 * 60000);
  assert.strictEqual(later.stale, false);
  assert.strictEqual(h.fetches.length, 2);
});

test("MET 5xx / empty body → stale, never an empty forecast in cache", async () => {
  const h = harness(oldCache(), [{status: 503, headers: {}}]);
  assert.strictEqual((await h.get()).stale, true);
  const e = harness(oldCache(), [{status: 200, headers: {}, body: {properties: {timeseries: []}}}]);
  assert.strictEqual((await e.get()).stale, true);
  assert.strictEqual(e.store.get("HN").hours.length, 1);
});

test("no cache and MET fails → null, and the backoff holds without a cache", async () => {
  const h = harness(null, [new Error("ECONNRESET")]);
  assert.strictEqual(await h.get(), null);
  assert.strictEqual(await h.get(NOW + 60000), null);
  assert.strictEqual(h.fetches.length, 1);
});

test("every city in the JSON is a valid MET point (≤ 4 decimals, in range)", () => {
  const ids = new Set();
  for (const c of CITIES) {
    assert.ok(!ids.has(c.id), c.id);
    ids.add(c.id);
    assert.ok(Math.abs(c.lat) <= 90 && Math.abs(c.lon) <= 180, c.id);
    assert.ok(Number.isInteger(Math.round(c.lat * 100)) && Math.abs(c.lat * 100 - Math.round(c.lat * 100)) < 1e-9, c.id);
    assert.ok(Math.abs(c.lon * 100 - Math.round(c.lon * 100)) < 1e-9, c.id);
  }
  assert.strictEqual(CITIES.length, 116);
});

// ---- review 2026-10-20 -------------------------------------------------------

test("MET 403 / 429 → stale old copy + 10-minute backoff", async () => {
  for (const status of [403, 429]) {
    const h = harness(oldCache(), [{status, headers: {}}]);
    const out = await h.get();
    assert.strictEqual(out.stale, true, `${status}`);
    assert.strictEqual(h.store.get("HN").retryAt, NOW + 10 * 60000);
  }
});

test("retryAt stops mattering after one good fetch", async () => {
  const h = harness(oldCache(), [new Error("timeout"), {status: 200, headers: {}, body: metBody()}]);
  await h.get();
  await h.get(NOW + 11 * 60000);
  assert.strictEqual(h.store.get("HN").retryAt, undefined);
  // Next expiry: MET is asked again straight away, no leftover backoff.
  h.replies.push({status: 304, headers: {}});
  await h.get(NOW + 60 * 60000);
  assert.strictEqual(h.fetches.length, 3);
});

test("soft lock: a second caller during a refresh gets the old copy, no MET call", async () => {
  const h = harness({...oldCache(), lockUntil: NOW + 30000}, []);
  const out = await h.get();
  assert.deepStrictEqual([out.stale, out.fetchedAt], [false, NOW - 2 * HOUR]);
  assert.strictEqual(h.fetches.length, 0);
  // Lock expired → this caller refreshes.
  h.replies.push({status: 200, headers: {}, body: metBody()});
  await h.get(NOW + 61000);
  assert.strictEqual(h.fetches.length, 1);
});

test("6-hour data only still makes a forecast", () => {
  const hours = normalize()(metBody({hourly: 0, sixHourly: 6}), NOW);
  assert.ok(hours.length > 0);
  assert.ok(hours.every((h) => h.symbol === "lightrain" && h.rain === 0.5));
});

class HttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function callableWith(results) {
  const start = SRC.indexOf("exports.getCityWeather = onCall(");
  const end = SRC.indexOf("\n);", start);
  const body = `const exports = {};\n${SRC.slice(start, end + 3)}\nreturn exports.getCityWeather;`;
  const parse = load("parseWeatherCityIds", ["function parseWeatherCityIds"], {
    WEATHER_CITIES: new Map(CITIES.map((c) => [c.id, c])),
  });
  const scope = {
    onCall: (opts, handler) => handler,
    HttpsError,
    weatherErrorCopy: () => ({signIn: "s", badCities: "b", unavailable: "u"}),
    parseWeatherCityIds: parse,
    WEATHER_CITIES: new Map(CITIES.map((c) => [c.id, c])),
    getWeatherForCity: async (city) => results[city.id] || null,
  };
  return new Function(...Object.keys(scope), body)(...Object.values(scope));
}

test("getCityWeather: sign-in required, bad ids refused", async () => {
  const call = callableWith({});
  await assert.rejects(call({data: {cityIds: ["vn-ha-noi"]}}), {code: "unauthenticated"});
  await assert.rejects(call({auth: {uid: "a"}, data: {cityIds: ["fake"]}}), {code: "invalid-argument"});
});

test("getCityWeather: one city with data + one without → only the one", async () => {
  const hn = {fetchedAt: NOW, stale: false, hours: []};
  const call = callableWith({"vn-ha-noi": hn});
  const out = await call({auth: {uid: "a"}, data: {cityIds: ["vn-ha-noi", "vn-tp-hcm"]}});
  assert.deepStrictEqual(out, {ok: true, cities: {"vn-ha-noi": hn}});
  await assert.rejects(
    callableWith({})({auth: {uid: "a"}, data: {cityIds: ["vn-ha-noi", "vn-tp-hcm"]}}),
    {code: "unavailable"},
  );
});
