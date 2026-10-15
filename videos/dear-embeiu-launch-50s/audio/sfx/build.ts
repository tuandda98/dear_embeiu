// node audio/sfx/build.ts (project root) → out/audio/sfx.wav. The film's foley (DESIGN §7): one kit, close-miked,
// dry-ish, tactile, quiet — paper, wood, glass, a little rubber and air. Every voice is placed on an EVENTS frame (its
// first sample is the transient; the few swells END on the frame they lead into). Nothing that starts before the cut
// (1920) sounds past it, nothing reaches 2988. Room tone under everything but the two silences.
import { mkdirSync } from "node:fs";
import { LEN, SILENCE, SPF, SR, smp, stereo, enforceSilence, writeWav24, peakDb } from "../core.ts";
import { EVENTS, num, str, A1, A2, A3, A4, A6, A7, type Ev } from "../events.ts";
import { ACTS } from "../../src/timeline/grid.ts";
import { type Rand, rand, add, bell, bp, buf, chirp, db, env, hp, lp, mix, modes, ms, mul, noise, norm, sat, svfBand, tone, uni } from "./synth.ts";
import { key, thock, scrape, paperSlide, paperClick, typeset, stamp, hairTick, dome, glassDraw, settleAir, paperZip, exhale, uiSlide, airPop, cardFlutter, gather, sheen, roomTone } from "./kit.ts";

const out = stereo();
/** calibration knob: SFX_SOLO=id,id renders only those ids (no room tone) to out/audio/sfx-solo.wav */
const SOLO = process.env.SFX_SOLO?.split(",").filter(Boolean) ?? [];
const S = (f: number) => smp(f);
/** the kit's one level knob, balanced against the landed score (measured 15/10, 400 ms loudness: at 6.5, as in the
 *  reference build, the hero hits sat 1–4 dB UNDER the music; at 11 land/ting/stop/lock clear it by 6–8 dB and each
 *  act's foley sits 3–8 dB under its bed). Retune here if the score's level moves. */
const LIFT = 11;
/** crest control for percussive voices (clicks, knocks, presses): normalise, soft-saturate, normalise. Never on tonal ones */
const tame = (x: Float32Array, drive = 3) => norm(sat(norm(x, 0), drive), 0);
const D5 = 587.33, D6 = 1174.66, D7 = 2349.32;
const GLASS = [1, 2.32, 4.25, 6.63]; // wine-glass partials (the kit's)

// ───────────────────────────────────────── placement: walls, pans, the sync log
const WALLS = SILENCE.map(([a]) => a); // smp(1920), smp(2988): a voice that starts before a wall never sounds past it
let cur = { id: "", f: 0 };
const log: { id: string; late: number }[] = []; // per voice: frames from its start to its onset
const trimmed: string[] = [];
/** place mono `x` at frame f (fractional ok), level gdb (+LIFT), pan fixed or moving [from, to] across the voice */
function at(x: Float32Array, f: number, gdb: number, pan: number | [number, number] = 0) {
  const s = S(f);
  if (SILENCE.some(([a, b]) => s >= a && s < b)) throw new Error(`${cur.id}@${cur.f}: a voice placed inside a silence`);
  const wall = WALLS.find((w) => s < w) ?? LEN;
  let y = x;
  if (s + y.length > wall) {
    y = x.slice(0, Math.max(0, wall - s));
    const d = Math.min(ms(3), y.length);
    for (let i = 0; i < d; i++) y[y.length - 1 - i] *= i / d;
    trimmed.push(`${cur.id}@${cur.f}`);
  }
  let pk = 0;
  for (let i = 0; i < y.length; i++) pk = Math.max(pk, Math.abs(y[i]));
  let on = 0;
  while (on < y.length && Math.abs(y[on]) < pk / 4) on++; // onset = first sample within −12 dB of the voice's peak
  log.push({ id: cur.id, late: on / SPF });
  const [p0, p1] = typeof pan === "number" ? [pan, pan] : pan;
  const g = db(gdb + LIFT);
  for (let i = Math.max(0, -s); i < y.length && s + i < LEN; i++) {
    const a = ((Math.max(-1, Math.min(1, p0 + (p1 - p0) * (i / y.length))) + 1) * Math.PI) / 4;
    out.L[s + i] += y[i] * Math.cos(a) * g;
    out.R[s + i] += y[i] * Math.sin(a) * g;
  }
}

