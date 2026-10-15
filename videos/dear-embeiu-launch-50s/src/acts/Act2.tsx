// Act 2 · Người ấy (f 240–719). The partner's dot swoops into an iOS notification while the number steps back and the
// phone rises with the real Home; the Home is flicked down to today's cards and three lavender leader lines pin his side
// of each (question, mood, sleep); rose carets wait on your side. You pick the same mood in the app's sheet, you send
// your answer in the app's sheet, both answers open (echoed large beside the phone), and the whole picture compresses
// into one navy cell (H720). Every position is a pure function of the GLOBAL frame.
import type { CSSProperties, ReactNode } from "react";
import { Easing, useCurrentFrame } from "remotion";
import { A2 } from "../timeline/cues.ts";
import { T } from "../copy/strings.ts";
import { C, PHONE, RADIUS } from "../lib/tokens.ts";
import { ease, lerp, press, settle } from "../lib/ease.ts";
import { COUNTER, COUNTER_DOT, Counter } from "../story/Counter.tsx";
import { Blur } from "../components/Blur.tsx";
import { Dot } from "../components/Dot.tsx";
import { Heart } from "../components/Heart.tsx";
import { Phone } from "../components/Phone.tsx";
import { Caption } from "../components/Text.tsx";
import { A1Caption, a1CaptionExit, Camera, dropY } from "./a1/shared.tsx";
import { AnswerSheet, HomeA2, MoodSheet, Q_H, Scrim, anchors, type HomeState } from "./a2/home.tsx";
import * as K from "./a2/timing.ts";

const IN_OUT = Easing.inOut(Easing.cubic);
const IN = Easing.in(Easing.cubic);
const FLICK = Easing.bezier(0.2, 0.55, 0.1, 1); // a finger flick: a short push, a long glide
const SNAP = 20; // px/frame: above this a piece is motion-blurred (BRIEF §7.4)

type Rect = { x: number; y: number; w: number; h: number };
const mixRect = (a: Rect, b: Rect, t: number): Rect => ({ x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t), w: lerp(a.w, b.w, t), h: lerp(a.h, b.h, t) });
/** fastest corner of a moving rect, px per frame (sampled across the 180° shutter) */
const speedOf = (at: (f: number) => Rect, f: number) => {
  const a = at(f - 0.5), b = at(f + 0.5);
  return Math.max(Math.hypot(b.x - a.x, b.y - a.y), Math.hypot(b.x + b.w - a.x - a.w, b.y + b.h - a.y - a.h));
};
const hex = (c: string) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));

// ── geometry (film px) ────────────────────────────────────────────────────────────────────────────────────────────
const CELL: Rect = { x: 120, y: 540, w: 28, h: 28 }; // H720: the first streak cell (radius 6, navy)
const CARD: Rect = { x: 120, y: 520, w: 560, h: 124 }; // the notification, under the stepped-back number
const AV = { cx: CARD.x + 28 + 28, cy: CARD.y + CARD.h / 2, r: 28 }; // its 56 px app-icon slot = the dot's place
const BEZEL = 12; // Phone.tsx's bezel, in screen points
const PH: Rect = { x: 1180, y: 230, w: (PHONE.w + 2 * BEZEL) * PHONE.side, h: (PHONE.h + 2 * BEZEL) * PHONE.side }; // ≈ 307×647
const ECHO: Rect = { x: 120, y: 680, w: 600, h: 213 }; // both answers, large, under the notification (his first line fits)
const ECHO_B = 96; // his block's top inside the echo
const S1 = 620, S2 = 470; // the page's scroll: today's three cards (his sides above the nav) · the whole question card

