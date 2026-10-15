// node audio/music/build.ts (project root) → out/audio/music.wav. Deterministic, no packages.
import { mkdirSync } from "node:fs";
import { LEN, SPF, enforceSilence, writeWav24, peakDb } from "../core.ts";
import { compose } from "./score.ts";

const t0 = performance.now();
const mix = compose();
const peak = peakDb(mix);
if (peak > -1) {
  const g = 10 ** ((-1.05 - peak) / 20);
  for (let i = 0; i < LEN; i++) {
    mix.L[i] *= g;
    mix.R[i] *= g;
  }
  console.warn(`music peak ${peak.toFixed(2)} dBFS > -1: scaled by ${(20 * Math.log10(g)).toFixed(2)} dB`);
}
enforceSilence(mix);
mkdirSync("out/audio", { recursive: true });
writeWav24("out/audio/music.wav", mix);
console.log(`music.wav · ${mix.L.length / SPF} f · peak ${peakDb(mix).toFixed(2)} dBFS · ${((performance.now() - t0) / 1000).toFixed(1)} s`);
