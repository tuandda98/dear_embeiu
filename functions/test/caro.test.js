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
