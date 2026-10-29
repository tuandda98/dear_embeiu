// audio/vertical/sfx.ts — the SFX of the 9:16 cut (composition "Vertical", 1200 f at 60 fps; VERTICAL.md). The film's
// sound world (close, dry, tactile, quiet; phone-speaker friendly) placed frame-exact on V12_EVENTS + V34_EVENTS. The
// per-id designs are COPIED from audio/sfx/build.ts (the delivered film stays bit-identical: nothing there is touched);
// the kit is imported. verticalSfx() → Stereo of 1200 × SPF samples: VSILENCE (600–615, 1190–1200) digital zero, a
// dead wall at 600 (nothing rings past it), room tone under everything but the silences. Pans are narrow: the frame is
// a phone held upright.
import { SPF, smp, stereo, peakDb, type Stereo } from "../core.ts";
import { V12_EVENTS, type VEvent } from "../../src/vertical/v12/events.ts";
import { V34_EVENTS } from "../../src/vertical/v34/events.ts";
import { HOOK, TYPED, V } from "../../src/vertical/v12/timing.ts";
import { V34_CUES as Q } from "../../src/vertical/v34/cues.ts";
import { VERT, VSILENCE } from "../../src/vertical/timeline.ts";
import { A2 } from "../../src/timeline/cues.ts";
import { type Rand, rand, bp, buf, chirp, db, env, hp, lp, mix, modes, ms, mul, noise, norm, sat, svfBand, tone, uni } from "../sfx/synth.ts";
import { key, thock, paperSlide, paperClick, typeset, dome, glassDraw, settleAir, paperZip, exhale, uiSlide, airPop, gather, sheen, roomTone } from "../sfx/kit.ts";

const VLEN = VERT.total * SPF;
const S = (f: number) => smp(f);
/** the film's level knob (audio/sfx/build.ts), kept so the cut sounds like the film */
const LIFT = 11;
const tame = (x: Float32Array, drive = 3) => norm(sat(norm(x, 0), drive), 0);
const D5 = 587.33, D6 = 1174.66;
const GLASS = [1, 2.32, 4.25, 6.63];
const AIR_MAX = 48; // frames: the longest noise voice (0.8 s)
const SIL = VSILENCE.map(([a, b]) => [S(a), S(b)] as const);
const WALLS = SIL.map(([a]) => a); // smp(600), smp(1190)

// ───────────────────────────────────────── designs copied from audio/sfx/build.ts (same names, same numbers)
function woodTick(r: Rand, { f0 = D5, bright = 1, body = 0.1 } = {}): Float32Array {
  const knock = mul(bp(noise(ms(16), r), 1400 * bright, 0.7), env(ms(16), ms(0.3), ms(3.5)));
  const low = mul(lp(noise(ms(14), r), 700), env(ms(14), ms(0.4), ms(3.2)));
  const tip = mul(bp(noise(ms(3), r), 3400 * bright, 1.4), env(ms(3), ms(0.06), ms(0.4)));
  const bar = modes(ms(60), [f0, f0 * 2.756, f0 * 5.404].map((x) => x * uni(r, 0.995, 1.005)), [ms(8), ms(3.2), ms(1.3)], [1, 0.45, 0.18], r);
  const box = modes(ms(40), [f0 / 2], [ms(4.4)], [1], r);
  return norm(lp(hp(mix([{ b: knock }, { b: low, g: 0.5 }, { b: tip, g: 0.35 }, { b: bar, g: body }, { b: box, g: body * 0.6 }]), 140), 6000 * bright), 0);
}
function leaf(r: Rand, kind: "counter" | "entry", p = 1): Float32Array {
  const e = kind === "entry";
  const click = mul(bp(noise(ms(2), r), (e ? uni(r, 1600, 2200) : uni(r, 2600, 3200)) * p, 1.2), env(ms(2), ms(0.05), ms(e ? 0.25 : 0.35)));
  return norm(mix([{ b: click }, { b: modes(ms(25), [(e ? uni(r, 880, 1050) : 1480) * p], [ms(e ? 2.5 : 4)], [0.5], r) }]), 0);
}
/** the film's ting (no sub boom: that is the score's). The cut ends 170 f after the lock, so the ring is 2.8 s long and
 *  fades over its last 1.0 s: it is gone by 1188, before the closing silence (the film's is 3.2 s with a 0.7 s fade) */