// ── timing as pure functions ──────────────────────────────────────────────────────────────────────────────────────
const camAt = (f: number) => 1.04 - 0.04 * ease(f, K.CAM[0], K.CAM[1], IN_OUT);
const stepAt = (f: number) => {
  const e = ease(f, K.STEP[0], K.STEP[1], Easing.out(Easing.sin)); // a recoil: quick off the contact, settling
  return { y: lerp(COUNTER.hero.y, 160, e), s: lerp(1, 0.55, e), o: lerp(1, 0.6, e) };
};
const counterRect = (f: number): Rect => {
  const { y, s } = stepAt(f);
  return { x: COUNTER.hero.x, y, w: 800 * s, h: 560 * s }; // the number's far corner leads the step-back
};
const dotR = (f: number) => lerp(14, AV.r, ease(f, K.GROW[0], K.GROW[1]));
/** the dot's swoop: a quadratic arc from its landing spot, under the small number, arriving level into the slot */
const dotAt = (f: number) => {
  const t = ease(f, A2.fly[0], A2.fly[1], IN_OUT), u = 1 - t;
  const [x0, y0, cx, cy] = [COUNTER_DOT.x, dropY(f), 560, AV.cy];
  return { x: u * u * x0 + 2 * u * t * cx + t * t * AV.cx, y: u * u * y0 + 2 * u * t * cy + t * t * AV.cy };
};
const dotRect = (f: number): Rect => {
  const p = dotAt(f), r = dotR(f);
  return { x: p.x - r, y: p.y - r, w: 2 * r, h: 2 * r };
};
const C0 = A2.compress[0];

/** the compress. The whole picture (card + answers + phone) shrinks uniformly about its centre while sliding left onto
 *  the cell's centre — a miniature of the day — then its pieces merge into the cell and turn navy as they land.
 *  Ends exactly on CELL_AT (719). */
const G = { cx: (CARD.x + PH.x + PH.w) / 2, cy: (PH.y + ECHO.y + ECHO.h) / 2 };
const shrink = (f: number) => ease(f, C0, K.CELL_AT - 3, IN_OUT);
const groupScale = (f: number) => lerp(1, 0.035, shrink(f));
const inGroup = (r: Rect, f: number): Rect => {
  const e = shrink(f), s = groupScale(f);
  const cx = lerp(G.cx, CELL.x + CELL.w / 2, e), cy = lerp(G.cy, CELL.y + CELL.h / 2, e);
  return { x: cx + (r.x - G.cx) * s, y: cy + (r.y - G.cy) * s, w: r.w * s, h: r.h * s };
};
const merge = (f: number) => ease(f, K.CELL_AT - 12, K.CELL_AT, IN_OUT);
const squeeze = (home: Rect, f: number) => mixRect(inGroup(home, f), CELL, merge(f));
const navy = (f: number) => ease(f, K.CELL_AT - 13, K.CELL_AT - 3); // white → navy while still a miniature
const cardRect = (f: number): Rect => (f >= C0 ? squeeze(CARD, f) : mixRect(dotRect(f), CARD, ease(f, K.OPEN[0], K.OPEN[1])));
/** the phone rises from below the frame over A2.card (a spring, one small overshoot), then rides the compress */
const phoneRect = (f: number): Rect =>
  f >= C0 ? squeeze(PH, f) : { ...PH, y: lerp(1080 + 24, PH.y, settle(f, A2.card[0], { stiffness: 200, zeta: 0.85 })) };
const echoRect = (f: number): Rect => (f >= C0 ? squeeze(ECHO, f) : ECHO);

/** the page inside the phone at frame f */
const scrollAt = (f: number) =>
  f < K.BACK_SCROLL[0] ? S1 * ease(f, A2.scroll[0], A2.scroll[1], FLICK) : lerp(S1, S2, ease(f, K.BACK_SCROLL[0], K.BACK_SCROLL[1], IN_OUT));
