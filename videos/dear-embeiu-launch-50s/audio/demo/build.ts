// node audio/demo/build.ts (project root) → out/audio/demo-master.wav: the demo's 45 s soundtrack (2700 f × 800 =
// 2 160 000 samples, 48 kHz / 24-bit). No voice-over. A light music bed from the film's kit (D major, 120 BPM: a glass
// pad, a plucked 8th-note arpeggio, a soft kick on 2 and 4 from segment 2, each voice set by its measured loudness)
// at −18 LUFS, and light foley from the film's SFX kit on the picture's own cues (src/demo/timeline.ts) just above it:
// a soft tick on every title wipe, a paper click as each callout lands, a quiet UI pop on the in-phone taps, a short
// riffle on every cut, one glass ting on the end card. The sum is normalised to −14 LUFS / true peak ≤ −1 dBTP exactly
// like audio/build.ts (its truePeak / limitGain). The last 10 frames are digital zero. Deterministic: seeded only.
import { spawnSync } from "node:child_process";
import { mkdirSync, rmSync } from "node:fs";
import { SPF, dbToGain, place, placeStereo, smp, stereo, writeWav24, type Stereo } from "../core.ts";
import { limitGain, truePeak } from "../build.ts";
import { notes, onepole, reverb } from "../music/dsp.ts";
import { glassPad, kick, pluck } from "../music/instruments.ts";
import { airPop, cardFlutter, microTick, paperClick, ting } from "../sfx/kit.ts";
import { hp, lp, norm, rand, sat } from "../sfx/synth.ts";
import { CALLOUT_CUES, DEMO, END, HOOK, SEG, SHOTS, TAPS, TITLE_CUES } from "../../src/demo/timeline.ts";

const LEN = DEMO.total * SPF;
const TARGET = -14; // LUFS integrated, the master
const BED = -18; // LUFS integrated, the bed alone
/**
 * Foley gains (dB on each voice's own 0 dBFS-normalised take), calibrated against the bed by the readout below
 * (level over the bed in the 100 ms after each hit): ticks ≈ the bed, clicks / pops / riffles 0…+2 dB over it, so
 * they sit just above it and the limiter only touches them (≤ 2.5 dB, a few frames). Retune here if the bed moves.
 */
const FOLEY = { tick: -5, click: -5.5, pop: -5, riffle: -4 } as const;
const TING = -17; // LUFS integrated, the end card's ting alone
const FADE = [2580, 2690] as const; // the bed fades out over the last ~2 s
const SILENT = smp(DEMO.total - 10); // the last 10 frames are digital zero

/** I–vi–IV–V twice, then I–IV–V into the end card's I: [first frame, voicing] — one chord per 2 bars */
const CHORDS: Array<[number, number[]]> = [
  [0, notes("D3", "A3", "E4", "F#4")], // D(add9)
  [240, notes("B2", "F#3", "A3", "D4")], // Bm7
  [480, notes("G2", "D3", "F#3", "B3")], // Gmaj7
  [720, notes("A2", "E3", "G3", "C#4")], // A7
  [960, notes("D3", "A3", "E4", "F#4")],
  [1200, notes("B2", "F#3", "A3", "D4")],
  [1440, notes("G2", "D3", "F#3", "B3")],
  [1680, notes("A2", "E3", "G3", "C#4")],
  [1920, notes("D3", "A3", "E4", "F#4")],
  [2160, notes("G2", "D3", "F#3", "B3")],
  [2280, notes("A2", "E3", "A3", "C#4")],
  [2400, notes("D3", "A3", "D4", "F#4")], // the end card: home
];
/** the arpeggio over each chord, one note per 8th (15 f): root, fifth, the colour note, the fifth, up and back */
const ARP: Record<number, number[]> = {
  0: notes("D4", "A4", "E5", "A4", "F#4", "A4", "E5", "A4"),
  240: notes("B3", "F#4", "D5", "F#4", "A4", "F#4", "D5", "F#4"),
  480: notes("G3", "D4", "B4", "D4", "F#4", "D4", "B4", "D4"),
  720: notes("A3", "E4", "C#5", "E4", "G4", "E4", "C#5", "E4"),
  2160: notes("G3", "D4", "B4", "D4", "F#4", "D4", "B4", "D4"),
  2280: notes("A3", "E4", "C#5", "E4", "A4", "E4", "C#5", "E4"),
  2400: notes("D4", "A4", "F#5", "A4", "D5", "A4", "F#5", "A4"),
};
const arpAt = (f0: number) => ARP[f0] ?? ARP[f0 % 960];
/** crest control for percussive voices (audio/sfx/build.ts): normalise, soft-saturate, normalise. Never on tonal ones */
const tame = (x: Float32Array, drive = 3) => norm(sat(norm(x, 0), drive), 0);

