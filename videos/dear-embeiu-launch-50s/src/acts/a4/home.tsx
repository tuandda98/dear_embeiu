// The app's Home, rebuilt as vectors in screen points (402×874) from ref/ios/home-today, home-sleep-card, home-top,
// dq-revealed-2, mood-matched and the source (lib/widgets/counter_card.dart, today_ritual_card.dart, mood_card.dart,
// sleep/sleep_card.dart, today_constellation.dart). Every state is a pure function of the frame: the day's events light
// the cards (question → both answers at 15:30, mood → matched at 22:45, the n/6 pill, the streak chip, the chat dot),
// and the page scrolls to the card the day is on.
import type { CSSProperties, ReactNode } from "react";
import { Img, staticFile } from "remotion";
import { C } from "../../lib/tokens.ts";
import { ease, lerp, settle } from "../../lib/ease.ts";
import { T } from "../../copy/strings.ts";
import { A4 } from "../../timeline/cues.ts";
import { StatusBar } from "../../components/Phone.tsx";
import { Digits } from "../../components/Digits.tsx";
import { HEART_PATH } from "../../components/Heart.tsx";
import { clockAt } from "../../story/Counter.tsx";
import { G } from "./glyphs.tsx";
import { EVENT_F } from "./events.ts";
import { Roll, countAt, diag, inOut } from "./parts.tsx";

const H = T.a4.home;
const WHITE_INK = "0 1px 4px rgba(0, 0, 0, 0.30)"; // white on a photo: a soft dark shadow, never a halo (BRIEF §4)
const SURFACE = C.tint; // AppColors.surfaceLight

// ── layout (content y = screen y at scroll 0) ──────────────────────────────────────────────────────────────────────
export const HOME = {
  view: 126, // the scroll viewport starts under the pinned header (the captures clip there)
  card: { x: 16, y: 146, w: 370, h: 392 }, // the counter card
  today: 566, // "Hôm nay của chúng mình" + the n/6 pill (44 tall)
  q: 622, // the question card
  qH: [155, 337], // nobody answered → both answers
  moodH: [282, 434], // nobody shared → matched
  sleepH: 198,
} as const;

const Q_REVEAL = EVENT_F[5]; // "Bạn đã trả lời · mở cả hai" (15:30)
const MATCH = EVENT_F[9]; // "Bạn: Nhớ 🥹" (22:45)
export const revealT = (f: number) => ease(f, Q_REVEAL, Q_REVEAL + 18);
export const matchT = (f: number) => ease(f, MATCH, MATCH + 18);

/** the page's scroll (pt): to the question card before 15:00, to the mood card before 22:00, back to the number */
const SCROLL: [number, number, number, number][] = [
  [1500, 1530, 0, 222], // on 8ths, like every other move
  [1575, 1620, 222, 600],
  [A4.caption + 5, A4.caption + 65, 600, 0], // back to the number while the caption says it is still there
];
export const scrollAt = (f: number) => SCROLL.reduce((y, [a, b, from, to]) => (f >= a ? lerp(from, to, inOut(f, a, b)) : y), 0);

// ── small pieces ───────────────────────────────────────────────────────────────────────────────────────────────────
const abs = (s: CSSProperties): CSSProperties => ({ position: "absolute", ...s });
const Txt: React.FC<{ s: CSSProperties; children: ReactNode }> = ({ s, children }) => <div style={abs({ whiteSpace: "nowrap", ...s })}>{children}</div>;

