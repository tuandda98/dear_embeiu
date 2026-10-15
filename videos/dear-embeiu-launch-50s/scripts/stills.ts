// node scripts/stills.ts <name> <frames…> [--scale=0.5]
//   frames: 600 720 1200   or ranges a-b:step (e.g. 240-720:30)
// Bundles once, renders JPEGs to out/stills/<name>/fNNNN.jpg and a contact sheet out/stills/<name>/sheet.jpg (4 per row).
import path from "node:path";
import { mkdirSync, readdirSync, rmSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { bundle } from "@remotion/bundler";
import { openBrowser, renderStill, selectComposition } from "@remotion/renderer";

const args = process.argv.slice(2);
const flags = Object.fromEntries(args.filter((a) => a.startsWith("--")).map((a) => a.slice(2).split("=")));
const [name, ...spec] = args.filter((a) => !a.startsWith("--"));
if (!name || !spec.length) throw new Error("usage: node scripts/stills.ts <name> <frames…> [--scale=0.5]");
const frames = spec.flatMap((s) => {
  const m = s.match(/^(\d+)-(\d+):(\d+)$/);
  if (!m) return [Number(s)];
  const out: number[] = [];
  for (let f = +m[1]; f <= +m[2]; f += +m[3]) out.push(f);
  return out;
});
const scale = Number(flags.scale ?? 0.5);
const dir = path.resolve("out/stills", name);
mkdirSync(dir, { recursive: true });
for (const f of readdirSync(dir)) rmSync(path.join(dir, f));

const chromiumOptions = { gl: "angle" as const };
const serveUrl = await bundle({ entryPoint: path.resolve("src/index.ts"), enableCaching: false });
const browser = await openBrowser("chrome", { chromiumOptions });
const composition = await selectComposition({ serveUrl, id: process.env.COMP ?? "Film", puppeteerInstance: browser, chromiumOptions });
for (const frame of frames) {
  const output = path.join(dir, `f${String(frame).padStart(4, "0")}.jpg`);
  await renderStill({ serveUrl, composition, frame, output, imageFormat: "jpeg", jpegQuality: 92, scale, puppeteerInstance: browser, chromiumOptions, overwrite: true });
  console.log(output);
}
await browser.close({ silent: true });
rmSync(serveUrl, { recursive: true, force: true }); // bundles are not cached: keep the disk clean
if (frames.length > 1) {
  const rows = Math.ceil(frames.length / 4);
  execFileSync("ffmpeg", ["-y", "-loglevel", "error", "-pattern_type", "glob", "-i", path.join(dir, "f*.jpg"), "-vf", `scale=480:-1,tile=4x${rows}:padding=6:color=0x303030`, "-frames:v", "1", path.join(dir, "sheet.jpg")]);
  console.log(path.join(dir, "sheet.jpg"));
}
