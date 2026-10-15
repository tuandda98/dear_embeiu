// Integrator (DESIGN §7): rebuild both stems from the current cues, sum them, normalise the sum to −14 LUFS
// integrated and true-peak limit it under −1 dBTP. Both stems get the same gain curve, so music + SFX = master.
// Usage (project root): node audio/build.ts [--mix-only]
import { spawnSync } from "node:child_process";
import { mkdirSync, rmSync } from "node:fs";
import { LEN, SILENCE, SPF, SR, dbToGain, readWav24, stereo, writeWav24, type Stereo } from "./core.ts";

const NAME = "dear-embeiu-launch-50s";
const TARGET = -14; // LUFS integrated
const LOOK = 96; // 2 ms look-ahead = attack time
const REL = Math.exp(-1 / (0.08 * SR)); // 80 ms release
const SIDE = 16; // interpolation taps per side

// 4× oversampling for true-peak detection: Blackman-windowed sinc kernels for the points ¼, ½, ¾ past each sample
const KERNELS = [0.25, 0.5, 0.75].map((p) =>
  Float64Array.from({ length: 2 * SIDE }, (_, j) => {
    const t = j - SIDE + 1 - p;
    const w = 0.42 + 0.5 * Math.cos((Math.PI * t) / (SIDE + 1)) + 0.08 * Math.cos((2 * Math.PI * t) / (SIDE + 1));
    return (Math.sin(Math.PI * t) / (Math.PI * t)) * w;
  }),
);

/** per-sample true peak (max over both channels of the sample and the 3 interpolated points after it) */
export function truePeak(t: Stereo) {
  const n = t.L.length;
  const tp = new Float32Array(n);
  for (const x of [t.L, t.R]) {
    for (let i = 0; i < n; i++) {
      let m = Math.abs(x[i]);
      const lo = Math.max(0, SIDE - 1 - i);
      const hi = Math.min(2 * SIDE, n - i + SIDE - 1);
      for (const h of KERNELS) {
        let y = 0;
        for (let j = lo; j < hi; j++) y += x[i + j - SIDE + 1] * h[j];
        m = Math.max(m, Math.abs(y));
      }
      if (m > tp[i]) tp[i] = m;
    }
  }
  return tp;
}

/** gain envelope that keeps tp × g × env ≤ ceil: look-ahead min, box-smoothed attack, exponential release */
export function limitGain(tp: Float32Array, g: number, ceil: number) {
  const n = tp.length;
  const need = Float32Array.from(tp, (v) => (v * g > ceil ? ceil / (v * g) : 1));
  // m[i] = min(need[i … i+LOOK]); the mean of m[i−LOOK … i] is ≤ need[i] because every one of those windows covers i
  const m = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    let v = 1;
    for (let k = i, e = Math.min(n - 1, i + LOOK); k <= e; k++) if (need[k] < v) v = need[k];
    m[i] = v;
  }
  const env = new Float32Array(n);
  let sum = LOOK + 1;
  let prev = 1;
  for (let i = 0; i < n; i++) {
    sum += m[i] - (i > LOOK ? m[i - LOOK - 1] : 1);
    const a = Math.min(1, sum / (LOOK + 1));
    prev = a < prev ? a : prev + (a - prev) * (1 - REL);
    env[i] = prev;
  }
  return env;
}

const apply = (t: Stereo, g: number, env: Float32Array) => {
  const o = stereo(t.L.length);
  for (let i = 0; i < t.L.length; i++) {
    o.L[i] = t.L[i] * g * env[i];
    o.R[i] = t.R[i] * g * env[i];
  }
  return o;
};

function sh(cmd: string, args: string[], quiet = false) {
  const r = spawnSync(cmd, args, { encoding: "utf8", stdio: quiet ? "pipe" : "inherit", maxBuffer: 1 << 26 });
  if (r.status !== 0) throw new Error(`${cmd} ${args.join(" ")} failed\n${r.stderr ?? ""}`);
  return r.stderr ?? "";
}

/** BS.1770 integrated loudness, true peak and LRA, as ffmpeg's ebur128 measures them */
function measure(t: Stereo, tmp = "out/audio/.measure.wav") {
  writeWav24(tmp, t);
  const log = sh("ffmpeg", ["-hide_banner", "-nostats", "-i", tmp, "-af", "ebur128=peak=true:framelog=quiet", "-f", "null", "-"], true);
  const last = (re: RegExp) => Number([...log.matchAll(re)].at(-1)?.[1] ?? NaN);
  return { I: last(/I:\s+(-?[\d.]+) LUFS/g), TP: last(/Peak:\s+(-?[\d.]+) dBFS/g), LRA: last(/LRA:\s+(-?[\d.]+) LU/g) };
}

