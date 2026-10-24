// Composition "Demo" (2700 f, 1920×1080, 60 fps): the 45 s product demo. One phone in the centre plays the REAL app
// (Screen.tsx); no voice-over, so a short title at the left and one callout beside the phone carry each segment; the
// film's lock-up at the end. Every pixel is a function of the frame (no Math.random / Date). Timings: timeline.ts.
import type { ReactNode } from "react";
import { AbsoluteFill, Easing, useCurrentFrame } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { Blur } from "../components/Blur.tsx";
import { Pill } from "../components/Card.tsx";
import { Heart } from "../components/Heart.tsx";
import { Phone } from "../components/Phone.tsx";
import { ease, lerp, settle } from "../lib/ease.ts";
import { C, FONT, HEAD, colW, colX, gradient } from "../lib/tokens.ts";
import { useFonts } from "../lib/useFonts.ts";
import { softWipe } from "../acts/a5/wipe.ts";
import { Screen } from "./Screen.tsx";
import { D } from "./strings.ts";
import { CALLOUT_CUES, END, HOOK, MORE_ROWS, POSES, TITLE_CUES } from "./timeline.ts";

const OUTER = { w: 426, h: 898 } as const; // the phone's outer box at scale 1 (Phone.tsx: screen + 2 × 12 bezel)
const outIn = Easing.in(Easing.cubic);
const inOut = Easing.inOut(Easing.cubic);
const textW = (text: string, size: number, weight: number, letterSpacing?: string) => measureText({ text, fontFamily: FONT, fontSize: size, fontWeight: weight, letterSpacing }).width;

// ───────────────────────────── the phone rig: centre, scale, rotation per frame
type Pose = { cx: number; cy: number; s: number; rot: number };
function pose(f: number): Pose {
  let k = 0;
  while (k + 1 < POSES.length && POSES[k + 1][0] <= f) k++;
  const [from, dx1, dy1, r1] = POSES[k];
  const [, dx0, dy0, r0] = POSES[Math.max(0, k - 1)];
  const u = ease(f, from, from + 150, inOut);
  let cx = 960 + lerp(dx0, dx1, u);
  let cy = 540 + lerp(dy0, dy1, u);
  let rot = lerp(r0, r1, u);
  let s = 1;
  cy += 420 * (1 - settle(f, 0, { stiffness: 90, zeta: 0.88 })); // the rise: frame 0 already shows the counter card
  if (f >= END.move[0]) {
    const e = ease(f, END.move[0], END.move[1], inOut);
    s = lerp(1, 0.8, e);
    cx = lerp(cx, 300 + (OUTER.w * 0.8) / 2, e);
    cy = lerp(cy, 540, e);
    rot = lerp(rot, 0, e);
  }
  return { cx, cy, s, rot };
}
/** a point on the phone's outer edge (side) at screen point y, in film px */
function edge(f: number, side: "left" | "right", yPt: number) {
  const { cx, cy, s, rot } = pose(f);
  const lx = ((side === "right" ? 1 : -1) * OUTER.w) / 2;
  const ly = 12 + yPt - OUTER.h / 2;
  const r = (rot * Math.PI) / 180;
  return { x: cx + s * (lx * Math.cos(r) - ly * Math.sin(r)), y: cy + s * (lx * Math.sin(r) + ly * Math.cos(r)) };
}

const Rig: React.FC = () => {
  const f = useCurrentFrame();
  const { cx, cy, s, rot } = pose(f);
  return (
    <AbsoluteFill style={{ transform: `rotate(${rot}deg)`, transformOrigin: `${cx}px ${cy}px` }}>
      <Phone x={cx - (OUTER.w * s) / 2} y={cy - (OUTER.h * s) / 2} scale={s}>
        <Screen />
      </Phone>
    </AbsoluteFill>
  );
};