// ───────────────────────────────────────── designs only this film needs (the rest is the kit)
/** THE CLOCK'S SECOND: a short filtered knock (the knock carries it) with a faint D body — a small, heavily damped free
 *  wood bar (1 : 2.76 : 5.40) over a D box an octave down. Wood, never electronic; ~25 ms. Measured: 800–3200 Hz on top,
 *  the D5 band 6 dB under it. `bright` darkens/brightens, `body` how much D you hear. */
function woodTick(r: Rand, { f0 = D5, bright = 1, body = 0.1 } = {}): Float32Array {
  const knock = mul(bp(noise(ms(16), r), 1400 * bright, 0.7), env(ms(16), ms(0.3), ms(3.5)));
  const low = mul(lp(noise(ms(14), r), 700), env(ms(14), ms(0.4), ms(3.2)));
  const tip = mul(bp(noise(ms(3), r), 3400 * bright, 1.4), env(ms(3), ms(0.06), ms(0.4)));
  const bar = modes(ms(60), [f0, f0 * 2.756, f0 * 5.404].map((x) => x * uni(r, 0.995, 1.005)), [ms(8), ms(3.2), ms(1.3)], [1, 0.45, 0.18], r);
  const box = modes(ms(40), [f0 / 2], [ms(4.4)], [1], r);
  return norm(lp(hp(mix([{ b: knock }, { b: low, g: 0.5 }, { b: tip, g: 0.35 }, { b: bar, g: body }, { b: box, g: body * 0.6 }]), 140), 6000 * bright), 0);
}
/** the kit's micro-tick (counter leaf / entry marker) with a pitch factor: the day cells rise, "you" is brighter */
function leaf(r: Rand, kind: "counter" | "entry", p = 1): Float32Array {
  const e = kind === "entry";
  const click = mul(bp(noise(ms(2), r), (e ? uni(r, 1600, 2200) : uni(r, 2600, 3200)) * p, 1.2), env(ms(2), ms(0.05), ms(e ? 0.25 : 0.35)));
  return norm(mix([{ b: click }, { b: modes(ms(25), [(e ? uni(r, 880, 1050) : 1480) * p], [ms(e ? 2.5 : 4)], [0.5], r) }]), 0);
}
/** a tiny glass tick (wine-glass partials, short): the constellation's stars, glyph 1 */
function glassTick(r: Rand, f0: number, len = 150): Float32Array {
  const body = modes(ms(len), GLASS.map((x) => f0 * x), [ms(len * 0.45), ms(len * 0.22), ms(len * 0.1), ms(len * 0.05)], [1, 0.3, 0.1, 0.03], r);
  return norm(mix([{ b: body }, { b: mul(bp(noise(ms(2), r), 5200, 1.2), env(ms(2), ms(0.05), ms(0.3))), g: 0.3 }]), 0);
}
/** the kit's ting WITHOUT its sub boom (the boom is the score's): D6 glass, long, a slow fade so it never truncates */
function ting(r: Rand): Float32Array {
  const n = ms(3200);
  const y = mix([{ b: modes(n, GLASS.map((x) => D6 * x), [ms(750), ms(380), ms(180), ms(90)], [1, 0.32, 0.1, 0.03], r) }, { b: mul(bp(noise(ms(3), r), 5200, 1), env(ms(3), ms(0.05), ms(0.5))), g: 0.35 }]);
  const d = ms(700);
  for (let i = 0; i < d; i++) y[n - 1 - i] *= 0.5 - 0.5 * Math.cos((Math.PI * i) / d);
  return norm(y, 0);
}
/** the kit's ping at any pitch (the three widgets step down D6 → B5 → A5) */
function ping(r: Rand, f0 = D6): Float32Array {
  return norm(mix([{ b: modes(ms(420), [f0, f0 * 2, f0 * 3.01], [ms(105), ms(55), ms(25)], [1, 0.25, 0.05], r) }, { b: mul(bp(noise(ms(2), r), 4000, 1), env(ms(2), ms(0.05), ms(0.3))), g: 0.2 }]), 0);
}
/** something light set down: a felt tap over a short low body (the phone settling, a widget landing) */
function thunk(r: Rand, f0 = 120): Float32Array {
  const body = mul(tone(ms(120), chirp(f0 * 1.4, f0, ms(25))), env(ms(120), ms(1), ms(28)));
  const felt = mul(lp(noise(ms(40), r), 520), env(ms(40), ms(0.5), ms(6)));
  const tick = mul(bp(noise(ms(3), r), 2100, 1.2), env(ms(3), ms(0.08), ms(0.5)));
  return norm(mix([{ b: body, g: 0.8 }, { b: felt }, { b: tick, g: 0.25 }]), 0);
}
/** a paper flower opening: a soft low pop, the petals' flick */
function paperPop(r: Rand, p = 1): Float32Array {
  const pop = mul(tone(ms(40), chirp(420 * p, 160 * p, ms(30))), env(ms(40), ms(0.4), ms(8)));
  const flick = mul(bp(noise(ms(30), r), 2300 * p, 0.9), env(ms(30), ms(0.3), ms(4)));
  const petals = mul(svfBand(noise(ms(90), r), (i) => 1600 + 900 * (i / ms(90)), () => 1.2), bell(ms(90), ms(5), ms(70)));
  return norm(mix([{ b: pop }, { b: flick, g: 0.5 }, { b: petals, at: ms(4), g: 0.25 }]), 0);
}
/** the two dots touch: a tiny soft pop (smaller and higher than the send pop) */
function tinyPop(r: Rand): Float32Array {
  const pop = mul(tone(ms(30), chirp(900, 380, ms(22))), env(ms(30), ms(0.3), ms(5)));
  return norm(mix([{ b: pop }, { b: mul(bp(noise(ms(50), r), 1800, 0.7), env(ms(50), ms(1), ms(10))), g: 0.35 }]), 0);
}
/** air that swells INTO its end (the dot's fall, the riser): band noise sweeping up, ends on the frame it leads to */
function airRise(r: Rand, dur: number, f0: number, f1: number): Float32Array {
  const y = svfBand(noise(dur, r), (i) => f0 * (f1 / f0) ** (i / dur), (i) => 0.8 + 1.6 * (i / dur));
  const e = buf(dur);
  for (let i = 0; i < dur; i++) e[i] = (i / dur) ** 2.2 * (1 - Math.exp(-(dur - i) / ms(6)));
  return norm(mul(y, e), 0);
}
/** air that swells and settles over `dur` (a lift, a rise): band noise gliding f0 → f1, raised-cosine arc */
function airArc(r: Rand, dur: number, f0: number, f1: number, peakAt = 0.4): Float32Array {
  const y = svfBand(noise(dur, r), (i) => f0 * (f1 / f0) ** (i / dur), () => 1.1);
  const a = Math.max(1, Math.round(dur * peakAt));
  const e = Float32Array.from({ length: dur }, (_, i) => (i < a ? 0.5 - 0.5 * Math.cos((Math.PI * i) / a) : 0.5 + 0.5 * Math.cos((Math.PI * (i - a)) / (dur - a))));
  return norm(mul(y, e), 0);
}
/** friction that follows an ease-out motion (speed ∝ (1−t)²) over `dur`, with a soft felt stop at its end */
function easeSlide(r: Rand, dur: number, f0: number, f1: number, stop = 0.25): Float32Array {
  const fr = svfBand(noise(dur, r), (i) => f0 + (f1 - f0) * (i / dur), () => 1.2);
  const e = Float32Array.from({ length: dur }, (_, i) => Math.min(1, i / ms(8)) * (1 - i / dur) ** 2);
  const felt = mul(lp(noise(ms(40), r), 420), env(ms(40), ms(0.5), ms(7)));
  return norm(mix([{ b: mul(fr, e) }, { b: felt, at: dur, g: stop }]), 0);
}
/** a dry card riffle (the kit's cardFlutter) whose tick rate `rate(p)` /s, level `amp(p)` and pitch `lift(p)` follow the
 *  motion, p = 0…1 */