function sh(cmd: string, args: string[]) {
  const r = spawnSync(cmd, args, { encoding: "utf8", stdio: "pipe", maxBuffer: 1 << 26 });
  if (r.status !== 0) throw new Error(`${cmd} ${args.join(" ")} failed\n${r.stderr ?? ""}`);
  return r.stderr ?? "";
}
/** BS.1770 integrated loudness and true peak, as ffmpeg's ebur128 measures them (audio/build.ts) */
function measure(t: Stereo, tmp = "out/audio/.demo-measure.wav") {
  writeWav24(tmp, t);
  const log = sh("ffmpeg", ["-hide_banner", "-nostats", "-i", tmp, "-af", "ebur128=peak=true:framelog=quiet", "-f", "null", "-"]);
  rmSync(tmp, { force: true });
  const last = (re: RegExp) => Number([...log.matchAll(re)].at(-1)?.[1] ?? NaN);
  return { I: last(/I:\s+(-?[\d.]+) LUFS/g), TP: last(/Peak:\s+(-?[\d.]+) dBFS/g) };
}
function scale(t: Stereo, g: number) {
  for (let i = 0; i < t.L.length; i++) {
    t.L[i] *= g;
    t.R[i] *= g;
  }
  return t;
}
/** set a stem to an integrated loudness; returns what it measured before */
const level = (t: Stereo, lufs: number) => {
  const before = measure(t).I;
  scale(t, dbToGain(lufs - before));
  return before;
};

function bed(): Stereo {
  const pad = stereo(LEN);
  const arp = stereo(LEN);
  const drum = stereo(LEN);
  // the pad: glass partials (airy, light), high-passed under 110 Hz
  CHORDS.forEach(([f0, voicing], k) => {
    const f1 = k + 1 < CHORDS.length ? CHORDS[k + 1][0] : FADE[1];
    const len = smp(f1 - f0) + smp(10); // the next chord takes over in its attack: no gap, no swell
    const g = glassPad(voicing, len, { atk: smp(k ? 18 : 45), rel: smp(16), seed: 300 + k });
    placeStereo(pad, { L: onepole(g.L, 110, "hp"), R: onepole(g.R, 110, "hp") }, smp(f0));
  });
  // the plucked 8th-note arpeggio and the soft kick on 2 and 4 come in with segment 2, stop when the end card holds
  for (let f = SEG.counter; f < END.hold; f += 15) {
    const block = CHORDS.filter(([f0]) => f0 <= f).at(-1)![0];
    const step = ((f - block) / 15) % 8;
    const accent = step % 4 === 0;
    place(arp, tame(pluck(arpAt(block)[step], accent ? 0.5 : 0.42, { t60: 0.5, tone: 0.42, exc: 2400, seed: 40 + step }), 2), smp(f), accent ? 1 : 0.86, step % 2 ? 0.22 : -0.22);
  }
  for (let f = SEG.counter; f < FADE[0]; f += 120) {
    place(drum, tame(kick(0.55, 500 + f), 3.5), smp(f + 30), 1);
    place(drum, tame(kick(0.5, 501 + f), 3.5), smp(f + 90), 0.9);
  }
  // balance by measured loudness (LUFS of each voice alone), then one shared room
  const parts: Array<[Stereo, number, number]> = [
    [pad, -23, -10], // [voice, its LUFS, its reverb send dB]: the loudness comes from the sustained pad, not the peaks
    [arp, -27, -8],
    [drum, -33, -Infinity],
  ];
  const bus = stereo(LEN);
  const send = stereo(LEN);
  for (const [t, lufs, sendDb] of parts) {
    level(t, lufs);
    placeStereo(bus, t, 0);
    if (sendDb > -90) placeStereo(send, t, 0, dbToGain(sendDb));
  }
  placeStereo(bus, reverb(send, [[0, LEN]], { room: 0.82, damp: 0.35, lp: 5200, hp: 220 }), 0);
  // fade out, then exact zero
  const a = smp(FADE[0]);
  const b = smp(FADE[1]);
  for (let i = a; i < LEN; i++) {
    const g = i >= b ? 0 : 0.5 + 0.5 * Math.cos((Math.PI * (i - a)) / (b - a));
    bus.L[i] *= g;
    bus.R[i] *= g;
  }
  return bus;
}

/** the foley, every voice on a picture cue at its FOLEY gain (titles pan left, callouts to their side) */
const HITS: Array<[keyof typeof FOLEY, number]> = []; // [kind, frame], for the calibration readout
function foley(): { small: Stereo; bell: Stereo } {
  const small = stereo(LEN);
  const put = (kind: keyof typeof FOLEY, x: Float32Array, f: number, pan = 0) => {
    HITS.push([kind, f]);
    place(small, x, smp(f), dbToGain(FOLEY[kind]), pan);
  };
  // a title's tick lands as its wipe completes (16 f; the hook's 20 / 18 f), clear of the riffle of the cut before it
  [HOOK.wordmark + 20, HOOK.sub + 18, ...TITLE_CUES.map(([, at]) => at + 16)].forEach((f, k) => put("tick", tame(microTick(rand(900 + k)), 4), f, -0.3));
  CALLOUT_CUES.forEach((c, k) => put("click", tame(paperClick(rand(940 + k)), 5), c.in + 8, c.side === "right" ? 0.3 : -0.3)); // the card lands
  TAPS.forEach((f, k) => put("pop", tame(airPop(rand(960 + k)), 3), f)); // in-phone taps
  for (const [k, s] of SHOTS.entries()) if (s.join) put("riffle", tame(cardFlutter(rand(980 + k), smp(Math.max(10, s.join.dur))), 7), s.from); // every cut
  // a gentle 9 kHz top: the kit's clicks are close-miked and spiky up there, which AAC turns into true-peak overshoot
  for (const ch of [small.L, small.R]) ch.set(lp(lp(ch, 9000), 9000));
  const bell = stereo(LEN);
  place(bell, hp(ting(rand(999)), 140), smp(END.ting), 1); // the glass only: its D1 boom is below what a laptop plays and eats headroom
  return { small, bell };
}

