// V3 said up front (600–900) + V4 sign-off (900–1200) of the 9:16 cut, re-laid out from the film's Act 5 (navy
// headlines + the two dots) and Act 7 (the heart drawing around the touching dots, the sunset tile, the wordmark, the
// lines, the url pill). Reads the GLOBAL frame of the "Vertical" composition. Spec: VERTICAL.md; frames: ./cues.ts.
import { AbsoluteFill, Easing, useCurrentFrame } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { Blur } from "../../components/Blur.tsx";
import { Pill } from "../../components/Card.tsx";
import { Dot } from "../../components/Dot.tsx";
import { Heart } from "../../components/Heart.tsx";
import { Head } from "../../components/Text.tsx";
import { T } from "../../copy/strings.ts";
import { ease, lerp, settle } from "../../lib/ease.ts";
import { C, FONT, HEAD } from "../../lib/tokens.ts";
import { softWipe } from "../../acts/a5/wipe.ts";
import { SAFE, VERT } from "../timeline.ts";
import { V34_CUES as Q } from "./cues.ts";

// ── V3 geometry: five lines at x 80 from y 560, pitch 132. 98 px, not the spec's 104: at 104 "Không quảng cáo." is
// 894 px wide and would run past the safe edge (x 940); at 98 it is 842 px.
const SAID = { x: SAFE.left, top: 560, pitch: 132, size: 98 } as const;
const R = 18; // the dots
const GAP = 28; // edge to edge while they rest: they touch only in V4
const [S1, S2] = T.a5.h1.split(/(?<=\.)\s+/); // "Không bảng tin." · "Không người lạ."
const LINES = [S1, S2, T.a5.h2, T.a5.h3[0], T.a5.h3[1]];
const WIPE = [14, 14, 12, 10, 14];

// ── V4 geometry: the end card, centred; the stack (tile top 400 → pill bottom 1319) sits in the middle of SAFE
const MARK = { x: VERT.w / 2, y: 590, size: 380 } as const; // the tile spans y 400 → 780
const MARK_BOTTOM = MARK.y + MARK.size / 2; // the wordmark slides out from under this edge
const INSIDE = Math.round(MARK.y + ((420 - 512) / 1024) * MARK.size); // the heart's interior centre: the dots rest here
const TOUCH = { y: 760, you: VERT.w / 2 - R, other: VERT.w / 2 + R } as const; // where the dots meet (VERTICAL.md)
// tops of the line boxes: tile → wordmark caps 56 · wordmark → l1 60 · l1 / l2 pitch 80 · l2 → offer 72 · offer → pill 32
const CARD = { wordmark: 807, l1: 944, l2: 1024, offer: 1147, url: 1223 } as const;
const PILL = { size: 40, h: 96 } as const;

const headW = (text: string, size: number) => measureText({ text, fontFamily: FONT, fontSize: size, fontWeight: 700, letterSpacing: HEAD.letterSpacing }).width;
const speed = (fn: (x: number) => number, f: number) => Math.abs(fn(f + 0.25) - fn(f - 0.25)) * 2;

type P = { x: number; y: number };
const quad = (a: P, c: P, b: P, t: number): P => ({ x: (1 - t) ** 2 * a.x + 2 * t * (1 - t) * c.x + t * t * b.x, y: (1 - t) ** 2 * a.y + 2 * t * (1 - t) * c.y + t * t * b.y });

/** the two dots through both sections: glide in under "Chỉ hai người." and rest after it (V3); stay on top of the
 * rising sheet, travel to the centre and touch; rise into the heart while it draws; melt into its fill (V4) */
