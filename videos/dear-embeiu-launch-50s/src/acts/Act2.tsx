// Act 2 · Người ấy (f 240–719), v3: the daily question is the hero. The number steps back to its corner and the
// partner's dot opens into a large notification while the phone (the real Home) rises at the right and scrolls to
// today's question. The notification leaves; the question card lifts out of the phone into the left column at hero
// scale — his answer locked, yours empty. You type, press Gửi, and both answers open at the same instant (UNLOCK).
// "Cần cả hai." Then everything compresses into the first streak cell (H720). One or two motions at a time (V3 G2).
// Every position is a pure function of the GLOBAL frame.
import type { CSSProperties, ReactNode } from "react";
import { Easing, useCurrentFrame } from "remotion";
import { A2 } from "../timeline/cues.ts";
import { typed } from "../timeline/typing.ts";
import { T } from "../copy/strings.ts";
import { C, PHONE, colX } from "../lib/tokens.ts";
import { ease, lerp, press, settle } from "../lib/ease.ts";
import { CORNER, COUNTER, COUNTER_DOT, Counter } from "../story/Counter.tsx";
import { Blur } from "../components/Blur.tsx";
import { Dot } from "../components/Dot.tsx";
import { Heart } from "../components/Heart.tsx";
import { Phone } from "../components/Phone.tsx";
import { Pill } from "../components/Card.tsx";
import { Caption } from "../components/Text.tsx";
import { G as Glyph } from "./a4/glyphs.tsx";
import { HOME } from "./a4/home.tsx";
import { A1Caption, a1CaptionExit, Camera, dropY } from "./a1/shared.tsx";
import { HomeA2, Q_H, type HomeState } from "./a2/home.tsx";
import * as K from "./a2/timing.ts";

const IN_OUT = Easing.inOut(Easing.cubic);
const IN = Easing.in(Easing.cubic);
const SINE = Easing.inOut(Easing.sin);
const SNAP = 20; // px/frame: above this a piece is motion-blurred (BRIEF §7.4)

type Rect = { x: number; y: number; w: number; h: number };
const mixRect = (a: Rect, b: Rect, t: number): Rect => ({ x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t), w: lerp(a.w, b.w, t), h: lerp(a.h, b.h, t) });
/** fastest corner of a moving rect, px per frame (sampled across the 180° shutter) */
const speedOf = (at: (f: number) => Rect, f: number) => {
  const a = at(f - 0.5), b = at(f + 0.5);
  return Math.max(Math.hypot(b.x - a.x, b.y - a.y), Math.hypot(b.x + b.w - a.x - a.w, b.y + b.h - a.y - a.h));
};
const hex = (c: string) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));
const rgba = (c: string, a: number) => `rgba(${hex(c).join(",")},${a})`;
const abs = (x: number, y: number, extra?: CSSProperties): CSSProperties => ({ position: "absolute", left: x, top: y, ...extra });

// ── geometry (film px) ────────────────────────────────────────────────────────────────────────────────────────────
const CELL: Rect = { x: 120, y: 540, w: 28, h: 28 }; // H720: the first streak cell (radius 6, navy)
const CARD: Rect = { x: 120, y: 330, w: 780, h: 170 }; // the notification, large (40 / 36 / 28 px)
const AV = { cx: CARD.x + 36 + 44, cy: CARD.y + CARD.h / 2, r: 44 }; // its 88 px app-icon slot = the dot's place
const BEZEL = 12; // Phone.tsx's bezel, in screen points
const PS = 840 / (PHONE.h + 2 * BEZEL); // ≈ 0.935: the phone ≈ 840 px tall
const PH: Rect = { x: colX(9), y: 180, w: (PHONE.w + 2 * BEZEL) * PS, h: (PHONE.h + 2 * BEZEL) * PS }; // columns 10–12, under the act title (y 96–150)
const SCROLL = 436; // pt: "Hôm nay của chúng mình" under the header, today's question card below it
/** the hero: the question card lifted out at film scale, laid out in its own box at (120, 330) */
const HERO: Rect = { x: 120, y: 330, w: 1000, h: 524 }; // question 330–462 · his card 494–690 · yours 710–854
const HIS = { y: 164, h: 196 }; // his answer card (hero-local): label + two 40 px lines, broken at his comma
const YOURS = { y: 380, h: 144 }; // your answer card: label + one 40 px line + the Gửi pill beside it
const TEXT_X = 36; // after the 6 px edge
const TEXT_Y = 68; // the answers' first line, under their 28 px label
const LINE = 50; // 40 px answers
const SEND = { w: 112, h: 56 };
/** where the lift starts: the phone's question card at the scroll above (film px) */
const FROM: Rect = { x: PH.x + (BEZEL + 16) * PS, y: PH.y + (BEZEL + HOME.q - SCROLL) * PS, w: 370 * PS, h: Q_H[0] * PS };

