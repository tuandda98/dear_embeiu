// The film's foley kit: one sound world, close-miked, dry-ish, tactile. Each design returns a mono buffer whose
// first sample is the transient (placed exactly on the event sample). Tonal references: D (brief: glass tuned to D).
import { SR } from "../core.ts";
import { type Rand, add, bell, bp, buf, chirp, env, hp, lp, mix, modes, ms, mul, noise, norm, sat, svfBand, tone, uni } from "./synth.ts";

const D1 = 36.708, D4 = 293.665, D5 = 587.33, D6 = 1174.66;
/** wine-glass flexural mode ratios (n = 2..5) */
const GLASS = [1, 2.32, 4.25, 6.63];

// ---------------------------------------------------------------- keyboard
/**
 * Low-profile mechanical key: a thin 2 ms click, a short damped case body, a tiny bottom-out thud and a quieter
 * release tick 55–75 ms later. Every parameter is drawn from `r`, so no two keys are the same sample.
 * kind: "key" | "space" | "ai" (thin, far, very soft) | "digit" (tiny click only)
 */
export function key(r: Rand, kind: "key" | "space" | "ai" | "digit" = "key"): Float32Array {
  const space = kind === "space";
  const n = ms(space ? 130 : 110);
  const fc = uni(r, 2600, 5200);
  const click = mul(bp(noise(ms(6), r), fc, 1.2), env(ms(6), ms(0.15), ms(space ? 1.4 : 0.9)));
  const body = modes(ms(60), [uni(r, 1, 1) * (space ? uni(r, 120, 160) : uni(r, 210, 330)), space ? uni(r, 380, 470) : uni(r, 700, 980)], [ms(uni(r, 7, 13)), ms(uni(r, 3, 5))], [1, 0.35], r);
  const thud = mul(lp(noise(ms(14), r), space ? 260 : 420), env(ms(14), ms(0.4), ms(space ? 4 : 2.6)));
  const release = mul(bp(noise(ms(5), r), uni(r, 3000, 5600), 1.5), env(ms(5), ms(0.1), ms(0.7)));
  const relAt = ms(uni(r, 55, 75));
  let out: Float32Array;
  if (kind === "digit") out = mix([{ b: click, g: 0.9 }, { b: body, g: 0.12 }]);
  else if (kind === "ai") out = mix([{ b: hp(click, 1800), g: 0.7 }, { b: body, g: 0.1 }, { b: release, at: relAt, g: 0.2 }]);
  else out = mix([{ b: click, g: 1 }, { b: body, g: space ? 0.7 : 0.4 }, { b: thud, g: space ? 1.1 : 0.55 }, { b: release, at: relAt, g: 0.28 }]);
  if (space) {
    // stabiliser rattle: a second, smaller click 6 ms in
    add(out, mul(bp(noise(ms(4), r), uni(r, 3500, 5000), 1.5), env(ms(4), ms(0.1), ms(0.6))), ms(6), 0.35);
  }
  const y = buf(n);
  add(y, out, 0, 1);
  return norm(y, uni(r, -1.2, 1.2) + (space ? 0.8 : 0));
}

/** Enter: the deep "thock" (sub pulse + kick belong to the music) */
export function thock(r: Rand): Float32Array {
  const n = ms(260);
  const body = mul(tone(n, chirp(96, 58, ms(55))), env(n, ms(1.5), ms(95)));
  const knock = mul(lp(noise(ms(40), r), 420), env(ms(40), ms(0.5), ms(9)));
  const click = mul(bp(noise(ms(5), r), 2400, 1.2), env(ms(5), ms(0.15), ms(0.9)));
  const case_ = modes(ms(160), [148, 236, 410], [ms(45), ms(28), ms(14)], [1, 0.4, 0.2], r);
  return norm(sat(norm(mix([{ b: body, g: 1 }, { b: knock, g: 1.3 }, { b: click, g: 0.5 }, { b: case_, g: 0.7 }]), 0), 2.5), 0);
}