function dotsAt(f: number): { you: P; other: P; r: number } | null {
  if (f < Q.dots[0] || f >= Q.fill[1]) return null;
  // x-height centre of line 3 in Head's 1.14 line box (Quicksand: ascent 1, descent 0.25; x-height 0.503 em)
  const y = Math.round(SAID.top + 2 * SAID.pitch + ((1.14 - 1.25) / 2 + 1 - 0.503 / 2) * SAID.size);
  const restYou = { x: Math.round(SAID.x + headW(LINES[2], SAID.size) + 30 + R), y };
  const restOther = { x: restYou.x + 2 * R + GAP, y };
  const g = ease(f, Q.dots[0], Q.dots[1]);
  const t = ease(f, Q.travel[0], Q.travel[1], Easing.inOut(Easing.cubic));
  const up = ease(f, Q.rise[0], Q.rise[1], Easing.inOut(Easing.cubic));
  const melt = ease(f, Q.fill[0], Q.fill[1], Easing.in(Easing.cubic));
  // V3: arcs that dip under line 3 (lines 4–5 are not on screen yet), never across a word
  const you = g < 1 ? quad({ x: -3 * R, y: 1010 }, { x: restYou.x - 4, y: 1040 }, restYou, g) : restYou;
  const other = g < 1 ? quad({ x: VERT.w + 3 * R, y: 1010 }, { x: restOther.x + 120, y: 1040 }, restOther, g) : restOther;
  const meetY = lerp(TOUCH.y, INSIDE, up);
  return {
    you: { x: lerp(lerp(you.x, TOUCH.you, t), VERT.w / 2, melt), y: lerp(you.y, meetY, t) },
    other: { x: lerp(lerp(other.x, TOUCH.other, t), VERT.w / 2, melt), y: lerp(other.y, meetY, t) },
    r: R * (1 - melt),
  };
}
const dotsFast = (f: number) => {
  const [a, b] = [dotsAt(f - 0.25), dotsAt(f + 0.25)];
  if (!a || !b) return false;
  return Math.max(Math.hypot(b.you.x - a.you.x, b.you.y - a.you.y), Math.hypot(b.other.x - a.other.x, b.other.y - a.other.y)) * 2 > 20;
};
const Dots: React.FC = () => {
  const d = dotsAt(useCurrentFrame());
  if (!d || d.r <= 0.2) return null;
  return (
    <>
      <Dot x={d.you.x} y={d.you.y} r={d.r} who="you" />
      <Dot x={d.other.x} y={d.other.y} r={d.r} who="other" />
    </>
  );
};

/** V3: the five lines on navy, each wiped in on its cue */
const Said: React.FC<{ f: number }> = ({ f }) => (
  <AbsoluteFill style={{ background: C.ink }}>
    {LINES.map((text, k) => {
      const at = Q.lines[k];
      if (f < at) return null;
      return (
        <Head key={k} x={SAID.x} y={SAID.top + k * SAID.pitch} size={SAID.size} color={k === 4 ? C.rose : C.white} style={{ whiteSpace: "nowrap", padding: "20px 0", marginTop: -20, ...softWipe(ease(f, at, at + WIPE[k]), headW(text, SAID.size), 96) }}>
          {text}
        </Head>
      );
    })}
  </AbsoluteFill>
);

/** the light sheet: its top edge leaves the frame (28 px corners and all) by Q.sheet[1] */
const sheetTop = (f: number) => VERT.h - (VERT.h + 40) * ease(f, Q.sheet[0], Q.sheet[1], Easing.out(Easing.poly(5)));
const sheetFast = (f: number) => f > Q.sheet[0] && speed(sheetTop, f) > 20;
const Sheet: React.FC = () => <div style={{ position: "absolute", left: 0, top: sheetTop(useCurrentFrame()), width: VERT.w, height: VERT.h + 80, background: C.bg, borderRadius: "28px 28px 0 0" }} />;

