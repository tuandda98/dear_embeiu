// V1 hook (0–120) + V2 the question (120–600) of the 9:16 cut (1080×1920). Spec: VERTICAL.md. The film's Act 1–2
// re-laid out for a phone held upright: the counter, the typed hook, the dot's drop and swoop, the notification, the
// real Home phone, the question card lifting out, your answer typing, the UNLOCK, "Cần cả hai.". Everything that must be
// read sits inside SAFE (x 80–940, y 200–1500); at most two things move at once. Every pixel is a function of the frame.
import type { CSSProperties, ReactNode } from "react";
import { AbsoluteFill, Easing, useCurrentFrame } from "remotion";
import { T } from "../../copy/strings.ts";
import { C, PHONE } from "../../lib/tokens.ts";
import { blink, ease, lerp, press, settle } from "../../lib/ease.ts";
import { typedCount } from "../../timeline/typing.ts";
import { clockAt } from "../../story/Counter.tsx";
import { Digits, digitsWidth, group, pad2 } from "../../components/Digits.tsx";
import { Blur } from "../../components/Blur.tsx";
import { Dot } from "../../components/Dot.tsx";
import { Heart } from "../../components/Heart.tsx";
import { Phone } from "../../components/Phone.tsx";
import { Pill } from "../../components/Card.tsx";
import { G as Glyph } from "../../acts/a4/glyphs.tsx";
import { HOME } from "../../acts/a4/home.tsx";
import { HomeA2, Q_H, type HomeState } from "../../acts/a2/home.tsx";
import { SAFE } from "../timeline.ts";
import { HOOK, TYPED, V } from "./timing.ts";

const IN_OUT = Easing.inOut(Easing.cubic);
const IN = Easing.in(Easing.cubic);
const SNAP = 20; // px/frame: above this a piece is motion-blurred
type Rect = { x: number; y: number; w: number; h: number };
const mixRect = (a: Rect, b: Rect, t: number): Rect => ({ x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t), w: lerp(a.w, b.w, t), h: lerp(a.h, b.h, t) });
const speedOf = (at: (f: number) => Rect, f: number) => {
  const a = at(f - 0.5), b = at(f + 0.5);
  return Math.max(Math.hypot(b.x - a.x, b.y - a.y), Math.hypot(b.x + b.w - a.x - a.w, b.y + b.h - a.y - a.h));
};
const hex = (c: string) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));
const rgba = (c: string, a: number) => `rgba(${hex(c).join(",")},${a})`;
const abs = (x: number, y: number, extra?: CSSProperties): CSSProperties => ({ position: "absolute", left: x, top: y, ...extra });
const B = T.vertical.v12.breaks;
/** a text cut into lines at word indices (layout data in T.vertical.v12): each line's [start, end) char range */
const lineRanges = (text: string, breaks: readonly number[]) => {
  const words = text.split(" ");
  const starts = [0, ...breaks];
  const at = (w: number) => words.slice(0, w).join(" ").length + (w > 0 ? 1 : 0); // char index where word w starts
  return starts.map((w, i) => [at(w), i + 1 < starts.length ? at(starts[i + 1]) - 1 : text.length] as const);
};
const lines = (text: string, breaks: readonly number[]) => lineRanges(text, breaks).map(([a, b]) => text.slice(a, b));
/** which line the caret is on after n typed characters (the break's space moves it to the next line) */
const caretLine = (ranges: readonly (readonly [number, number])[], n: number) => {
  const i = ranges.findIndex(([, b]) => n <= b);
  return i < 0 ? ranges.length - 1 : i;
};

