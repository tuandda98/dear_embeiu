// Feature expenses (Sổ tiền), gap cases from project/features/expenses/test-cases.md
// (I18N-08). Same approach as index.test.js: index.js can't be required, so the
// code under test is lifted out of the source verbatim.

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

const buildMoneyText = new Function(
  `${declaration("const MONEY_COPY")}\n${declaration("function buildMoneyText")}\nreturn buildMoneyText;`,
)();

test("I18N-08: money push copy follows the device language (vi default, en for en*)", () => {
  const goal = {emoji: "🏝️", walletName: "Đà Lạt", actorName: "Tuấn", percent: 40};
  assert.strictEqual(buildMoneyText("vi", "goal", goal).body, "Tuấn vừa góp vào quỹ, giờ được 40%");
  assert.strictEqual(buildMoneyText("en", "goal", goal).body, "Tuấn just chipped in. The fund is at 40%");
  // en-US / EN / padded still English; unknown or missing falls back to Vietnamese.
  assert.strictEqual(buildMoneyText(" EN-us ", "reached", goal).body, "We hit the goal together. Time to make plans.");
  assert.strictEqual(buildMoneyText(undefined, "reached", goal).body, "Chúng mình góp đủ mục tiêu rồi. Lên lịch đi thôi.");
  assert.strictEqual(buildMoneyText("fr", "reached", goal).title, "🏝️ Đà Lạt đủ rồi!");
});

test("I18N-08: budget copy per level and language; no amount ever appears", () => {
  const vi80 = buildMoneyText("vi", "budget", {level: 80, daysLeft: 9});
  const en80 = buildMoneyText("en", "budget", {level: 80, daysLeft: 9});
  assert.strictEqual(vi80.title, "Tháng này chúng mình đã tiêu 80% ngân sách");
  assert.strictEqual(en80.title, "We've used 80% of this month's budget");
  assert.strictEqual(buildMoneyText("vi", "budget", {level: 100, daysLeft: 3}).body, "Chậm lại chút nhé, còn 3 ngày nữa mới sang tháng.");
  assert.strictEqual(buildMoneyText("en", "budget", {level: 100, daysLeft: 1}).body, "Let's slow down a little. One more day to go this month.");
  assert.strictEqual(buildMoneyText("en", "budget", {level: 100, daysLeft: 0}).body, "Let's slow down a little. Today is the last day of the month.");
  for (const lang of ["vi", "en"]) {
    for (const level of [80, 100]) {
      const t = buildMoneyText(lang, "budget", {level, daysLeft: 5, amount: 1250000});
      assert.doesNotMatch(`${t.title} ${t.body}`, /1[.,]?250[.,]?000|₫|đ\b/);
    }
  }
});

test("I18N-08: missing actor name falls back to the localized 'partner' word", () => {
  assert.match(buildMoneyText("vi", "goal", {percent: 10}).body, /^Người ấy vừa góp/);
  assert.match(buildMoneyText("en", "goal", {percent: 10}).body, /^Your person just chipped in/);
});
