// SRT of the on-screen text (BRIEF §3), built from the same cues and strings as the picture, so it follows any retime
// or an EN cut. Cues are sequential and never overlap; a block that builds up line by line rolls up.
// Usage (project root): node scripts/srt.ts  ->  out/deliver/dear-embeiu-launch-50s.<lang>.srt
import { mkdirSync, writeFileSync } from "node:fs";
import { LANG as lang, T } from "../src/copy/strings.ts";
import { A1, A2, A3, A4, A5, A6, A7, hourToFrame } from "../src/timeline/cues.ts";
import { group, pad2 } from "../src/lib/num.ts";

const NAME = "dear-embeiu-launch-50s";
const a1 = T.a1;
const clock = `${group(a1.clock.hours)} : ${pad2(a1.clock.minutes)} : ${pad2(a1.clock.seconds)}`;
const events = T.a4.events.map((e) => ({ f: hourToFrame(e.hour), text: `${pad2(Math.floor(e.hour))}:${pad2(Math.round((e.hour % 1) * 60))} ${e.title} · ${e.body}` }));
const counters = (end: boolean) => T.a4.counters.map((c) => `${c.label} ${end ? c.to : c.from}`).join(" · ");
/** a line longer than 48 characters breaks at the sentence boundary nearest its middle */
const wrap = (line: string) => {
  const cuts = [...line.matchAll(/[.!?] /g)].map((m) => m.index + 1);
  if (line.length <= 48 || !cuts.length) return line;
  const at = cuts.reduce((a, b) => (Math.abs(b - line.length / 2) < Math.abs(a - line.length / 2) ? b : a));
  return `${line.slice(0, at)}\n${line.slice(at + 1)}`;
};

const CUES: [from: number, to: number, text: string][] = [
  [0, A1.caption.frames[0], `${a1.eyebrow}\n${a1.days} ${a1.unit} · ${clock}`],
  [A1.caption.frames[0], A1.land, `${a1.days} ${a1.unit} · ${clock}\n${a1.caption}`],
  [A2.card[0], A2.leave[0], `${T.a2.push.title}\n${T.a2.push.body}`],
  [A2.lift[0], A2.unlock, `${T.a2.question}\n${T.a2.answerOther.label}: ${T.a2.rows[0].other}`],
  [A2.unlock, A2.compress[0], `${T.a2.answerOther.label}: ${T.a2.answerOther.text}\n${T.a2.answerYou.label}: ${T.a2.answerYou.text}\n${T.a2.caption}`],
  [A3.chip, A3.checks[0], T.a3.chip],
  ...T.a3.checks.map((c, k): [number, number, string] => [A3.checks[k], A3.checks[k + 1] ?? A3.stars[0], T.a3.checks.slice(0, k + 1).map((x) => `✓ ${x}`).join("\n")]),
  [A3.stars[0], A3.label.frames[0], `${T.a3.stars.join(" · ")} · ${T.couple.youLabel} / ${T.couple.otherLabel}`],
  [A3.label.frames[0], A4.ruler[0], `${T.a3.labelBadge} ${T.a3.labelFlowers}`],
  [A4.ruler[0], events[0].f, `${T.a4.label}\n${counters(false)}`],
  ...events.map((e, k): [number, number, string] => [e.f, events[k + 1]?.f ?? A4.caption, e.text]),
  [A4.caption, A4.lift[0], `${T.a4.caption.join(" ")}\n${counters(true)}`],
  [A4.lift[0], A4.cut, `${T.a4.widget.names} · ${T.a4.widget.days} ${T.a4.widget.caption}\n${T.a4.widget.milestone} · ${T.a4.widget.left}\n${T.a4.caption.join(" ")}`],
  [A5.h1, A5.h2, T.a5.h1],
  [A5.h2, A5.h3, `${T.a5.h1}\n${T.a5.h2}`],
  [A5.h3, A5.fine, `${T.a5.h1}\n${T.a5.h2}\n${T.a5.h3.join(" ")}`],
  [A5.fine, A5.hold, `${T.a5.h1}\n${T.a5.h2}\n${T.a5.h3.join(" ")}\n${T.a5.fine}`],
  [A6.glyphs[0], A6.recede[0], `${T.a6.glyphs.slice(0, 4).join(" · ")}\n${T.a6.glyphs.slice(4).join(" · ")}`],
  [A7.lock, A7.l2, `${T.a7.wordmark}\n${T.a7.l1}\n${T.a7.legal}`],
  [A7.l2, A7.offer, `${T.a7.wordmark}\n${T.a7.l1} ${T.a7.l2}\n${T.a7.legal}`],
  [A7.offer, 3000, `${T.a7.offer} · ${T.a7.url}\n${T.a7.legal}`],
];

const ts = (f: number) => {
  const ms = Math.round((f * 1000) / 60);
  const p = (v: number, n = 2) => String(v).padStart(n, "0");
  return `${p(Math.floor(ms / 3600000))}:${p(Math.floor(ms / 60000) % 60)}:${p(Math.floor(ms / 1000) % 60)},${p(ms % 1000, 3)}`;
};

CUES.forEach(([a, b], k) => {
  if (!(b > a) || (k > 0 && a < CUES[k - 1][1])) throw new Error(`cue ${k + 1} (${a}–${b}) is empty or overlaps the one before`);
});
const out = `out/deliver/${NAME}.${lang}.srt`;
mkdirSync("out/deliver", { recursive: true });
writeFileSync(out, CUES.map(([a, b, text], k) => `${k + 1}\n${ts(a)} --> ${ts(b)}\n${text.split("\n").map(wrap).join("\n")}\n`).join("\n"));
console.log(`${out}: ${CUES.length} cues`);