// ── geometry (1080×1920) ──────────────────────────────────────────────────────────────────────────────────────────
const X = SAFE.left; // 80
const NUM = 300; // the number's type size at hero scale
/** the vertical counter's own layout (offsets inside its block, at scale 1) */
const VC = { x: X, y: 430, eyebrow: 0, number: 70, unit: 392, clock: 470, labels: 542 } as const;
const CORNER = { x: X, y: 200, scale: 0.36, opacity: 0.7 } as const; // V2: small, top-left, out of the story's way
const DOT = { x: VC.x + digitsWidth(T.a1.days, NUM) + 64, y: VC.y + VC.number + NUM / 2 }; // where the dot lands
const HOOK_POS = { x: X, y: 1070, size: 80, line: 98 }; // 84 px: line 1 needs 896 px, SAFE has 860 → 80 px keeps the two-line break
const CARD: Rect = { x: X, y: 420, w: 920, h: 218 }; // the notification (title 52 · body 46 · time 36)
const AV = { cx: CARD.x + 40 + 56, cy: CARD.y + CARD.h / 2, r: 56 }; // its 112 px avatar slot = the dot's place
const BEZEL = 12;
const PS = 1100 / (PHONE.h + 2 * BEZEL); // ≈ 1.225: the phone ≈ 1100 px tall
const PH: Rect = { x: (1080 - (PHONE.w + 2 * BEZEL) * PS) / 2, y: 700, w: (PHONE.w + 2 * BEZEL) * PS, h: (PHONE.h + 2 * BEZEL) * PS };
const SINK_Y = 1460; // sunk: only its top shows, under the cards
const SCROLL = 436; // pt: today's question card high in the phone's viewport
/** the hero, in its own box: question 420–648 · his card 684–994 · your card 1018–1264 */
const HERO: Rect = { x: X, y: 420, w: 920, h: 844 };
const HIS = { y: 264, h: 310 };
const YOURS = { y: 598, h: 246 };
const TEXT_X = 40; // after the 6 px edge
const TEXT_Y = 92; // first answer line under its 40 px label
const LINE = 64; // 52 px answers
const SEND = { w: 170, h: 84, right: SAFE.right - X }; // the pill's right edge on SAFE.right (hero-local 860)
const CAPTION = { x: X, y: 1310, size: 96 };
/** where the lift starts: the phone's question card at SCROLL, the phone risen (film px) */
const FROM: Rect = { x: PH.x + (BEZEL + 16) * PS, y: PH.y + (BEZEL + HOME.q - SCROLL) * PS, w: 370 * PS, h: Q_H[0] * PS };

// ── the vertical counter (story/Counter.tsx's block, re-set for 9:16: eyebrow 36 · 1250 at 300 · NGÀY 40 · clock 60 ·
// labels 32; Counter's own sizes are fixed for 16:9). Its fine print fades out below scale 0.4, as the film's does.
const VCounter: React.FC<{ x: number; y: number; s: number; o: number; f: number }> = ({ x, y, s, o, f }) => {
  const c = clockAt(f);
  const fine = Math.min(1, Math.max(0, (s - 0.4) / 0.3));
  const groups = [group(c.h), pad2(c.m), pad2(c.s)];
  const label: CSSProperties = { fontWeight: 600, color: C.ink2, opacity: fine, whiteSpace: "nowrap" };
  return (
    <div style={abs(x, y, { width: 900, height: 600, transformOrigin: "0 0", transform: `scale(${s})`, opacity: o, color: C.ink })}>
      <div style={abs(0, VC.eyebrow, { ...label, fontSize: 36, letterSpacing: "0.12em" })}>{T.a1.eyebrow}</div>
      <Digits value={T.a1.days} size={NUM} weight={700} style={{ position: "absolute", left: -7, top: VC.number, letterSpacing: "-0.02em" }} />
      <div style={abs(0, VC.unit, { ...label, fontSize: 40, letterSpacing: "0.14em" })}>{T.a1.unit}</div>
      <div style={abs(0, VC.clock, { display: "flex", alignItems: "flex-start" })}>
        {groups.map((g, i) => (
          <div key={i} style={{ display: "flex", alignItems: "flex-start" }}>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
              <Digits value={g} size={60} weight={700} />
              <div style={{ ...label, marginTop: 10, fontSize: 32, letterSpacing: "0.12em" }}>{T.a1.clock.labels[i]}</div>
            </div>
            {i < 2 && <div style={{ width: 40, textAlign: "center", fontSize: 60, fontWeight: 700, lineHeight: 1, color: C.ink2 }}>:</div>}
          </div>
        ))}
      </div>
    </div>
  );
};

