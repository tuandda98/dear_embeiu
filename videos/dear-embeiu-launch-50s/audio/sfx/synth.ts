// DSP primitives for the SFX stem. Plain TS, Node 25, no packages. Everything is deterministic (seeded noise only),
// band-limited by construction (sines + filtered white noise, nothing wraps past Nyquist) and click-free (every
// voice has an attack and a release that ends on an exact zero).
import { rng } from "../../src/lib/rand.ts";
import { SR, type Stereo } from "../core.ts";

export const ms = (x: number) => Math.round((x * SR) / 1000);
export const buf = (n: number) => new Float32Array(Math.max(1, Math.round(n)));
export const db = (x: number) => 10 ** (x / 20);
export type Rand = () => number;
export const rand = (seed: number): Rand => rng(seed);
/** uniform in [a, b) */
export const uni = (r: Rand, a: number, b: number) => a + (b - a) * r();

// ---------------------------------------------------------------- envelopes
/** attack (sin² ramp, `a` samples) then exponential decay with time constant `tau` (samples); length n; ends on 0 */
export function env(n: number, a: number, tau: number, hold = 0): Float32Array {
  const e = buf(n);
  const rel = Math.min(ms(2), n >> 2);
  for (let i = 0; i < n; i++) {
    let v: number;
    if (i < a) v = Math.sin((Math.PI / 2) * (i / a)) ** 2;
    else if (i < a + hold) v = 1;
    else v = Math.exp(-(i - a - hold) / tau);
    if (i >= n - rel) v *= (n - i) / rel;
    e[i] = v;
  }
  return e;
}
/** a smooth bell/plateau over n samples: rise `a`, fall `d` (raised-cosine), 1 in between */
export function bell(n: number, a: number, d: number): Float32Array {
  const e = buf(n);
  for (let i = 0; i < n; i++) {
    let v = 1;
    if (i < a) v = 0.5 - 0.5 * Math.cos((Math.PI * i) / a);
    else if (i >= n - d) v = 0.5 - 0.5 * Math.cos((Math.PI * (n - i)) / d);
    e[i] = v;
  }
  return e;
}
export function mul(x: Float32Array, e: Float32Array | number): Float32Array {
  const y = buf(x.length);
  if (typeof e === "number") for (let i = 0; i < x.length; i++) y[i] = x[i] * e;
  else for (let i = 0; i < x.length; i++) y[i] = x[i] * (e[i] ?? 0);
  return y;
}
/** add src into dst at offset (dst keeps its length) */
export function add(dst: Float32Array, src: Float32Array, at = 0, gain = 1): Float32Array {
  const end = Math.min(src.length, dst.length - at);
  for (let i = Math.max(0, -at); i < end; i++) dst[at + i] += src[i] * gain;
  return dst;
}
/** sum of parts, each {b, at, g}; length = max extent */
export function mix(parts: { b: Float32Array; at?: number; g?: number }[]): Float32Array {
  const n = Math.max(...parts.map((p) => (p.at ?? 0) + p.b.length));
  const y = buf(n);
  for (const p of parts) add(y, p.b, p.at ?? 0, p.g ?? 1);
  return y;
}
export function peak(x: Float32Array): number {
  let p = 0;
  for (let i = 0; i < x.length; i++) p = Math.max(p, Math.abs(x[i]));
  return p;
}
/** gentle saturation (tanh), normalised so a full-scale input stays full scale: density for the hero hits */
export function sat(x: Float32Array, drive = 2.5): Float32Array {
  const y = buf(x.length);
  const k = 1 / Math.tanh(drive);
  for (let i = 0; i < x.length; i++) y[i] = Math.tanh(drive * x[i]) * k;
  return y;
}
/** scale so the peak is `dbfs` */
export function norm(x: Float32Array, dbfs: number): Float32Array {
  const p = peak(x);
  return p ? mul(x, db(dbfs) / p) : x;
}

