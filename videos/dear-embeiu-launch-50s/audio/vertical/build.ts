// node audio/vertical/build.ts (project root) → out/audio/vertical-master.wav + the stems vertical-music.wav and
// vertical-sfx.wav: the 9:16 cut's soundtrack (VERTICAL.md · Audio), 1200 f × 800 samples, 48 kHz / 24-bit. The music
// (./score.ts) + the SFX (./sfx.ts, the SFX agent's; a silent stand-in only while that file does not exist), mastered like
// the film (audio/build.ts): −14 LUFS integrated, true peak ≤ −1 dBTP — gain + its look-ahead limiter (truePeak /
// limitGain), iterated. VSILENCE (600–615, 1190–1200) is digital zero in the master and in both stems. The stems carry the
// master's gain curve, so music + sfx = master.
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { SPF, dbToGain, smp, stereo, writeWav24, type Stereo } from "../core.ts";
import { limitGain, truePeak } from "../build.ts";
import { VERT, VSILENCE } from "../../src/vertical/timeline.ts";
import { verticalMusic } from "./score.ts";

const LEN = VERT.total * SPF;
const TARGET = -14; // LUFS integrated
const TMP = `out/audio/.vertical-measure-${process.pid}.wav`; // per process: other audio builds may measure at the same time
const SECTIONS: Array<[string, number, number]> = [
  ["V1 hook", 0, 120],
  ["V2 question", 120, 600],
  ["V3 said up front", 615, 900],
  ["V4 sign-off", 900, 1190],
];

/** BS.1770 integrated loudness and true peak (ffmpeg ebur128, as audio/build.ts); with `frames`, the momentary log too */
function loud(t: Stereo, frames = false) {
  writeWav24(TMP, t);
  const r = spawnSync("ffmpeg", ["-hide_banner", "-nostats", ...(frames ? ["-v", "verbose"] : []), "-i", TMP, "-af", `ebur128=peak=true:framelog=${frames ? "verbose" : "quiet"}`, "-f", "null", "-"], { encoding: "utf8", maxBuffer: 1 << 26 });
  rmSync(TMP, { force: true });
  if (r.status !== 0) throw new Error(`ffmpeg failed\n${r.stderr}`);
  const last = (re: RegExp) => Number([...r.stderr.matchAll(re)].at(-1)?.[1] ?? NaN);
  const M = [...r.stderr.matchAll(/t:\s*([\d.]+)\s+TARGET.*?M:\s*(-?[\d.]+)/g)].map((m) => [Number(m[1]), Number(m[2])] as const);
  return { I: last(/I:\s+(-?[\d.]+) LUFS/g), TP: last(/Peak:\s+(-?[\d.]+) dBFS/g), M };
}
const silence = (t: Stereo) => {
  for (const [a, b] of VSILENCE) {
    t.L.fill(0, smp(a), smp(b));
    t.R.fill(0, smp(a), smp(b));
  }
  return t;
};
const apply = (t: Stereo, g: number, env: Float32Array) => {
  const o = stereo(LEN);
  for (let i = 0; i < LEN; i++) {
    o.L[i] = t.L[i] * g * env[i];
    o.R[i] = t.R[i] * g * env[i];
  }
  return silence(o);
};
async function sfxStem(): Promise<Stereo> {
  const file = new URL("./sfx.ts", import.meta.url);
  if (!existsSync(file)) {
    console.warn("vertical: audio/vertical/sfx.ts is not written yet — the SFX stem is silent for now");
    return stereo(LEN);
  }
  const mod = await import(file.href); // a runtime specifier: typecheck stays clean while the file does not exist
  return mod.verticalSfx() as Stereo;
}

mkdirSync("out/audio", { recursive: true });
const music = silence(verticalMusic());
const sfx = silence(await sfxStem());
for (const [k, t] of [["music", music], ["sfx", sfx]] as const)
  if (t.L.length !== LEN || t.R.length !== LEN) throw new Error(`vertical ${k} has ${t.L.length} samples, the cut needs ${LEN}`);
const sum = stereo(LEN);
for (let i = 0; i < LEN; i++) {
  sum.L[i] = music.L[i] + sfx.L[i];
  sum.R[i] = music.R[i] + sfx.R[i];
}

// −14 LUFS integrated, true peak ≤ −1 dBTP: gain + the film's look-ahead limiter, iterated
const tp = truePeak(sum);
const raw = loud(sum);
let gDb = TARGET - raw.I;
let ceilDb = -1.2;
let env = new Float32Array(LEN);
let out = sum;
let m = raw;
for (let it = 0; it < 6; it++) {
  env = limitGain(tp, dbToGain(gDb), dbToGain(ceilDb));
  out = apply(sum, dbToGain(gDb), env);
  m = loud(out);
  const okI = Math.abs(m.I - TARGET) <= 0.05;
  const okTP = m.TP <= -1.0;
  if (okI && okTP) break;
  if (!okI) gDb += TARGET - m.I;
  if (!okTP) ceilDb -= m.TP + 1.0 + 0.05;
}
if (Math.abs(m.I - TARGET) > 0.05 || m.TP > -1.0) throw new Error(`vertical master missed the target: I ${m.I} · TP ${m.TP}`);
const stems = { music: apply(music, dbToGain(gDb), env), sfx: apply(sfx, dbToGain(gDb), env) };
for (const [name, t] of [["master", out], ["music", stems.music], ["sfx", stems.sfx]] as const)
  for (const [a, b] of VSILENCE)
    for (let i = smp(a); i < smp(b); i++) if (t.L[i] !== 0 || t.R[i] !== 0) throw new Error(`${name}: sample ${i} must be digital zero`);
writeWav24("out/audio/vertical-master.wav", out);
writeWav24("out/audio/vertical-music.wav", stems.music);
writeWav24("out/audio/vertical-sfx.wav", stems.sfx);

// the readout: the limiter's work (runs > 1 dB), and per section the momentary (400 ms) min – max over whole windows
const spans: string[] = [];
let from = -1;
let deep = 1;
for (let f = 0; f <= VERT.total; f++) {
  const lo = f < VERT.total ? Math.min(...env.subarray(f * SPF, (f + 1) * SPF)) : 1;
  if (lo < dbToGain(-1)) {
    if (from < 0) from = f;
    deep = Math.min(deep, lo);
  } else if (from >= 0) {
    spans.push(`f${from}–${f - 1} ${(-20 * Math.log10(deep)).toFixed(1)} dB`);
    [from, deep] = [-1, 1];
  }
}
const M = loud(out, true).M;
const sections = SECTIONS.map(([name, a, b]) => {
  const w = M.filter(([t]) => t - 0.4 >= a / VERT.fps - 0.01 && t <= b / VERT.fps + 0.01).map(([, x]) => x); // ffmpeg's t drifts by µs
  return `${name} ${(a / VERT.fps).toFixed(2)}–${(b / VERT.fps).toFixed(2)} s: ${Math.min(...w).toFixed(1)} … ${Math.max(...w).toFixed(1)}`;
});
console.log(
  [
    `raw sum      I ${raw.I} LUFS · TP ${raw.TP} dBTP${sfx.L.some((x) => x !== 0) ? "" : " (music only: no SFX yet)"}`,
    `master       I ${m.I} LUFS · TP ${m.TP} dBTP · gain ${gDb.toFixed(2)} dB · ceiling ${ceilDb.toFixed(2)} dB · ${LEN} samples (${LEN / SPF} f)`,
    `limiter      > 1 dB: ${spans.join(", ") || "none"}`,
    `momentary    ${sections.join(" · ")} (LUFS)`,
  ].join("\n"),
);
