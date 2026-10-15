// Shared by audio/music and audio/sfx (Node 25, plain TS). Sample-accurate frame mapping and 24-bit WAV I/O.
import { readFileSync, writeFileSync } from "node:fs";

export const SR = 48000;
export const SPF = 800; // samples per video frame (48000 / 60)
export const LEN = 3000 * SPF; // 2 400 000 samples = 50.000 s
export const smp = (f: number) => Math.round(f * SPF); // frame -> sample
/** mandatory exact digital zero: the one hard cut, Act 4 → Act 5 (32.0–32.5 s, nothing rings across it) and 49.8–50.0 s */
export const SILENCE = [
  [smp(1920), smp(1950)],
  [smp(2988), LEN],
] as const;

export type Stereo = { L: Float32Array; R: Float32Array };
export const stereo = (n = LEN): Stereo => ({ L: new Float32Array(n), R: new Float32Array(n) });
export const dbToGain = (db: number) => 10 ** (db / 20);

/** add a mono buffer at sample `at` with gain and equal-power pan (−1 … 1) */
export function place(dst: Stereo, src: Float32Array, at: number, gain = 1, pan = 0) {
  const a = ((Math.max(-1, Math.min(1, pan)) + 1) * Math.PI) / 4;
  const gl = Math.cos(a) * gain;
  const gr = Math.sin(a) * gain;
  const end = Math.min(src.length, dst.L.length - at);
  for (let i = Math.max(0, -at); i < end; i++) {
    dst.L[at + i] += src[i] * gl;
    dst.R[at + i] += src[i] * gr;
  }
}

/** add a stereo buffer at sample `at` */
export function placeStereo(dst: Stereo, src: Stereo, at: number, gain = 1) {
  const end = Math.min(src.L.length, dst.L.length - at);
  for (let i = Math.max(0, -at); i < end; i++) {
    dst.L[at + i] += src.L[i] * gain;
    dst.R[at + i] += src.R[i] * gain;
  }
}

/** write the mandatory silences (call last, after every voice is placed) */
export function enforceSilence(t: Stereo) {
  for (const [a, b] of SILENCE) {
    t.L.fill(0, a, b);
    t.R.fill(0, a, b);
  }
}

export function peakDb(t: Stereo) {
  let p = 0;
  for (let i = 0; i < t.L.length; i++) p = Math.max(p, Math.abs(t.L[i]), Math.abs(t.R[i]));
  return 20 * Math.log10(p || 1e-12);
}

/** 24-bit PCM stereo WAV, no dither (silence stays exact zero) */
export function writeWav24(path: string, t: Stereo) {
  const n = t.L.length;
  const bytes = n * 6;
  const b = Buffer.alloc(44 + bytes);
  b.write("RIFF", 0);
  b.writeUInt32LE(36 + bytes, 4);
  b.write("WAVEfmt ", 8);
  b.writeUInt32LE(16, 16);
  b.writeUInt16LE(1, 20);
  b.writeUInt16LE(2, 22);
  b.writeUInt32LE(SR, 24);
  b.writeUInt32LE(SR * 6, 28);
  b.writeUInt16LE(6, 32);
  b.writeUInt16LE(24, 34);
  b.write("data", 36);
  b.writeUInt32LE(bytes, 40);
  let o = 44;
  for (let i = 0; i < n; i++) {
    for (const ch of [t.L, t.R]) {
      const v = Math.max(-8388608, Math.min(8388607, Math.round(ch[i] * 8388607)));
      b.writeIntLE(v, o, 3);
      o += 3;
    }
  }
  writeFileSync(path, b);
}

/** read a 24-bit PCM stereo WAV written by writeWav24 (or ffmpeg -c:a pcm_s24le) */
export function readWav24(path: string): Stereo {
  const b = readFileSync(path);
  let o = 12;
  while (b.toString("ascii", o, o + 4) !== "data") o += 8 + b.readUInt32LE(o + 4);
  const n = b.readUInt32LE(o + 4) / 6;
  const t = stereo(n);
  o += 8;
  for (let i = 0; i < n; i++, o += 6) {
    t.L[i] = b.readIntLE(o, 3) / 8388607;
    t.R[i] = b.readIntLE(o + 3, 3) / 8388607;
  }
  return t;
}