// ── timing as pure functions ──────────────────────────────────────────────────────────────────────────────────────
/** the drop (src/acts/a1/shared.tsx): settle(zeta 0.75), stiffness solved so the first contact falls on V.land */
const Z = 0.75;
const WD = (Math.PI - Math.atan(Math.sqrt(1 - Z * Z) / Z)) / ((V.land - V.dropStart) / 60);
const DROP_K = (WD / Math.sqrt(1 - Z * Z)) ** 2;
const dropY = (f: number) => lerp(-50, DOT.y, settle(f, V.dropStart, { zeta: Z, stiffness: DROP_K }));
const stepAt = (f: number) => {
  const e = ease(f, V.step[0], V.step[1], Easing.out(Easing.sin)); // a recoil off the contact
  return { x: lerp(VC.x, CORNER.x, e), y: lerp(VC.y, CORNER.y, e), s: lerp(1, CORNER.scale, e), o: lerp(1, CORNER.opacity, e) };
};
const counterRect = (f: number): Rect => {
  const { x, y, s } = stepAt(f);
  return { x, y, w: 820 * s, h: 600 * s };
};
const dotR = (f: number) => lerp(18, AV.r, ease(f, V.swoop[1] - 4, V.card[0] + 10));
const dotAt = (f: number) => {
  const t = ease(f, V.swoop[0], V.swoop[1], IN_OUT), u = 1 - t;
  const [x0, y0, cx, cy] = [DOT.x, dropY(f), 560, AV.cy + 90];
  return { x: u * u * x0 + 2 * u * t * cx + t * t * AV.cx, y: u * u * y0 + 2 * u * t * cy + t * t * AV.cy };
};
const dotRect = (f: number): Rect => {
  const p = dotAt(f), r = dotR(f);
  return { x: p.x - r, y: p.y - r, w: 2 * r, h: 2 * r };
};
const cardRect = (f: number): Rect => {
  const open = mixRect(dotRect(f), CARD, ease(f, V.card[0], V.card[1]));
  return { ...open, x: open.x - (CARD.x + CARD.w + 40) * ease(f, V.leave[0], V.leave[1], IN) };
};
const phoneRect = (f: number): Rect => {
  const up = lerp(1920 + 30, PH.y, settle(f, V.phone[0], { stiffness: 190, zeta: 0.85 }));
  return { ...PH, y: lerp(up, SINK_Y, ease(f, V.sink[0], V.sink[1], IN_OUT)) };
};
const lift = (f: number) => ease(f, V.lift[0], V.lift[1], IN_OUT);
const heroRect = (f: number): Rect => {
  const k = lerp(FROM.w / HERO.w, 1, lift(f));
  return { x: lerp(FROM.x, HERO.x, lift(f)), y: lerp(FROM.y, HERO.y, lift(f)), w: HERO.w * k, h: HERO.h * k };
};
const homeAt = (f: number): HomeState => {
  const m = V.mirror;
  return {
    f,
    scroll: SCROLL * ease(f, V.scroll[0], V.scroll[1], Easing.inOut(Easing.sin)),
    qH: lerp(Q_H[0], Q_H[1], ease(f, m, m + 27)),
    teaserOut: ease(f, m, m + 5, IN),
    ansA: ease(f, m, m + 22),
    ansB: ease(f, m + 5, m + 27),
    check: ease(f, m + 22, m + 34),
    match: 0, // the mood match is not in the 9:16 cut
    cta: 1,
    answered: ease(f, m, m + 12),
    carets: [],
  };
};

// ── pieces ────────────────────────────────────────────────────────────────────────────────────────────────────────
const SteppedCounter: React.FC = () => {
  const f = useCurrentFrame();
  const { x, y, s, o } = stepAt(f);
  return <VCounter x={x} y={y} s={s} o={o} f={f} />;
};
const FallingDot: React.FC = () => <Dot x={DOT.x} y={dropY(useCurrentFrame())} r={18} who="other" />;
const FlyingDot: React.FC = () => {
  const f = useCurrentFrame();
  const p = dotAt(f);
  return <Dot x={p.x} y={p.y} r={dotR(f)} who="other" glow={0.35 * (1 - ease(f, V.swoop[1] - 4, V.card[0] + 4))} />;
};