const ANCHOR = anchors(Q_H[0]);
const hop = (a: { x: number; y: number }, b: { x: number; y: number }, t: number) => ({ x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t) - 26 * Math.sin(Math.PI * t) });
const homeAt = (f: number): HomeState => {
  const jump = ease(f, A2.moodJump, A2.moodJump + K.JUMP, IN_OUT);
  const blinkOn = Math.floor((f - A2.carets) / 30) % 2 === 0;
  const jumping = f >= A2.moodJump && f < A2.moodJump + K.JUMP + 3;
  const carets =
    f >= A2.carets && f < A2.moodJump + K.JUMP + 3
      ? ANCHOR.you.map((p, k) => ({ ...(k === 1 ? p : hop(p, ANCHOR.you[1], jump)), on: jumping || blinkOn }))
      : [];
  return {
    f,
    scroll: scrollAt(f),
    qH: lerp(Q_H[0], Q_H[1], ease(f, A2.answerYou, A2.answerOther + K.UNFOLD)),
    teaserOut: ease(f, A2.answerYou, A2.answerYou + 5, IN),
    ansA: ease(f, A2.answerYou, A2.answerYou + K.UNFOLD),
    ansB: ease(f, A2.answerOther, A2.answerOther + K.UNFOLD),
    check: ease(f, A2.check, A2.check + K.CHECK),
    match: ease(f, A2.matched, A2.matched + K.MATCH),
    cta: press(f, A2.press),
    answered: ease(f, A2.answerYou, A2.answerYou + 12),
    carets,
  };
};
/** the two sheets: up (house ease) after their cue, down (accelerating) at the match / after Gửi */
const moodSheetAt = (f: number) => (f < A2.matched ? ease(f, A2.sheets[0], A2.sheets[0] + K.SHEET_UP) : 1 - ease(f, A2.matched, A2.matched + K.SHEET_DOWN, IN));
const answerSheetAt = (f: number) => (f < A2.send + 8 ? ease(f, A2.sheets[1], A2.sheets[1] + K.ANSWER_UP) : 1 - ease(f, A2.send + 8, A2.send + 8 + K.SHEET_DOWN, IN));
const scrimAt = (f: number) =>
  f < A2.sheets[1] ? Math.min(ease(f, A2.sheets[0], A2.sheets[0] + 12), 1 - ease(f, A2.matched, A2.matched + 10)) : Math.min(ease(f, A2.sheets[1], A2.sheets[1] + 6), 1 - ease(f, A2.send + 8, A2.send + 18));

/** a screen point of the page (content coords) → film coords, through the phone's current rect and the scroll */
const onScreen = (p: { x: number; y: number }, f: number) => {
  const r = phoneRect(f), k = r.w / (PHONE.w + 2 * BEZEL);
  return { x: r.x + (BEZEL + p.x) * k, y: r.y + (BEZEL + p.y - scrollAt(f)) * k };
};

// ── small pieces ──────────────────────────────────────────────────────────────────────────────────────────────────
const abs = (x: number, y: number, extra?: CSSProperties): CSSProperties => ({ position: "absolute", left: x, top: y, ...extra });

/** a piece whose rect animates; content is laid out for `home` and either fixed or, from C0, squeezed into the cell */
const Piece: React.FC<{ rect: Rect; home: Rect; f: number; radius: number; alpha?: number; shadow?: boolean; children: ReactNode }> = ({ rect, home, f, radius, alpha = 1, shadow = true, children }) => {
  const squeezing = f >= C0;
  const fade = squeezing ? 1 - ease(f, K.CELL_AT - 9, K.CELL_AT - 4) : 1;
  const s = squeezing ? Math.min(rect.w / home.w, rect.h / home.h) : 1;
  const n = navy(f);
  const [r, g, b] = hex(C.white).map((v, i) => Math.round(lerp(v, hex(C.ink)[i], n)));
  const k = squeezing ? groupScale(f) : 1;
  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: Math.max(0, rect.w),
        height: Math.max(0, rect.h),
        borderRadius: squeezing ? lerp(radius * k, 6, merge(f)) : radius,
        background: `rgba(${r},${g},${b},${lerp(alpha, 1, n)})`,
        boxShadow: shadow && fade > 0.01 ? `0 ${8 * k}px ${24 * k}px rgba(255, 107, 157, ${0.12 * fade})` : undefined,
        overflow: squeezing || alpha > 0 ? "hidden" : "visible",
      }}
    >
      <div
        style={{
          position: "absolute",
          left: squeezing ? 0 : home.x - rect.x,
          top: squeezing ? (rect.h - home.h * s) / 2 : home.y - rect.y,
          width: home.w,
          height: home.h,
          transformOrigin: "0 0",
          transform: squeezing ? `scale(${s})` : undefined,
          opacity: fade,
        }}
      >
        {children}
      </div>
    </div>
  );
};