// ---------------------------------------------------------------- paper, pencil, pen
/** pencil / ruler scrape for `dur` samples: graphite grain = band noise with a seeded 60–120 Hz amplitude flutter */
export function scrape(r: Rand, dur: number, { f0 = 2400, f1 = 3300, soft = false } = {}): Float32Array {
  const n = dur + ms(25);
  const grain = svfBand(noise(n, r), (i) => f0 + (f1 - f0) * (i / dur), () => 2.2);
  const flutter = lp(noise(n, r), uni(r, 60, 120));
  const e = bell(n, ms(12), ms(25));
  const y = buf(n);
  for (let i = 0; i < n; i++) y[i] = grain[i] * e[i] * (0.65 + 0.35 * flutter[i] * 3);
  return norm(soft ? lp(y, 2200) : y, 0);
}
/** a sheet row set down: a short paper slide and a settle tap */
export function paperSlide(r: Rand): Float32Array {
  const n = ms(170);
  const slide = mul(svfBand(noise(ms(120), r), (i) => 1200 + 900 * (i / ms(120)), () => 1.1), bell(ms(120), ms(8), ms(60)));
  const settle = mul(lp(noise(ms(30), r), 500), env(ms(30), ms(0.6), ms(6)));
  return norm(mix([{ b: slide, g: 1 }, { b: settle, at: ms(95), g: 0.8 }]), 0);
}
/** soft paper click: a card set on the desk. Deterministic (seed fixed by the caller) so cards are identical */
export function paperClick(r: Rand): Float32Array {
  const n = ms(90);
  const tap = mul(lp(noise(ms(40), r), 900), env(ms(40), ms(0.5), ms(7)));
  const snap = mul(bp(noise(ms(5), r), 1900, 1.3), env(ms(5), ms(0.1), ms(0.8)));
  const paper = mul(bp(noise(n, r), 2600, 0.8), env(n, ms(2), ms(18)));
  return norm(mix([{ b: tap, g: 1 }, { b: snap, g: 0.6 }, { b: paper, g: 0.25 }]), 0);
}
/** a headline typeset in place: a letterpress thump */
export function typeset(r: Rand): Float32Array {
  const n = ms(120);
  const thump = mul(lp(noise(ms(50), r), 260), env(ms(50), ms(0.8), ms(9)));
  const ink = mul(bp(noise(n, r), 1400, 0.9), env(n, ms(1), ms(22)));
  return norm(mix([{ b: thump, g: 1 }, { b: ink, g: 0.35 }]), 0);
}
/** pen strike through "30": pressed ballpoint on paper for `dur` */
export function penStrike(r: Rand, dur: number): Float32Array {
  const n = dur + ms(30);
  const tip = mul(bp(noise(ms(6), r), 3200, 1.5), env(ms(6), ms(0.1), ms(1)));
  const stroke = svfBand(noise(n, r), (i) => 3400 + 1200 * Math.sin((Math.PI * i) / dur), () => 3);
  const press = bell(n, ms(6), ms(40));
  const y = buf(n);
  const grain = lp(noise(n, r), 180);
  for (let i = 0; i < n; i++) y[i] = stroke[i] * press[i] * (0.7 + 0.3 * grain[i] * 3) * (1 - 0.35 * (i / n));
  return norm(mix([{ b: tip, g: 0.8 }, { b: y, g: 1 }]), 0);
}
/** check stroke: a felt marker, smoother than the pencil */
export const markerStroke = (r: Rand, dur: number) => scrape(r, dur, { f0: 900, f1: 1500, soft: true });