function riffle(r: Rand, dur: number, rate: (p: number) => number, amp: (p: number) => number, lift = (_p: number) => 1): Float32Array {
  const y = buf(dur + ms(30));
  for (let t = 0; t < dur; t += Math.round((SR / rate(t / dur)) * uni(r, 0.85, 1.15)))
    add(y, mul(bp(noise(ms(4), r), uni(r, 1500, 3400) * lift(t / dur), 1.3), env(ms(4), ms(0.08), ms(0.7))), t, uni(r, 0.4, 1) * amp(t / dur));
  return norm(mix([{ b: y }, { b: mul(lp(noise(y.length, r), 700), bell(y.length, ms(60), ms(200))), g: 0.12 }]), 0);
}
/** a tiny bell swinging once: the clapper hits both sides (same bell, the return softer) */
function bellSwing(r: Rand): Float32Array {
  const hit = (g: number) => mix([{ b: modes(ms(260), [D6, D6 * 2.01, D6 * 2.93, D6 * 4.1], [ms(110), ms(60), ms(30), ms(15)], [1, 0.4, 0.2, 0.08], r) }, { b: mul(bp(noise(ms(2), r), 4600, 1.2), env(ms(2), ms(0.05), ms(0.3))), g: 0.4 * g }]);
  return norm(mix([{ b: hit(1) }, { b: hit(0.6), at: ms(150), g: 0.6 }]), 0);
}
/** the eight things (A6): eight different micro-sounds from the one kit, one per glyph, each mirroring its drawing */
function glyphSound(r: Rand, n: number): Float32Array {
  switch (n) {
    case 0: return tame(woodTick(r, { f0: D5 * 0.84, bright: 0.85, body: 0.25 }), 2); // digits ticking in a box: wood knock
    case 1: return glassTick(r, D7, 180); // two frames overlapping: a glass tick
    case 2: return tame(paperSlide(r), 2); // two bubbles, the lock opens: a paper slide
    case 3: return tame(mix([{ b: dome(r) }, { b: dome(r, true), at: ms(70), g: 0.6 }]), 2); // a face that smiles: rubber dome
    case 4: return hairTick(r); // a moon filling: the metal hairline tick
    case 5: return tame(tinyPop(r), 2); // a bubble with three dots: a soft pop
    case 6: return bellSwing(r); // a bell swinging once: two ticks
    default: return norm(mix([0, 110, 220].map((t, k) => ({ b: scrape(r, ms(60), { f0: 2500 + 250 * k, f1: 3100 + 250 * k }), at: ms(t), g: 1 - 0.12 * k }))), 0); // ✌️ ✊ ✋: three strokes
  }
}
const GLYPH_TRIM = [5, -5, -6, 3.5, 4.5, 4, -3, -3]; // dB: equal energy in the first 100 ms (measured), so the eight read alike