// ───────────────────────────── ground: Dawn Blush at 60 % over the paper + one soft white glow; it clears to paper
// for the end card so the 16 px legal line keeps 4.5:1
const Ground: React.FC<{ f: number }> = ({ f }) => (
  <AbsoluteFill style={{ background: C.bg }}>
    <AbsoluteFill style={{ background: gradient(C.dawn), opacity: lerp(0.6, 0.12, ease(f, END.move[0], END.move[1] + 10)) }} />
    <AbsoluteFill style={{ background: "radial-gradient(1200px 900px at 6% -4%, rgba(255,255,255,0.75), rgba(255,255,255,0) 72%)" }} />
  </AbsoluteFill>
);

// ───────────────────────────── titles: wipe in left → right, a 4 px rose underline draws under, wipe out left → right
const TITLE = { x: colX(0), y: 120, size: 56 } as const;
const Title: React.FC<{ f: number; text: string; at: number; out: number }> = ({ f, text, at, out }) => {
  if (f < at || f >= out + 10) return null;
  const w = textW(text, TITLE.size, 700, HEAD.letterSpacing);
  const pin = ease(f, at, at + 16);
  const pout = ease(f, out, out + 10, outIn);
  const line = ease(f, at + 8, at + 28);
  const top = TITLE.y + Math.round(TITLE.size * 1.14) + 10;
  return (
    <>
      <div style={{ position: "absolute", left: TITLE.x, top: TITLE.y, fontSize: TITLE.size, lineHeight: 1.14, color: C.ink, whiteSpace: "nowrap", ...HEAD, clipPath: `inset(-8px ${(1 - pin) * 100}% -12px ${pout * 100}%)` }}>
        {text}
      </div>
      <div style={{ position: "absolute", left: TITLE.x + w * pout, top, width: Math.max(0, w * line - w * pout), height: 4, borderRadius: 2, background: C.rose }} />
    </>
  );
};

const Titles: React.FC<{ f: number }> = ({ f }) => (
  <>
    {TITLE_CUES.map(([key, at, out]) => (
      <Title key={key} f={f} text={D.titles[key]} at={at} out={out} />
    ))}
  </>
);

/** the hook: the wordmark and its line at the left, vertically centred on the phone (84 px: at 96 the wordmark ends 46 px from the bezel) */
const Hook: React.FC<{ f: number }> = ({ f }) => {
  if (f >= HOOK.out + 12) return null;
  const pout = ease(f, HOOK.out, HOOK.out + 12, outIn);
  const wipe = (at: number, dur: number) => `inset(-10px ${(1 - ease(f, at, at + dur)) * 100}% -14px ${pout * 100}%)`;
  return (
    <>
      <div style={{ position: "absolute", left: colX(0), top: 460, fontSize: 84, lineHeight: 1.14, color: C.ink, whiteSpace: "nowrap", ...HEAD, clipPath: wipe(HOOK.wordmark, 20) }}>
        {D.hook.wordmark}
      </div>
      <div style={{ position: "absolute", left: colX(0) + 3, top: 572, fontSize: 32, fontWeight: 500, lineHeight: 1.3, color: C.ink2, whiteSpace: "nowrap", clipPath: wipe(HOOK.sub, 18) }}>
        {D.hook.sub}
      </div>
    </>
  );
};