/** a centred end-card line that wipes in left → right */
const Line: React.FC<{ f: number; at: number; dur: number; text: string; y: number; size: number; weight: number; color: string; head?: boolean }> = ({ f, at, dur, text, y, size, weight, color, head }) => {
  if (f < at) return null;
  const ls = head ? HEAD.letterSpacing : undefined;
  const w = measureText({ text, fontFamily: FONT, fontSize: size, fontWeight: weight, letterSpacing: ls }).width;
  return (
    <div style={{ position: "absolute", left: Math.round(VERT.w / 2 - w / 2), top: y, fontSize: size, fontWeight: weight, lineHeight: 1.25, letterSpacing: ls, color, whiteSpace: "nowrap", ...softWipe(ease(f, at, at + dur), w, 72) }}>
      {text}
    </div>
  );
};

/** V4: the heart draws (rose, so it reads on the light ground), fills, the tile blooms, the rim thins away; the wordmark,
 * the two lines, the offer and the url pill follow */
const SignOff: React.FC<{ f: number }> = ({ f }) => {
  const draw = ease(f, Q.heart[0], Q.heart[1], Easing.bezier(0.45, 0, 0.2, 1));
  const rim = 28 * (1 - ease(f, Q.fill[1], Q.tile[1]));
  const fill = f < Q.fill[0] ? 0 : rim > 0 ? Math.min(0.999, ease(f, Q.fill[0], Q.fill[1])) : 1;
  const tile = f < Q.tile[0] ? 0 : f >= Q.lock + 30 ? 1 : settle(f, Q.tile[0], { stiffness: 220, zeta: 0.8 });
  const wm = T.a7.wordmark;
  const wmW = headW(wm, 96);
  const wmTop = CARD.wordmark - 140 * (1 - ease(f, Q.wordmark[0], Q.wordmark[1])); // starts wholly behind the tile
  const pillW = Math.ceil(measureText({ text: T.vertical.v34.url, fontFamily: FONT, fontSize: PILL.size, fontWeight: 600, letterSpacing: "0.02em" }).width + 3.2 * PILL.size);
  const pillDrop = (PILL.h + 8) * (1 - settle(f, Q.url, { stiffness: 170, zeta: 0.8 }));
  return (
    <>
      {f >= Q.wordmark[0] && (
        <div style={{ position: "absolute", left: Math.round(VERT.w / 2 - wmW / 2), top: wmTop, fontSize: 96, lineHeight: 1.25, color: C.ink, whiteSpace: "nowrap", ...HEAD, clipPath: f < Q.wordmark[1] ? `inset(${Math.max(0, MARK_BOTTOM - wmTop)}px 0 0 0)` : undefined }}>
          {wm}
        </div>
      )}
      <Heart x={MARK.x} y={MARK.y} size={MARK.size} draw={draw} fill={fill} tile={tile} stroke={C.rose} strokeWidth={rim} />
      <Line f={f} at={Q.l1} dur={16} text={T.a7.l1} y={CARD.l1} size={64} weight={700} color={C.ink} head />
      <Line f={f} at={Q.l2} dur={18} text={T.a7.l2} y={CARD.l2} size={64} weight={700} color={C.rose} head />
      <Line f={f} at={Q.offer} dur={16} text={T.a7.offer} y={CARD.offer} size={44} weight={600} color={C.ink2} />
      {f >= Q.url && (
        <div style={{ position: "absolute", left: Math.round(VERT.w / 2 - pillW / 2) - 6, top: CARD.url - 12, width: pillW + 12, height: PILL.h + 12, overflow: "hidden" }}>
          <Pill text={T.vertical.v34.url} size={PILL.size} style={{ left: 6, top: 12 + pillDrop, height: PILL.h }} />
        </div>
      )}
    </>
  );
};

export const V34: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: C.bg }}>
      {f < Q.sheet[1] && <Said f={f} />}
      {f >= Q.sheet[0] && f < Q.sheet[1] && (
        <Blur on={sheetFast(f)}>
          <Sheet />
        </Blur>
      )}
      {f >= Q.heart[0] && <SignOff f={f} />}
      <Blur on={dotsFast(f)}>
        <Dots />
      </Blur>
    </AbsoluteFill>
  );
};