/** rubber stamp + metal latch (latch 15 ms after the stamp). Hero at f720; reused at the stop without the latch. */
export function stamp(r: Rand, latch = true): Float32Array {
  const n = ms(420);
  const thud = mul(tone(ms(320), chirp(98, 62, ms(45))), env(ms(320), ms(1.2), ms(100)));
  const slap = mul(bp(noise(ms(24), r), 720, 1), env(ms(24), ms(0.3), ms(6)));
  const rubber = mul(lp(noise(ms(60), r), 340), env(ms(60), ms(0.6), ms(14)));
  // the rubber body is saturated for density (all its content sits below 2 kHz: no fold-over); the latch is added clean
  // mix pass: the 62–98 Hz thud set the peak but hardly any loudness; a little less thud, a little more slap, and a
  // firmer saturation keep the hit as loud at 2 dB less peak
  const y = buf(n);
  add(y, sat(norm(mix([{ b: thud, g: 0.85 }, { b: slap, g: 1.1 }, { b: rubber, g: 0.9 }]), 0), 3.2), 0, 1);
  if (latch) {
    const m1 = modes(ms(80), [2150, 3420, 5290, 7900], [ms(40), ms(28), ms(20), ms(14)], [1, 0.6, 0.35, 0.2], r);
    const c1 = mul(bp(noise(ms(2), r), 5000, 1), env(ms(2), ms(0.05), ms(0.4)));
    const m2 = modes(ms(60), [2630, 4100, 6700], [ms(22), ms(16), ms(10)], [0.7, 0.4, 0.2], r);
    add(y, mix([{ b: c1, at: ms(15), g: 0.5 }, { b: m1, at: ms(15), g: 0.45 }, { b: m2, at: ms(24), g: 0.3 }]), 0, 0.8);
  }
  return norm(y, 0);
}
/** a cyan hairline flash: one pure, tiny tick */
export function hairTick(r: Rand): Float32Array {
  const n = ms(40);
  return norm(mix([{ b: modes(n, [4200, 6900], [ms(6), ms(3)], [1, 0.3], r) }, { b: mul(bp(noise(ms(2), r), 4500, 1.5), env(ms(2), ms(0.05), ms(0.3))), g: 0.6 }]), 0);
}
/** a white pill pressed: rubber dome down; `up` = the softer release */
export function dome(r: Rand, up = false): Float32Array {
  const n = ms(70);
  const thump = mul(lp(noise(ms(30), r), up ? 700 : 380), env(ms(30), ms(0.5), ms(up ? 3 : 5)));
  const click = mul(bp(noise(ms(3), r), up ? 3000 : 2200, 1.2), env(ms(3), ms(0.1), ms(0.5)));
  const y = buf(n);
  add(y, mix([{ b: thump, g: 1 }, { b: click, g: up ? 0.5 : 0.35 }]), 0, 1);
  return norm(y, 0);
}

// ---------------------------------------------------------------- glass, pour, metal
/**
 * Glass resonance tuned to D (D5 with wine-glass partials), rubbed while the outline draws for `dur` samples,
 * then ringing out. Excitation = narrow resonators on noise (the singing rim) + the pure modes.
 */
export function glassDraw(r: Rand, dur: number, { f0 = D5, gentle = false } = {}): Float32Array {
  const n = dur + ms(gentle ? 500 : 900);
  const ex = noise(n, r);
  const y = buf(n);
  GLASS.forEach((ratio, k) => {
    const f = f0 * ratio;
    if (f > SR * 0.4) return;
    const sing = bp(bp(ex, f, 40), f, 40);
    const g = [1, 0.4, 0.18, 0.08][k];
    for (let i = 0; i < n; i++) y[i] += sing[i] * g * 6;
  });
  const draw = bell(n, ms(60), n - dur + ms(40));
  const ring = modes(n, GLASS.map((x) => f0 * x), [ms(650), ms(380), ms(200), ms(120)], [1, 0.3, 0.12, 0.05], r);
  const out = buf(n);
  for (let i = 0; i < n; i++) {
    const inDraw = i < dur ? 1 : Math.exp(-(i - dur) / ms(gentle ? 120 : 220));
    out[i] = y[i] * draw[i] * inDraw + ring[i] * (i < dur ? 0.25 * (i / dur) : 0.25 * Math.exp(-(i - dur) / ms(400)));
  }
  const hiss = mul(bp(noise(dur, r), 5200, 0.7), bell(dur, ms(30), ms(60)));
  add(out, hiss, 0, gentle ? 0.05 : 0.09);
  return norm(hp(out, 160), 0);
}
/** the glass ting on the logo lock (D6 tonic, long) + a soft D1 sub boom */
export function ting(r: Rand): Float32Array {
  const n = ms(2600);
  const glass = modes(n, GLASS.map((x) => D6 * x), [ms(750), ms(380), ms(180), ms(90)], [1, 0.32, 0.1, 0.03], r);
  const strike = mul(bp(noise(ms(3), r), 5200, 1), env(ms(3), ms(0.05), ms(0.5)));
  const boom = mul(tone(ms(1100), (i) => D1 * (1 + 0.15 * Math.exp(-i / ms(60)))), env(ms(1100), ms(12), ms(300)));
  const boom2 = mul(tone(ms(700), D1 * 2), env(ms(700), ms(10), ms(180)));
  return norm(mix([{ b: glass, g: 1 }, { b: strike, g: 0.35 }, { b: boom, g: 1.1 }, { b: boom2, g: 0.3 }]), 0);
}
/**
 * A pour step into the flask: close-miked pour noise with the glass's fill resonance at `resHz` (D-chord tones
 * rising per step), a glug at the start and bubbles quantised to 16ths (every 6000 samples, 4 per beat).
 */