/** the couple's names with the icon's heart between them (the app draws the heart as an icon, not a glyph) */
export const Names: React.FC<{ size: number; heart: number; color: string; gap: number; shadow?: string; weight?: number; upper?: boolean; heartColor?: string; tracking?: string; pair?: readonly [string, string] }> = ({
  pair = [T.couple.you, T.couple.other],
  size,
  heart,
  color,
  gap,
  shadow,
  weight = 700,
  upper,
  heartColor,
  tracking,
}) => {
  const t = (s: string) => (upper ? s.toUpperCase() : s);
  return (
    <div style={{ display: "flex", alignItems: "center", gap, fontSize: size, fontWeight: weight, color, textShadow: shadow, letterSpacing: tracking, whiteSpace: "nowrap", lineHeight: 1.2 }}>
      <span>{t(pair[0])}</span>
      <svg width={heart} height={heart} viewBox="150 140 724 640" style={{ filter: shadow ? "drop-shadow(0 1px 3px rgba(0,0,0,0.3))" : undefined }}>
        <path d={HEART_PATH} fill={heartColor ?? color} />
      </svg>
      <span>{t(pair[1])}</span>
    </div>
  );
};

/** the app's EyebrowChip with its leading glyph (frosted pill, tracked uppercase 600) */
const GlyphChip: React.FC<{ text: string; glyph: ReactNode; style: CSSProperties }> = ({ text, glyph, style }) => (
  <div
    style={abs({
      display: "flex",
      alignItems: "center",
      gap: 8,
      height: 28,
      padding: "0 14px 0 12px",
      borderRadius: 999,
      background: "rgba(255,255,255,0.72)",
      boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.65), 0 4px 12px rgba(255,107,157,0.10)",
      fontSize: 12,
      fontWeight: 600,
      letterSpacing: "0.12em",
      color: C.ink,
      whiteSpace: "nowrap",
      ...style,
    })}
  >
    {glyph}
    {text}
  </div>
);

// ── the counter card (lib/widgets/counter_card.dart, days-only hero + live clock, over the cover photo) ─────────────
export const CARD_SHADOW = "0 16px 36px rgba(255,107,157,0.36), 0 24px 48px rgba(167,139,250,0.18)";

/** the photo + the scrim (the app's adaptive one, at this beach photo's strength) + the glass hairline */
export const PhotoBack: React.FC<{ top: number; bottom: number; radius: number; pos?: string; rim?: number }> = ({ top, bottom, radius, pos = "50% 50%", rim = 1 }) => (
  <>
    <Img src={staticFile("photos/03.jpg")} style={abs({ inset: 0, width: "100%", height: "100%", objectFit: "cover", objectPosition: pos })} />
    <div style={abs({ inset: 0, background: `linear-gradient(180deg, rgba(0,0,0,${top}) 0%, rgba(0,0,0,${bottom}) 100%)` })} />
    {rim > 0 && <div style={abs({ inset: 0, borderRadius: radius, boxShadow: `inset 0 0 0 1.2px rgba(255,255,255,${0.3 * rim})` })} />}
  </>
);

const Hairline: React.FC<{ toRight: boolean }> = ({ toRight }) => (
  <div style={{ width: 28, height: 1, background: `linear-gradient(90deg, rgba(255,255,255,${toRight ? 0.55 : 0}), rgba(255,255,255,${toRight ? 0 : 0.55}))` }} />
);