// ── the number, stepping back ─────────────────────────────────────────────────────────────────────────────────────
const SteppedCounter: React.FC = () => {
  const f = useCurrentFrame();
  const { y, s, o } = stepAt(f);
  return <Counter x={COUNTER.hero.x} y={y} scale={s} opacity={o} f={f} />;
};

// ── the partner's dot → the notification ──────────────────────────────────────────────────────────────────────────
const FlyingDot: React.FC = () => {
  const f = useCurrentFrame();
  const p = dotAt(f);
  return <Dot x={p.x} y={p.y} r={dotR(f)} who="other" glow={0.35 * (1 - ease(f, K.GROW[0], K.OPEN[0]))} />;
};
const Notification: React.FC = () => {
  const f = useCurrentFrame();
  const rect = cardRect(f);
  const r = f >= C0 ? AV.r : dotR(f);
  const p = T.a2.push;
  const [ax, ay] = [AV.cx - CARD.x, AV.cy - CARD.y];
  return (
    <Piece rect={rect} home={CARD} f={f} radius={f >= C0 ? RADIUS.card : Math.min(RADIUS.card, rect.h / 2)} alpha={0.92}>
      <div style={abs(ax - r, ay - r, { width: 2 * r, height: 2 * r, borderRadius: "50%", background: C.lavender })} />
      <div style={abs(ax + 20 - 14, ay + 20 - 14, { width: 28, height: 28, borderRadius: 8, background: C.white })} />
      <Heart x={ax + 20} y={ay + 20} size={23} />
      <div style={abs(102, 30, { width: CARD.w - 102 - 28, height: 30, display: "flex", alignItems: "baseline", justifyContent: "space-between", whiteSpace: "nowrap" })}>
        <span style={{ fontSize: 24, fontWeight: 600, color: C.ink }}>{p.title}</span>
        <span style={{ fontSize: 18, fontWeight: 500, color: C.ink3 }}>{p.when}</span>
      </div>
      <div style={abs(102, 66, { fontSize: 22, fontWeight: 500, color: C.ink2, whiteSpace: "nowrap", lineHeight: "28px" })}>{p.body}</div>
    </Piece>
  );
};

// ── the phone: the real Home, its sheets ──────────────────────────────────────────────────────────────────────────
const PhoneShot: React.FC = () => {
  const f = useCurrentFrame();
  const rect = phoneRect(f);
  const screen = (
    <>
      <HomeA2 s={homeAt(f)} />
      <Scrim o={scrimAt(f)} />
      {f >= A2.sheets[0] && f < A2.matched + K.SHEET_DOWN && (
        <MoodSheet f={f} rise={moodSheetAt(f)} drops={A2.moods} ring={ease(f, A2.pick, A2.pick + K.RING)} picked={ease(f, A2.pick, A2.pick + 8)} />
      )}
      {f >= A2.sheets[1] && f < A2.send + 8 + K.SHEET_DOWN && <AnswerSheet rise={answerSheetAt(f)} send={press(f, A2.send)} />}
    </>
  );
  if (f < C0) return <Phone x={rect.x} y={rect.y} scale={PHONE.side}>{screen}</Phone>;
  return (
    <Piece rect={rect} home={PH} f={f} radius={(PHONE.radius + BEZEL) * PHONE.side} alpha={0} shadow={false}>
      <Phone x={0} y={0} scale={PHONE.side}>
        {screen}
      </Phone>
    </Piece>
  );
};

// ── leader lines (1 px lavender) from the card's right edge into the phone, each pinning his side of a card ───────
const Leaders: React.FC<{ f: number }> = ({ f }) => {
  if (f < A2.rows[0] || f >= K.LET_GO[1]) return null;
  const c = cardRect(f);
  const gone = ease(f, K.LET_GO[0], K.LET_GO[1], IN);
  return (
    <svg style={abs(0, 0)} width={1920} height={1080}>
      {A2.rows.map((start, k) => {
        if (f < start) return null;
        const end = onScreen(ANCHOR.other[k], f);
        const [x0, y0, x1, y1] = [c.x + c.w, c.y + c.h / 2, end.x, end.y];
        const d = (x1 - x0) * 0.5;
        const pin = f >= A2.rowLand[k] ? settle(f, A2.rowLand[k], { stiffness: 420, zeta: 0.8 }) * (1 - gone) : 0;
        return (
          <g key={k}>
            <path
              d={`M ${x0} ${y0} C ${x0 + d} ${y0}, ${x1 - d} ${y1}, ${x1} ${y1}`}
              fill="none"
              stroke={C.lavender}
              strokeWidth={1}
              pathLength={1}
              strokeDasharray="1 1"
              strokeDashoffset={gone > 0 ? -gone : 1 - ease(f, start, start + K.LEADER)}
            />
            {pin > 0 && <circle cx={x1} cy={y1} r={5 * pin} fill={C.lavender} stroke={C.white} strokeWidth={1.5 * pin} />}
          </g>
        );
      })}
    </svg>
  );
};