export function pour(r: Rand, resHz: number, beat = 24000): Float32Array {
  const n = beat + ms(160);
  const body = svfBand(noise(n, r), (i) => 700 + 500 * Math.sin((Math.PI * i) / n), () => 0.9);
  const res = bp(bp(noise(n, r), resHz, 18), resHz, 18);
  const e = bell(n, ms(18), ms(220));
  const y = buf(n);
  const splash = lp(noise(n, r), 14);
  for (let i = 0; i < n; i++) y[i] = (body[i] * (0.8 + 0.2 * splash[i] * 4) + res[i] * 7) * e[i] * (1 - 0.45 * (i / n));
  const glug = mul(tone(ms(70), chirp(330, 150, ms(55))), env(ms(70), ms(2), ms(18)));
  const parts: { b: Float32Array; at?: number; g?: number }[] = [{ b: y, g: 1 }, { b: glug, g: 0.5 }];
  for (let k = 0; k < 4; k++) {
    const f0 = uni(r, 520, 900);
    const bub = mul(tone(ms(30), chirp(f0, f0 * uni(r, 1.6, 2.1), ms(25))), env(ms(30), ms(0.6), ms(7)));
    parts.push({ b: bub, at: k * 6000, g: uni(r, 0.28, 0.42) });
  }
  return norm(hp(mix(parts), 120), 0);
}
/** the flask lifts like a bell jar: a seal release (air), a glass release tick, the ring fading as it rises */
export function bellJarLift(r: Rand, dur: number): Float32Array {
  const n = dur + ms(300);
  const tick = modes(ms(140), GLASS.map((x) => D5 * x), [ms(70), ms(40), ms(20), ms(10)], [1, 0.3, 0.1, 0.04], r);
  const air = mul(svfBand(noise(ms(220), r), (i) => 900 - 500 * (i / ms(220)), () => 0.8), env(ms(220), ms(4), ms(45)));
  const rise = mul(svfBand(noise(n, r), (i) => 300 + 400 * (i / n), () => 1.4), bell(n, ms(80), ms(250)));
  return norm(mix([{ b: tick, g: 0.5 }, { b: air, g: 1 }, { b: rise, g: 0.35 }]), 0);
}
/** heavy metal clunk (a twisted gold object set on a ruled surface) + low boom. Hero at f1200. */
export function clunk(r: Rand, size = 1): Float32Array {
  const n = ms(1300);
  const f = 1 / size;
  const metal = modes(ms(700), [142, 237, 391, 622, 988, 1572, 2510, 3900].map((x) => x * f), [ms(360), ms(300), ms(220), ms(160), ms(100), ms(70), ms(50), ms(35)], [1, 0.8, 0.6, 0.5, 0.35, 0.25, 0.15, 0.08], r);
  const contact = mul(lp(noise(ms(12), r), 1600), env(ms(12), ms(0.2), ms(2.5)));
  const weight = mul(tone(ms(300), chirp(74 * f, 44 * f, ms(80))), env(ms(300), ms(1.5), ms(90)));
  const boom = mul(tone(n, 44 * Math.sqrt(f)), env(n, ms(14), ms(330)));
  return norm(sat(norm(mix([{ b: metal, g: 0.9 }, { b: contact, g: 0.8 }, { b: weight, g: 1 }, { b: boom, g: size >= 1 ? 1.1 : 0.4 }]), 0), size >= 1 ? 3 : 1.4), 0);
}
/** the rows swivel into bars: a bearing turn with a settle tick at the end of `dur` */
export function swivel(r: Rand, dur: number): Float32Array {
  const n = dur + ms(60);
  const turn = mul(svfBand(noise(n, r), (i) => 380 + 160 * Math.sin((Math.PI * i) / dur), () => 1.6), bell(dur, ms(40), ms(60)));
  const settle = modes(ms(50), [1800, 2900], [ms(8), ms(5)], [1, 0.4], r);
  return norm(mix([{ b: turn, g: 1 }, { b: settle, at: dur, g: 0.5 }]), 0);
}
/** the one light sweep across the gold: an airy sheen, nothing more */
export function sheen(r: Rand, dur: number): Float32Array {
  return norm(mul(svfBand(noise(dur, r), (i) => 6500 + 2500 * Math.sin((Math.PI * i) / dur), () => 2), bell(dur, dur >> 1, dur >> 1)), 0);
}

