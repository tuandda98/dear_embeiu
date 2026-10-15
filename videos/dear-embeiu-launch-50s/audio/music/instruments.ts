// audio/music/instruments.ts — every voice of the score, synthesized (no samples). Each returns a buffer that starts
// with its attack at sample 0 and ends at exact zero (fadeEdges), so placing it at smp(f) is sample-aligned and clean.
import { SR, type Stereo } from "../core.ts";
import { rng } from "../../src/lib/rand.ts";
import { TAU, hz, ms, sec, cents, clamp, noise, fadeEdges, scaleTo, peak, gain, decayMul, smooth, sawBL, squareBL, triAdd, svf, onepole, dcBlock, sat, add } from "./dsp.ts";

const NYQ = SR * 0.45;

/**
 * Felt piano: additive partials with inharmonicity (f_k = k f0 √(1 + B k²)), a felt ceiling that darkens with a
 * softer touch, two detuned strings per note above the bass, a two-stage (prompt + sustain) decay, a felt hammer
 * thump and a damper release when `dur` (samples) is given.
 */
export function feltPiano(midi: number, vel = 0.7, dur?: number, seed = 11): Float32Array {
  const f0 = hz(midi);
  const r = rng(seed * 7919 + midi);
  const B = 0.00012 + 0.0005 * clamp((midi - 36) / 48, 0, 1);
  const t60 = 11 * 2 ** (-(midi - 38) / 16); // D2 ≈ 11 s · D4 ≈ 3.9 s · D5 ≈ 2.5 s
  const natural = sec(Math.min(t60 * 0.8, 8));
  const len = dur === undefined ? natural : Math.min(natural, dur + ms(180));
  const out = new Float32Array(len);
  const felt = 800 + 2800 * vel;
  for (let k = 1; k <= 28; k++) {
    const fk = k * f0 * Math.sqrt(1 + B * k * k);
    if (fk > NYQ) break;
    const a = vel ** (1 + 0.12 * (k - 1)) / k ** 1.2 / (1 + (fk / felt) ** 2.4);
    if (a < 2e-4) continue;
    const mSlow = decayMul(t60 / (1 + 0.25 * (k - 1)));
    const mPrompt = decayMul(0.35);
    const dets = midi > 44 ? [cents(-1.2 - r() * 1.5), cents(1.2 + r() * 1.5)] : [1];
    for (const det of dets) {
      let ph = r() * TAU;
      const w = (TAU * fk * det) / SR;
      const g = a / dets.length;
      let e1 = 1;
      let e2 = 1;
      for (let i = 0; i < len; i++) {
        out[i] += g * (0.6 * e1 + 0.4 * e2) * Math.sin(ph);
        ph += w;
        if (ph > TAU) ph -= TAU;
        e1 *= mSlow;
        e2 *= mPrompt;
      }
    }
  }
  scaleTo(out, 0.85 * (0.35 + 0.65 * vel));
  // transient shaping (mix pass): the hammer and the felt thump used to add ~3 dB of peak above the strings' own
  // peak while adding almost no loudness; kept, but at a level where the note's crest is set by the strings
  const hammer = onepole(noise(ms(12), seed + 1), 1400, "lp");
  for (let i = 0; i < hammer.length; i++) out[i] += hammer[i] * 0.3 * vel * Math.exp(-i / ms(2));
  const thump = onepole(noise(ms(30), seed + 2), 260, "lp");
  for (let i = 0; i < thump.length; i++) out[i] += thump[i] * 0.6 * vel * Math.exp(-i / ms(8));
  if (dur !== undefined && dur < len) {
    const damper = onepole(noise(ms(25), seed + 3), 600, "lp");
    for (let i = dur; i < len; i++) out[i] *= Math.exp(-(i - dur) / ms(40));
    for (let i = 0; i < damper.length && dur + i < len; i++) out[dur + i] += damper[i] * 0.05 * Math.exp(-i / ms(6));
  }
  return fadeEdges(out, ms(1.2), ms(4));
}