// ── timing as pure functions ──────────────────────────────────────────────────────────────────────────────────────
const camAt = (f: number) => 1.04 - 0.04 * ease(f, K.CAM[0], K.CAM[1], IN_OUT);
const stepAt = (f: number) => {
  const e = ease(f, K.STEP[0], K.STEP[1], Easing.out(Easing.sin)); // a recoil: quick off the contact, settling
  return { x: lerp(COUNTER.hero.x, CORNER.x, e), y: lerp(COUNTER.hero.y, CORNER.y, e), s: lerp(1, CORNER.scale, e), o: lerp(1, CORNER.opacity, e) };
};
const counterRect = (f: number): Rect => {
  const { x, y, s } = stepAt(f);
  return { x, y, w: 800 * s, h: 560 * s }; // the number's far corner leads the step-back
};
const dotR = (f: number) => lerp(14, AV.r, ease(f, K.GROW[0], K.GROW[1]));
/** the dot's swoop: a quadratic arc from its landing spot, under the corner, arriving level into the avatar slot */
const dotAt = (f: number) => {
  const t = ease(f, A2.fly[0], A2.fly[1], IN_OUT), u = 1 - t;
  const [x0, y0, cx, cy] = [COUNTER_DOT.x, dropY(f), 600, AV.cy];
  return { x: u * u * x0 + 2 * u * t * cx + t * t * AV.cx, y: u * u * y0 + 2 * u * t * cy + t * t * AV.cy };
};
const dotRect = (f: number): Rect => {
  const p = dotAt(f), r = dotR(f);
  return { x: p.x - r, y: p.y - r, w: 2 * r, h: 2 * r };
};
const C0 = A2.compress[0];

/** the compress. Hero + phone (centred on the frame) shrink uniformly about their common centre while sliding onto the
 *  cell's centre — a miniature of the moment — then merge into the cell and turn navy as they land, on CELL_AT (719) */
const G = { cx: (HERO.x + PH.x + PH.w) / 2, cy: (PH.y + PH.y + PH.h) / 2 };
const shrink = (f: number) => ease(f, C0, K.CELL_AT - 3, IN_OUT);
const groupScale = (f: number) => lerp(1, 0.035, shrink(f));
const inGroup = (r: Rect, f: number): Rect => {
  const e = shrink(f), s = groupScale(f);
  const cx = lerp(G.cx, CELL.x + CELL.w / 2, e), cy = lerp(G.cy, CELL.y + CELL.h / 2, e);
  return { x: cx + (r.x - G.cx) * s, y: cy + (r.y - G.cy) * s, w: r.w * s, h: r.h * s };
};
const merge = (f: number) => ease(f, K.CELL_AT - 12, K.CELL_AT, IN_OUT);
const squeeze = (home: Rect, f: number) => mixRect(inGroup(home, f), CELL, merge(f));
const navy = (f: number) => ease(f, K.CELL_AT - 13, K.CELL_AT - 3);

/** the notification: opens from the dot, holds, slides out to the left completely */
const cardRect = (f: number): Rect => {
  const open = mixRect(dotRect(f), CARD, ease(f, A2.card[0], A2.card[1]));
  return { ...open, x: open.x - (CARD.x + CARD.w + 40) * ease(f, A2.leave[0], A2.leave[1], IN) };
};
/** the phone rises from below the frame (a spring, one small overshoot), then rides the compress */
const phoneRect = (f: number): Rect => (f >= C0 ? squeeze(PH, f) : { ...PH, y: lerp(1080 + 24, PH.y, settle(f, A2.phone[0], { stiffness: 190, zeta: 0.85 })) });
/** the hero lifts out of the phone's question card (scale + travel), then rides the compress */
const lift = (f: number) => ease(f, A2.lift[0], A2.lift[1], IN_OUT);
const heroRect = (f: number): Rect => {
  if (f >= C0) return squeeze(HERO, f);
  const k = lerp(FROM.w / HERO.w, 1, lift(f));
  return { x: lerp(FROM.x, HERO.x, lift(f)), y: lerp(FROM.y, HERO.y, lift(f)), w: HERO.w * k, h: HERO.h * k };
};