// ---------------------------------------------------------------- act 4
/** satin flowing in: a fabric slide, low and soft */
export function satinIn(r: Rand, dur: number): Float32Array {
  return norm(mul(svfBand(noise(dur, r), (i) => 260 + 300 * (i / dur), () => 0.9), bell(dur, dur >> 1, dur >> 2)), 0);
}
/** counter micro-tick: a flip-counter leaf, very small. kind "entry" = the ▲ marker dropping: lower and shorter */
export function microTick(r: Rand, kind: "counter" | "entry" = "counter"): Float32Array {
  const entry = kind === "entry";
  const n = ms(25);
  const click = mul(bp(noise(ms(2), r), entry ? uni(r, 1600, 2200) : uni(r, 2500, 3500), 1.2), env(ms(2), ms(0.05), ms(entry ? 0.25 : 0.35)));
  return norm(mix([{ b: click }, { b: modes(n, [entry ? uni(r, 880, 1050) : uni(r, 1400, 1700)], [ms(entry ? 2.5 : 4)], [0.5], r) }]), 0);
}
/** the bot is lowered onto the baseline (A3_LOWER): a low settling air that closes down into the clunk */
export function settleAir(r: Rand, dur: number): Float32Array {
  return norm(mul(svfBand(noise(dur, r), (i) => 420 - 220 * (i / dur), (i) => 0.9 + 1.5 * (i / dur)), bell(dur, ms(40), dur >> 2)), 0);
}
/** the short ping after the download press: D6 + its octave, clean and brief */
export function ping(r: Rand): Float32Array {
  const n = ms(420);
  return norm(mix([{ b: modes(n, [D6, D6 * 2, D6 * 3.01], [ms(105), ms(55), ms(25)], [1, 0.25, 0.05], r) }, { b: mul(bp(noise(ms(2), r), 4000, 1), env(ms(2), ms(0.05), ms(0.3))), g: 0.2 }]), 0);
}
/** the inputs table unfolds: a paper zip (accelerating paper ticks, rising) with a soft fold body */
export function paperZip(r: Rand, dur: number): Float32Array {
  const n = dur + ms(40);
  const y = buf(n);
  let t = 0;
  while (t < dur) {
    const p = t / dur;
    const tick = mul(bp(noise(ms(3), r), 1900 + 1800 * p + uni(r, -200, 200), 1.5), env(ms(3), ms(0.08), ms(0.5)));
    add(y, tick, t, uni(r, 0.5, 1));
    t += ms(9 - 4.5 * p + uni(r, -0.6, 0.6));
  }
  const body = mul(svfBand(noise(n, r), (i) => 600 + 500 * (i / n), () => 1), bell(n, ms(20), ms(60)));
  return norm(mix([{ b: y, g: 1 }, { b: body, g: 0.3 }]), 0);
}

