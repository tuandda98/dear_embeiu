// Technical check of the 9:16 cut (last step of scripts/render-vertical.sh; exit 1 on any miss):
// 1200 frames · 20.000 s · 1080×1920 · 60 fps (30 for the upload copy) · −14 LUFS ±0.1 (±0.3 upload) · ≤ −1 dBTP ·
// the upload copy ≤ 9.5 MB.
import { spawnSync } from "node:child_process";
import { existsSync, statSync } from "node:fs";

const D = "out/deliver";
const NAME = "dear-embeiu-vertical-20s";
let bad = 0;
const ok = (cond: boolean, what: string) => {
  console.log(`${cond ? "✓" : "✗"} ${what}`);
  if (!cond) bad++;
};
type Stream = Record<string, string | number | undefined>;
const probe = (f: string): { streams: Stream[]; format: Stream } =>
  JSON.parse(spawnSync("ffprobe", ["-v", "error", "-count_frames", "-show_streams", "-show_format", "-of", "json", f], { encoding: "utf8" }).stdout);
const loud = (f: string) => {
  const log = spawnSync("ffmpeg", ["-hide_banner", "-nostats", "-i", f, "-map", "0:a", "-af", "ebur128=peak=true:framelog=quiet", "-f", "null", "-"], { encoding: "utf8" }).stderr;
  const last = (re: RegExp) => Number([...log.matchAll(re)].at(-1)?.[1] ?? NaN);
  return { I: last(/I:\s+(-?[\d.]+) LUFS/g), TP: last(/Peak:\s+(-?[\d.]+) dBFS/g) };
};

for (const [file, fps, frames, tol] of [[`${D}/${NAME}.mp4`, "60/1", 1200, 0.1], [`${D}/${NAME}_threads.mp4`, "30/1", 600, 0.3]] as const) {
  if (!existsSync(file)) {
    ok(false, `${file} missing`);
    continue;
  }
  const p = probe(file);
  const v = p.streams.find((s) => s.codec_type === "video")!;
  const a = p.streams.find((s) => s.codec_type === "audio");
  console.log(file);
  ok(v.codec_name === "h264", `  video ${v.codec_name} ${v.profile ?? ""} ${v.pix_fmt} · ${(Number(v.bit_rate) / 1e6).toFixed(1)} Mbps`);
  ok(v.width === 1080 && v.height === 1920, `  ${v.width}×${v.height}`);
  ok(v.r_frame_rate === fps, `  ${v.r_frame_rate} fps`);
  ok(Number(v.nb_read_frames ?? v.nb_frames) === frames, `  ${v.nb_read_frames ?? v.nb_frames} frames`);
  ok(Math.abs(Number(p.format.duration) - 20) < 0.05, `  ${p.format.duration} s`);
  ok(a?.codec_name === "aac" && a?.sample_rate === "48000" && a?.channels === 2, `  audio ${a?.codec_name} ${a?.sample_rate} Hz · ${a?.channels} ch · ${Number(a?.bit_rate) / 1000} kb/s`);
  const l = loud(file);
  ok(Math.abs(l.I + 14) <= tol && l.TP <= -1, `  ${l.I} LUFS integrated · ${l.TP} dBTP`);
  if (file.endsWith("_threads.mp4")) ok(statSync(file).size <= 9.5e6, `  ${(statSync(file).size / 1e6).toFixed(2)} MB (≤ 9.5 for the browser upload)`);
}
ok(existsSync(`${D}/${NAME}_poster.png`), `${D}/${NAME}_poster.png`);

console.log(bad ? `\n${bad} check(s) failed` : "\nall vertical checks passed");
process.exit(bad ? 1 : 0);