/** the hook, two lines at 84 px, typed; the rose caret after the last letter, then it blinks until the landing */
const HOOK_LINES = lineRanges(HOOK.text, B.hook);
const LAST_HOOK_KEY = HOOK.frames[HOOK.frames.length - 1];
const Hook: React.FC<{ f: number }> = ({ f }) => {
  const n = typedCount(HOOK, f);
  const out = ease(f, V.hookOut[0], V.hookOut[1], IN);
  const caretOn = f >= HOOK.frames[0] && f < V.land && (f <= LAST_HOOK_KEY + 15 || blink(f) === 1);
  const { x, y, size, line } = HOOK_POS;
  const pad = 18;
  return (
    <div style={abs(x, y - pad, { width: 1000, height: HOOK_LINES.length * line + 2 * pad, overflow: "hidden" })}>
      <div style={abs(0, pad + out * (HOOK_LINES.length * line + pad), { fontSize: size, fontWeight: 700, lineHeight: `${line}px`, letterSpacing: "-0.02em", color: C.ink })}>
        {HOOK_LINES.map(([a, b], i) => {
          const shown = HOOK.text.slice(a, Math.min(b, Math.max(a, n)));
          const here = n > 0 && i === caretLine(HOOK_LINES, n);
          return (
            <div key={i} style={{ height: line, whiteSpace: "nowrap", display: "flex", alignItems: "center" }}>
              {shown}
              {here && <span style={{ display: "inline-block", width: 5, height: 76, marginLeft: 8, background: C.rose, opacity: caretOn ? 1 : 0 }} />}
            </div>
          );
        })}
      </div>
    </div>
  );
};

const Notification: React.FC = () => {
  const f = useCurrentFrame();
  const rect = cardRect(f);
  const r = dotR(f);
  const p = T.a2.push;
  const [ax, ay] = [AV.cx - CARD.x, AV.cy - CARD.y];
  const home = f < V.leave[0] ? CARD : { ...CARD, x: rect.x };
  return (
    <div style={abs(rect.x, rect.y, { width: rect.w, height: rect.h, borderRadius: Math.min(36, rect.h / 2), background: "rgba(255,255,255,0.95)", boxShadow: C.shadow, overflow: "hidden" })}>
      <div style={abs(home.x - rect.x, home.y - rect.y, { width: CARD.w, height: CARD.h })}>
        <div style={abs(ax - r, ay - r, { width: 2 * r, height: 2 * r, borderRadius: "50%", background: C.lavender })} />
        <div style={abs(ax + 40 - 24, ay + 40 - 24, { width: 48, height: 48, borderRadius: 14, background: C.white })} />
        <Heart x={ax + 40} y={ay + 40} size={40} />
        <div style={abs(184, 44, { fontSize: 52, fontWeight: 700, lineHeight: "64px", letterSpacing: "-0.01em", color: C.ink, whiteSpace: "nowrap" })}>{p.title}</div>
        <div style={abs(184, 118, { width: SAFE.right - X - 184, height: 56, display: "flex", alignItems: "baseline", justifyContent: "space-between", whiteSpace: "nowrap" })}>
          <span style={{ fontSize: 46, fontWeight: 500, color: C.ink2 }}>{p.body}</span>
          <span style={{ fontSize: 36, fontWeight: 500, color: C.ink2 }}>{p.when}</span>
        </div>
      </div>
    </div>
  );
};

const PhoneShot: React.FC = () => {
  const f = useCurrentFrame();
  const r = phoneRect(f);
  return (
    <Phone x={r.x} y={r.y} scale={PS}>
      <HomeA2 s={homeAt(f)} />
    </Phone>
  );
};