/** the page inside the phone: scrolled to today's question; from A2.mirror its card shows both answers */
const homeAt = (f: number): HomeState => {
  const m = A2.mirror;
  return {
    f,
    scroll: SCROLL * ease(f, A2.scroll[0], A2.scroll[1], SINE),
    qH: lerp(Q_H[0], Q_H[1], ease(f, m, m + 27)),
    teaserOut: ease(f, m, m + 5, IN),
    ansA: ease(f, m, m + 22),
    ansB: ease(f, m + 5, m + 27),
    check: ease(f, m + 22, m + 34),
    match: 0, // the mood match is Act 4's (V3)
    cta: 1,
    answered: ease(f, m, m + 12),
    carets: [],
  };
};

// ── a piece whose rect animates; content is laid out for `home`; from C0 it is squeezed into the cell ───────────────
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

// ── the number, stepping back to its corner ───────────────────────────────────────────────────────────────────────
const SteppedCounter: React.FC = () => {
  const f = useCurrentFrame();
  const { x, y, s, o } = stepAt(f);
  return <Counter x={x} y={y} scale={s} opacity={o} f={f} />;
};

// ── the partner's dot → the notification ──────────────────────────────────────────────────────────────────────────
const FlyingDot: React.FC = () => {
  const f = useCurrentFrame();
  const p = dotAt(f);
  return <Dot x={p.x} y={p.y} r={dotR(f)} who="other" glow={0.35 * (1 - ease(f, K.GROW[0], A2.card[0] + 4))} />;
};
const Notification: React.FC = () => {
  const f = useCurrentFrame();
  const rect = cardRect(f);
  const r = dotR(f);
  const p = T.a2.push;
  const [ax, ay] = [AV.cx - CARD.x, AV.cy - CARD.y];
  // while it opens the card is the dot growing; once open it slides as one piece
  const home = f < A2.leave[0] ? CARD : { ...CARD, x: rect.x };
  return (
    <Piece rect={rect} home={home} f={f} radius={Math.min(32, rect.h / 2)} alpha={0.94}>
      <div style={abs(ax - r, ay - r, { width: 2 * r, height: 2 * r, borderRadius: "50%", background: C.lavender })} />
      <div style={abs(ax + 31 - 19, ay + 31 - 19, { width: 38, height: 38, borderRadius: 11, background: C.white })} />
      <Heart x={ax + 31} y={ay + 31} size={32} />
      <div style={abs(152, 36, { width: CARD.w - 152 - 36, height: 50, display: "flex", alignItems: "baseline", justifyContent: "space-between", whiteSpace: "nowrap" })}>
        <span style={{ fontSize: 40, fontWeight: 700, color: C.ink, letterSpacing: "-0.01em" }}>{p.title}</span>
        <span style={{ fontSize: 28, fontWeight: 500, color: C.ink2 }}>{p.when}</span>
      </div>
      <div style={abs(152, 94, { fontSize: 36, fontWeight: 500, color: C.ink2, whiteSpace: "nowrap", lineHeight: "44px" })}>{p.body}</div>
    </Piece>
  );
};

// ── the phone: the real Home ──────────────────────────────────────────────────────────────────────────────────────
const PhoneShot: React.FC = () => {
  const f = useCurrentFrame();
  const rect = phoneRect(f);
  const screen = <HomeA2 s={homeAt(f)} />;
  if (f < C0) return <Phone x={rect.x} y={rect.y} scale={PS}>{screen}</Phone>;
  return (
    <Piece rect={rect} home={PH} f={f} radius={(PHONE.radius + BEZEL) * PS} alpha={0} shadow={false}>
      <Phone x={0} y={0} scale={PS}>
        {screen}
      </Phone>
    </Piece>
  );
};