function ting(r: Rand, len = 2800, fade = 1000): Float32Array {
  const n = ms(len);
  const y = mix([{ b: modes(n, GLASS.map((x) => D6 * x), [ms(750), ms(380), ms(180), ms(90)], [1, 0.32, 0.1, 0.03], r) }, { b: mul(bp(noise(ms(3), r), 5200, 1), env(ms(3), ms(0.05), ms(0.5))), g: 0.35 }]);
  const d = ms(fade);
  for (let i = 0; i < d; i++) y[n - 1 - i] *= 0.5 - 0.5 * Math.cos((Math.PI * i) / d);
  return norm(y, 0);
}
function thunk(r: Rand, f0 = 120): Float32Array {
  const body = mul(tone(ms(120), chirp(f0 * 1.4, f0, ms(25))), env(ms(120), ms(1), ms(28)));
  const felt = mul(lp(noise(ms(40), r), 520), env(ms(40), ms(0.5), ms(6)));
  const tick = mul(bp(noise(ms(3), r), 2100, 1.2), env(ms(3), ms(0.08), ms(0.5)));
  return norm(mix([{ b: body, g: 0.8 }, { b: felt }, { b: tick, g: 0.25 }]), 0);
}
function tinyPop(r: Rand): Float32Array {
  const pop = mul(tone(ms(30), chirp(900, 380, ms(22))), env(ms(30), ms(0.3), ms(5)));
  return norm(mix([{ b: pop }, { b: mul(bp(noise(ms(50), r), 1800, 0.7), env(ms(50), ms(1), ms(10))), g: 0.35 }]), 0);
}
function airRise(r: Rand, dur: number, f0: number, f1: number, taper = 6): Float32Array {
  const y = svfBand(noise(dur, r), (i) => f0 * (f1 / f0) ** (i / dur), (i) => 0.8 + 1.6 * (i / dur));
  const e = buf(dur);
  for (let i = 0; i < dur; i++) e[i] = (i / dur) ** 2.2 * (1 - Math.exp(-(dur - i) / ms(taper)));
  return norm(mul(y, e), 0);
}
function airArc(r: Rand, dur: number, f0: number, f1: number, peakAt = 0.4): Float32Array {
  const y = svfBand(noise(dur, r), (i) => f0 * (f1 / f0) ** (i / dur), () => 1.1);
  const a = Math.max(1, Math.round(dur * peakAt));
  const e = Float32Array.from({ length: dur }, (_, i) => (i < a ? 0.5 - 0.5 * Math.cos((Math.PI * i) / a) : 0.5 + 0.5 * Math.cos((Math.PI * (i - a)) / (dur - a))));
  return norm(mul(y, e), 0);
}
function easeSlide(r: Rand, dur: number, f0: number, f1: number, stop = 0.25): Float32Array {
  const fr = svfBand(noise(dur, r), (i) => f0 + (f1 - f0) * (i / dur), () => 1.2);
  const e = Float32Array.from({ length: dur }, (_, i) => Math.min(1, i / ms(8)) * (1 - i / dur) ** 2);
  const felt = mul(lp(noise(ms(40), r), 420), env(ms(40), ms(0.5), ms(7)));
  return norm(mix([{ b: mul(fr, e) }, { b: felt, at: dur, g: stop }]), 0);
}

// ───────────────────────────────────────── the events
const EVENTS = [...V12_EVENTS, ...V34_EVENTS].filter((e) => Number.isFinite(e.f)).sort((a, b) => a.f - b.f);
const num = (e: VEvent, k: string, d = 0) => (typeof e.data?.[k] === "number" ? (e.data[k] as number) : d);
const next = (id: string, f: number, d: number) => EVENTS.find((x) => x.id === id && x.f > f)?.f ?? d;
/** where a span sound ends: the event's own `to`, else the cue's end, kept within 6–180 f */
const till = (e: VEvent, end: number) => Math.max(e.f + 6, Math.min(num(e, "to", end), e.f + 180));
const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
const along = (frames: number[], f: number) => Math.max(0, frames.indexOf(f)) / Math.max(1, frames.length - 1);

/** ids that are deliberately silent */
export const VERTICAL_SILENT: Record<string, string> = { word: "the motif note is the score's (as in the film)" };

/**
 * The cut's SFX stem. `solo` (calibration only) renders just those ids, without room tone.
 */