// ── the hero: the question and the two answers ────────────────────────────────────────────────────────────────────
const glowAt = (f: number) => (f < V.unlock ? 0 : Math.sin(Math.PI * Math.min(1, (f - V.unlock) / 30)));
const AnswerCard: React.FC<{ y: number; h: number; who: "you" | "other"; glow: number; children: ReactNode }> = ({ y, h, who, glow, children }) => {
  const edge = who === "you" ? C.rose : C.lavender;
  return (
    <div style={abs(0, y, { width: HERO.w, height: h, borderRadius: 28, background: C.card, overflow: "hidden", boxShadow: `0 8px 24px rgba(255,107,157,0.12), 0 0 0 ${4 * glow}px ${rgba(edge, 0.45 * glow)}, 0 0 ${60 * glow}px ${rgba(edge, 0.5 * glow)}` })}>
      <div style={abs(0, 0, { width: 6, height: h, background: edge })} />
      {children}
    </div>
  );
};
const HeroContent: React.FC = () => {
  const f = useCurrentFrame();
  const g = glowAt(f);
  const unmask = ease(f, V.unlock + 4, V.unlock + 22);
  const veil = 1 - ease(f, V.unlock, V.unlock + 12);
  const teaserOut = ease(f, V.unlock, V.unlock + 4, IN);
  const sendIn = ease(f, V.sendIn[0], V.sendIn[1]);
  const sendOut = ease(f, V.unlock, V.unlock + 8, IN);
  const typing = f >= V.type[0] && f <= V.type[1];
  const caretOn = f >= V.lift[1] && f < V.press && (typing || Math.floor((f - V.lift[1]) / 30) % 2 === 0);
  const n = typedCount(TYPED, f);
  const yours = lineRanges(T.a2.answerYou.text, B.you);
  const TEXT: CSSProperties = { fontSize: 52, fontWeight: 500, lineHeight: `${LINE}px`, letterSpacing: "-0.005em", color: C.ink, whiteSpace: "nowrap" };
  const LABEL: CSSProperties = { fontSize: 40, fontWeight: 600, lineHeight: "48px", whiteSpace: "nowrap" };
  const his = lines(T.a2.answerOther.text, B.other).map((l, i) => <div key={i}>{l}</div>);
  return (
    <>
      <div style={abs(0, 0, { fontSize: 64, fontWeight: 700, lineHeight: "76px", letterSpacing: "-0.012em", color: C.ink })}>
        {lines(T.a2.question, B.question).map((l, i) => (
          <div key={i} style={{ whiteSpace: "nowrap" }}>{l}</div>
        ))}
      </div>
      <AnswerCard y={HIS.y} h={HIS.h} who="other" glow={g}>
        <div style={abs(TEXT_X, 28, { ...LABEL, color: C.lavenderDeep })}>{T.a2.answerOther.label}</div>
        {veil > 0 && <div style={abs(TEXT_X, TEXT_Y, { ...TEXT, filter: "blur(14px)", opacity: veil })}>{his}</div>}
        {veil > 0 && <div style={abs(TEXT_X - 14, TEXT_Y - 8, { width: SAFE.right - X - TEXT_X + 28, height: 3 * LINE + 16, borderRadius: 20, background: rgba(C.lavender, 0.1 * veil) })} />}
        {teaserOut < 1 && (
          <div style={abs(TEXT_X + 8, TEXT_Y + (3 * LINE) / 2 - 28 - 14 * teaserOut, { height: 56, display: "flex", alignItems: "center", gap: 18, opacity: 1 - teaserOut })}>
            <Glyph name="lock" size={42} color={C.lavenderDeep} />
            <span style={{ fontSize: 44, fontWeight: 600, color: C.ink, whiteSpace: "nowrap" }}>{T.a2.rows[0].other}</span>
          </div>
        )}
        {unmask > 0 && <div style={abs(TEXT_X, TEXT_Y, { ...TEXT, clipPath: `inset(-8px ${(1 - unmask) * 100}% -8px 0)` })}>{his}</div>}
      </AnswerCard>
      <AnswerCard y={YOURS.y} h={YOURS.h} who="you" glow={g}>
        <div style={abs(TEXT_X, 28, { ...LABEL, color: C.roseDeep })}>{T.a2.answerYou.label}</div>
        <div style={abs(TEXT_X, TEXT_Y, TEXT)}>
          {yours.map(([a, b], i) => {
            const shown = T.a2.answerYou.text.slice(a, Math.min(b, Math.max(a, n)));
            const here = i === caretLine(yours, n);
            return (
              <div key={i} style={{ height: LINE, display: "flex", alignItems: "center" }}>
                {shown}
                {here && <span style={{ display: "inline-block", width: 4, height: 56, marginLeft: 6, background: C.rose, opacity: caretOn ? 1 : 0 }} />}
              </div>
            );
          })}
        </div>
        {sendIn > 0 && sendOut < 1 && (
          <Pill
            text={T.a2.send}
            size={44}
            scale={press(f, V.press) * (1 - sendOut)}
            style={{ left: SEND.right - lerp(SEND.h, SEND.w, sendIn), top: TEXT_Y + LINE + LINE / 2 - SEND.h / 2, width: lerp(SEND.h, SEND.w, sendIn), height: SEND.h, padding: 0, overflow: "hidden" }}
          />
        )}
      </AnswerCard>
    </>
  );
};
const Hero: React.FC = () => {
  const f = useCurrentFrame();
  const rect = heroRect(f);
  const k = rect.w / HERO.w;
  const plate = mixRect(FROM, { x: HERO.x - 24, y: HERO.y - 24, w: HERO.w + 48, h: HERO.h + 48 }, lift(f));
  const plateO = 1 - ease(f, (V.lift[0] + V.lift[1]) / 2, V.lift[1]);
  return (
    <>
      {plateO > 0 && <div style={abs(plate.x, plate.y, { width: plate.w, height: plate.h, borderRadius: lerp(24 * PS, 36, lift(f)), background: C.card, opacity: plateO, boxShadow: "0 10px 30px rgba(255,107,157,0.14)" })} />}
      <div style={abs(rect.x, rect.y, { width: HERO.w, height: HERO.h, transformOrigin: "0 0", transform: `scale(${k})` })}>
        <HeroContent />
      </div>
    </>
  );
};