const peakDb = (t: Stereo) => 20 * Math.log10(t.L.reduce((p, v, i) => Math.max(p, Math.abs(v), Math.abs(t.R[i])), 1e-12));

if (import.meta.main) {
  mkdirSync("out/deliver/stems", { recursive: true });
  if (!process.argv.includes("--mix-only")) for (const s of ["music", "sfx"]) sh("node", [`audio/${s}/build.ts`]);
  const music = readWav24("out/audio/music.wav");
  const sfx = readWav24("out/audio/sfx.wav");
  for (const [k, t] of [["music", music], ["sfx", sfx]] as const)
    if (t.L.length !== LEN) throw new Error(`${k}.wav has ${t.L.length} samples, the film needs ${LEN}`);

  const sum = stereo();
  for (let i = 0; i < LEN; i++) {
    sum.L[i] = music.L[i] + sfx.L[i];
    sum.R[i] = music.R[i] + sfx.R[i];
  }
  const tp = truePeak(sum);
  const raw = measure(sum);
  let gDb = TARGET - raw.I;
  let ceilDb = -1.2;
  let env = new Float32Array(LEN);
  let out = sum;
  let m = raw;
  for (let it = 0; it < 6; it++) {
    env = limitGain(tp, dbToGain(gDb), dbToGain(ceilDb));
    out = apply(sum, dbToGain(gDb), env);
    m = measure(out);
    const okI = Math.abs(m.I - TARGET) <= 0.05;
    const okTP = m.TP <= -1.0;
    if (okI && okTP) break;
    if (!okI) gDb += TARGET - m.I;
    if (!okTP) ceilDb -= m.TP + 1.0 + 0.05;
  }
  rmSync("out/audio/.measure.wav", { force: true });
  if (Math.abs(m.I - TARGET) > 0.05 || m.TP > -1.0) throw new Error(`master missed the target: ${JSON.stringify(m)}`);
  for (const [a, b] of SILENCE)
    for (let i = a; i < b; i++) if (out.L[i] !== 0 || out.R[i] !== 0) throw new Error(`sample ${i} must be digital zero`);

  writeWav24("out/audio/master.wav", out);
  const stems = { music: apply(music, dbToGain(gDb), env), sfx: apply(sfx, dbToGain(gDb), env) };
  for (const [k, t] of Object.entries(stems)) writeWav24(`out/deliver/stems/${NAME}_${k}.wav`, t);

  let gr = 1;
  let grAt = 0;
  const spans: string[] = []; // runs of frames limited by more than 1 dB, with their deepest reduction
  for (let i = 0; i < LEN; i++) if (env[i] < gr) [gr, grAt] = [env[i], i];
  let from = -1;
  let deep = 1;
  for (let f = 0; f <= LEN / SPF; f++) {
    const lo = f < LEN / SPF ? Math.min(...env.subarray(f * SPF, (f + 1) * SPF)) : 1;
    if (lo < dbToGain(-1)) {
      if (from < 0) from = f;
      deep = Math.min(deep, lo);
    } else if (from >= 0) {
      spans.push(`f${from}–${f - 1} ${(-20 * Math.log10(deep)).toFixed(1)} dB`);
      from = -1;
      deep = 1;
    }
  }
  console.log(
    [
      `raw sum      I ${raw.I} LUFS · TP ${raw.TP} dBTP · LRA ${raw.LRA} LU`,
      `master       I ${m.I} LUFS · TP ${m.TP} dBTP · LRA ${m.LRA} LU · gain ${gDb.toFixed(2)} dB · ceiling ${ceilDb.toFixed(2)} dB`,
      `limiter      max ${(-20 * Math.log10(gr)).toFixed(2)} dB at f${Math.floor(grAt / SPF)} · > 1 dB: ${spans.join(", ") || "none"}`,
      `stems        music peak ${peakDb(stems.music).toFixed(2)} dBFS · sfx peak ${peakDb(stems.sfx).toFixed(2)} dBFS`,
    ].join("\n"),
  );
}