/** marimba: three modal bars (1 : 3.92 : 9.93) with a soft yarn-mallet transient */
export function marimba(midi: number, vel = 0.7, seed = 21): Float32Array {
  const f0 = hz(midi);
  const r = rng(seed * 131 + midi);
  const ratios = [1, 3.92, 9.93];
  const amps = [1, 0.28, 0.09];
  const t60s = [1.1 * 2 ** (-(midi - 60) / 24), 0.3, 0.12];
  const len = sec(t60s[0] * 1.05) + ms(10);
  const out = new Float32Array(len);
  for (let k = 0; k < 3; k++) {
    const fk = f0 * ratios[k];
    if (fk > NYQ) continue;
    const w = (TAU * fk) / SR;
    const m = decayMul(t60s[k]);
    let ph = r() * TAU;
    let e = 1;
    const a = amps[k] * vel;
    for (let i = 0; i < len; i++) {
      out[i] += a * e * Math.sin(ph);
      ph += w;
      if (ph > TAU) ph -= TAU;
      e *= m;
    }
  }
  scaleTo(out, 0.8 * vel);
  const mallet = svf(noise(ms(5), seed + 1), 1900, 0.3, "bp");
  for (let i = 0; i < mallet.length; i++) out[i] += mallet[i] * 0.35 * vel * Math.exp(-i / ms(1.2));
  return fadeEdges(out, ms(0.8), ms(4));
}

/** Karplus-Strong pluck with a one-pole damping filter in the loop. tone 0..1 (low = muted), exc = excitation LP Hz */
export function pluck(midi: number, vel = 0.7, o: { t60?: number; tone?: number; exc?: number; seed?: number } = {}): Float32Array {
  const { t60 = 0.6, tone = 0.5, exc = 3000, seed = 31 } = o;
  const f0 = hz(midi);
  const Nf = SR / f0 - 0.5;
  const di = Math.floor(Nf);
  const fr = Nf - di;
  const len = sec(t60 * 1.3) + ms(20);
  const y = new Float32Array(len);
  const burst = onepole(onepole(noise(di + 2, seed * 977 + midi), exc, "lp"), exc * 1.5, "lp"); // 2-pole: a muted pick stays muted
  let mean = 0;
  for (const v of burst) mean += v;
  mean /= burst.length;
  const rho = 10 ** (-3 / (t60 * f0));
  const c = 0.08 + 0.92 * clamp(tone, 0, 1);
  let lp = 0;
  for (let i = 0; i < len; i++) {
    const d = (i - di >= 0 ? y[i - di] : 0) * (1 - fr) + (i - di - 1 >= 0 ? y[i - di - 1] : 0) * fr;
    lp += c * (d - lp);
    y[i] = (i < burst.length ? (burst[i] - mean) * vel : 0) + rho * lp;
  }
  dcBlock(y);
  sat(y, 2); // mix pass: a gentle clip on the pick burst (11 dB crest) before the peak is set: more ring per peak
  scaleTo(y, 0.8 * vel);
  return fadeEdges(y, ms(0.4), ms(15));
}

/** tight muted kick: sine sweep 180 → 48 Hz, soft clip, 2 kHz lid, a 1.5 ms click.
 *  The clip is deliberately firm (drive 2.6): the peak is normalised afterwards, so a denser body means more
 *  loudness per peak where the kick stacks with a pluck or a motif note on the same beat. */
export function kick(vel = 1, seed = 41): Float32Array {
  const len = ms(150);
  const out = new Float32Array(len);
  let ph = 0;
  for (let i = 0; i < len; i++) {
    const t = i / SR;
    const f = 48 + 132 * Math.exp(-t / 0.014);
    ph += (TAU * f) / SR;
    out[i] = Math.sin(ph) * Math.exp(-t / 0.05);
  }
  sat(out, 2.6);
  const click = onepole(noise(ms(1.5), seed), 2500, "hp");
  for (let i = 0; i < click.length; i++) out[i] += click[i] * 0.35 * Math.exp(-i / ms(0.4));
  const lid = onepole(out, 2000, "lp");
  scaleTo(lid, 0.9 * vel);
  return fadeEdges(lid, ms(0.3), ms(10));
}