// ───────────────────────────────────────── room tone: under everything, digital zero in the silences
if (!SOLO.length) {
  const [l, r] = [roomTone(rand(7), LEN), roomTone(rand(8), LEN)];
  const ramp = (i: number, a: number, n: number) => Math.min(1, Math.max(0, (i - a) / n));
  const cos = (x: number) => 0.5 - 0.5 * Math.cos(Math.PI * x);
  const [cut, back, end] = [S(A4.cut), SILENCE[0][1], WALLS[1]];
  for (let i = 0; i < LEN; i++) {
    let g: number;
    if (i < cut) g = db(-50) * ramp(i, 0, ms(10)) * (1 - ramp(i, cut - ms(3), ms(3))); // dead cut at 32.0 (3 ms declick)
    else if (i < back) g = 0;
    else g = db(-53 + 3 * cos(ramp(i, S(A6.composer[0]), S(30)))) * cos(ramp(i, back, S(15))) * (1 - cos(ramp(i, end - S(48), S(48)))); // A5 faint
    out.L[i] += l[i] * g;
    out.R[i] += r[i] * g;
  }
}

// ───────────────────────────────────────── the events
const actOf = (f: number) => ACTS.find((x) => f >= x.from && f < x.to)?.id ?? "a7";
const next = (id: string, f: number, d: number) => EVENTS.find((x) => x.id === id && x.f > f)?.f ?? d;
/** where a span sound ends: the event's own `to`, else the cue's end, kept within 6–180 f (a reused id never runs away) */
const till = (e: Ev, end: number) => Math.max(e.f + 6, Math.min(num(e, "to", end), e.f + 180));
const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
/** where letter `f` of a typed line sits (0 … 1), to pan the keys along the line as it types */
const along = (keys: { frames: number[] }, f: number) => Math.max(0, keys.frames.indexOf(f)) / Math.max(1, keys.frames.length - 1);
/** Act 5: the SAME soft paper click for all seven facts, identical samples (plainness is the message) */
const FACT = tame(paperClick(rand(1950)), 2.5);
/** the three captions: level and where they sit (A2 bottom left, A4 under the ruler, A6 bottom left) */
const CAPTION: Record<string, [number, number]> = { a2: [-28, -0.4], a4: [-25, 0.06], a6: [-27, -0.3] };

