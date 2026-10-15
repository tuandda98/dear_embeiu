// Act 5 · Nói trước — the whole act as a pure function of the frame. Act 6 draws this same scene (at A5.hold − 1)
// under its rising sheet, so H2280 is pixel-identical on both sides of the boundary.
// At A5.dim the fact grid slides down and shrinks into a fine-print strip at the bottom, so the headlines land on
// clean navy: text never sits on text.
import { AbsoluteFill } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { Head } from "../../components/Text.tsx";
import { T } from "../../copy/strings.ts";
import { ease, lerp } from "../../lib/ease.ts";
import { C, FONT, colW, colX } from "../../lib/tokens.ts";
import { A5 } from "../../timeline/cues.ts";
import { softWipe } from "./wipe.ts";

export const A5_LAYOUT = {
  cols: [colX(0), colX(4), colX(8)], // the 3 × 2 fact grid
  rows: [300, 600],
  label: 40, // fact label px (the strip: 22)
  strip: [844, 912], // the fine-print strip's two rows (label tops); rules 14 px above
  heads: [300, 420, 540], // H2280: the three headlines at colX(0), 96 px, on clean navy
  headSize: 96,
  footerY: 984,
} as const;

const RULE = "rgba(255, 255, 255, 0.25)"; // DESIGN §4: a hairline on dark
const HEAD_WIPE = [18, 12, 16]; // frames per headline wipe (long line → longer wipe)
const S = 22 / A5_LAYOUT.label; // the strip's label scale

/** the letterpress thump: the block is set at 102 %, 101 % on the next frame, then 100 % — no fade */
const thump = (f: number, at: number) => (f - at < 1 ? 1.02 : f - at < 2 ? 1.01 : 1);

const Fact: React.FC<{ f: number; k: number }> = ({ f, k }) => {
  const at = A5.facts[k];
  if (f < at) return null;
  const [label, detail] = T.a5.facts[k];
  const x = A5_LAYOUT.cols[k % 3];
  const row = Math.floor(k / 3);
  // into the strip: columns stagger by 2 f, the two rows move together (row 1 never crosses row 2)
  const from = A5.dim + 2 * (k % 3);
  const p = ease(f, from, from + 24);
  const out = ease(f, from, from + 8); // the detail line retracts as the block starts to move
  const y = lerp(A5_LAYOUT.rows[row], A5_LAYOUT.strip[row], p);
  const s = lerp(1, S, p) * thump(f, at);
  return (
    <>
      <div style={{ position: "absolute", left: x, top: Math.round(lerp(A5_LAYOUT.rows[row] - 28, A5_LAYOUT.strip[row] - 14, p)), width: colW(4), height: 1, background: RULE, transformOrigin: "0 0", transform: `scaleX(${ease(f, at, at + 10)})` }} />
      <div style={{ position: "absolute", left: x, top: y, transformOrigin: "0 0", transform: s === 1 ? undefined : `scale(${s})`, whiteSpace: "nowrap" }}>
        <div style={{ fontSize: A5_LAYOUT.label, fontWeight: 700, lineHeight: "50px", letterSpacing: "-0.01em", color: `rgba(255, 255, 255, ${lerp(1, 0.7, p)})` }}>{label}</div>
        {out < 1 && (
          <div style={{ marginTop: 8, fontSize: 22, fontWeight: 500, lineHeight: "28px", color: C.ink3, clipPath: out > 0 ? `inset(0 ${out * 100}% 0 0)` : undefined }}>{detail}</div>
        )}
      </div>
    </>
  );
};

const Headline: React.FC<{ f: number; n: 0 | 1 | 2; text: string; children: React.ReactNode }> = ({ f, n, text, children }) => {
  const at = [A5.h1, A5.h2, A5.h3][n];
  if (f < at) return null;
  const w = measureText({ text, fontFamily: FONT, fontSize: A5_LAYOUT.headSize, fontWeight: 700, letterSpacing: "-0.01em" }).width;
  const wipe = softWipe(ease(f, at, at + HEAD_WIPE[n]), w, 96);
  // the 20 px padding (cancelled by the margin) keeps descenders inside the mask box during the wipe
  return (
    <Head x={colX(0)} y={A5_LAYOUT.heads[n]} size={A5_LAYOUT.headSize} color={C.white} style={{ whiteSpace: "nowrap", padding: "20px 0", marginTop: -20, ...wipe }}>
      {children}
    </Head>
  );
};

/** `back` 0 → 1: Act 6's sheet presentation pushes the content back a touch (the navy ground itself never moves) */
export const A5Scene: React.FC<{ f: number; back?: number }> = ({ f, back = 0 }) => {
  const [s1, s2] = T.a5.h3;
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      <AbsoluteFill style={back > 0 ? { transformOrigin: "960px 540px", transform: `translateY(${-28 * back}px) scale(${1 - 0.04 * back})` } : undefined}>
        {T.a5.facts.map((_, k) => (
          <Fact key={k} f={f} k={k} />
        ))}
        {f >= A5.footer && (
          <div style={{ position: "absolute", left: colX(0), top: A5_LAYOUT.footerY, fontSize: 22, fontWeight: 600, lineHeight: "28px", letterSpacing: "0.02em", color: C.ink3, transformOrigin: "0 50%", transform: thump(f, A5.footer) === 1 ? undefined : `scale(${thump(f, A5.footer)})` }}>
            {T.a5.footer}
          </div>
        )}
        <Headline f={f} n={0} text={T.a5.h1}>
          {T.a5.h1}
        </Headline>
        <Headline f={f} n={1} text={T.a5.h2}>
          {T.a5.h2}
        </Headline>
        <Headline f={f} n={2} text={`${s1} ${s2}`}>
          {s1} <span style={{ color: C.rose }}>{s2}</span>
        </Headline>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
