// The streak (BRIEF §5 act 3, 12.0–13.5 s): 31 day cells slide out one from under the other, the count rides the head
// of the strip, a navy flame draws above the newest cell. At A3.chip the strip steps back (×32/46 about its left end,
// as the number steps back in act 2) to make room for its words, the flame tucks in beside it and a frosted pill
// draws around strip + flame + count + words: the product's streak chip, earned rather than stamped on. At A3.collapse
// the whole chip scales into one point between its cells 22 and 30, where the two dots are born (V3 G3: it leaves
// completely before the night covers its place). Reads the frame itself, so <Blur> can sample its fast moves.
import { Easing, useCurrentFrame } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { Digits, digitsWidth, roll } from "../../components/Digits.tsx";
import { C, FONT } from "../../lib/tokens.ts";
import { ease, lerp, settle } from "../../lib/ease.ts";
import { T } from "../../copy/strings.ts";
import { A3 } from "../../timeline/cues.ts";

const N = T.a3.streak;
const NUM = String(N);
const REST = T.a3.chip.slice(NUM.length); // the chip's words after its number (the number is the count)
const TEXT = REST.trimStart();
const TEXT_GAP = REST.startsWith(" ") ? 14 : 3;
const TEXT_SIZE = 32;

// the build: 36 px cells, 10 px gaps, from x 120 on the H720 cell's row (centre y 554); 31 cells end at x 1536
const X0 = 120;
const MID = 554;
const CELL = 36;
const PITCH = 46;
const END = X0 + (N - 1) * PITCH + CELL;
// the chip: the strip at ×32/46, its row centred at y 524 (pill 482–566: 34 px clear of the sky card at y 600)
const S = 32 / 46;
export const CHIP_MID = 524;
const COUNT = 64;
const FLAME = { h: 56, inline: 44, w: 28 / 40 }; // the glyph's box is 28 × 40 (w = width / height)
const END_CHIP = X0 + (END - X0) * S;
const FLAME_CHIP = { x: END_CHIP + 18 + (FLAME.inline * FLAME.w) / 2, y: CHIP_MID };
const COUNT_CHIP = END_CHIP + 18 + FLAME.inline * FLAME.w + 16;
const TEXT_X = COUNT_CHIP + digitsWidth(NUM, COUNT) + TEXT_GAP;
const PILL = { left: X0 - 24, top: CHIP_MID - 42, h: 84, r: 42 };
const capTop = (mid: number, size: number) => mid - 0.525 * size; // Quicksand: cap-height centre 0.525 em below the box top

const STEP = (A3.cells[1] - A3.cells[0]) / (N - 1); // 3 f
const start = (k: number) => A3.cells[0] + k * STEP;
const slide = (f: number, k: number) => (f < start(k) ? 0 : settle(f, start(k), { stiffness: 420, zeta: 0.8 }));
/** the left edge of cell k in the build: each cell slides one pitch out from under the one before it */
const cellLeft = (f: number, k: number) => {
  let x = X0;
  for (let j = 1; j <= k; j++) x += PITCH * slide(f, j);
  return x;
};
const back = (f: number) => (f < A3.chip ? 0 : settle(f, A3.chip, { stiffness: 200, zeta: 0.86 }));
const headOf = (f: number) => Math.max(0, Math.min(N - 1, Math.floor((f - A3.cells[0]) / STEP)));
const countX = (f: number) => lerp(cellLeft(f, headOf(f)) + CELL + 24, COUNT_CHIP, back(f));
/** the centre of cell k once the strip is the chip */
const chipCell = (k: number) => ({ x: X0 + (k * PITCH + CELL / 2) * S, y: CHIP_MID });
/** where the chip collapses to and the two dots are born: between its cells 22 and 30, under the dots' targets */
export const CHIP_POINT = { x: (chipCell(22).x + chipCell(30).x) / 2, y: CHIP_MID };
const gone = (f: number) => Easing.in(Easing.cubic)(Math.min(1, Math.max(0, (f - A3.collapse[0]) / (A3.collapse[1] - A3.collapse[0]))));
/** px per frame of the fastest part (the count while it rides and steps back, the pill's far end while it collapses) */
export const stripSpeed = (f: number) =>
  Math.max(Math.abs(countX(f + 0.5) - countX(f - 0.5)), (CHIP_POINT.x - X0 + 24) * Math.abs(gone(f + 0.5) - gone(f - 0.5)));

// the flame: two strokes in a 28×40 box (outer tongue with a curled tip, inner tongue)
const FLAME_OUTER = "M14 38.5C7 38.5 2.5 33.5 2.5 27C2.5 19.5 8 15 11.5 9C13 6.5 13.6 4 13.4 1.5C20.5 6 25.5 14.5 25.5 24.5C25.5 32.5 20.5 38.5 14 38.5Z";
const FLAME_INNER = "M14 35.5C11 35.5 9 33.2 9 30.4C9 27 11.8 24.6 13.6 20.5C17 23.4 19 26.8 19 30.4C19 33.2 17 35.5 14 35.5Z";