mkdirSync("out/audio", { recursive: true });
const music = bed();
const bedRaw = level(music, BED);
const { small, bell } = foley();
const foleyLvl = measure(small).I;
level(bell, TING);
const sum = stereo(LEN);
for (let i = 0; i < LEN; i++) {
  sum.L[i] = music.L[i] + small.L[i] + bell.L[i];
  sum.R[i] = music.R[i] + small.R[i] + bell.R[i];
}

// −14 LUFS integrated, true peak ≤ −1 dBTP: gain + the look-ahead limiter of audio/build.ts, iterated
const tp = truePeak(sum);
const raw = measure(sum);
let gDb = TARGET - raw.I;
let ceilDb = -1.5; // 0.3 dB lower than the film's: the AAC delivery adds ~0.4 dB of true peak on the foley's clicks
let out = sum;
let m = raw;
let lim = new Float32Array(LEN);
for (let it = 0; it < 6; it++) {
  lim = limitGain(tp, dbToGain(gDb), dbToGain(ceilDb));
  out = stereo(LEN);
  for (let i = 0; i < LEN; i++) {
    const g = i >= SILENT ? 0 : dbToGain(gDb) * lim[i];
    out.L[i] = sum.L[i] * g;
    out.R[i] = sum.R[i] * g;
  }
  m = measure(out);
  const okI = Math.abs(m.I - TARGET) <= 0.05;
  const okTP = m.TP <= -1.0;
  if (okI && okTP) break;
  if (!okI) gDb += TARGET - m.I;
  if (!okTP) ceilDb -= m.TP + 1.0 + 0.05;
}
if (Math.abs(m.I - TARGET) > 0.05 || m.TP > -1.0) throw new Error(`demo master missed the target: ${JSON.stringify(m)}`);
for (let i = SILENT; i < LEN; i++) if (out.L[i] !== 0 || out.R[i] !== 0) throw new Error(`sample ${i} must be digital zero`);
writeWav24("out/audio/demo-master.wav", out);
// calibration: each hit's level over the bed in the 100 ms after it (RMS dB), by kind — the "just above the bed" check
const rms = (t: Stereo, a: number, n: number) => {
  let e = 0;
  for (let i = a; i < a + n; i++) e += t.L[i] ** 2 + t.R[i] ** 2;
  return 10 * Math.log10(e / (2 * n) + 1e-20);
};
const over: Record<string, number[]> = {};
for (const [kind, f] of HITS) (over[kind] ??= []).push(rms(small, smp(f), smp(6)) - rms(music, smp(f), smp(6)));
const med = (v: number[]) => [...v].sort((x, y) => x - y)[Math.floor(v.length / 2)];
// the limiter's work, per frame: runs limited by more than 1 dB and their deepest reduction (audio/build.ts)
const spans: string[] = [];
let from = -1;
let deep = 1;
for (let f = 0; f <= DEMO.total; f++) {
  const lo = f < DEMO.total ? Math.min(...lim.subarray(f * SPF, (f + 1) * SPF)) : 1;
  if (lo < dbToGain(-1)) {
    if (from < 0) from = f;
    deep = Math.min(deep, lo);
  } else if (from >= 0) {
    spans.push(`f${from}–${f - 1} ${(-20 * Math.log10(deep)).toFixed(1)} dB`);
    [from, deep] = [-1, 1];
  }
}
console.log(
  [
    `bed          ${BED} LUFS (composed at ${bedRaw}) · foley ${foleyLvl} LUFS (its own blocks) · ting ${TING} LUFS · sum ${raw.I} LUFS`,
    `foley/bed    ${Object.entries(over).map(([k, v]) => `${k} ${med(v) >= 0 ? "+" : ""}${med(v).toFixed(1)} dB`).join(" · ")} (median over the 100 ms after each hit)`,
    `limiter      > 1 dB: ${spans.join(", ") || "none"}`,
    `master       I ${m.I} LUFS · TP ${m.TP} dBTP · gain ${gDb.toFixed(2)} dB · ceiling ${ceilDb.toFixed(2)} dB · ${out.L.length} samples (${out.L.length / SPF} f)`,
  ].join("\n"),
);