/** very short hat: band-passed noise + inharmonic metallic partials; accent = a touch longer and brighter */
export function hat(accent: boolean, vel = 0.7, seed = 51): Float32Array {
  const len = accent ? ms(45) : ms(16);
  const tau = accent ? 0.011 : 0.0042;
  const nz = svf(noise(len, seed), 8800, 0.45, "bp");
  const out = new Float32Array(len);
  const r = rng(seed);
  const metal = [3137, 4421, 5603, 7307, 8923, 10391, 12203];
  for (let i = 0; i < len; i++) out[i] = nz[i] * 0.9 * Math.exp(-i / (tau * SR));
  for (const fm of metal) {
    const w = (TAU * fm) / SR;
    let ph = r() * TAU;
    for (let i = 0; i < len; i++) {
      out[i] += 0.07 * Math.sin(ph) * Math.exp(-i / (tau * 0.7 * SR));
      ph += w;
      if (ph > TAU) ph -= TAU;
    }
  }
  const o = onepole(onepole(out, 4500, "hp"), 15000, "lp");
  scaleTo(o, 0.7 * vel);
  return fadeEdges(o, ms(0.3), ms(2));
}

/** soft clap: four noise bursts then a tail, per-channel seeds so it sits wide */
export function clap(seed = 61): Stereo {
  const mk = (s: number) => {
    const len = ms(160);
    const nz = noise(len, s);
    const out = new Float32Array(len);
    const bursts = [0, 9, 19, 30].map(ms);
    for (let i = 0; i < len; i++) {
      let e = 0;
      for (const b of bursts) if (i >= b) e = Math.max(e, Math.exp(-(i - b) / ms(3.5)));
      if (i >= bursts[3]) e = Math.max(e, 0.8 * Math.exp(-(i - bursts[3]) / ms(32)));
      out[i] = nz[i] * e;
    }
    const f = onepole(svf(out, 1300, 0.3, "bp"), 500, "hp");
    scaleTo(f, 0.7);
    return fadeEdges(f, ms(0.3), ms(8));
  };
  return { L: mk(seed), R: mk(seed + 7) };
}

/** brushed side-stick: a wooden tick with a short brush swish */
export function sideStick(seed = 71): Float32Array {
  const len = ms(90);
  const out = new Float32Array(len);
  let p1 = 0;
  let p2 = 0;
  for (let i = 0; i < len; i++) {
    out[i] = 0.6 * Math.sin(p1) * Math.exp(-i / ms(6)) + 0.5 * Math.sin(p2) * Math.exp(-i / ms(20));
    p1 += (TAU * 1850) / SR;
    p2 += (TAU * 640) / SR;
  }
  const brush = svf(noise(len, seed), 5500, 0.3, "bp");
  for (let i = 0; i < len; i++) out[i] += brush[i] * 0.4 * Math.exp(-i / ms(22));
  scaleTo(out, 0.6);
  return fadeEdges(out, ms(0.3), ms(6));
}

/** bass: band-limited saw + sub pulse through a resonant low-pass with a pluck envelope on the cutoff */
export function bassNote(midi: number, len: number, vel = 0.8, o: { cut0?: number; cut1?: number; res?: number; sub?: number; rel?: number } = {}): Float32Array {
  const { cut0 = 1400, cut1 = 260, res = 0.35, sub = 0.5, rel = ms(6) } = o;
  const f = hz(midi);
  const x = sawBL(len, f);
  const sq = squareBL(len, f / 2);
  for (let i = 0; i < len; i++) x[i] = x[i] * 0.8 + sq[i] * sub * 0.5;
  const y = svf(x, (i) => cut1 + (cut0 - cut1) * Math.exp(-i / ms(70)), res, "lp");
  sat(y, 1.3);
  scaleTo(y, 0.8 * vel);
  return fadeEdges(y, ms(2), rel);
}

