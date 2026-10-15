// Technical check of every delivery file against brief §3 (last step of scripts/render.sh; exit 1 on any miss).
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";

const D = "out/deliver";
const NAME = "dear-embeiu-launch-50s";
let bad = 0;
const ok = (cond: boolean, what: string) => {
  console.log(`${cond ? "✓" : "✗"} ${what}`);
  if (!cond) bad++;
};
type Stream = Record<string, string | number | undefined>;
const probe = (f: string): { streams: Stream[]; format: Stream } =>
  JSON.parse(spawnSync("ffprobe", ["-v", "error", "-show_streams", "-show_format", "-of", "json", f], { encoding: "utf8" }).stdout);
const loud = (f: string) => {
  const log = spawnSync("ffmpeg", ["-hide_banner", "-nostats", "-i", f, "-map", "0:a", "-af", "ebur128=peak=true:framelog=quiet", "-f", "null", "-"], {
    encoding: "utf8",
  }).stderr;
  const last = (re: RegExp) => Number([...log.matchAll(re)].at(-1)?.[1] ?? NaN);
  return { I: last(/I:\s+(-?[\d.]+) LUFS/g), TP: last(/Peak:\s+(-?[\d.]+) dBFS/g) };
};

for (const [file, codec] of [
  [`${D}/${NAME}_prores422hq.mov`, "prores"],
  [`${D}/${NAME}_h264.mp4`, "h264"],
]) {
  if (!existsSync(file)) {
    ok(false, `${file} missing`);
    continue;
  }
  const p = probe(file);
  const v = p.streams.find((s) => s.codec_type === "video")!;
  const a = p.streams.find((s) => s.codec_type === "audio")!;
  console.log(file);
  ok(v.codec_name === codec, `  video ${v.codec_name} ${v.profile ?? ""} ${v.pix_fmt}`);
  ok(v.width === 1920 && v.height === 1080, `  ${v.width}×${v.height}`);
  ok(v.r_frame_rate === "60/1", `  ${v.r_frame_rate} fps`);
  ok(Number(v.nb_frames) === 3000, `  ${v.nb_frames} frames`);
  ok(Math.abs(Number(p.format.duration) - 50) < 0.025, `  ${p.format.duration} s`);
  ok(v.color_space === "bt709" && v.color_primaries === "bt709" && v.color_transfer === "bt709", `  colour ${v.color_space}/${v.color_primaries}/${v.color_transfer}`);
  if (codec === "prores") {
    ok(v.profile === "HQ" && v.pix_fmt === "yuv422p10le", `  ProRes 422 HQ 10-bit`);
    ok(a?.codec_name === "pcm_s24le", `  audio ${a?.codec_name}`);
  } else {
    ok(Number(v.bit_rate) >= 20e6, `  video ${(Number(v.bit_rate) / 1e6).toFixed(1)} Mbps (≥ 20)`);
    ok(a?.codec_name === "aac", `  audio ${a?.codec_name} ${Number(a?.bit_rate) / 1000} kb/s`);
  }
  ok(a?.sample_rate === "48000" && a?.channels === 2, `  ${a?.sample_rate} Hz · ${a?.channels} ch`);
  const l = loud(file);
  ok(Math.abs(l.I + 14) <= 0.1 && l.TP <= -1, `  ${l.I} LUFS integrated · ${l.TP} dBTP`);
}

for (const s of ["music", "sfx"]) {
  const f = `${D}/stems/${NAME}_${s}.wav`;
  const a = existsSync(f) ? probe(f).streams[0] : undefined;
  ok(a?.codec_name === "pcm_s24le" && a?.sample_rate === "48000" && a?.channels === 2 && Number(a?.duration_ts) === 2_400_000, `${f}: ${a?.codec_name} ${a?.sample_rate} Hz ${a?.channels} ch ${a?.duration_ts} samples`);
}
const poster = `${D}/${NAME}_poster.png`;
const ps = existsSync(poster) ? probe(poster).streams[0] : undefined;
ok(ps?.codec_name === "png" && ps?.width === 1920 && ps?.height === 1080, `${poster}: ${ps?.width}×${ps?.height}`);
const srt = `${D}/${NAME}.vi.srt`;
const cues = existsSync(srt) ? readFileSync(srt, "utf8").split(/\n\n/).filter((c) => / --> /.test(c)).length : 0;
ok(cues > 0, `${srt}: ${cues} cues`);

console.log(bad ? `\n${bad} check(s) failed` : "\nall delivery checks passed");
process.exit(bad ? 1 : 0);