const DESIGN: Record<string, (e: Ev, r: Rand) => void> = {
  // A1 · the number
  tick: (e, r) => (e.f < A1.land ? at(tame(woodTick(r), 2), e.f, -24, -0.2) : at(tame(woodTick(r), 2), e.f, -32, -0.32)), // after A1 the counter sits small at 60 %
  key: (e, r) => {
    const a = actOf(e.f);
    if (a === "a6") {
      const sp = e.data?.space;
      const space = sp !== undefined ? !!sp : A6.typed.text[A6.typed.frames.indexOf(e.f)] === " ";
      return at(tame(key(r, space ? "space" : "key")), e.f, -29 + uni(r, -1.5, 1), lerp(-0.33, -0.14, along(A6.typed, e.f)));
    }
    if (a === "a3" || (a === "a4" && e.f < A4.ruler[0])) return at(tame(key(r, "ai")), e.f, -34, lerp(-0.12, 0.12, along(A3.label, e.f))); // A3's label (a tail typed past 1200 still belongs to it)
    if (a === "a4") return at(tame(key(r, "ai")), e.f, -34, lerp(0.1, 0.3, along(A4.label, e.f)));
    at(tame(key(r, "digit")), e.f, -31, lerp(-0.45, -0.1, along(A1.caption, e.f))); // the caption types left → right
  },
  drop: (e, r) => at(airRise(r, S(till(e, next("land", e.f, A1.land))) - S(e.f), 500, 2600), e.f, -30, 0.03), // swells into the landing
  land: (e, r) => at(tame(thock(r), 2.2), e.f, -17, 0.03),

  // A2 · the other
  scroll: (e, r) => at(tame(paperSlide(r), 2), e.f, -34, 0.05), // the Home is flicked inside the phone (A2.scroll)
  sheet: (e, r) => at(uiSlide(r, S(num(e, "n") === 1 ? 8 : 16)), e.f, -34, 0.05), // a sheet rises inside the phone: mood 16 f, answer 8 f
  unfold: (e, r) => at(easeSlide(r, S(till(e, A2.card[1])) - S(e.f), 700, 1500), e.f, -31, [0.05, 0.2]),
  leader: (e, r) => at(scrape(r, ms(150), { f0: 2300 + 100 * num(e, "n"), f1: 3200 }), e.f, -32, [-0.05, 0.12]),
  row: (e, r) => at(tame(paperSlide(r), 2), e.f - (95 / 1000) * 60, -30, [0.12 + 0.05 * num(e, "n"), 0.25 + 0.05 * num(e, "n")]), // its settle tap lands on the row
  jump: (e, r) => at(hairTick(r), e.f, -21, 0.15),
  mood: (e, r) => at(tame(hp(paperClick(r), 900), 3), e.f, -35, 0.05 + 0.05 * num(e, "n")),
  pick: (e, r) => at(airPop(r), e.f, -22, 0.15),
  matched: (e, r) => {
    at(hairTick(r), e.f, -21, 0.2);
    at(sheen(r, ms(320)), e.f, -32, [0.05, 0.4]);
  },
  caption: (e, r) => {
    const [g, p] = CAPTION[actOf(e.f)] ?? [-28, 0];
    at(tame(typeset(r), 2), e.f, g, p);
  },
  press: (e, r) => {
    at(tame(dome(r)), e.f, -21, 0.35);
    at(tame(dome(r, true)), e.f + 6, -27, 0.35);
    at(tame(airPop(r), 2), e.f + 6, -25, 0.35);
  },
  unfoldRow: (e, r) => at(paperZip(r, ms(170)), e.f, -27, 0.25),
  check: (e, r) => {
    const draw = glassDraw(r, ms(200), { gentle: true });
    const touch = mul(lp(noise(ms(6), r), 2500), env(ms(6), ms(0.2), ms(1.2))); // the felt tip touches down on 672
    at(norm(mix([{ b: draw }, { b: norm(touch, 0), g: 0.35 }]), 0), e.f, -31, 0.25);
  },
  compress: (e, r) => {
    const end = till(e, next("cell", e.f, A2.compress[1]));
    at(gather(r, S(end) - S(e.f)), e.f, -29, [0.25, -0.45]);
    at(tame(lp(paperClick(r), 1200), 2), end, -31, -0.5); // the sheet lands as the first cell
  },

  // A3 · the streak
  cell: (e, r) => {
    const k = num(e, "n") / 30;
    at(tame(leaf(r, "counter", 1 + 0.35 * k), 2), e.f, -33, lerp(-0.52, 0.16, k)); // the strip extends to the right
  },
  flame: (e, r) => at(sheen(r, ms(450)), e.f, -33, 0.17),
  chip: (e, r) => (actOf(e.f) === "a6" ? at(tame(paperClick(r), 2.5), e.f, -29, -0.45 + 0.18 * num(e, "n")) : at(tame(paperClick(r), 2.5), e.f, -28, 0)),
  node: (e, r) => at(tame(woodTick(r, { bright: 0.75, body: 0.15 }), 2), e.f, -27, -0.15), // the clock's wood, one per step, under the score's climbing marimba knock
  treeCheck: (e, r) => at(hairTick(r), e.f, -22, 0.15),
  riser: (e, r) => at(airRise(r, S(till(e, A3.riser[1])) - S(e.f), 300, 2400), e.f, -34, 0),
  flower: (e, r) => {
    const n = num(e, "n");
    at(tame(paperPop(r, [1, 1.12, 1.26][n % 3]), 2), e.f, -28, [-0.2, -0.12, -0.16][n % 3]);
  },
  skyRise: (e, r) => at(easeSlide(r, S(till(e, A3.sky[1])) - S(e.f), 350, 800, 0.3), e.f, -33, 0), // the night sheet rises from the bottom edge
  rise: (e, r) => at(settleAir(r, S(till(e, A3.dotsRise[1])) - S(e.f)), e.f, -35, 0), // the two dots rise and come to rest
  star: (e, r) => {
    const n = num(e, "n"); // one per 16th: you, other × Câu hỏi, Tâm trạng, Nhắn tin (A3.stars)
    const you = (str(e, "who") || (n % 2 ? "other" : "you")) === "you";
    const f0 = [D7, D7 * 1.26, D7 * 1.498][(n >> 1) % 3]; // D F# A for your three; the other's sit a fifth below
    at(glassTick(r, you ? f0 : f0 / 1.5, 140), e.f, -33, (you ? -1 : 1) * (0.06 + 0.04 * (n >> 1))); // rose half left, lavender right
  },
  heartResolve: (e, r) => at(gather(r, S(till(e, A3.heart[1])) - S(e.f)), e.f, -31, 0),
  sweep: (e, r) => at(sheen(r, S(till(e, A3.sweep[1])) - S(e.f)), e.f, -33, [-0.12, 0.12]), // the one light sweep across the tile
  ting: (e, r) => at(ting(r), e.f, -18, 0),

  // A4 · one day
  phoneRise: (e, r) => {
    at(settleAir(r, S(till(e, A4.phone[1])) - S(e.f)), e.f, -29, -0.38);
    at(tame(thunk(r), 2), A4.phone[1], -25, -0.38);
  },
  rulerIn: (e, r) => at(cardFlutter(r, ms(700)), e.f, -22, [0.55, 0.25]),
  event: (e, r) => {
    const you = str(e, "who") === "you";
    const card = tame(paperClick(r), 2.5);
    at(you ? norm(mix([{ b: card }, { b: hp(card, 2500), g: 0.6 }]), 0) : card, e.f, -24, 0.2 + uni(r, -0.03, 0.03));
    at(leaf(r, "entry", you ? 1.3 : 1), e.f, -25, 0.2);
  },
  count: (e, r) => {
    const n = num(e, "n") % 3; // a digit lands in its box: Ảnh · Sao hôm nay · Chuỗi (colX 9 / 10 / 11 under the ruler)
    at(tame(leaf(r, "counter", [1, 1.06, 1.12][n]), 2), e.f, -34, [0.3, 0.39, 0.47][n]);
  },
  stop: (e, r) => at(stamp(r, true), e.f, -17, 0.2),
  lift: (e, r) => at(airArc(r, S(till(e, next("widget", e.f, A4.widgetMedium) - 2)) - S(e.f), 380, 1500, 0.45), e.f, -32, -0.35),
  widget: (e, r) => {
    const n = num(e, "n");
    at(tame(thunk(r, 120 - 8 * n), 2), e.f, -28, [-0.35, -0.2, -0.05][n % 3]);
    at(ping(r, [D6, D6 * 0.8409, D6 * 0.7492][n % 3]), e.f, -27 - n, [-0.35, -0.2, -0.05][n % 3]); // D6 → B5 → A5
  },
  cover: (e, r) => at(uiSlide(r, S(till(e, A4.cover[1])) - S(e.f)), e.f, -36, 0), // the navy sheet rises; the wall at 1920 cuts its stop dead
  cut: () => {}, // NOTHING: the walls in at() and the room tone's dead cut do the work

  // A5 · said up front
  fact: (e) => at(FACT, e.f, -32, 0),
  dim: (e, r) => at(exhale(r, ms(600)), e.f, -41, 0),
  headline: (e, r) => at(tame(typeset(r), 2), e.f, -29, [-0.02, -0.3, -0.13][num(e, "n") % 3]),

  // A6 · the range
  composerIn: (e, r) => at(uiSlide(r, S(till(e, A6.composer[1])) - S(e.f)), e.f, -35, 0), // felt stop when the sheet covers the frame
  send: (e, r) => at(tame(airPop(r), 2), e.f, -21, 0.3),
  typingDot: (e, r) => {
    const n = num(e, "n") % 3; // the three dots rise one after another (D6 E6 F#6), levelled to read alike
    at(tame(woodTick(r, { f0: D6 * [1, 1.122, 1.26][n], bright: 0.7, body: 0.12 }), 2), e.f, -31 + [2, 1, 0][n], -0.35);
  },
  glyph: (e, r) => {
    const n = num(e, "n") % 8;
    at(glyphSound(r, n), e.f, -26 + GLYPH_TRIM[n], [-0.44, -0.17, 0.1, 0.36][n % 4]);
  },
  chipsOut: (e, r) => at(riffle(r, S(till(e, A6.chipsOut[1])) - S(e.f), (p) => 30 + 20 * p, (p) => 1 - 0.5 * p, (p) => 1 + 0.6 * p), e.f, -27, 0), // the picks lift out of the top edge
  dotsIn: (e, r) => {
    at(leaf(r, "entry", 1.3), e.f, -27, -0.5); // the rose dot from the left edge (brighter)
    at(leaf(r, "entry", 1), e.f, -27, 0.5); // the lavender one from the right
  },
  ticker: (e, r) => at(riffle(r, S(till(e, A6.ticker[1])) - S(e.f), (p) => 14 + 50 * (1 - p) ** 2, (p) => 0.35 + 0.65 * (1 - p) ** 1.5), e.f, -22, [0.3, -0.1]), // flicks in from behind the lavender dot, then drifts
  recede: (e, r) =>
    actOf(e.f) === "a6"
      ? at(gather(r, S(till(e, A6.recede[1])) - S(e.f)), e.f, -31, 0) // everything gathers into the two dots
      : at(exhale(r, S(Math.min(till(e, A3.recede[1]), e.f + 24)) - S(e.f)), e.f, -38, 0), // A3: the night sheet drops away, a short breath down

  // A7 · the signature
  touch: (e, r) => at(tinyPop(r), e.f, -22, 0),
  heartDraw: (e, r) => at(glassDraw(r, S(till(e, A7.heart[1])) - S(e.f), { gentle: true }), e.f, -32, 0),
  heartFill: (e, r) => at(sheen(r, S(till(e, A7.tile[1])) - S(e.f)), e.f, -34, 0),
  wordmark: (e, r) => at(tame(paperSlide(r), 2), e.f, -31, [-0.05, 0.1]),
  lock: (e, r) => at(ting(r), e.f, -18, 0), // the same ting that set the heart at 1200; the score's sub boom makes it the bigger one
  line: (e, r) => at(tame(typeset(r), 2), e.f, -29, 0),
  url: (e, r) => {
    at(tame(dome(r), 2), e.f, -24, 0);
    at(settleAir(r, ms(300)), e.f, -32, 0);
  },
};
/** ids that are deliberately not foley */
const IGNORED: Record<string, string> = {
  word: "the motif note is the score's",
  night: "the sky's growth sits under the dots' rise air: no second air",
  fill: "the heart's gather is still closing over it; the sweep's sheen and the ting follow",
};

