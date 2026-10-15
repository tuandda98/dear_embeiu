// Act 6 · the range (v3): eight feature cards, nothing else — then the two dots enter at the bottom edge and everything
// recedes into the centre while they travel to their touch (H2640). Layers read the frame themselves (they may sit
// inside <Blur>).
import { AbsoluteFill, Easing, useCurrentFrame } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { Dot } from "../../components/Dot.tsx";
import { T } from "../../copy/strings.ts";
import { ease, lerp, settle } from "../../lib/ease.ts";
import { C, FONT } from "../../lib/tokens.ts";
import { A6 } from "../../timeline/cues.ts";
import { softWipe } from "../a5/wipe.ts";
import { GLYPHS } from "./Glyphs.tsx";
import { CARDS, DOTS, TOUCH } from "./layout.ts";

const FILL = { rose: "#FFF1F4", lavender: "#F3EFFD" } as const; // rose 8 % / lavender 10 % on white
const speed = (fn: (x: number) => number, f: number) => Math.abs(fn(f + 0.25) - fn(f - 0.25)) * 2;
const textW = (text: string, size: number, weight: number, letterSpacing?: string) =>
  Math.max(...text.split("\n").map((line) => measureText({ text: line, fontFamily: FONT, fontSize: size, fontWeight: weight, letterSpacing }).width));

/** the recede: 1 → 0 into the frame centre, accelerating, gone before the dots meet */
const recedeAt = (f: number) => 1 - ease(f, A6.recede[0], A6.recede[0] + 36, Easing.in(Easing.cubic));
export const gridFast = (f: number) => speed(recedeAt, f) * 900 > 20; // the far card corners sit ~900 px from the centre

/** the dots: in from the frame edges at y 960 (A6.dots), then together to the touch, landing at rest on 2639 */
function dotsAt(f: number) {
  const m = ease(f, A6.recede[0], A6.recede[1] - 1, Easing.inOut(Easing.cubic));
  if (m >= 1) return { you: TOUCH.you, other: TOUCH.other };
  const a = ease(f, A6.dots[0], A6.dots[1]);
  const you = lerp(-3 * TOUCH.r, DOTS.you, a);
  const other = lerp(1920 + 3 * TOUCH.r, DOTS.other, a);
  return {
    you: { x: lerp(you, TOUCH.you.x, m), y: lerp(DOTS.y, TOUCH.you.y, m) },
    other: { x: lerp(other, TOUCH.other.x, m), y: lerp(DOTS.y, TOUCH.other.y, m) },
  };
}
export const dotsFast = (f: number) =>
  Math.max(speed((x) => dotsAt(x).you.x, f), speed((x) => dotsAt(x).you.y, f), speed((x) => dotsAt(x).other.x, f)) > 20;

/** card k lands on its cue (settle + a top-down reveal); 6 f later its circle pops and the glyph plays, the title wipes
 * in, the benefit 6 f after that. Fills alternate like a checkerboard. */
const Card: React.FC<{ k: number; f: number }> = ({ k, f }) => {
  const g = A6.glyphs[k];
  if (f < g) return null;
  const col = k % 4;
  const row = Math.floor(k / 4);
  const rose = (col + row) % 2 === 0;
  const ground = rose ? C.rose : C.lavender;
  const p = settle(f, g, { stiffness: 190, zeta: 0.8 });
  const reveal = ease(f, g, g + 8);
  const ring = settle(f, g + 6, { stiffness: 240, zeta: 0.75 });
  const Glyph = GLYPHS[k];
  const title = T.a6.glyphs[k];
  const benefit = T.a6.benefits[k];
  return (
    <div
      style={{
        position: "absolute",
        left: CARDS.cols[col],
        top: CARDS.rows[row],
        width: CARDS.w,
        height: CARDS.h,
        borderRadius: CARDS.r,
        background: rose ? FILL.rose : FILL.lavender,
        transform: Math.abs(1 - p) < 1e-4 ? undefined : `translateY(${(1 - p) * 28}px) scale(${0.92 + 0.08 * p})`,
        clipPath: reveal < 1 ? `inset(0 0 ${(1 - reveal) * 100}% 0 round ${CARDS.r}px)` : undefined,
      }}
    >
      {f >= g + 6 && (
        <div style={{ position: "absolute", left: CARDS.pad, top: CARDS.pad, width: CARDS.circle, height: CARDS.circle, borderRadius: CARDS.circle / 2, background: ground, transform: Math.abs(1 - ring) < 1e-4 ? undefined : `scale(${ring})` }}>
          <div style={{ position: "absolute", left: (CARDS.circle - CARDS.icon) / 2, top: (CARDS.circle - CARDS.icon) / 2, width: CARDS.icon, height: CARDS.icon }}>
            <Glyph t={f - g - 6} ground={ground} />
          </div>
        </div>
      )}
      {f >= g + 6 && (
        <div style={{ position: "absolute", left: CARDS.pad, top: CARDS.titleTop, fontSize: 40, fontWeight: 700, lineHeight: "50px", letterSpacing: "-0.01em", color: C.ink, whiteSpace: "nowrap", ...softWipe(ease(f, g + 6, g + 20), textW(title, 40, 700, "-0.01em"), 64) }}>
          {title}
        </div>
      )}
      {f >= g + 12 && (
        <div style={{ position: "absolute", left: CARDS.pad, top: CARDS.benefitTop, fontSize: 28, fontWeight: 500, lineHeight: "35px", color: C.ink2, whiteSpace: "pre", ...softWipe(ease(f, g + 12, g + 28), textW(benefit, 28, 500), 64) }}>
          {benefit}
        </div>
      )}
    </div>
  );
};

export const GridLayer: React.FC = () => {
  const f = useCurrentFrame();
  const s = recedeAt(f);
  if (s <= 0.004) return null;
  return (
    <AbsoluteFill style={s < 1 ? { transformOrigin: "960px 540px", transform: `scale(${s})` } : undefined}>
      {GLYPHS.map((_, k) => (
        <Card key={k} k={k} f={f} />
      ))}
    </AbsoluteFill>
  );
};

export const DotsLayer: React.FC = () => {
  const f = useCurrentFrame();
  if (f < A6.dots[0]) return null;
  const d = dotsAt(f);
  return (
    <>
      <Dot x={d.you.x} y={d.you.y} r={TOUCH.r} who="you" />
      <Dot x={d.other.x} y={d.other.y} r={TOUCH.r} who="other" />
    </>
  );
};