/** wide pad: per note two detuned saws (opposite detune per channel) + a triangle, slow low-pass, cosine attack/release */
export function padChord(midis: number[], len: number, o: { atk?: number; rel?: number; cut?: (i: number) => number; seed?: number } = {}): Stereo {
  const { atk = ms(100), rel = ms(140), cut = () => 1400, seed = 81 } = o;
  const r = rng(seed);
  const L = new Float32Array(len);
  const R = new Float32Array(len);
  for (const m of midis) {
    const f = hz(m);
    const tri = triAdd(len, f, r());
    add(L, tri, 0.35);
    add(R, tri, 0.35);
    add(L, sawBL(len, f * cents(-7), r()), 0.3);
    add(L, sawBL(len, f * cents(3), r()), 0.3);
    add(R, sawBL(len, f * cents(7), r()), 0.3);
    add(R, sawBL(len, f * cents(-3), r()), 0.3);
  }
  const g = 1 / (midis.length * 1.1);
  const env = (i: number) => smooth(i, atk) * (1 - smooth(i - (len - rel), rel));
  const fl = svf(L, cut, 0.12, "lp");
  const fr = svf(R, cut, 0.12, "lp");
  for (let i = 0; i < len; i++) {
    const e = env(i) * g;
    fl[i] *= e;
    fr[i] *= e;
  }
  const k = 0.6 / Math.max(1e-6, peak(fl), peak(fr)); // predictable level whatever the voicing and the low-pass
  gain(fl, k);
  gain(fr, k);
  return { L: fl, R: fr };
}

/** glass pad: pure partials in slow-beating detuned pairs, each with its own slow amplitude breath */
export function glassPad(midis: number[], len: number, o: { atk?: number; rel?: number; seed?: number } = {}): Stereo {
  const { atk = ms(600), rel = ms(250), seed = 91 } = o;
  const r = rng(seed);
  const L = new Float32Array(len);
  const R = new Float32Array(len);
  const parts: Array<[number, number]> = [
    [1, 1],
    [2, 0.18],
    [3, 0.06],
  ];
  for (const m of midis) {
    for (const [ratio, a] of parts) {
      const f = hz(m) * ratio;
      if (f > NYQ) continue;
      for (const [dst, det] of [
        [L, cents(-2.5)],
        [R, cents(2.5)],
      ] as const) {
        const w = (TAU * f * det) / SR;
        const lfoW = (TAU * (0.07 + 0.18 * r())) / SR;
        let ph = r() * TAU;
        let lph = r() * TAU;
        for (let i = 0; i < len; i++) {
          dst[i] += a * (0.75 + 0.25 * Math.sin(lph)) * Math.sin(ph);
          ph += w;
          if (ph > TAU) ph -= TAU;
          lph += lfoW;
        }
      }
    }
  }
  const g = 0.9 / (midis.length * 1.3);
  for (let i = 0; i < len; i++) {
    const e = smooth(i, atk) * (1 - smooth(i - (len - rel), rel)) * g;
    L[i] *= e;
    R[i] *= e;
  }
  return { L, R };
}

/** glass chime: bell partials at sensible octaves, a 2 ms strike */
export function chime(midi: number, vel = 0.8, seed = 101): Float32Array {
  const f0 = hz(midi);
  const r = rng(seed + midi);
  const parts: Array<[number, number, number]> = [
    [0.5, 0.12, 2.2],
    [1, 1, 2.6],
    [2, 0.4, 1.6],
    [2.76, 0.22, 1.1],
    [4.07, 0.1, 0.7],
    [5.4, 0.05, 0.45],
  ];
  const len = sec(2.8);
  const out = new Float32Array(len);
  for (const [ratio, a, t60] of parts) {
    const f = f0 * ratio;
    if (f > NYQ) continue;
    const w = (TAU * f) / SR;
    const m = decayMul(t60);
    let ph = r() * TAU;
    let e = 1;
    for (let i = 0; i < len; i++) {
      out[i] += a * e * Math.sin(ph);
      ph += w;
      if (ph > TAU) ph -= TAU;
      e *= m;
    }
  }
  scaleTo(out, 0.8 * vel);
  const strike = svf(noise(ms(3), seed), 6000, 0.3, "bp");
  for (let i = 0; i < strike.length; i++) out[i] += strike[i] * 0.12 * vel * Math.exp(-i / ms(0.8));
  return fadeEdges(out, ms(0.8), ms(10));
}