// ── both answers, large, beside the phone (the phone's words are too small at film scale) ─────────────────────────
const field = (top: number, h: number, u: number, tint: string, label: string, labelColor: string, text: string) => (
  <div style={abs(0, top, { width: ECHO.w, height: h * u, borderRadius: 20, background: tint, overflow: "hidden" })}>
    <div style={abs(22, 14 - 12 * (1 - u))}>
      <div style={{ fontSize: 18, fontWeight: 600, color: labelColor, lineHeight: "23px" }}>{label}</div>
      <div style={{ marginTop: 4, fontSize: 24, fontWeight: 500, color: C.ink, lineHeight: "31px", whiteSpace: "nowrap" }}>
        {text.split(/(?<=,) /).map((part, i) => (
          <div key={i}>{part}</div>
        ))}
      </div>
    </div>
  </div>
);
const Echo: React.FC = () => {
  const f = useCurrentFrame();
  const uA = ease(f, A2.answerYou, A2.answerYou + K.UNFOLD), uB = ease(f, A2.answerOther, A2.answerOther + K.UNFOLD);
  return (
    <Piece rect={echoRect(f)} home={ECHO} f={f} radius={20} alpha={0} shadow={false}>
      {field(0, 86, uA, "#FFEDF0", T.a2.answerYou.label, C.roseDeep, T.a2.answerYou.text)}
      {f >= A2.answerOther && field(ECHO_B, 117, uB, "#F6F3FE", T.a2.answerOther.label, C.lavenderDeep, T.a2.answerOther.text)}
    </Piece>
  );
};

// ── the act ───────────────────────────────────────────────────────────────────────────────────────────────────────
export const Act2: React.FC = () => {
  const f = useCurrentFrame();
  if (f >= K.CELL_AT) {
    // H720: the picture IS the cell now; the number stays small, dim and ticking. Nothing else.
    return (
      <Camera s={1}>
        <SteppedCounter />
        <div style={abs(CELL.x, CELL.y, { width: CELL.w, height: CELL.h, borderRadius: 6, background: C.ink })} />
      </Camera>
    );
  }
  const capIn = ease(f, A2.caption, A2.caption + 16);
  const capOut = ease(f, K.CAP_OUT[0], K.CAP_OUT[1], IN);
  return (
    <Camera s={camAt(f)}>
      <Blur on={speedOf(counterRect, f) > SNAP}>
        <SteppedCounter />
      </Blur>
      {f < K.OLD_OUT[1] && <A1Caption f={f} exit={a1CaptionExit(f, K.OLD_OUT[0], K.OLD_OUT[1])} />}
      {f >= A2.card[0] && (
        <Blur on={speedOf(phoneRect, f) > SNAP}>
          <PhoneShot />
        </Blur>
      )}
      {f >= A2.answerYou && (
        <Blur on={speedOf(echoRect, f) > SNAP}>
          <Echo />
        </Blur>
      )}
      {f < K.OPEN[0] ? (
        <Blur on={speedOf(dotRect, f) > SNAP}>
          <FlyingDot />
        </Blur>
      ) : (
        <Blur on={speedOf(cardRect, f) > SNAP}>
          <Notification />
        </Blur>
      )}
      <Leaders f={f} />
      {f >= A2.caption && <Caption text={T.a2.caption} x={120} y={930} style={{ clipPath: `inset(-12px ${(1 - capIn) * 100}% -12px ${capOut * 100}%)` }} />}
    </Camera>
  );
};
