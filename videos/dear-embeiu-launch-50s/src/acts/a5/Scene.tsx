// Act 5 · Nói trước (v3) — said up front, on clean navy: three headlines, the two dots resting after "Chỉ hai người.",
// one fine-print line. A pure function of the frame: Act 6 draws this same scene (at A5.hold − 1) under its rising
// sheet, so H2280 is pixel-identical on both sides of the boundary.
import { AbsoluteFill } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { Dot } from "../../components/Dot.tsx";
import { Head } from "../../components/Text.tsx";
import { T } from "../../copy/strings.ts";
import { ease } from "../../lib/ease.ts";
import { C, FONT, colX } from "../../lib/tokens.ts";
import { A5 } from "../../timeline/cues.ts";
import { softWipe } from "./wipe.ts";

export const A5_LAYOUT = {
  x: colX(0),
  heads: [300, 420, 540], // H2280: the three headlines, 96 px, line-box tops
  size: 96,
  fineY: 980, // the fine-print line (26 px, white 60 %)
  r: 14, // the dots
  gap: 28, // edge to edge: they touch only in Act 7
} as const;

const HEAD_WIPE = [18, 12, 16]; // frames per headline wipe (long line → longer wipe)
const headW = (text: string) => measureText({ text, fontFamily: FONT, fontSize: A5_LAYOUT.size, fontWeight: 700, letterSpacing: "-0.01em" }).width;
/** h2's x-height centre (487): in Head's 1.14 line box the baseline sits (1.14 − 1.25) / 2 + 1 em under the top
 * (Quicksand: ascent 1, descent 0.25); the x-height is 0.503 em */
const DOT_Y = Math.round(A5_LAYOUT.heads[1] + ((1.14 - 1.25) / 2 + 1 - 0.503 / 2) * A5_LAYOUT.size);

type P = { x: number; y: number };
const quad = (a: P, c: P, b: P, t: number): P => ({ x: (1 - t) ** 2 * a.x + 2 * t * (1 - t) * c.x + t * t * b.x, y: (1 - t) ** 2 * a.y + 2 * t * (1 - t) * c.y + t * t * b.y });

/** the two dots: they glide in from the frame edges on arcs that dip under "Chỉ hai người." (never across a word) and
 * come to rest just after its full stop, on its x-height, 28 px apart */
export function dotsAt(f: number): { you: P; other: P } {
  const { x, r, gap } = A5_LAYOUT;
  const you = { x: Math.round(x + headW(T.a5.h2) + 30 + r), y: DOT_Y };
  const other = { x: you.x + 2 * r + gap, y: DOT_Y };
  const p = ease(f, A5.dots[0], A5.dots[1]);
  if (p >= 1) return { you, other };
  return {
    you: quad({ x: -3 * r, y: 600 }, { x: you.x - 4, y: 640 }, you, p),
    other: quad({ x: 1920 + 3 * r, y: 600 }, { x: other.x + 120, y: 640 }, other, p),
  };
}
export const dotsFast = (f: number) => {
  const [a, b] = [dotsAt(f - 0.25), dotsAt(f + 0.25)];
  return Math.max(Math.hypot(b.you.x - a.you.x, b.you.y - a.you.y), Math.hypot(b.other.x - a.other.x, b.other.y - a.other.y)) * 2 > 20;
};

export const A5Dots: React.FC<{ f: number }> = ({ f }) => {
  if (f < A5.dots[0]) return null;
  const d = dotsAt(f);
  return (
    <>
      <Dot x={d.you.x} y={d.you.y} r={A5_LAYOUT.r} who="you" />
      <Dot x={d.other.x} y={d.other.y} r={A5_LAYOUT.r} who="other" />
    </>
  );
};

const Headline: React.FC<{ f: number; n: 0 | 1 | 2; text: string; children: React.ReactNode }> = ({ f, n, text, children }) => {
  const at = [A5.h1, A5.h2, A5.h3][n];
  if (f < at) return null;
  const wipe = softWipe(ease(f, at, at + HEAD_WIPE[n]), headW(text), 96);
  // the 20 px padding (cancelled by the margin) keeps descenders inside the mask box during the wipe
  return (
    <Head x={A5_LAYOUT.x} y={A5_LAYOUT.heads[n]} size={A5_LAYOUT.size} color={C.white} style={{ whiteSpace: "nowrap", padding: "20px 0", marginTop: -20, ...wipe }}>
      {children}
    </Head>
  );
};

/** `dots`: draw the dots inside the scene (Act 6's underlay); Act 5 draws them itself so it can blur their glide.
 * `back` 0 → 1: Act 6's sheet presentation pushes the content back a touch (the navy ground itself never moves). */
export const A5Scene: React.FC<{ f: number; dots?: boolean; back?: number }> = ({ f, dots = false, back = 0 }) => {
  const [s1, s2] = T.a5.h3;
  const fineW = measureText({ text: T.a5.fine, fontFamily: FONT, fontSize: 26, fontWeight: 500 }).width;
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      <AbsoluteFill style={back > 0 ? { transformOrigin: "960px 540px", transform: `translateY(${-28 * back}px) scale(${1 - 0.04 * back})` } : undefined}>
        <Headline f={f} n={0} text={T.a5.h1}>
          {T.a5.h1}
        </Headline>
        <Headline f={f} n={1} text={T.a5.h2}>
          {T.a5.h2}
        </Headline>
        <Headline f={f} n={2} text={`${s1} ${s2}`}>
          {s1} <span style={{ color: C.rose }}>{s2}</span>
        </Headline>
        {f >= A5.fine && (
          <div style={{ position: "absolute", left: A5_LAYOUT.x, top: A5_LAYOUT.fineY, fontSize: 26, fontWeight: 500, lineHeight: "33px", color: "rgba(255, 255, 255, 0.6)", whiteSpace: "nowrap", ...softWipe(ease(f, A5.fine, A5.fine + 22), fineW, 72) }}>
            {T.a5.fine}
          </div>
        )}
        {dots && <A5Dots f={f} />}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