// ───────────────────────────── callouts: a 1 px rose leader from the phone edge, then the card unfolds from it
const CARD = { right: colX(8), left: colX(3) + colW(1), max: colW(4) } as const; // right cards start on col 9, left cards end on col 4
const Callout: React.FC<{ f: number; side: "left" | "right"; at: number; out: number; y: number; children: ReactNode }> = ({ f, side, at, out, y, children }) => {
  if (f < at || f >= out + 16) return null;
  const e = edge(f, side, y);
  const cardX = side === "right" ? CARD.right : CARD.left;
  const lineIn = ease(f, at, at + 10);
  const lineOut = ease(f, out + 6, out + 14, outIn);
  const reveal = ease(f, at + 6, at + 22) * (1 - ease(f, out, out + 10, outIn));
  const st = settle(f, at + 6, { stiffness: 210, zeta: 0.8 });
  const dir = side === "right" ? 1 : -1;
  // the leader grows outward from the phone and retracts back into it
  const x0 = e.x + (cardX - e.x) * lineOut;
  const x1 = e.x + (cardX - e.x) * lineIn;
  const ly = Math.round(e.y);
  const dotR = 3.5 * settle(f, at, { stiffness: 260, zeta: 0.75 }) * (1 - lineOut);
  const clip = side === "right" ? `inset(-40px calc(${(1 - reveal) * 100}% - ${reveal * 40}px) -40px -40px)` : `inset(-40px -40px -40px calc(${(1 - reveal) * 100}% - ${reveal * 40}px))`;
  return (
    <>
      <div style={{ position: "absolute", left: Math.min(x0, x1), top: ly, width: Math.abs(x1 - x0), height: 1, background: C.rose }} />
      {dotR > 0.2 && <div style={{ position: "absolute", left: e.x - dotR, top: ly + 0.5 - dotR, width: 2 * dotR, height: 2 * dotR, borderRadius: "50%", background: C.rose }} />}
      {reveal > 0 && (
        <div
          style={{
            position: "absolute",
            top: e.y,
            ...(side === "right" ? { left: cardX } : { right: 1920 - cardX }),
            maxWidth: CARD.max,
            transform: `translate(${dir * -18 * (1 - st)}px, -50%)`,
            clipPath: clip,
          }}
        >
          <div style={{ background: C.card, borderRadius: 28, boxShadow: C.shadow, padding: "22px 28px" }}>{children}</div>
        </div>
      )}
    </>
  );
};
const Quote: React.FC<{ children: ReactNode; width?: number }> = ({ children, width }) => (
  <div style={{ width, fontSize: 28, fontWeight: 600, lineHeight: 1.3, color: C.ink, textWrap: "balance" }}>{children}</div>
);
/** the montage's callout: its three screens as a list, each row lighting up (ink, rose dot) with its screen */
const mixHex = (a: string, b: string, t: number) =>
  `#${[1, 3, 5].map((i) => Math.round(lerp(parseInt(a.slice(i, i + 2), 16), parseInt(b.slice(i, i + 2), 16), t)).toString(16).padStart(2, "0")).join("")}`;
const MoreList: React.FC<{ f: number }> = ({ f }) => (
  <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
    {[D.titles.photos, D.titles.chat, D.titles.care].map((text, k) => {
      const next = MORE_ROWS[k + 1];
      const on = ease(f, MORE_ROWS[k], MORE_ROWS[k] + 8) * (next === undefined ? 1 : 1 - ease(f, next, next + 8));
      return (
        <div key={text} style={{ display: "flex", alignItems: "center", gap: 14, fontSize: 28, fontWeight: 600, lineHeight: 1.3, color: mixHex(C.ink2, C.ink, on), whiteSpace: "nowrap" }}>
          <div style={{ width: 10, height: 10, borderRadius: 5, background: mixHex(C.ink3, C.rose, on), transform: `scale(${0.8 + 0.4 * on})` }} />
          {text}
        </div>
      );
    })}
  </div>
);
const Callouts: React.FC<{ f: number }> = ({ f }) => (
  <>
    {CALLOUT_CUES.map((c) => (
      <Callout key={c.id} f={f} side={c.side} at={c.in} out={c.out} y={c.y}>
        {c.id === "more" ? <MoreList f={f} /> : <Quote width={c.id === "question" || c.id === "sleep" ? 330 : undefined}>{D.callouts[c.id]}</Quote>}
      </Callout>
    ))}
  </>
);