// ---------------------------------------------------------------- act 5–6
/** the grid dims: a soft exhale, almost nothing */
export function exhale(r: Rand, dur: number): Float32Array {
  return norm(mul(svfBand(noise(dur, r), (i) => 500 - 250 * (i / dur), () => 0.8), bell(dur, ms(30), dur >> 1)), 0);
}
/** chat bar slides up for `dur`, felt stop at the end */
export function uiSlide(r: Rand, dur: number): Float32Array {
  const n = dur + ms(60);
  const slide = mul(svfBand(noise(dur, r), (i) => 900 + 700 * (i / dur), () => 1.2), bell(dur, ms(10), ms(40)));
  const stop = mul(lp(noise(ms(40), r), 420), env(ms(40), ms(0.5), ms(7)));
  return norm(mix([{ b: slide, g: 0.8 }, { b: stop, at: dur, g: 1 }]), 0);
}
/** send: a short air-pop (resonant impulse with a pitch drop, plus a breath) */
export function airPop(r: Rand): Float32Array {
  const n = ms(120);
  const pop = mul(tone(ms(45), chirp(640, 180, ms(35))), env(ms(45), ms(0.3), ms(9)));
  const breath = mul(bp(noise(ms(90), r), 1400, 0.6), env(ms(90), ms(1.5), ms(22)));
  const tick = mul(bp(noise(ms(2), r), 3200, 1.2), env(ms(2), ms(0.05), ms(0.35)));
  const y = buf(n);
  add(y, mix([{ b: pop, g: 1 }, { b: breath, g: 0.5 }, { b: tick, g: 0.4 }]), 0, 1);
  return norm(y, 0);
}
/** ticker: a dry card-shuffle flutter (riffle rate rises then falls), not a whoosh */
export function cardFlutter(r: Rand, dur: number): Float32Array {
  const n = dur + ms(30);
  const y = buf(n);
  let t = 0;
  while (t < dur) {
    const p = t / dur;
    const rate = 16 + 44 * Math.sin(Math.PI * p) ** 0.8; // ticks per second
    const tick = mul(bp(noise(ms(4), r), uni(r, 1500, 3400), 1.3), env(ms(4), ms(0.08), ms(0.7)));
    add(y, tick, t, uni(r, 0.4, 1) * (0.6 + 0.4 * Math.sin(Math.PI * p)));
    t += Math.round((SR / rate) * uni(r, 0.85, 1.15));
  }
  const body = mul(lp(noise(n, r), 700), bell(n, ms(60), ms(200)));
  return norm(mix([{ b: y, g: 1 }, { b: body, g: 0.12 }]), 0);
}
/** everything recedes into the caret: a low paper gather closing down */
export function gather(r: Rand, dur: number): Float32Array {
  return norm(mul(svfBand(noise(dur, r), (i) => 800 - 500 * (i / dur), (i) => 1 + 2 * (i / dur)), bell(dur, ms(30), dur >> 1)), 0);
}