// ── V12 ───────────────────────────────────────────────────────────────────────────────────────────────────────────
export const V12: React.FC = () => {
  const f = useCurrentFrame();
  const capIn = ease(f, V.caption, V.caption + 16);
  return (
    <AbsoluteFill>
      <Blur on={speedOf(counterRect, f) > SNAP}>
        <SteppedCounter />
      </Blur>
      {f < V.hookOut[1] && <Hook f={f} />}
      {f >= V.phone[0] && (
        <Blur on={speedOf(phoneRect, f) > SNAP}>
          <PhoneShot />
        </Blur>
      )}
      {f >= V.dropStart && f < V.swoop[0] && (
        <Blur on={Math.abs(dropY(f + 0.5) - dropY(f - 0.5)) > SNAP}>
          <FallingDot />
        </Blur>
      )}
      {f >= V.swoop[0] && f < V.card[0] && (
        <Blur on={speedOf(dotRect, f) > SNAP}>
          <FlyingDot />
        </Blur>
      )}
      {f >= V.card[0] && f < V.leave[1] && (
        <Blur on={speedOf(cardRect, f) > SNAP}>
          <Notification />
        </Blur>
      )}
      {f >= V.lift[0] && (
        <Blur on={speedOf(heroRect, f) > SNAP}>
          <Hero />
        </Blur>
      )}
      {f >= V.caption && (
        <div style={abs(CAPTION.x, CAPTION.y - 16, { fontSize: CAPTION.size, fontWeight: 700, lineHeight: 1.2, letterSpacing: "-0.015em", color: C.ink, whiteSpace: "nowrap", padding: "16px 0", clipPath: `inset(0 ${(1 - capIn) * 100}% 0 0)` })}>
          {T.a2.caption}
        </div>
      )}
    </AbsoluteFill>
  );
};
