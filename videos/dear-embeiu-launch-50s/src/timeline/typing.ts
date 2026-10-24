// Human typing: each unit (a word, a line) finishes on its end frame; inside a unit the letters arrive at uneven
// intervals of minGap–maxGap frames (BRIEF §5 act 1: 2–4 f). Deterministic (seeded), so the audio build places a key
// sound on the very same frames. Returns one frame per letter, in order.
import { rng } from "../lib/rand.ts";

export type Keys = { frames: number[]; text: string };

/** letters of `units` (joined by `joiner`) typed so that unit k ends exactly on ends[k] */
export function schedule(units: string[], ends: number[], { seed = 1, minGap = 2, maxGap = 4, joiner = " " } = {}): Keys {
  const r = rng(seed);
  const frames: number[] = [];
  let text = "";
  units.forEach((u, k) => {
    const piece = (k ? joiner : "") + u;
    const gaps = Array.from({ length: piece.length }, () => minGap + Math.floor(r() * (maxGap - minGap + 1)));
    // walk back from the end frame so the last letter lands on ends[k]
    let f = ends[k];
    const unit: number[] = [];
    for (let i = piece.length - 1; i >= 0; i--) {
      unit.unshift(f);
      f -= gaps[i];
    }
    const prevEnd = frames.length ? frames[frames.length - 1] : -Infinity;
    // never earlier than the previous unit's last letter + minGap
    const shift = Math.max(0, prevEnd + minGap - unit[0]);
    frames.push(...unit.map((v) => v + shift));
    text += piece;
  });
  return { frames, text };
}

/** how many letters are on screen at frame f */
export const typedCount = (keys: Keys, f: number) => keys.frames.filter((k) => k <= f).length;
export const typed = (keys: Keys, f: number) => keys.text.slice(0, typedCount(keys, f));
/** letters typed at a constant pace between [from, to], last letter on `to` */
export const even = (text: string, from: number, to: number): Keys => ({
  text,
  frames: Array.from({ length: text.length }, (_, i) => Math.round(from + ((to - from) * i) / Math.max(1, text.length - 1))),
});