export function verticalSfx(solo: string[] = []): Stereo {
  const out = stereo(VLEN);
  let cur = { id: "", f: 0 };
  let voices = 0;
  const at = (x: Float32Array, f: number, gdb: number, pan: number | [number, number] = 0) => {
    const s = S(f);
    if (SIL.some(([a, b]) => s >= a && s < b)) throw new Error(`vertical sfx ${cur.id}@${cur.f}: a voice placed inside a silence`);
    const wall = WALLS.find((w) => s < w) ?? VLEN;
    let y = x;
    if (s + y.length > wall) {
      y = x.slice(0, Math.max(0, wall - s));
      const d = Math.min(ms(3), y.length);
      for (let i = 0; i < d; i++) y[y.length - 1 - i] *= i / d;
    }
    const [p0, p1] = typeof pan === "number" ? [pan, pan] : pan;
    const g = db(gdb + LIFT);
    for (let i = Math.max(0, -s); i < y.length && s + i < VLEN; i++) {
      const a = ((Math.max(-1, Math.min(1, p0 + (p1 - p0) * (i / y.length))) + 1) * Math.PI) / 4;
      out.L[s + i] += y[i] * Math.cos(a) * g;
      out.R[s + i] += y[i] * Math.sin(a) * g;
    }
    voices++;
  };

  // room tone: −50 dBFS under V1–V2, a dead cut on 600 (3 ms declick), back faint (−53) after the silence, up to −50
  // with the light sheet, faded out by 1190
  if (!solo.length) {
    const [l, r] = [roomTone(rand(7), VLEN), roomTone(rand(8), VLEN)];
    const ramp = (i: number, a: number, n: number) => Math.min(1, Math.max(0, (i - a) / n));
    const cos = (x: number) => 0.5 - 0.5 * Math.cos(Math.PI * x);
    const [cut, back] = SIL[0];
    const end = SIL[1][0];
    for (let i = 0; i < VLEN; i++) {
      let g: number;
      if (i < cut) g = db(-50) * ramp(i, 0, ms(10)) * (1 - ramp(i, cut - ms(3), ms(3)));
      else if (i < back) g = 0;
      else g = db(-53 + 3 * cos(ramp(i, S(Q.sheet[0]), S(30)))) * cos(ramp(i, back, S(15))) * (1 - cos(ramp(i, end - S(48), S(48))));
      out.L[i] += l[i] * g;
      out.R[i] += r[i] * g;
    }
  }

  const DESIGN: Record<string, (e: VEvent, r: Rand) => void> = {
    // ── V1 · the hook
    tick: (e, r) => (e.f < V.land ? at(tame(woodTick(r), 2), e.f, -24, -0.06) : at(tame(woodTick(r), 2), e.f, -32, -0.18)), // after the landing the counter sits small, top left
    key: (e, r) => {
      if (num(e, "n") === 1) {
        const k = TYPED.frames.indexOf(e.f); // your answer, ~44 letters/s: tiny clicks, spaces softer (as the film)
        return at(tame(key(r, "digit")), e.f, TYPED.text[k] === " " ? -36 : -33, lerp(-0.2, 0.15, along(TYPED.frames, e.f)));
      }
      at(tame(key(r, "digit")), e.f, -32, lerp(-0.2, 0.15, along(HOOK.frames, e.f))); // the hook, two lines at x 80
    },
    drop: (e, r) => at(airRise(r, S(till(e, next("land", e.f, V.land))) - S(e.f), 500, 2600), e.f, -30, 0.15), // swells into the landing
    land: (e, r) => at(tame(thock(r), 2.2), e.f, -17, 0.15),

    // ── V2 · the question, the hero
    swoop: (e, r) => at(airArc(r, S(till(e, V.swoop[1])) - S(e.f), 700, 1500, 0.5), e.f, -33, [0.15, -0.18]), // into the notification's avatar
    unfold: (e, r) => at(easeSlide(r, S(till(e, V.card[1])) - S(e.f), 700, 1500), e.f, -31, [-0.18, 0]),
    phoneRise: (e, r) => {
      const end = till(e, V.phone[1]); // the Home phone rises from the bottom, centred…
      at(settleAir(r, S(Math.min(end, e.f + AIR_MAX)) - S(e.f)), e.f, -32, 0);
      at(tame(thunk(r), 2), end, -27, 0); // …and settles
    },
    scroll: (e, r) => at(easeSlide(r, S(till(e, V.scroll[1])) - S(e.f), 1400, 2400, 0.12), e.f, -36, 0),
    leave: (e, r) => at(airRise(r, S(till(e, V.leave[1])) - S(e.f), 900, 1900, 15), e.f, -34, [0, -0.25]), // the notification slides out, left
    lift: (e, r) => {
      const end = till(e, V.lift[1]); // the question card lifts out of the phone into the upper half…
      at(airArc(r, S(end) - S(e.f), 380, 1300, 0.45), e.f, -32, 0);
      at(tame(lp(paperClick(r), 1600), 2), end, -29, 0); // …and settles
    },
    sink: (e, r) => {
      const end = till(e, V.sink[1]); // the phone sinks to the bottom edge (it overlaps the lift: kept under it)…
      at(settleAir(r, S(Math.min(end, e.f + AIR_MAX)) - S(e.f)), e.f, -36, 0);
      at(tame(thunk(r, 105), 2), end, -31, 0); // …and rests there
    },
    sendIn: (e, r) => at(tame(dome(r, true), 2), e.f, -27, 0.15), // the Gửi pill unfolds beside your answer
    press: (e, r) => {
      at(tame(dome(r)), e.f, -24, 0.15); // smaller than the unlock it leads into
      at(tame(dome(r, true)), e.f + 6, -30, 0.15);
      at(tame(airPop(r), 2), e.f + 6, -28, 0.15); // your answer leaves
    },
    // UNLOCK, the hero beat: the film's design and levels (−1.5 dB against the music's arrival): the mask lifts like
    // tissue, both edges glow once (glass breathing in D5), a low breath. Intimate, not a win. It runs on the film's own
    // seed, so it IS the film's hero voice for voice: the glass draw is narrow-band noise normalised to its peak, and
    // another seed read 2.4 dB hotter at the same gains (measured).
    unlock: (e) => {
      const r = rand(seed({ id: "unlock", f: A2.unlock }));
      at(easeSlide(r, ms(300), 1100, 2300, 0), e.f, -24.5, [-0.2, 0.15]);
      at(glassDraw(r, ms(140), { gentle: true }), e.f, -19.5, 0);
      at(exhale(r, ms(520)), e.f, -27.5, 0);
    },
    caption: (e, r) => at(tame(typeset(r), 2), e.f, -28, -0.09), // "Cần cả hai." 96 px under the cards
    unfoldRow: (e, r) => at(paperZip(r, ms(170)), e.f, -27, 0), // the phone's card opens both answers too

    // ── V3 · said up front: five lines typeset in place, the dots glide in after "Chỉ hai người."
    headline: (e, r) => at(tame(typeset(r), 2), e.f, -26, [0, 0, -0.05, -0.1, 0][num(e, "n") % 5]),
    dotsIn: (e, r) => {
      const end = till(e, Q.dots[1]);
      at(airArc(r, S(end) - S(e.f), 900, 1500, 0.35), e.f, -37, [-0.25, 0.13]); // rose from the left edge…
      at(airArc(r, S(end) - S(e.f), 820, 1400, 0.35), e.f, -37, [0.25, 0.15]); // …lavender from the right
      at(leaf(r, "entry", 1.3), end, -29, 0.13); // and they rest (rose brighter)
      at(leaf(r, "entry", 1), end, -29, 0.15);
    },

    // ── V4 · sign-off
    composerIn: (e, r) => at(uiSlide(r, S(till(e, Q.sheet[1])) - S(e.f)), e.f, -35, 0), // the light sheet rises; felt stop as it covers the navy
    recede: (e, r) => at(gather(r, S(Math.min(till(e, Q.travel[1]), e.f + AIR_MAX)) - S(e.f)), e.f, -33, 0), // the dots travel to the centre
    touch: (e, r) => at(tinyPop(r), e.f, -22, 0),
    heartDraw: (e, r) => at(glassDraw(r, S(till(e, Q.heart[1])) - S(e.f), { gentle: true }), e.f, -32, 0),
    heartFill: (e, r) => at(sheen(r, S(till(e, Q.tile[1])) - S(e.f)), e.f, -34, 0),
    wordmark: (e, r) => at(tame(paperSlide(r), 2), e.f, -31, [-0.03, 0.05]),
    lock: (e, r) => at(ting(r), e.f, -20, 0), // the score adds the sub boom; −2 dB (integration): it peaked V4 at −7.5 LUFS momentary
    line: (e, r) => at(tame(typeset(r), 2), e.f, -29, 0),
    url: (e, r) => {
      at(tame(dome(r), 2), e.f, -24, 0);
      at(settleAir(r, ms(300)), e.f, -32, 0);
    },
  };

  const seed = (e: VEvent) => {
    let h = 2166136261;
    for (const c of `${e.id}:${e.f}:${num(e, "n", -1)}`) h = Math.imul(h ^ c.charCodeAt(0), 16777619);
    return h >>> 0;
  };
  const missing = new Set<string>();
  for (const e of EVENTS) {
    cur = { id: e.id, f: e.f };
    if (solo.length && !solo.includes(e.id)) continue;
    if (DESIGN[e.id]) DESIGN[e.id](e, rand(seed(e)));
    else if (!VERTICAL_SILENT[e.id]) missing.add(e.id);
  }
  if (missing.size) console.warn(`⚠️  vertical sfx: NO DESIGN for event id(s) ${[...missing].join(", ")} — silent until one is added`);

  const peak = peakDb(out);
  if (peak > -1) {
    const g = 10 ** ((-1.05 - peak) / 20);
    for (let i = 0; i < VLEN; i++) (out.L[i] *= g), (out.R[i] *= g);
  }
  for (const [a, b] of SIL) out.L.fill(0, a, b), out.R.fill(0, a, b); // digital zero, last
  if (!solo.length)
    console.log(`vertical sfx · ${EVENTS.length} events · ${voices} voices · peak ${peakDb(out).toFixed(2)} dBFS · silent: ${Object.entries(VERTICAL_SILENT).map(([k, v]) => `${k} (${v})`).join(", ")}`);
  return out;
}