const ClockPill: React.FC<{ f: number }> = ({ f }) => {
  const c = clockAt(f);
  const seg = (v: string, label: string, w?: number) => (
    <div style={{ width: w, padding: w ? 0 : "0 7px", display: "flex", flexDirection: "column", alignItems: "center" }}>
      <Digits value={v} size={20} weight={700} color={C.white} style={{ textShadow: "0 0 12px rgba(255,255,255,0.35)" }} />
      <div style={{ marginTop: 4, fontSize: 10, fontWeight: 600, letterSpacing: "0.11em", lineHeight: 1, color: "rgba(255,255,255,0.70)" }}>{label}</div>
    </div>
  );
  const sep = <div style={{ paddingTop: 2, fontSize: 16, fontWeight: 700, lineHeight: 1, color: "rgba(255,255,255,0.60)" }}>:</div>;
  const [lh, lm, ls] = T.a1.clock.labels;
  return (
    <div style={{ display: "flex", alignItems: "flex-start", padding: "10px 11px", borderRadius: 999, background: "rgba(255,255,255,0.14)", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.22)" }}>
      {seg(c.text.split(" : ")[0], lh)}
      {sep}
      {seg(c.text.split(" : ")[1], lm, 40)}
      {sep}
      {seg(c.text.split(" : ")[2], ls, 40)}
    </div>
  );
};

/** the streak chip: "30 ngày kết nối · chờ trả lời hôm nay 🌸" rolls up into "31 ngày kết nối · hôm nay xong rồi" */
const StreakChip: React.FC<{ f: number }> = ({ f }) => {
  const t = ease(f, Q_REVEAL, Q_REVEAL + 10);
  const w = lerp(300, 266, t);
  const line = (s: string, y: number, o: number) => (
    <div style={abs({ left: 36, top: 8 + y, fontSize: 13, fontWeight: 700, letterSpacing: "-0.008em", lineHeight: "16px", color: C.white, opacity: o, whiteSpace: "nowrap" })}>{s}</div>
  );
  return (
    <div style={abs({ left: (370 - w) / 2, top: 333, width: w, height: 32, borderRadius: 999, overflow: "hidden", background: "rgba(255,255,255,0.18)", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.30)" })}>
      <G name="star" size={14} color={C.rose} style={abs({ left: 14, top: 9 })} />
      {t < 1 && line(H.streakBefore, -t * 22, 1 - t)}
      {t > 0 && line(T.a3.chip, (1 - t) * 22, t)}
    </div>
  );
};

/** the hero number's style on the card (the lift carries it on its own, see widgets.tsx) */
export const NUMBER = { top: 99, size: 76, tracking: -0.021, shadow: [2, 18, 0.45] } as const;
/** the card's content in its 370×392 box (shared with the card that lifts off at the delivery) */
export const CounterContent: React.FC<{ f: number; number?: boolean }> = ({ f, number = true }) => {
  const row = (top: number, h: number, children: ReactNode) => <div style={abs({ left: 0, right: 0, top, height: h, display: "flex", justifyContent: "center", alignItems: "center" })}>{children}</div>;
  return (
    <>
      {row(28, 24, <Names size={20} heart={18} color={C.white} gap={6} shadow={WHITE_INK} />)}
      {row(
        64,
        15,
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <Hairline toRight={false} />
          <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: "0.18em", color: "rgba(255,255,255,0.92)", textShadow: WHITE_INK }}>{T.a1.eyebrow}</span>
          <Hairline toRight />
        </div>,
      )}
      {number &&
        row(
          NUMBER.top,
          NUMBER.size,
          <span style={{ fontSize: NUMBER.size, fontWeight: 800, lineHeight: 1, letterSpacing: `${NUMBER.tracking}em`, color: C.white, textShadow: `0 ${NUMBER.shadow[0]}px ${NUMBER.shadow[1]}px rgba(0,0,0,${NUMBER.shadow[2]})` }}>{T.a1.days}</span>,
        )}
      {row(181, 15, <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: "0.13em", color: "rgba(255,255,255,0.82)", textShadow: WHITE_INK }}>{T.a1.unit}</span>)}
      {row(212, 54, <ClockPill f={f} />)}
      <div style={abs({ left: 24, right: 24, top: 284, height: 17, display: "flex", alignItems: "center", gap: 8, color: C.white, textShadow: WHITE_INK })}>
        <G name="flag" size={15} color="rgba(255,255,255,0.92)" />
        <span style={{ flex: 1, fontSize: 13, fontWeight: 700, letterSpacing: "0.015em" }}>{H.milestone}</span>
        <span style={{ fontSize: 12, fontWeight: 600, color: "rgba(255,255,255,0.85)" }}>{H.milestoneLeft}</span>
      </div>
      <div style={abs({ left: 24, right: 24, top: 311, height: 8, borderRadius: 999, background: "rgba(255,255,255,0.25)", overflow: "hidden" })}>
        <div style={{ width: `${(1250 / 1500) * 100}%`, height: "100%", borderRadius: 999, background: C.white }} />
      </div>
      <StreakChip f={f} />
    </>
  );
};