// ---------------------------------------------------------------- the glyph kit (small objects on a wood desk)
const woodTick = (r: Rand, f = 1) => modes(ms(70), [1150 * f, 2870 * f, 4900 * f].map((x) => x * uni(r, 0.97, 1.03)), [ms(22), ms(11), ms(6)], [1, 0.45, 0.2], r);
const woodBlock = (r: Rand, f = 1) => modes(ms(110), [620 * f, 1480 * f, 2900 * f].map((x) => x * uni(r, 0.98, 1.02)), [ms(38), ms(18), ms(9)], [1, 0.5, 0.2], r);
const glassTick = (r: Rand, f = 1) => modes(ms(220), GLASS.map((x) => 2350 * f * x), [ms(110), ms(55), ms(22), ms(10)], [1, 0.3, 0.1, 0.03], r);
const metalTick = (r: Rand, f = 1) => modes(ms(80), [3100 * f, 5100 * f, 7700 * f, 11200 * f], [ms(26), ms(22), ms(16), ms(10)], [1, 0.6, 0.35, 0.15], r);
const clickN = (r: Rand, fc: number) => mul(bp(noise(ms(2), r), fc, 1.2), env(ms(2), ms(0.05), ms(0.3)));
const paperSnap = (r: Rand) => mix([{ b: mul(bp(noise(ms(10), r), 2600, 0.8), env(ms(10), ms(0.1), ms(1.4))) }, { b: clickN(r, 3800), at: ms(3), g: 0.5 }, { b: clickN(r, 4600), at: ms(7), g: 0.3 }]);
const paperSet = (r: Rand) => mul(lp(noise(ms(60), r), 650), env(ms(60), ms(0.8), ms(10)));
function rubber(r: Rand): Float32Array {
  const st = ms(120);
  const creak = lp(noise(st, r), 1);
  const stretch = svfBand(noise(st, r), (i) => 300 + 600 * (i / st), () => 4);
  const y = buf(st);
  for (let i = 0; i < st; i++) y[i] = stretch[i] * (0.5 + 0.5 * Math.abs(Math.sin(2 * Math.PI * i * (40 + 60 * (i / st)) / SR))) * (0.3 + 0.7 * (i / st)) * (1 + creak[i]);
  const snap = mix([{ b: mul(tone(ms(30), chirp(220, 90, ms(20))), env(ms(30), ms(0.3), ms(6))) }, { b: clickN(r, 2200), g: 0.6 }]);
  return mix([{ b: y, g: 0.8 }, { b: snap, at: st, g: 1 }]);
}
/** glyph n (0..7) -> its micro-sound. One kit, eight gestures that mirror the drawings. */
export function glyph(r: Rand, n: number): Float32Array {
  const P = (b: Float32Array, at = 0, g = 1) => ({ b, at, g });
  let parts: { b: Float32Array; at?: number; g?: number }[];
  switch (n) {
    case 0: parts = [P(woodTick(r, 1), 0, 1), P(clickN(r, 3000), 0, 0.5), P(woodTick(r, 0.84), ms(70), 0.9), P(clickN(r, 2600), ms(70), 0.4)]; break; // two EMAs cross
    case 1: parts = [P(woodTick(r, 0.7), 0, 0.5), P(paperSnap(r), ms(55), 1)]; break; // price escapes the box
    case 2: parts = [P(metalTick(r, 1), 0, 0.8), P(metalTick(r, 1.19), ms(35), 0.7), P(metalTick(r, 0.94), ms(70), 0.75)]; break; // micro zig-zag
    case 3: parts = [P(rubber(r), 0, 1)]; break; // stretch past the band, snap back
    case 4: parts = [P(woodBlock(r, 1.12), 0, 0.8), P(woodBlock(r, 1), ms(45), 0.85), P(woodBlock(r, 0.89), ms(90), 0.9), P(metalTick(r, 0.8), ms(150), 0.6), P(clickN(r, 2400), ms(150), 0.4)]; break; // stacked steps under a hard cap
    case 5: parts = [P(paperSet(r), 0, 1), P(clickN(r, 1800), 0, 0.3), P(scrape(r, ms(60), { f0: 2600, f1: 3100 }), ms(60), 0.35)]; break; // order block + BOS line
    case 6: parts = [P(glassTick(r, 1), 0, 0.8), P(glassTick(r, 1.06), ms(30), 0.7), P(glassTick(r, 1.12), ms(60), 0.65), P(clickN(r, 5000), 0, 0.25)]; break; // three parallel lines
    default: parts = [P(metalTick(r, 1.05), 0, 0.6), P(metalTick(r, 0.95), ms(40), 0.6), P(woodBlock(r, 1.3), ms(80), 0.9), P(clickN(r, 2800), ms(80), 0.5)]; // two arrows lock
  }
  return norm(mix(parts), 0);
}

// ---------------------------------------------------------------- textures (generated over long spans)
/** room tone: decorrelated per channel by seed. Returns length n, RMS ≈ 1 before gain. */
export function roomTone(r: Rand, n: number): Float32Array {
  const low = lp(lp(noise(n, r), 380), 380);
  const hiss = hp(lp(noise(n, r), 9000), 3000);
  const y = buf(n);
  const breathe = lp(noise(n, r), 0.3);
  let s = 0;
  for (let i = 0; i < n; i++) {
    y[i] = low[i] * (1 + 0.5 * breathe[i] * 30) + hiss[i] * 0.045;
    s += y[i] * y[i];
  }
  const rms = Math.sqrt(s / n) || 1;
  return mul(y, 1 / rms);
}