// ---------------------------------------------------------------- sources
export function noise(n: number, r: Rand): Float32Array {
  const y = buf(n);
  for (let i = 0; i < n; i++) y[i] = r() * 2 - 1;
  return y;
}
/** sine with a per-sample frequency (Hz) — phase-accumulated, so chirps are clean */
export function tone(n: number, freq: number | ((i: number) => number), phase = 0): Float32Array {
  const y = buf(n);
  let ph = phase;
  const nyq = SR * 0.48;
  for (let i = 0; i < n; i++) {
    const f = Math.min(nyq, typeof freq === "number" ? freq : freq(i));
    y[i] = Math.sin(ph);
    ph += (2 * Math.PI * f) / SR;
  }
  return y;
}
/** exponential chirp f0 -> f1 over `dur` samples, then f1 */
export const chirp = (f0: number, f1: number, dur: number) => (i: number) => (i >= dur ? f1 : f0 * (f1 / f0) ** (i / dur));
/**
 * a struck body: a set of decaying sine partials. freqs in Hz, taus in samples, amps linear.
 * Partials above Nyquist are dropped. Each partial gets a tiny attack so there is never a step.
 */
export function modes(n: number, freqs: number[], taus: number[], amps: number[], r?: Rand): Float32Array {
  const y = buf(n);
  const att = ms(0.4);
  for (let k = 0; k < freqs.length; k++) {
    const f = freqs[k];
    if (f >= SR * 0.45) continue;
    const ph = r ? r() * 2 * Math.PI : 0;
    const tau = taus[k];
    const a = amps[k];
    let p = ph;
    const w = (2 * Math.PI * f) / SR;
    for (let i = 0; i < n; i++) {
      const e = (i < att ? i / att : 1) * Math.exp(-i / tau);
      if (e < 1e-5 && i > att) break;
      y[i] += a * e * Math.sin(p);
      p += w;
    }
  }
  const rel = ms(2);
  for (let i = n - rel; i < n; i++) y[i] *= (n - i) / rel;
  return y;
}

// ---------------------------------------------------------------- filters (RBJ biquads)
export type Biq = { b0: number; b1: number; b2: number; a1: number; a2: number };
export function biquad(type: "lp" | "hp" | "bp" | "peak" | "notch", f0: number, Q: number, gainDb = 0): Biq {
  const w = (2 * Math.PI * Math.min(f0, SR * 0.45)) / SR;
  const cs = Math.cos(w), sn = Math.sin(w);
  const al = sn / (2 * Q);
  const A = 10 ** (gainDb / 40);
  let b0 = 1, b1 = 0, b2 = 0, a0 = 1, a1 = 0, a2 = 0;
  switch (type) {
    case "lp": b0 = (1 - cs) / 2; b1 = 1 - cs; b2 = b0; a0 = 1 + al; a1 = -2 * cs; a2 = 1 - al; break;
    case "hp": b0 = (1 + cs) / 2; b1 = -(1 + cs); b2 = b0; a0 = 1 + al; a1 = -2 * cs; a2 = 1 - al; break;
    case "bp": b0 = al; b1 = 0; b2 = -al; a0 = 1 + al; a1 = -2 * cs; a2 = 1 - al; break; // constant 0 dB peak gain
    case "notch": b0 = 1; b1 = -2 * cs; b2 = 1; a0 = 1 + al; a1 = -2 * cs; a2 = 1 - al; break;
    case "peak": b0 = 1 + al * A; b1 = -2 * cs; b2 = 1 - al * A; a0 = 1 + al / A; a1 = -2 * cs; a2 = 1 - al / A; break;
  }
  return { b0: b0 / a0, b1: b1 / a0, b2: b2 / a0, a1: a1 / a0, a2: a2 / a0 };
}
export function filt(x: Float32Array, c: Biq): Float32Array {
  const y = buf(x.length);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) {
    const v = c.b0 * x[i] + c.b1 * x1 + c.b2 * x2 - c.a1 * y1 - c.a2 * y2;
    x2 = x1; x1 = x[i]; y2 = y1; y1 = v;
    y[i] = v;
  }
  return y;
}
export const lp = (x: Float32Array, f: number, Q = 0.707) => filt(x, biquad("lp", f, Q));
export const hp = (x: Float32Array, f: number, Q = 0.707) => filt(x, biquad("hp", f, Q));
export const bp = (x: Float32Array, f: number, Q = 1) => filt(x, biquad("bp", f, Q));
/** time-varying 2-pole band-pass (Chamberlin SVF, oversampled ×2 so it stays stable up to ~8 kHz) */
export function svfBand(x: Float32Array, fc: (i: number) => number, q: (i: number) => number): Float32Array {
  const y = buf(x.length);
  let low = 0, band = 0;
  for (let i = 0; i < x.length; i++) {
    const f = 2 * Math.sin((Math.PI * Math.min(fc(i), 8000)) / (2 * SR));
    const d = 1 / Math.max(0.5, q(i));
    for (let k = 0; k < 2; k++) {
      const high = x[i] - low - d * band;
      band += f * high;
      low += f * band;
    }
    y[i] = band;
  }
  return y;
}
/** one-pole DC blocker */
export function dcBlock(x: Float32Array, fHz = 10): Float32Array {
  const y = buf(x.length);
  const R = 1 - (2 * Math.PI * fHz) / SR;
  let x1 = 0, y1 = 0;
  for (let i = 0; i < x.length; i++) {
    y1 = x[i] - x1 + R * y1;
    x1 = x[i];
    y[i] = y1;
  }
  return y;
}

