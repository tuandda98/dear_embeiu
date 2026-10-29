// The voice-over stem: the lines of public/vo/<set>/index.json (rendered by scripts/vo.sh) placed on their frames,
// mono → centre, with a sidechain envelope the music/SFX are ducked by (DESIGN §7 addendum: VO sits on top; beds dip
// 7 dB under it with 120 ms attack / 350 ms release so nothing pumps). Deterministic: no randomness.
import { existsSync, readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { LEN, SR, smp, stereo, type Stereo } from "./core.ts";

export type VoIndex = { id: string; at: number; file: string; duration: number }[];

/** read a wav (any format ffmpeg can open) as 48 kHz mono float samples */
function readMono(path: string): Float32Array {
  const r = spawnSync("ffmpeg", ["-v", "error", "-i", path, "-f", "f32le", "-acodec", "pcm_f32le", "-ac", "1", "-ar", String(SR), "-"], { maxBuffer: 1 << 28 });
  if (r.status !== 0) throw new Error(`ffmpeg could not read ${path}: ${r.stderr}`);
  return new Float32Array(r.stdout.buffer, r.stdout.byteOffset, r.stdout.length / 4);
}

/** the VO stem for a set ("film" | "demo"), at `gainDb`, plus its duck envelope (1 = no duck, `duck` under speech) */
export function voStem(set: string, { gainDb = -3, duck = 10 ** (-7 / 20), fadeMs = 12, len = LEN } = {}): { vo: Stereo; env: Float32Array; lines: VoIndex } {
  const idx = `public/vo/${set}/index.json`;
  const lines: VoIndex = existsSync(idx) ? JSON.parse(readFileSync(idx, "utf8")) : [];
  const vo = stereo(len);
  const g = 10 ** (gainDb / 20);
  const fade = Math.round((fadeMs * SR) / 1000);
  const active = new Uint8Array(len);
  for (const l of lines) {
    const x = readMono(`public/${l.file}`);
    const at = smp(l.at);
    for (let i = 0; i < x.length && at + i < len; i++) {
      const e = Math.min(1, i / fade, (x.length - 1 - i) / fade); // tiny edge fades, no clicks
      const v = x[i] * g * e;
      vo.L[at + i] += v;
      vo.R[at + i] += v;
    }
    active.fill(1, at, Math.min(len, at + x.length));
  }
  // duck envelope: attack 120 ms, release 350 ms (one-pole), from the speech gate
  const aA = Math.exp(-1 / (0.12 * SR));
  const aR = Math.exp(-1 / (0.35 * SR));
  const env = new Float32Array(len);
  let cur = 1;
  for (let i = 0; i < len; i++) {
    const target = active[i] ? duck : 1;
    cur = target < cur ? target + (cur - target) * aA : target + (cur - target) * aR;
    env[i] = cur;
  }
  return { vo, env, lines };
}
