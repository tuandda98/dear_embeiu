// audio/music/dsp.ts — dependency-free DSP for the score. Node 25, plain TS, deterministic (seeded noise only).
import { SR, type Stereo } from "../core.ts";
import { rng } from "../../src/lib/rand.ts";

export const TAU = 2 * Math.PI;
export const hz = (midi: number) => 440 * 2 ** ((midi - 69) / 12);
export const db = (d: number) => 10 ** (d / 20);
export const ms = (m: number) => Math.round((m * SR) / 1000);
export const sec = (s: number) => Math.round(s * SR);
export const cents = (c: number) => 2 ** (c / 1200);
export const clamp = (x: number, a: number, b: number) => (x < a ? a : x > b ? b : x);
export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

const NAMES: Record<string, number> = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
/** "D4" → 62 · "F#4" → 66 · "Bb2" → 46 (C4 = 60, D1 = 26 = 36.7 Hz) */
export function n(name: string): number {
  const m = /^([A-G])([#b]?)(-?\d)$/.exec(name);
  if (!m) throw new Error(`bad note ${name}`);
  return 12 * (Number(m[3]) + 1) + NAMES[m[1]] + (m[2] === "#" ? 1 : m[2] === "b" ? -1 : 0);
}
export const notes = (...names: string[]) => names.map(n);

export function noise(len: number, seed: number): Float32Array {
  const r = rng(seed);
  const o = new Float32Array(len);
  for (let i = 0; i < len; i++) o[i] = r() * 2 - 1;
  return o;
}

/** linear fade-in over `atk` samples and fade-out over the last `rel` samples, in place (every voice: no clicks) */
export function fadeEdges(x: Float32Array, atk: number, rel: number): Float32Array {
  const nn = x.length;
  for (let i = 0; i < atk && i < nn; i++) x[i] *= i / atk;
  for (let i = 0; i < rel && i < nn; i++) x[nn - 1 - i] *= i / rel;
  return x;
}
export function peak(x: Float32Array): number {
  let p = 0;
  for (let i = 0; i < x.length; i++) {
    const a = Math.abs(x[i]);
    if (a > p) p = a;
  }
  return p;
}
export function scaleTo(x: Float32Array, p: number): Float32Array {
  const q = peak(x);
  if (q > 0) for (let i = 0, g = p / q; i < x.length; i++) x[i] *= g;
  return x;
}
export function gain(x: Float32Array, g: number): Float32Array {
  for (let i = 0; i < x.length; i++) x[i] *= g;
  return x;
}
export function add(dst: Float32Array, src: Float32Array, g = 1, at = 0) {
  const end = Math.min(src.length, dst.length - at);
  for (let i = Math.max(0, -at); i < end; i++) dst[at + i] += src[i] * g;
}
/** per-sample multiplier of an exponential decay that reaches −60 dB after t60 seconds */
export const decayMul = (t60: number) => Math.exp(-6.9078 / (t60 * SR));
/** cosine ramp 0 → 1 over len samples */
export const smooth = (i: number, len: number) => (i <= 0 ? 0 : i >= len ? 1 : 0.5 - 0.5 * Math.cos((Math.PI * i) / len));

export function sine(len: number, freq: number | ((i: number) => number), phase = 0): Float32Array {
  const o = new Float32Array(len);
  let ph = phase;
  if (typeof freq === "number") {
    const w = (TAU * freq) / SR;
    for (let i = 0; i < len; i++) {
      o[i] = Math.sin(ph);
      ph += w;
      if (ph > TAU) ph -= TAU;
    }
  } else {
    for (let i = 0; i < len; i++) {
      o[i] = Math.sin(ph);
      ph += (TAU * freq(i)) / SR;
      if (ph > TAU) ph -= TAU;
    }
  }
  return o;
}
function polyblep(t: number, dt: number) {
  if (t < dt) {
    t /= dt;
    return t + t - t * t - 1;
  }
  if (t > 1 - dt) {
    t = (t - 1) / dt;
    return t * t + t + t + 1;
  }
  return 0;
}
/** band-limited (PolyBLEP) sawtooth */
export function sawBL(len: number, freq: number, phase = 0): Float32Array {
  const o = new Float32Array(len);
  const dt = freq / SR;
  let t = phase % 1;
  for (let i = 0; i < len; i++) {
    o[i] = 2 * t - 1 - polyblep(t, dt);
    t += dt;
    if (t >= 1) t -= 1;
  }
  return o;
}
/** band-limited (PolyBLEP) pulse */
export function squareBL(len: number, freq: number, pw = 0.5, phase = 0): Float32Array {
  const o = new Float32Array(len);
  const dt = freq / SR;
  let t = phase % 1;
  for (let i = 0; i < len; i++) {
    let v = t < pw ? 1 : -1;
    v += polyblep(t, dt);
    v -= polyblep((t + 1 - pw) % 1, dt);
    o[i] = v;
    t += dt;
    if (t >= 1) t -= 1;
  }
  return o;
}
/** band-limited triangle (additive, odd harmonics 1/k²) */
export function triAdd(len: number, freq: number, phase = 0): Float32Array {
  const o = new Float32Array(len);
  const nyq = SR * 0.45;
  for (let k = 1, s = 1; k * freq < nyq && k <= 23; k += 2, s = -s) {
    const w = (TAU * k * freq) / SR;
    const a = (s * 8) / (Math.PI * Math.PI * k * k);
    let ph = phase * k;
    for (let i = 0; i < len; i++) {
      o[i] += a * Math.sin(ph);
      ph += w;
      if (ph > TAU) ph -= TAU;
    }
  }
  return o;
}

/** TPT state-variable filter (Zavalishin); cutoff may be a per-sample function (updated every 16 samples) */
export function svf(x: Float32Array, cutoff: number | ((i: number) => number), res = 0, mode: "lp" | "bp" | "hp" = "lp"): Float32Array {
  const o = new Float32Array(x.length);
  let ic1 = 0;
  let ic2 = 0;
  const k = 2 - 1.9 * clamp(res, 0, 1);
  let a1 = 0;
  let a2 = 0;
  let a3 = 0;
  const set = (fc: number) => {
    const g = Math.tan((Math.PI * clamp(fc, 10, 20000)) / SR);
    a1 = 1 / (1 + g * (g + k));
    a2 = g * a1;
    a3 = g * a2;
  };
  const fn = typeof cutoff === "function" ? cutoff : null;
  if (!fn) set(cutoff as number);
  for (let i = 0; i < x.length; i++) {
    if (fn && (i & 15) === 0) set(fn(i));
    const v0 = x[i];
    const v3 = v0 - ic2;
    const v1 = a1 * ic1 + a2 * v3;
    const v2 = ic2 + a2 * ic1 + a3 * v3;
    ic1 = 2 * v1 - ic1;
    ic2 = 2 * v2 - ic2;
    o[i] = mode === "lp" ? v2 : mode === "bp" ? v1 : v0 - k * v1 - v2;
  }
  return o;
}
export function onepole(x: Float32Array, fc: number | ((i: number) => number), mode: "lp" | "hp" = "lp"): Float32Array {
  const o = new Float32Array(x.length);
  let y = 0;
  let a = typeof fc === "number" ? 1 - Math.exp((-TAU * fc) / SR) : 0;
  for (let i = 0; i < x.length; i++) {
    if (typeof fc === "function") a = 1 - Math.exp((-TAU * clamp(fc(i), 1, 20000)) / SR);
    y += a * (x[i] - y);
    o[i] = mode === "lp" ? y : x[i] - y;
  }
  return o;
}
/** removes DC (≈ 10 Hz corner), in place */
export function dcBlock(x: Float32Array): Float32Array {
  const R = 1 - (TAU * 10) / SR;
  let xm = 0;
  let ym = 0;
  for (let i = 0; i < x.length; i++) {
    const y = x[i] - xm + R * ym;
    xm = x[i];
    ym = y;
    x[i] = y;
  }
  return x;
}
/** soft saturation, unity at small signals, in place */
export function sat(x: Float32Array, drive: number): Float32Array {
  const k = 1 / Math.tanh(drive);
  for (let i = 0; i < x.length; i++) x[i] = Math.tanh(x[i] * drive) * k;
  return x;
}

/**
 * Stereo Schroeder/Freeverb reverb on a send bus. Each segment is processed with fresh state, so nothing can ring
 * across a boundary (the hard cut at 32.0): the tail of segment k never reaches segment k+1.
 */
export function reverb(send: Stereo, segments: Array<[number, number]>, o: { room?: number; damp?: number; predelay?: number; lp?: number; hp?: number } = {}): Stereo {
  const { room = 0.83, damp = 0.32, predelay = ms(14), lp = 6000, hp = 170 } = o;
  const scale = SR / 44100;
  const COMB = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617].map((d) => Math.round(d * scale));
  const AP = [556, 441, 341, 225].map((d) => Math.round(d * scale));
  const spread = Math.round(23 * scale);
  const out = { L: new Float32Array(send.L.length), R: new Float32Array(send.R.length) };
  for (const [ch, src, dst] of [
    [0, send.L, out.L],
    [1, send.R, out.R],
  ] as const) {
    for (const [a, b] of segments) {
      const combs = COMB.map((d) => ({ buf: new Float32Array(d + ch * spread), i: 0, fs: 0 }));
      const aps = AP.map((d) => ({ buf: new Float32Array(d + ch * spread), i: 0 }));
      const wet = new Float32Array(b - a);
      for (let i = a; i < b; i++) {
        const j = i - predelay;
        const inp = j >= a ? src[j] : 0;
        let sum = 0;
        for (const c of combs) {
          const y = c.buf[c.i];
          c.fs = y * (1 - damp) + c.fs * damp;
          c.buf[c.i] = inp + c.fs * room;
          if (++c.i >= c.buf.length) c.i = 0;
          sum += y;
        }
        let v = sum * 0.06;
        for (const p of aps) {
          const y = p.buf[p.i];
          p.buf[p.i] = v + y * 0.5;
          if (++p.i >= p.buf.length) p.i = 0;
          v = y - v;
        }
        wet[i - a] = v;
      }
      const filtered = onepole(onepole(wet, hp, "hp"), lp, "lp");
      dst.set(filtered, a);
    }
  }
  return out;
}

/**
 * Tape stop in place: between s0 and s1 the playback rate falls from 1 to 0 (rate = (1−u)^pow), the sound gets
 * duller and quieter as it slows, and it is exactly zero from s1 on. Reads the original (full-speed) material.
 */
export function tapeStop(t: Stereo, s0: number, s1: number, pow = 1.6) {
  const L = t.L.slice(s0);
  const R = t.R.slice(s0);
  const nn = s1 - s0;
  let p = 0;
  let yl = 0;
  let yr = 0;
  for (let i = 0; i < nn; i++) {
    const u = i / nn;
    const r = (1 - u) ** pow;
    const k = Math.floor(p);
    const fr = p - k;
    const l = (L[k] ?? 0) * (1 - fr) + (L[k + 1] ?? 0) * fr;
    const rr = (R[k] ?? 0) * (1 - fr) + (R[k + 1] ?? 0) * fr;
    const a = 1 - Math.exp((-TAU * (150 + 14000 * r)) / SR); // one-pole LP tracks the speed
    yl += a * (l - yl);
    yr += a * (rr - yr);
    const g = Math.sqrt(r);
    t.L[s0 + i] = yl * g;
    t.R[s0 + i] = yr * g;
    p += r;
  }
  t.L.fill(0, s1);
  t.R.fill(0, s1);
}