// ───────────────────────────── the end card: the film's lock-up, centred on x 1300 beside the phone
const LOCK = { x: 1300, tile: 380, size: 200, wordmark: 508, line: 600, offer: 666, url: 716, legal: 1004 } as const;
const Centered: React.FC<{ f: number; at: number; dur: number; y: number; size: number; weight: number; color?: string; head?: boolean; children: ReactNode; text: string }> = ({ f, at, dur, y, size, weight, color = C.ink, head, children, text }) => {
  if (f < at) return null;
  const ls = head ? HEAD.letterSpacing : undefined;
  const w = textW(text, size, weight, ls);
  return (
    <div style={{ position: "absolute", left: Math.round(LOCK.x - w / 2), top: y, fontSize: size, fontWeight: weight, lineHeight: 1.25, letterSpacing: ls, color, whiteSpace: "nowrap", ...softWipe(ease(f, at, at + dur), w, 64) }}>
      {children}
    </div>
  );
};
const EndCard: React.FC<{ f: number }> = ({ f }) => {
  if (f < END.heart) return null;
  const h = END.heart;
  const draw = ease(f, h, h + 30, Easing.bezier(0.45, 0, 0.2, 1));
  const rim = 26 * (1 - ease(f, h + 40, h + 56));
  const fill = f < h + 26 ? 0 : rim > 0 ? Math.min(0.999, ease(f, h + 26, h + 40)) : 1;
  const tile = f < h + 32 ? 0 : f >= END.hold ? 1 : settle(f, h + 32, { stiffness: 150, zeta: 0.8 });
  const tileBottom = LOCK.tile + LOCK.size / 2;
  const wm = D.end.wordmark;
  const wmW = textW(wm, 64, 700, HEAD.letterSpacing);
  const wmTop = LOCK.wordmark - 96 * (1 - ease(f, END.wordmark, END.wordmark + 22));
  const pill = { size: 18, padX: 28.8, h: 62 };
  const pillW = Math.ceil(textW(D.end.url, pill.size, 600, "0.02em") + 2 * pill.padX);
  const pillDrop = (pill.h + 8) * (1 - (f < END.url ? 0 : f >= END.hold ? 1 : settle(f, END.url, { stiffness: 170, zeta: 0.8 })));
  return (
    <>
      {f >= END.wordmark && (
        <div style={{ position: "absolute", left: Math.round(LOCK.x - wmW / 2), top: wmTop, fontSize: 64, lineHeight: 1.25, color: C.ink, whiteSpace: "nowrap", ...HEAD, clipPath: `inset(${Math.max(0, tileBottom - wmTop)}px 0 0 0)` }}>
          {wm}
        </div>
      )}
      <Heart x={LOCK.x} y={LOCK.tile} size={LOCK.size} draw={draw} fill={fill} tile={tile} stroke={C.rose} strokeWidth={rim} />
      <Centered f={f} at={END.line} dur={18} y={LOCK.line} size={36} weight={700} head text={`${D.end.l1} ${D.end.l2}`}>
        {D.end.l1} <span style={{ color: C.rose }}>{D.end.l2}</span>
      </Centered>
      <Centered f={f} at={END.offer} dur={16} y={LOCK.offer} size={24} weight={600} color={C.ink2} text={D.end.offer}>
        {D.end.offer}
      </Centered>
      {f >= END.url && (
        <div style={{ position: "absolute", left: Math.round(LOCK.x - pillW / 2) - 6, top: LOCK.url - 12, width: pillW + 12, height: pill.h + 12, overflow: "hidden" }}>
          <Pill text={D.end.url} size={pill.size} style={{ left: 6, top: 12 + pillDrop, height: pill.h }} />
        </div>
      )}
      <Centered f={f} at={END.legal} dur={24} y={LOCK.legal} size={16} weight={500} color={C.ink2} text={D.end.legal}>
        {D.end.legal}
      </Centered>
    </>
  );
};

export const Demo: React.FC = () => {
  const f = useCurrentFrame();
  const ready = useFonts();
  const rising = f < 40; // the rise peaks near 25 px/f: shuttered (DESIGN §3)
  return (
    <AbsoluteFill style={{ background: C.bg, color: C.ink, fontFamily: FONT, WebkitFontSmoothing: "antialiased" }}>
      <Ground f={f} />
      {ready && (
        <>
          <Callouts f={f} />
          <Blur on={rising} samples={8}>
            <Rig />
          </Blur>
          <Hook f={f} />
          <Titles f={f} />
          <EndCard f={f} />
        </>
      )}
    </AbsoluteFill>
  );
};