const CounterCard: React.FC<{ f: number; y: number }> = ({ f, y }) => (
  <div style={abs({ left: HOME.card.x, top: y, width: HOME.card.w, height: HOME.card.h, borderRadius: 28, boxShadow: CARD_SHADOW, background: `linear-gradient(${diag(370, 392)}deg, ${C.sunset.join(", ")})` })}>
    <div style={abs({ inset: 0, borderRadius: 28, overflow: "hidden" })}>
      <PhotoBack top={0.26} bottom={0.46} radius={28} />
      <CounterContent f={f} />
    </div>
  </div>
);

// ── "Hôm nay của chúng mình" + the constellation pill (today_constellation.dart ConstellationPill) ───────────────────
const OUTLINE: [number, number][] = [[130, 66], [70, 40], [30, 104], [82, 162], [130, 206], [178, 162], [230, 104], [190, 40]];
const STAR_AT = { you: [[70, 40], [30, 104], [82, 162]], other: [[190, 40], [230, 104], [178, 162]] } as const;
/** when each of the six stars is lit: [who, task (0 Câu hỏi · 1 Tâm trạng · 2 Nhắn tin), the event that lights it (-1 = before the day)] */
const LIGHTS: ["you" | "other", 0 | 1 | 2, number][] = [
  ["other", 0, -1],
  ["you", 2, -1],
  ["you", 0, 5],
  ["other", 2, 6],
  ["other", 1, 8],
  ["you", 1, 9],
];
const MiniHeart: React.FC<{ f: number }> = ({ f }) => {
  const k = 260 / 24; // the app's 260×216 box drawn at 24×20
  return (
    <svg width={24} height={20} viewBox="0 0 260 216" style={{ display: "block", flex: "none" }}>
      <polygon points={OUTLINE.map((p) => p.join(",")).join(" ")} fill="none" stroke="rgba(26,26,46,0.22)" strokeWidth={k} strokeLinejoin="round" />
      {LIGHTS.map(([who, task, ev]) => {
        const [x, y] = STAR_AT[who][task];
        const col = who === "you" ? C.rose : C.lavenderDeep;
        const lit = ev < 0 ? 1 : ease(f, EVENT_F[ev], EVENT_F[ev] + 8);
        return (
          <g key={who + task}>
            {lit < 1 && <circle cx={x} cy={y} r={2.1 * k} fill="none" stroke={col} strokeWidth={k} opacity={1 - lit} />}
            {lit > 0 && <circle cx={x} cy={y} r={2.6 * k * lit} fill={col} />}
          </g>
        );
      })}
    </svg>
  );
};
const TodayHeader: React.FC<{ f: number; y: number }> = ({ f, y }) => {
  const v = countAt(1, f);
  return (
    <>
      <Txt s={{ left: 16, top: y + 9, fontSize: 22, fontWeight: 700, letterSpacing: "-0.009em", lineHeight: "26px", color: C.ink }}>{H.today}</Txt>
      <div
        style={abs({
          right: 16,
          top: y,
          height: 44,
          padding: "0 11px 0 10px",
          display: "flex",
          alignItems: "center",
          gap: 5,
          borderRadius: 999,
          background: "rgba(255,255,255,0.72)",
          boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.65), 0 2px 6px rgba(255,77,109,0.16)",
          color: C.ink,
          fontSize: 13,
          fontWeight: 700,
        })}
      >
        <MiniHeart f={f} />
        <Roll v={v} size={13} />
        <span style={{ marginLeft: -3 }}>{H.pill(Math.floor(v)).slice(String(Math.floor(v)).length)}</span>
      </div>
    </>
  );
};