const seed = (e: Ev) => {
  let h = 2166136261;
  for (const c of `${e.id}:${e.f}:${num(e, "n", -1)}`) h = Math.imul(h ^ c.charCodeAt(0), 16777619);
  return h >>> 0;
};
const missing = new Set<string>();
for (const e of EVENTS) {
  cur = { id: e.id, f: e.f };
  if (SOLO.length && !SOLO.includes(e.id)) continue;
  if (DESIGN[e.id]) DESIGN[e.id](e, rand(seed(e)));
  else if (!IGNORED[e.id]) missing.add(e.id);
}
if (missing.size) console.warn(`⚠️  sfx: NO DESIGN for event id(s) ${[...missing].join(", ")} — silent until one is added (or listed in IGNORED)`);

// ───────────────────────────────────────── level and write
const peak = peakDb(out);
if (peak > -1) {
  const g = 10 ** ((-1.05 - peak) / 20);
  for (let i = 0; i < LEN; i++) (out.L[i] *= g), (out.R[i] *= g);
  console.warn(`sfx peak ${peak.toFixed(2)} dBFS > -1: scaled by ${(20 * Math.log10(g)).toFixed(2)} dB`);
}
enforceSilence(out);
mkdirSync("out/audio", { recursive: true });
writeWav24(SOLO.length ? "out/audio/sfx-solo.wav" : "out/audio/sfx.wav", out);

const ids = [...new Set(EVENTS.map((e) => e.id))];
const lag = new Map<string, number>();
for (const v of log) if (v.late > 1) lag.set(v.id, Math.max(lag.get(v.id) ?? 0, v.late));
const late = [...lag].map(([id, f]) => `${id} ${f.toFixed(1)}f`);
console.log(
  [
    `sfx.wav · ${EVENTS.length} events · ${log.length} voices · peak ${peakDb(out).toFixed(2)} dBFS`,
    `ids ${ids.length}: handled ${ids.filter((i) => DESIGN[i]).join(" ")}`,
    `ignored: ${ids.filter((i) => IGNORED[i]).map((i) => `${i} (${IGNORED[i]})`).join(", ") || "none"}`,
    `onset > 1 f after the start (swells into their frame, by design): ${late.join(" ") || "none"}`,
    `trimmed at a wall: ${trimmed.join(" ") || "none"}`,
  ].join("\n"),
);