// ── the hero: the question and the two answers at film scale ──────────────────────────────────────────────────────
const glowAt = (f: number) => (f < A2.unlock ? 0 : Math.sin(Math.PI * Math.min(1, (f - A2.unlock) / K.GLOW))); // once: up and gone
const AnswerCard: React.FC<{ y: number; h: number; who: "you" | "other"; glow: number; children: ReactNode }> = ({ y, h, who, glow, children }) => {
  const edge = who === "you" ? C.rose : C.lavender;
  return (
    <div
      style={abs(0, y, {
        width: HERO.w,
        height: h,
        borderRadius: 24,
        background: C.card,
        boxShadow: `0 8px 24px rgba(255,107,157,0.12), 0 0 0 ${3 * glow}px ${rgba(edge, 0.45 * glow)}, 0 0 ${48 * glow}px ${rgba(edge, 0.5 * glow)}`,
        overflow: "hidden",
      })}
    >
      <div style={abs(0, 0, { width: 6, height: h, background: edge })} />
      {children}
    </div>
  );
};
const answerLines = (text: string) => text.split(/(?<=,) /).map((part, i) => <div key={i}>{part}</div>); // his breaks at his comma
const HeroContent: React.FC = () => {
  const f = useCurrentFrame();
  const g = glowAt(f);
  const unmask = ease(f, A2.unlock + 4, A2.unlock + 4 + K.UNLOCK_WIPE); // starts once the teaser is out of its way
  const veil = 1 - ease(f, A2.unlock, A2.unlock + 12);
  const teaserOut = ease(f, A2.unlock, A2.unlock + 4, IN);
  const sendIn = ease(f, A2.sendIn[0], A2.sendIn[1]);
  const sendOut = ease(f, A2.unlock, A2.unlock + 8, IN);
  const typing = f >= A2.type[0] && f <= A2.type[1];
  const caretOn = f >= A2.lift[1] && f < A2.press && (typing || Math.floor((f - A2.lift[1]) / 30) % 2 === 0);
  const TEXT: CSSProperties = { fontSize: 40, fontWeight: 500, color: C.ink, lineHeight: `${LINE}px`, letterSpacing: "-0.005em", whiteSpace: "nowrap" };
  const LABEL: CSSProperties = { fontSize: 28, fontWeight: 600, lineHeight: "34px", whiteSpace: "nowrap" };
  return (
    <>
      <div style={abs(0, 0, { width: HERO.w, fontSize: 56, fontWeight: 700, lineHeight: "66px", letterSpacing: "-0.012em", color: C.ink, textWrap: "balance" } as CSSProperties)}>{T.a2.question}</div>
      <AnswerCard y={HIS.y} h={HIS.h} who="other" glow={g}>
        <div style={abs(TEXT_X, 24, { ...LABEL, color: C.lavenderDeep })}>{T.a2.answerOther.label}</div>
        {/* locked: his words are there but blurred under a lavender veil, the teaser on top */}
        {veil > 0 && (
          <div style={abs(TEXT_X, TEXT_Y, { ...TEXT, filter: "blur(12px)", opacity: veil })}>{answerLines(T.a2.answerOther.text)}</div>
        )}
        {veil > 0 && <div style={abs(TEXT_X - 12, TEXT_Y - 6, { width: HERO.w - TEXT_X - 24, height: 2 * LINE + 12, borderRadius: 18, background: rgba(C.lavender, 0.1 * veil) })} />}
        {teaserOut < 1 && (
          <div style={abs(TEXT_X + 8, TEXT_Y + LINE - 22 - 12 * teaserOut, { height: 44, display: "flex", alignItems: "center", gap: 16, opacity: 1 - teaserOut })}>
            <Glyph name="lock" size={34} color={C.lavenderDeep} />
            <span style={{ fontSize: 36, fontWeight: 600, color: C.ink, whiteSpace: "nowrap" }}>{T.a2.rows[0].other}</span>
          </div>
        )}
        {/* UNLOCK: the words unmask left → right */}
        {unmask > 0 && <div style={abs(TEXT_X, TEXT_Y, { ...TEXT, clipPath: `inset(-8px ${(1 - unmask) * 100}% -8px 0)` })}>{answerLines(T.a2.answerOther.text)}</div>}
      </AnswerCard>
      <AnswerCard y={YOURS.y} h={YOURS.h} who="you" glow={g}>
        <div style={abs(TEXT_X, 24, { ...LABEL, color: C.roseDeep })}>{T.a2.answerYou.label}</div>
        <div style={abs(TEXT_X, TEXT_Y, { ...TEXT, display: "flex", alignItems: "center" })}>
          {typed(K.TYPED, f)}
          <span style={{ display: "inline-block", width: 3, height: 44, marginLeft: 5, background: C.rose, opacity: caretOn ? 1 : 0 }} />
        </div>
        {sendIn > 0 && sendOut < 1 && (
          <Pill
            text={T.a2.send}
            size={28}
            scale={press(f, A2.press) * (1 - sendOut)}
            style={{ left: HERO.w - 28 - SEND.w, top: TEXT_Y + LINE / 2 - SEND.h / 2, width: lerp(SEND.h, SEND.w, sendIn), height: SEND.h, padding: 0, overflow: "hidden" }}
          />
        )}
      </AnswerCard>
    </>
  );
};
const Hero: React.FC = () => {
  const f = useCurrentFrame();
  const rect = heroRect(f);
  if (f >= C0)
    return (
      <Piece rect={rect} home={HERO} f={f} radius={24} alpha={0} shadow={false}>
        <HeroContent />
      </Piece>
    );
  const k = rect.w / HERO.w;
  // the plate: the phone's white card, growing with the lift and melting away as the hero arrives
  const plate = mixRect(FROM, { x: HERO.x - 28, y: HERO.y - 28, w: HERO.w + 56, h: HERO.h + 56 }, lift(f));
  const plateO = 1 - ease(f, (A2.lift[0] + A2.lift[1]) / 2, A2.lift[1]);
  return (
    <>
      {plateO > 0 && <div style={abs(plate.x, plate.y, { width: plate.w, height: plate.h, borderRadius: lerp(24 * PS, 32, lift(f)), background: C.card, opacity: plateO, boxShadow: "0 10px 30px rgba(255,107,157,0.14)" })} />}
      <div style={abs(rect.x, rect.y, { width: HERO.w, height: HERO.h, transformOrigin: "0 0", transform: `scale(${k})` })}>
        <HeroContent />
      </div>
    </>
  );
};