// ── the question card (today_ritual_card.dart): A "Chạm để trả lời…" → D both answers ─────────────────────────────
const CONTENT_SHADOW = "0 10px 16px rgba(0,0,0,0.06)";
const Answer: React.FC<{ label: string; text: string; mine: boolean; top: number; h: number }> = ({ label, text, mine, top, h }) => (
  <div style={abs({ left: 20, right: 20, top, height: h, borderRadius: 16, background: mine ? SURFACE : "rgba(167,139,250,0.10)", padding: 12, boxSizing: "border-box" })}>
    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.027em", lineHeight: "13px", color: mine ? C.roseDeep : C.lavenderDeep }}>{label}</div>
    <div style={{ marginTop: 4, fontSize: 15, fontWeight: 500, lineHeight: 1.5, color: C.ink }}>{text}</div>
  </div>
);
const QuestionCard: React.FC<{ f: number; y: number }> = ({ f, y }) => {
  const t = revealT(f);
  const h = lerp(HOME.qH[0], HOME.qH[1], t);
  const body = 87;
  return (
    <div style={abs({ left: 16, top: y, width: 370, height: h, borderRadius: 24, background: C.card, boxShadow: CONTENT_SHADOW, overflow: "hidden" })}>
      <div style={abs({ left: 20, top: 20, width: 330, fontSize: 21, fontWeight: 600, lineHeight: 1.25, letterSpacing: "-0.0095em", color: C.ink })}>{H.question}</div>
      {t < 1 && (
        <div style={abs({ left: 20, right: 20, top: body, height: 48, opacity: 1 - ease(f, Q_REVEAL, Q_REVEAL + 6), borderRadius: 16, padding: 1.5, boxSizing: "border-box", background: "linear-gradient(135deg, rgba(255,107,157,0.45), rgba(255,182,193,0.30))" })}>
          <div style={{ height: "100%", borderRadius: 14.5, background: C.card, display: "flex", alignItems: "center", gap: 10, padding: "0 16px" }}>
            <G name="pen" size={17} color={C.rose} />
            <span style={{ flex: 1, fontSize: 14, fontWeight: 600, color: C.ink2 }}>{H.tapToAnswer}</span>
            <G name="chevron" size={16} color={C.ink3} />
          </div>
        </div>
      )}
      {t > 0 && (
        <div style={abs({ inset: 0, opacity: ease(f, Q_REVEAL + 2, Q_REVEAL + 12) })}>
          <Answer label={T.a2.answerYou.label} text={T.a2.answerYou.text} mine top={body} h={64} />
          <Answer label={T.a2.answerOther.label} text={T.a2.answerOther.text} mine={false} top={body + 74} h={87} />
          <div style={abs({ left: 20, top: body + 169, height: 36, display: "flex", alignItems: "center", gap: 12 })}>
            <div style={{ width: 36, height: 36, borderRadius: 18, background: "rgba(255,77,109,0.08)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <G name="heartLine" size={18} color={C.rose} />
            </div>
            <span style={{ fontSize: 13, fontWeight: 500, color: C.ink2 }}>{H.reactHint}</span>
          </div>
          <Txt s={{ right: 20, top: body + 215, fontSize: 13, fontWeight: 700, lineHeight: "16px", color: C.roseDeep }}>{H.collapse}</Txt>
        </div>
      )}
    </div>
  );
};

// ── the mood card (mood_card.dart): nobody shared → "Chúng mình cùng một tâm trạng 💞" ────────────────────────────
const [MOOD_EMOJI, MOOD_LABEL] = T.a2.moods[T.a2.picked];
const MoodSide: React.FC<{ label: string; empty: string; me: boolean; left: number }> = ({ label, empty, me, left }) => (
  <div style={abs({ left, top: me ? 8 : 4, width: 158, display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center" })}>
    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.036em", lineHeight: "13px", color: C.ink2 }}>{label}</div>
    <div style={{ marginTop: 10, width: 56, height: 56, borderRadius: 28, background: SURFACE, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <G name={me ? "plus" : "faceNeutral"} size={24} color={C.ink3} />
    </div>
    <div style={{ marginTop: 8, width: 140, fontSize: 12, lineHeight: 1.3, color: C.ink2, textWrap: "balance" }}>{empty}</div>
  </div>
);
const MoodCard: React.FC<{ f: number; y: number }> = ({ f, y }) => {
  const t = matchT(f);
  const h = lerp(HOME.moodH[0], HOME.moodH[1], t);
  const box = 72; // the content under the header
  const before = 1 - ease(f, MATCH, MATCH + 6);
  const after = ease(f, MATCH + 2, MATCH + 14);
  const pop = settle(f, MATCH + 2, { stiffness: 260, zeta: 0.8 });
  const cta = lerp(box + 142, box + 294, t);
  return (
    <div style={abs({ left: 16, top: y, width: 370, height: h, borderRadius: 24, background: C.card, boxShadow: CONTENT_SHADOW, overflow: "hidden" })}>
      <div style={abs({ left: 20, top: 20, width: 36, height: 36, borderRadius: 12, background: "rgba(255,77,109,0.12)", display: "flex", alignItems: "center", justifyContent: "center" })}>
        <G name="faceTile" size={20} color={C.rose} />
      </div>
      <Txt s={{ left: 68, top: 25, fontSize: 22, fontWeight: 700, letterSpacing: "-0.009em", lineHeight: "26px", color: C.ink }}>{H.mood}</Txt>
      {before > 0 && (
        <div style={abs({ left: 20, top: box, width: 330, height: 126, opacity: before })}>
          <MoodSide label={T.couple.youLabel} empty={H.moodYouEmpty} me left={0} />
          <div style={abs({ left: 164.5, top: 0, width: 1, height: 126, background: SURFACE })} />
          <MoodSide label={T.couple.otherLabel} empty={H.moodOtherEmpty} me={false} left={172} />
        </div>
      )}
      {after > 0 && (
        <div style={abs({ left: 20, top: box, width: 330, height: 278, opacity: after, borderRadius: 20, background: "rgba(255,77,109,0.06)", boxShadow: "inset 0 0 0 1px rgba(255,77,109,0.12)" })}>
          <div style={abs({ left: 101, top: 22, width: 128, height: 128, borderRadius: 64, background: "radial-gradient(circle, rgba(255,77,109,0.24) 0%, rgba(255,77,109,0) 70%)" })} />
          <div style={abs({ left: 119, top: 40, width: 92, height: 92, borderRadius: 46, background: C.card, boxShadow: "0 6px 16px rgba(255,107,157,0.18)", display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${0.6 + 0.4 * pop})` })}>
            <span style={{ fontSize: 58, lineHeight: 1 }}>{MOOD_EMOJI}</span>
          </div>
          <div style={abs({ left: 0, right: 0, top: 160, textAlign: "center", fontSize: 20, fontWeight: 800, lineHeight: "24px", color: C.ink })}>{MOOD_LABEL}</div>
          <div style={abs({ left: 0, right: 0, top: 192, display: "flex", justifyContent: "center" })}>
            <Names pair={[T.couple.youLabel, T.couple.otherLabel]} size={11} heart={12} color="rgba(26,26,46,0.6)" heartColor={C.roseDeep} gap={8} tracking="0.13em" />
          </div>
          <div style={abs({ left: 0, right: 0, top: 211, textAlign: "center", fontSize: 13, fontWeight: 600, lineHeight: "17px", color: C.roseDeep })}>{T.a2.matched}</div>
          <div style={abs({ left: 0, right: 0, top: 240, textAlign: "center", fontSize: 12, fontStyle: "italic", lineHeight: "16px", color: C.ink2 })}>
            {`${T.couple.otherLabel}: "${H.moodNote}"`}
          </div>
        </div>
      )}
      <div style={abs({ left: 20, right: 20, top: cta, height: 48, borderRadius: 999, overflow: "hidden" })}>
        <div style={abs({ inset: 0, background: `linear-gradient(${diag(330, 48)}deg, ${C.sunset.join(", ")})`, opacity: 1 - t })} />
        <div style={abs({ inset: 0, background: SURFACE, opacity: t })} />
        <div style={abs({ inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 8, opacity: 1 - after, color: C.white, fontSize: 15, fontWeight: 700 })}>
          <G name="heart" size={18} color={C.white} />
          {H.moodShare}
        </div>
        <div style={abs({ inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 8, opacity: after, color: C.ink2, fontSize: 15, fontWeight: 700 })}>
          <G name="pen" size={18} color={C.ink2} />
          {H.moodUpdate}
        </div>
      </div>
    </div>
  );
};

// ── "Đêm qua" (sleep/sleep_card.dart) — his lane is his person colour, purple (DESIGN §4) ──────────────────────────
const Moon: React.FC<{ color: string; lit: number }> = ({ color, lit }) => {
  const r = 15;
  const rx = Math.abs(1 - 2 * lit) * r;
  return (
    <svg width={30} height={30} viewBox="0 0 30 30" style={{ display: "block", flex: "none" }}>
      <circle cx={r} cy={r} r={r} fill={color} fillOpacity={0.16} />
      <path d={`M${r} 0A${r} ${r} 0 0 1 ${r} ${2 * r}A${rx} ${r} 0 0 ${lit > 0.5 ? 1 : 0} ${r} 0z`} fill={color} />
    </svg>
  );
};
const Duration: React.FC<{ text: string }> = ({ text }) => (
  <div style={{ display: "flex", alignItems: "baseline", gap: 1, lineHeight: 1 }}>
    {[...text.matchAll(/(\d+)(\D+)/g)].map((m) => (
      <span key={m[0]} style={{ display: "flex", alignItems: "baseline" }}>
        <span style={{ fontSize: 22, fontWeight: 800, color: C.ink }}>{m[1]}</span>
        <span style={{ fontSize: 13, fontWeight: 700, color: C.ink2, marginLeft: 1, marginRight: 4 }}>{m[2].trim()}</span>
      </span>
    ))}
  </div>
);
const SleepSide: React.FC<{ label: string; color: string; lit: number; night: readonly string[]; left: number }> = ({ label, color, lit, night, left }) => (
  <div style={abs({ left, top: 74, width: 150 })}>
    <div style={{ display: "flex", alignItems: "center", gap: 6, height: 14 }}>
      <div style={{ width: 8, height: 8, borderRadius: 4, background: color }} />
      <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.09em", color: C.ink2 }}>{label}</span>
    </div>
    <div style={{ marginTop: 8, display: "flex", alignItems: "center", gap: 10 }}>
      <Moon color={color} lit={lit} />
      <div>
        <Duration text={night[0]} />
        <div style={{ marginTop: 3, fontSize: 12, fontWeight: 500, color: C.ink2 }}>{night[1]}</div>
      </div>
    </div>
  </div>
);
const SleepCard: React.FC<{ y: number }> = ({ y }) => (
  <div style={abs({ left: 16, top: y, width: 370, height: HOME.sleepH, borderRadius: 24, background: C.card, boxShadow: CONTENT_SHADOW, overflow: "hidden" })}>
    <div style={abs({ left: 16, top: 16, width: 44, height: 44, borderRadius: 14, background: "rgba(124,92,214,0.10)", display: "flex", alignItems: "center", justifyContent: "center" })}>
      <G name="moon" size={22} color={C.lavenderDeep} />
    </div>
    <Txt s={{ left: 72, top: 28, fontSize: 16, fontWeight: 800, lineHeight: "20px", color: C.ink }}>{H.sleep}</Txt>
    <G name="chevron" size={18} color={C.ink3} style={abs({ right: 16, top: 29 })} />
    <SleepSide label={T.couple.youLabel} color={C.rose} lit={0.72} night={H.sleepYou} left={16} />
    <div style={abs({ left: 184.5, top: 74, width: 1, height: 65, background: "rgba(107,107,123,0.10)" })} />
    <SleepSide label={T.couple.otherLabel} color={C.lavenderDeep} lit={0.5} night={H.sleepOther} left={199} />
    <div style={abs({ left: 16, right: 16, top: 153, height: 1, background: "rgba(107,107,123,0.10)" })} />
    <div style={abs({ left: 16, top: 166, display: "flex", alignItems: "center", gap: 6 })}>
      <G name="heart" size={14} color={C.rose} />
      <span style={{ fontSize: 12, fontWeight: 500, color: C.ink2 }}>{H.sleepTogether}</span>
    </div>
  </div>
);

// ── pinned header, floating nav ────────────────────────────────────────────────────────────────────────────────────
const Header: React.FC = () => (
  <>
    <GlyphChip text={H.greeting} glyph={<G name="sun" size={14} color={C.rose} />} style={{ left: 16, top: 79 }} />
    <G name="message" size={24} color={C.ink} style={abs({ left: 302, top: 89 })} />
    <G name="bell" size={24} color={C.ink} style={abs({ left: 352, top: 89 })} />
    <div style={abs({ left: 364, top: 80, width: 19, height: 19, borderRadius: 10, background: C.rose, boxShadow: "0 0 0 1.5px #FFFFFF", color: C.white, fontSize: 11, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center" })}>6</div>
  </>
);

const Nav: React.FC<{ f: number }> = ({ f }) => {
  const dot = f >= EVENT_F[6] ? settle(f, EVENT_F[6], { stiffness: 420, zeta: 0.7 }) : 0;
  const tab = (x: number, name: "chat" | "gallery" | "profile") => (
    <div style={abs({ left: x - 13, top: 769 })}>
      <G name={name === "chat" ? "message" : name} size={26} color="#A79CB4" />
    </div>
  );
  return (
    <>
      <div
        style={abs({
          left: 16,
          top: 741,
          width: 370,
          height: 83,
          borderRadius: 42,
          background: "rgba(255,255,255,0.46)",
          backdropFilter: "blur(14px) saturate(1.4)",
          boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.62), 0 10px 30px rgba(255,107,157,0.14)",
        })}
      />
      <div style={abs({ left: 28, top: 753, width: 79, height: 59, borderRadius: 22, background: "linear-gradient(135deg, #FF6B9D 0%, #FF4D6D 58%, #E63956 100%)", boxShadow: "0 6px 14px rgba(230,57,86,0.30)", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2, color: C.white })}>
        <G name="heart" size={22} color={C.white} />
        <span style={{ fontSize: 12, fontWeight: 700 }}>{H.nav[0]}</span>
      </div>
      {tab(156, "chat")}
      {tab(246, "gallery")}
      {tab(334, "profile")}
      {dot > 0 && <div style={abs({ left: 163, top: 765, width: 9, height: 9, borderRadius: 5, background: C.rose, boxShadow: "0 0 0 1.5px #FFFFFF", transform: `scale(${dot})` })} />}
    </>
  );
};

// ── the whole page ─────────────────────────────────────────────────────────────────────────────────────────────────
/** the Home tab at frame f; `card` = false once the counter card has lifted off (it is drawn on its own then) */
export const HomeApp: React.FC<{ f: number; card?: boolean }> = ({ f, card = true }) => {
  const s = scrollAt(f);
  const qH = lerp(HOME.qH[0], HOME.qH[1], revealT(f));
  const moodY = HOME.q + qH + 16;
  const sleepY = moodY + lerp(HOME.moodH[0], HOME.moodH[1], matchT(f)) + 16;
  return (
    <div style={abs({ inset: 0, background: `linear-gradient(${diag(402, 874)}deg, ${C.dawn.join(", ")})` })}>
      <div style={abs({ inset: 0, clipPath: `inset(${HOME.view}px 0 0 0)` })}>
        <div style={abs({ left: 0, top: 0, width: 402, height: 874, transform: `translateY(${-s}px)` })}>
          {card && <CounterCard f={f} y={HOME.card.y} />}
          <TodayHeader f={f} y={HOME.today} />
          <QuestionCard f={f} y={HOME.q} />
          {moodY - s < 874 && <MoodCard f={f} y={moodY} />}
          {sleepY - s < 874 && <SleepCard y={sleepY} />}
        </div>
      </div>
      <Header />
      <StatusBar dark />
      <Nav f={f} />
    </div>
  );
};