// ---------------------------------------------------------------- reverb (4-line FDN, Hadamard feedback, damped)
/**
 * Processes a stereo send bus into a stereo wet signal. L feeds lines 0/2, R feeds 1/3, so panned sends keep
 * their side. `rt60` seconds, `damp` Hz lowpass inside the loop (restrained high end). State is local to the call,
 * so processing separate ranges never lets a tail cross a cut.
 */
export function fdn(send: Stereo, from: number, to: number, out: Stereo, { rt60, damp, pre, lens }: { rt60: number; damp: number; pre: number; lens: number[] }) {
  const n = to - from;
  if (n <= 0) return;
  const D = lens.map((l) => Math.round(l));
  const g = D.map((l) => 10 ** ((-3 * l) / (rt60 * SR)));
  const lines = D.map((l) => new Float32Array(l));
  const idx = [0, 0, 0, 0];
  const lpS = [0, 0, 0, 0];
  const a = Math.exp((-2 * Math.PI * damp) / SR);
  const preN = Math.round(pre * SR);
  const preL = new Float32Array(preN + 1), preR = new Float32Array(preN + 1);
  let pi = 0;
  const inject = [0, 0, 0, 0];
  for (let s = 0; s < n; s++) {
    const i = from + s;
    // pre-delay
    preL[pi] = send.L[i]; preR[pi] = send.R[i];
    const ri = (pi + 1) % (preN + 1);
    const xl = preL[ri], xr = preR[ri];
    pi = ri;
    const o0 = lines[0][idx[0]], o1 = lines[1][idx[1]], o2 = lines[2][idx[2]], o3 = lines[3][idx[3]];
    // Hadamard mix ×0.5
    const h0 = 0.5 * (o0 + o1 + o2 + o3), h1 = 0.5 * (o0 - o1 + o2 - o3), h2 = 0.5 * (o0 + o1 - o2 - o3), h3 = 0.5 * (o0 - o1 - o2 + o3);
    inject[0] = h0 * g[0] + xl; inject[1] = h1 * g[1] + xr; inject[2] = h2 * g[2] + xl; inject[3] = h3 * g[3] + xr;
    for (let k = 0; k < 4; k++) {
      lpS[k] = a * lpS[k] + (1 - a) * inject[k];
      lines[k][idx[k]] = lpS[k];
      idx[k] = (idx[k] + 1) % D[k];
    }
    out.L[i] += 0.35 * (o0 + o2 * 0.8 - o3 * 0.3);
    out.R[i] += 0.35 * (o1 + o3 * 0.8 - o2 * 0.3);
  }
}
export const ROOM = { rt60: 0.45, damp: 4200, pre: 0.008, lens: [SR * 0.0231, SR * 0.0311, SR * 0.0397, SR * 0.0463] };
export const HALL = { rt60: 1.9, damp: 3000, pre: 0.018, lens: [SR * 0.0417, SR * 0.0569, SR * 0.0731, SR * 0.0887] };

/** linear fade-out ending at `end` over `n` samples (declick before a dead cut; the cut itself stays dead) */
export function fadeOut(t: Stereo, end: number, n: number) {
  for (let i = Math.max(0, end - n); i < end; i++) {
    const g = (end - i) / n;
    t.L[i] *= g; t.R[i] *= g;
  }
}
export function fadeIn(t: Stereo, start: number, n: number) {
  for (let i = start; i < Math.min(t.L.length, start + n); i++) {
    const g = (i - start) / n;
    t.L[i] *= g; t.R[i] *= g;
  }
}