// ── the act ───────────────────────────────────────────────────────────────────────────────────────────────────────
export const Act2: React.FC = () => {
  const f = useCurrentFrame();
  if (f >= K.CELL_AT) {
    // H720: the picture IS the cell now; the number rests at its corner, ticking. Nothing else.
    return (
      <Camera s={1}>
        <SteppedCounter />
        <div style={abs(CELL.x, CELL.y, { width: CELL.w, height: CELL.h, borderRadius: 6, background: C.ink })} />
      </Camera>
    );
  }
  const capIn = ease(f, A2.caption, A2.caption + K.CAP_IN);
  const capOut = ease(f, K.CAP_OUT[0], K.CAP_OUT[1], IN);
  return (
    <Camera s={camAt(f)}>
      <Blur on={speedOf(counterRect, f) > SNAP}>
        <SteppedCounter />
      </Blur>
      {f < K.OLD_OUT[1] && <A1Caption f={f} exit={a1CaptionExit(f, K.OLD_OUT[0], K.OLD_OUT[1])} />}
      {f >= A2.phone[0] && (
        <Blur on={speedOf(phoneRect, f) > SNAP}>
          <PhoneShot />
        </Blur>
      )}
      {f < A2.card[0] ? (
        <Blur on={speedOf(dotRect, f) > SNAP}>
          <FlyingDot />
        </Blur>
      ) : (
        f < A2.leave[1] && (
          <Blur on={speedOf(cardRect, f) > SNAP}>
            <Notification />
          </Blur>
        )
      )}
      {f >= A2.lift[0] && (
        <Blur on={speedOf(heroRect, f) > SNAP}>
          <Hero />
        </Blur>
      )}
      {f >= A2.caption && (
        <Caption text={T.a2.caption} x={120} y={900} size={64} weight={700} style={{ letterSpacing: "-0.01em", clipPath: `inset(-14px ${(1 - capIn) * 100}% -14px ${capOut * 100}%)` }} />
      )}
    </Camera>
  );
};