/** soft glass tone (the liquid steps): three near-harmonic partials, 8 ms attack */
export function glassTone(midi: number, vel = 0.6, seed = 111): Float32Array {
  const f0 = hz(midi);
  const r = rng(seed + midi);
  const parts: Array<[number, number, number]> = [
    [1, 1, 1.6],
    [2.01, 0.3, 0.9],
    [3.02, 0.1, 0.5],
  ];
  const len = sec(1.8);
  const out = new Float32Array(len);
  for (const [ratio, a, t60] of parts) {
    const f = f0 * ratio;
    if (f > NYQ) continue;
    const w = (TAU * f) / SR;
    const m = decayMul(t60);
    let ph = r() * TAU;
    let e = 1;
    for (let i = 0; i < len; i++) {
      out[i] += a * e * Math.sin(ph);
      ph += w;
      if (ph > TAU) ph -= TAU;
      e *= m;
    }
  }
  scaleTo(out, 0.8 * vel);
  return fadeEdges(out, ms(8), ms(10));
}

/** D1 sub pulse: a sine with a touch of 2nd/3rd harmonic (so small speakers feel it) and a short pitch dip */
export function subPulse(midi: number, t60 = 0.9): Float32Array {
  const len = sec(t60 * 1.1);
  const out = new Float32Array(len);
  const f0 = hz(midi);
  let p1 = 0;
  let p2 = 0;
  let p3 = 0;
  const m = decayMul(t60);
  let e = 1;
  for (let i = 0; i < len; i++) {
    const f = f0 * (1 + 0.25 * Math.exp(-i / ms(25)));
    out[i] = e * (Math.sin(p1) + 0.35 * Math.sin(p2) + 0.08 * Math.sin(p3));
    p1 += (TAU * f) / SR;
    p2 += (TAU * 2 * f) / SR;
    p3 += (TAU * 3 * f) / SR;
    e *= m;
  }
  scaleTo(out, 0.9);
  return fadeEdges(out, ms(3), ms(20));
}

/** sustained sine sub/drone with a soft 2nd harmonic */
export function subHold(midi: number, len: number, atk: number, rel: number): Float32Array {
  const out = new Float32Array(len);
  const f = hz(midi);
  let p1 = 0;
  let p2 = 0;
  for (let i = 0; i < len; i++) {
    out[i] = (Math.sin(p1) + 0.2 * Math.sin(p2)) * smooth(i, atk) * (1 - smooth(i - (len - rel), rel));
    p1 += (TAU * f) / SR;
    p2 += (TAU * 2 * f) / SR;
  }
  scaleTo(out, 0.8);
  return out;
}

/**
 * Granular cloud: Hann-windowed grains of pure partials at in-key pitches, random pan within `width`.
 * rate(u) = grains per second, pitchHz(u, rnd) picks a frequency, grainLen(u) in samples, amp(u) the envelope.
 */
export function grainCloud(o: { len: number; seed: number; rate: (u: number) => number; pitchHz: (u: number, r: () => number) => number; grainLen: (u: number) => number; amp: (u: number) => number; partials?: Array<[number, number]>; width?: number }): Stereo {
  const { len, seed, rate, pitchHz, grainLen, amp, partials = [[1, 1], [2, 0.2]], width = 0.8 } = o;
  const r = rng(seed);
  const L = new Float32Array(len);
  const R = new Float32Array(len);
  let t = 0;
  while (t < len) {
    const u = t / len;
    const gl = Math.round(grainLen(u));
    const f = pitchHz(u, r);
    const a = amp(u) * (0.7 + 0.3 * r());
    const pan = (r() * 2 - 1) * width;
    const ang = ((pan + 1) * Math.PI) / 4;
    const gL = Math.cos(ang) * a;
    const gR = Math.sin(ang) * a;
    const ph0 = r() * TAU;
    for (let i = 0; i < gl && t + i < len; i++) {
      const w = 0.5 - 0.5 * Math.cos((TAU * i) / gl);
      let v = 0;
      for (const [ratio, pa] of partials) if (f * ratio < NYQ) v += pa * Math.sin(ph0 * ratio + (TAU * f * ratio * i) / SR);
      L[t + i] += v * w * gL;
      R[t + i] += v * w * gR;
    }
    t += Math.max(32, Math.round((SR / rate(u)) * (0.7 + 0.6 * r())));
  }
  return { L, R };
}