export const Strip: React.FC = () => {
  const f = useCurrentFrame();
  const textW = measureText({ text: TEXT, fontFamily: FONT, fontSize: TEXT_SIZE, fontWeight: 600 }).width;
  const head = headOf(f);
  const c = back(f);
  const s = lerp(1, S, c);
  const mid = lerp(MID, CHIP_MID, c);
  const grow = ease(f, A3.cells[0], A3.cells[0] + 10); // H720's 28 px cell grows into the strip's 36

  // the pill draws from its left cap along both edges; `front` is where its two tips are
  const right = TEXT_X + textW + 30;
  const width = right - PILL.left;
  const { top, h, r, left } = PILL;
  const w = ease(f, A3.chip + 4, A3.chip + 24);
  const arc = (Math.PI * r) / 2;
  const run = w * (width - 2 * r + 2 * arc);
  const front =
    run < arc ? left + r * (1 - Math.cos(run / r)) : run < arc + width - 2 * r ? left + r + (run - arc) : right - r + r * Math.sin((run - arc - (width - 2 * r)) / r);
  const upper = `M${left} ${top + r}A${r} ${r} 0 0 1 ${left + r} ${top}L${right - r} ${top}A${r} ${r} 0 0 1 ${right} ${top + r}`;
  const lower = `M${left} ${top + r}A${r} ${r} 0 0 0 ${left + r} ${top + h}L${right - r} ${top + h}A${r} ${r} 0 0 0 ${right} ${top + r}`;
  const clipTo = (x: number) => `inset(-48px ${Math.max(0, 1920 - x)}px -48px -48px)`;

  const headCx = cellLeft(f, head) + CELL / 2;
  const fh = lerp(FLAME.h, FLAME.inline, c);
  const flame = { x: lerp(headCx, FLAME_CHIP.x, c), y: lerp(MID - CELL / 2 - 8 - FLAME.h / 2, FLAME_CHIP.y, c) };
  const outer = ease(f, A3.flame[0], A3.flame[0] + 20);
  const inner = ease(f, A3.flame[0] + 14, A3.flame[1]);
  const countIn = ease(f, A3.cells[0] + 1, A3.cells[0] + 9); // the number rises into its slot (masked)
  const countTop = lerp(capTop(MID, COUNT), capTop(CHIP_MID, COUNT), c);

  const k = 1 - gone(f);
  if (k <= 0) return null;
  return (
    <div style={{ position: "absolute", inset: 0, transformOrigin: `${CHIP_POINT.x}px ${CHIP_POINT.y}px`, transform: k < 1 ? `scale(${k})` : undefined }}>
      {w > 0 && (
        <div style={{ position: "absolute", inset: 0, clipPath: clipTo(front) }}>
          <div style={{ position: "absolute", left, top, width, height: h, borderRadius: r, background: C.white, boxShadow: `inset 0 0 0 1px rgba(255,255,255,0.65), ${C.shadow}` }} />
        </div>
      )}
      {Array.from({ length: head + 1 }, (_, k) => head - k).map((k) => {
        const size = (k === 0 ? lerp(28, CELL, grow) : CELL) * s;
        const radius = (k === 0 ? lerp(6, 8, grow) : 8) * s;
        return (
          <div key={k} style={{ position: "absolute", left: X0 + (cellLeft(f, k) - X0) * s, top: mid - size / 2, width: size, height: size, borderRadius: radius, background: C.ink }} />
        );
      })}
      {w > 0 && (
        <svg style={{ position: "absolute", left: 0, top: 0 }} width={1920} height={1080}>
          {[upper, lower].map((d) => (
            <path key={d} d={d} fill="none" stroke={`${C.ink3}99`} strokeWidth={1} pathLength={1} strokeDasharray={1} strokeDashoffset={1 - w} />
          ))}
        </svg>
      )}
      {outer > 0 && (
        <svg style={{ position: "absolute", left: flame.x - (fh * FLAME.w) / 2, top: flame.y - fh / 2, overflow: "visible" }} width={fh * FLAME.w} height={fh} viewBox="0 0 28 40">
          <path d={FLAME_OUTER} fill="none" stroke={C.ink} strokeWidth={2.4} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - outer} />
          {inner > 0 && <path d={FLAME_INNER} fill="none" stroke={C.ink} strokeWidth={2.4} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - inner} />}
        </svg>
      )}
      {countIn > 0 && (
        <div style={{ position: "absolute", left: countX(f), top: countTop, height: COUNT, overflow: "hidden" }}>
          <Digits value={roll(1, N, f - STEP / 2, A3.cells[0], A3.cells[1])} size={COUNT} weight={700} color={C.ink} style={{ transform: `translateY(${(1 - countIn) * COUNT}px)` }} />
        </div>
      )}
      {w > 0 && (
        <div style={{ position: "absolute", inset: 0, clipPath: clipTo(front) }}>
          {/* the words ride the count's live right edge (+ the final gap), so they never touch it while it steps back;
              once the count has settled this is exactly TEXT_X */}
          <div style={{ position: "absolute", left: countX(f) + digitsWidth(NUM, COUNT) + TEXT_GAP, top: capTop(CHIP_MID, COUNT) + 0.875 * COUNT - 0.875 * TEXT_SIZE, fontSize: TEXT_SIZE, lineHeight: 1, fontWeight: 600, color: C.ink, whiteSpace: "nowrap" }}>
            {TEXT}
          </div>
        </div>
      )}
    </div>
  );
};
