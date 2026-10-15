// The app's Home inside Act 2's phone, in screen points (402×874). Act 4's HomeApp follows Act 4's clock (its
// scroll, the reveal and the match are keyed to the day there) and its cards are not exported, so the cards Act 2 needs
// in Act 2's states (his answer locked, his mood shared, your sides empty) are drawn here from a4's layout (HOME) and
// its exported parts (CounterContent, PhotoBack, Names, G, Roll, diag); every state is an explicit prop.
// ponytail: mirrors a4/home.tsx's cards, header and nav — if a4 exports state-driven versions, use those and delete these.
import type { CSSProperties, ReactNode } from "react";
import { C } from "../../lib/tokens.ts";
import { ease, lerp } from "../../lib/ease.ts";
import { T } from "../../copy/strings.ts";
import { StatusBar } from "../../components/Phone.tsx";
import { CARD_SHADOW, CounterContent, HOME, Names, PhotoBack } from "../a4/home.tsx";
import { G } from "../a4/glyphs.tsx";
import { Roll, diag } from "../a4/parts.tsx";

const H = T.a4.home;
const SURFACE = C.tint;
const CONTENT_SHADOW = "0 10px 16px rgba(0,0,0,0.06)";
const abs = (s: CSSProperties): CSSProperties => ({ position: "absolute", ...s });
const Txt: React.FC<{ s: CSSProperties; children: ReactNode }> = ({ s, children }) => <div style={abs({ whiteSpace: "nowrap", ...s })}>{children}</div>;

// ── layout (content y = screen y at scroll 0) ──────────────────────────────────────────────────────────────────────
const BODY = 87; // the question card's content under its question
export const Q_H = [288, 337] as const; // his answer locked (home-today) → both answers (dq-revealed-2)
export const SLEEP_H = 168; // your night not in yet: the together line is not shown
export const moodY = (qH: number) => HOME.q + qH + 16;
export const sleepY = (qH: number, mH: number) => moodY(qH) + mH + 16;
/** Act 2's Home at one moment; every field is decided by the act, not by a clock */
export type HomeState = {
  f: number; // the frame: the counter card's clock
  scroll: number; // pt
  qH: number; // the question card's height
  teaserOut: number; // his locked teaser + your pill leave (0 → 1)
  ansA: number;
  ansB: number;
  check: number; // the check stroke draws (0 → 1)
  match: number; // the mood card turns matched (0 → 1)
  cta: number; // the rose pill's press scale
  answered: number; // your question star lights (0 → 1): 2/6 → 3/6 as captured
  carets: { x: number; y: number; on: boolean }[]; // content coords
};

// ── the counter card ───────────────────────────────────────────────────────────────────────────────────────────────
const CounterCard: React.FC<{ f: number }> = ({ f }) => (
  <div style={abs({ left: HOME.card.x, top: HOME.card.y, width: HOME.card.w, height: HOME.card.h, borderRadius: 28, boxShadow: CARD_SHADOW, background: `linear-gradient(${diag(370, 392)}deg, ${C.sunset.join(", ")})` })}>
    <div style={abs({ inset: 0, borderRadius: 28, overflow: "hidden" })}>
      <PhotoBack top={0.26} bottom={0.46} radius={28} />
      <CounterContent f={f} />
    </div>
  </div>
);

// ── "Hôm nay của chúng mình" + the constellation pill ────────────────────────────────────────────────────────────
const OUTLINE: [number, number][] = [[130, 66], [70, 40], [30, 104], [82, 162], [130, 206], [178, 162], [230, 104], [190, 40]];
const STARS: { who: "you" | "other"; at: [number, number]; lit: (s: HomeState) => number }[] = [
  { who: "other", at: [190, 40], lit: () => 1 }, // his question (answered)
  { who: "you", at: [82, 162], lit: () => 1 }, // your message (as captured, 2/6)
  { who: "you", at: [70, 40], lit: (s) => s.answered }, // your question
  { who: "other", at: [230, 104], lit: () => 0 },
  { who: "other", at: [178, 162], lit: () => 0 },
  { who: "you", at: [30, 104], lit: () => 0 },
];
const TodayHeader: React.FC<{ s: HomeState }> = ({ s }) => {
  const k = 260 / 24;
  return (
    <>
      <Txt s={{ left: 16, top: HOME.today + 9, fontSize: 22, fontWeight: 700, letterSpacing: "-0.009em", lineHeight: "26px", color: C.ink }}>{H.today}</Txt>
      <div style={abs({ right: 16, top: HOME.today, height: 44, padding: "0 11px 0 10px", display: "flex", alignItems: "center", gap: 5, borderRadius: 999, background: "rgba(255,255,255,0.72)", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.65), 0 2px 6px rgba(255,77,109,0.16)", color: C.ink, fontSize: 13, fontWeight: 700 })}>
        <svg width={24} height={20} viewBox="0 0 260 216" style={{ display: "block", flex: "none" }}>
          <polygon points={OUTLINE.map((p) => p.join(",")).join(" ")} fill="none" stroke="rgba(26,26,46,0.22)" strokeWidth={k} strokeLinejoin="round" />
          {STARS.map(({ who, at: [x, y], lit }, i) => {
            const l = lit(s), col = who === "you" ? C.rose : C.lavenderDeep;
            return (
              <g key={i}>
                {l < 1 && <circle cx={x} cy={y} r={2.1 * k} fill="none" stroke={col} strokeWidth={k} opacity={1 - l} />}
                {l > 0 && <circle cx={x} cy={y} r={2.6 * k * l} fill={col} />}
              </g>
            );
          })}
        </svg>
        <Roll v={2 + s.answered} size={13} />
        <span style={{ marginLeft: -3 }}>{H.pill(2).slice(1)}</span>
      </div>
    </>
  );
};

// ── the question card: his answer locked behind yours (home-today) → both answers (dq-revealed-2) ─────────────────
const Answer: React.FC<{ label: string; text: string; mine: boolean; top: number; h: number; u: number }> = ({ label, text, mine, top, h, u }) => (
  <div style={abs({ left: 20, right: 20, top, height: h * u, borderRadius: 16, overflow: "hidden", background: mine ? SURFACE : "rgba(167,139,250,0.10)" })}>
    <div style={abs({ left: 12, right: 12, top: 12 - 8 * (1 - u) })}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.027em", lineHeight: "13px", color: mine ? C.roseDeep : C.lavenderDeep }}>{label}</div>
      <div style={{ marginTop: 4, fontSize: 15, fontWeight: 500, lineHeight: 1.5, color: C.ink }}>{text}</div>
    </div>
  </div>
);
const QuestionCard: React.FC<{ s: HomeState }> = ({ s }) => {
  const out = s.teaserOut;
  return (
    <div style={abs({ left: 16, top: HOME.q, width: 370, height: s.qH, borderRadius: 24, background: C.card, boxShadow: CONTENT_SHADOW, overflow: "hidden" })}>
      <div style={abs({ left: 20, top: 20, width: 330, fontSize: 21, fontWeight: 600, lineHeight: 1.25, letterSpacing: "-0.0095em", color: C.ink })}>{H.question}</div>
      {out < 1 && (
        <div style={abs({ inset: 0, opacity: 1 - out, transform: `translateY(${-14 * out}px)` })}>
          {/* his answer, locked: three redaction bars and the teaser */}
          <div style={abs({ left: 20, top: BODY, width: 330, height: 118, borderRadius: 18, background: "rgba(167,139,250,0.06)", boxShadow: "inset 0 0 0 1px rgba(167,139,250,0.20)" })}>
            {[297, 260, 163].map((w, i) => (
              <div key={i} style={abs({ left: 17, top: 17 + 20 * i, width: w, height: 10, borderRadius: 5, background: "rgba(167,139,250,0.20)" })} />
            ))}
            <div style={abs({ left: 17, top: 82, height: 18, display: "flex", alignItems: "center", gap: 9 })}>
              <G name="lock" size={16} color={C.rose} />
              <span style={{ fontSize: 14, fontWeight: 600, color: C.ink, whiteSpace: "nowrap" }}>{T.a2.rows[0].other}</span>
            </div>
          </div>
          {/* your side: the rose pill */}
          <div style={abs({ left: 20, top: 217, width: 330, height: 51, borderRadius: 999, transform: `scale(${s.cta})`, background: "linear-gradient(90deg, #FF93A8 0%, #FFB4C2 100%)", boxShadow: "0 6px 14px rgba(255,107,157,0.22)", display: "flex", alignItems: "center", padding: "0 14px 0 18px", gap: 12, boxSizing: "border-box" })}>
            <G name="pen" size={18} color={C.roseDeep} />
            <span style={{ flex: 1, minWidth: 0, fontSize: 14, fontWeight: 700, color: C.roseDeep, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{H.unlock}</span>
            <G name="arrowCircle" size={20} color={C.roseDeep} />
          </div>
        </div>
      )}
      {s.ansA > 0 && <Answer label={T.a2.answerYou.label} text={T.a2.answerYou.text} mine top={BODY} h={64} u={s.ansA} />}
      {s.ansB > 0 && <Answer label={T.a2.answerOther.label} text={T.a2.answerOther.text} mine={false} top={BODY + 74} h={87} u={s.ansB} />}
      {s.check > 0 && (
        <>
          <div style={abs({ left: 20, top: BODY + 171, height: 36, display: "flex", alignItems: "center", gap: 10 })}>
            <svg width={22} height={22} viewBox="0 0 22 22" fill="none">
              <path d="M4 11.5l4.6 4.6L18 6.5" stroke={C.rose} strokeWidth={2.2} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - s.check} />
            </svg>
            <span style={{ fontSize: 13, fontWeight: 600, color: C.ink, whiteSpace: "nowrap", clipPath: `inset(-4px ${(1 - s.check) * 100}% -4px 0)` }}>{T.a2.both}</span>
          </div>
          <Txt s={{ right: 20, top: BODY + 215, fontSize: 13, fontWeight: 700, lineHeight: "16px", color: C.roseDeep, clipPath: `inset(-4px ${(1 - s.check) * 100}% -4px 0)` }}>{H.collapse}</Txt>
        </>
      )}
    </div>
  );
};

// ── the mood card: his mood shared, yours empty (home-today) → matched (mood-matched) ─────────────────────────────
const [MOOD_EMOJI, MOOD_LABEL] = T.a2.moods[T.a2.picked];
const MoodCard: React.FC<{ s: HomeState; y: number }> = ({ s, y }) => {
  const t = s.match;
  const h = lerp(HOME.moodH[0], HOME.moodH[1], t);
  const box = 72;
  const before = 1 - ease(t, 0, 0.33);
  const after = ease(t, 0.1, 0.75);
  const pop = 0.6 + 0.4 * ease(t, 0.08, 0.7); // the emoji's circle grows into place as the card opens
  const cta = lerp(box + 142, box + 294, t);
  const side = (left: number, label: string, children: ReactNode, top = 8) => (
    <div style={abs({ left, top, width: 158, display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center" })}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.036em", lineHeight: "13px", color: C.ink2 }}>{label}</div>
      {children}
    </div>
  );
  return (
    <div style={abs({ left: 16, top: y, width: 370, height: h, borderRadius: 24, background: C.card, boxShadow: CONTENT_SHADOW, overflow: "hidden" })}>
      <div style={abs({ left: 20, top: 20, width: 36, height: 36, borderRadius: 12, background: "rgba(255,77,109,0.12)", display: "flex", alignItems: "center", justifyContent: "center" })}>
        <G name="faceTile" size={20} color={C.rose} />
      </div>
      <Txt s={{ left: 68, top: 25, fontSize: 22, fontWeight: 700, letterSpacing: "-0.009em", lineHeight: "26px", color: C.ink }}>{H.mood}</Txt>
      {before > 0 && (
        <div style={abs({ left: 20, top: box, width: 330, height: 126, opacity: before })}>
          {side(
            0,
            T.couple.youLabel,
            <>
              <div style={{ marginTop: 10, width: 56, height: 56, borderRadius: 28, background: SURFACE, display: "flex", alignItems: "center", justifyContent: "center" }}>
                <G name="plus" size={24} color={C.ink3} />
              </div>
              <div style={{ marginTop: 8, fontSize: 12, lineHeight: 1.3, color: C.ink2 }}>{H.moodYouEmpty}</div>
            </>,
          )}
          <div style={abs({ left: 164.5, top: 0, width: 1, height: 126, background: SURFACE })} />
          {side(
            172,
            T.couple.otherLabel,
            <>
              <div style={{ marginTop: 10, width: 56, height: 56, borderRadius: 28, background: "rgba(255,77,109,0.08)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 32, lineHeight: 1 }}>{MOOD_EMOJI}</div>
              <div style={{ marginTop: 6, fontSize: 15, fontWeight: 700, lineHeight: "18px", color: C.ink }}>{MOOD_LABEL}</div>
              <div style={{ marginTop: 2, fontSize: 12, fontStyle: "italic", lineHeight: "16px", color: C.ink2, whiteSpace: "nowrap" }}>{`"${H.moodNote}"`}</div>
            </>,
            4,
          )}
        </div>
      )}
      {after > 0 && (
        <div style={abs({ left: 20, top: box, width: 330, height: 278, opacity: after, borderRadius: 20, background: "rgba(255,77,109,0.06)", boxShadow: "inset 0 0 0 1px rgba(255,77,109,0.12)" })}>
          <div style={abs({ left: 101, top: 22, width: 128, height: 128, borderRadius: 64, background: "radial-gradient(circle, rgba(255,77,109,0.24) 0%, rgba(255,77,109,0) 70%)" })} />
          <div style={abs({ left: 119, top: 40, width: 92, height: 92, borderRadius: 46, background: C.card, boxShadow: "0 6px 16px rgba(255,107,157,0.18)", display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${pop})` })}>
            <span style={{ fontSize: 58, lineHeight: 1 }}>{MOOD_EMOJI}</span>
          </div>
          <div style={abs({ left: 0, right: 0, top: 160, textAlign: "center", fontSize: 20, fontWeight: 800, lineHeight: "24px", color: C.ink })}>{MOOD_LABEL}</div>
          <div style={abs({ left: 0, right: 0, top: 192, display: "flex", justifyContent: "center" })}>
            <Names pair={[T.couple.youLabel, T.couple.otherLabel]} size={11} heart={12} color="rgba(26,26,46,0.6)" heartColor={C.roseDeep} gap={8} tracking="0.13em" />
          </div>
          <div style={abs({ left: 0, right: 0, top: 211, textAlign: "center", fontSize: 13, fontWeight: 600, lineHeight: "17px", color: C.roseDeep })}>{T.a2.matched}</div>
          <div style={abs({ left: 0, right: 0, top: 240, textAlign: "center", fontSize: 12, fontStyle: "italic", lineHeight: "16px", color: C.ink2 })}>{`${T.couple.otherLabel}: "${H.moodNote}"`}</div>
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

// ── "Đêm qua": his night in (his person colour), yours still empty ───────────────────────────────────────────────
const SleepCard: React.FC<{ y: number }> = ({ y }) => {
  const r = 15, lit = 0.5, rx = Math.abs(1 - 2 * lit) * r;
  const label = (text: string, color: string) => (
    <div style={{ display: "flex", alignItems: "center", gap: 6, height: 14 }}>
      <div style={{ width: 8, height: 8, borderRadius: 4, background: color }} />
      <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.09em", color: C.ink2 }}>{text}</span>
    </div>
  );
  return (
    <div style={abs({ left: 16, top: y, width: 370, height: SLEEP_H, borderRadius: 24, background: C.card, boxShadow: CONTENT_SHADOW, overflow: "hidden" })}>
      <div style={abs({ left: 16, top: 16, width: 44, height: 44, borderRadius: 14, background: "rgba(124,92,214,0.10)", display: "flex", alignItems: "center", justifyContent: "center" })}>
        <G name="moon" size={22} color={C.lavenderDeep} />
      </div>
      <Txt s={{ left: 72, top: 28, fontSize: 16, fontWeight: 800, lineHeight: "20px", color: C.ink }}>{H.sleep}</Txt>
      <G name="chevron" size={18} color={C.ink3} style={abs({ right: 16, top: 29 })} />
      <div style={abs({ left: 16, top: 74 })}>{label(T.couple.youLabel, C.rose)}</div>
      <div style={abs({ left: 184.5, top: 74, width: 1, height: 65, background: "rgba(107,107,123,0.10)" })} />
      <div style={abs({ left: 199, top: 74, width: 150 })}>
        {label(T.couple.otherLabel, C.lavenderDeep)}
        <div style={{ marginTop: 8, display: "flex", alignItems: "center", gap: 10 }}>
          <svg width={30} height={30} viewBox="0 0 30 30" style={{ display: "block", flex: "none" }}>
            <circle cx={r} cy={r} r={r} fill={C.lavenderDeep} fillOpacity={0.16} />
            <path d={`M${r} 0A${r} ${r} 0 0 1 ${r} ${2 * r}A${rx} ${r} 0 0 0 ${r} 0z`} fill={C.lavenderDeep} />
          </svg>
          <div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 1, lineHeight: 1 }}>
              {[...H.sleepOther[0].matchAll(/(\d+)(\D+)/g)].map((m) => (
                <span key={m[0]} style={{ display: "flex", alignItems: "baseline" }}>
                  <span style={{ fontSize: 22, fontWeight: 800, color: C.ink }}>{m[1]}</span>
                  <span style={{ fontSize: 13, fontWeight: 700, color: C.ink2, marginLeft: 1, marginRight: 4 }}>{m[2].trim()}</span>
                </span>
              ))}
            </div>
            <div style={{ marginTop: 3, fontSize: 12, fontWeight: 500, color: C.ink2 }}>{H.sleepOther[1]}</div>
          </div>
        </div>
      </div>
    </div>
  );
};

// ── pinned header, floating nav (as a4 draws them, before the day's chat) ──────────────────────────────────────────
const Header: React.FC = () => (
  <>
    <div style={abs({ left: 16, top: 79, display: "flex", alignItems: "center", gap: 8, height: 28, padding: "0 14px 0 12px", borderRadius: 999, background: "rgba(255,255,255,0.72)", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.65), 0 4px 12px rgba(255,107,157,0.10)", fontSize: 12, fontWeight: 600, letterSpacing: "0.12em", color: C.ink, whiteSpace: "nowrap" })}>
      <G name="sun" size={14} color={C.rose} />
      {H.greeting}
    </div>
    <G name="message" size={24} color={C.ink} style={abs({ left: 302, top: 89 })} />
    <G name="bell" size={24} color={C.ink} style={abs({ left: 352, top: 89 })} />
    <div style={abs({ left: 364, top: 80, width: 19, height: 19, borderRadius: 10, background: C.rose, boxShadow: "0 0 0 1.5px #FFFFFF", color: C.white, fontSize: 11, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center" })}>6</div>
  </>
);
const Nav: React.FC = () => (
  <>
    <div style={abs({ left: 16, top: 741, width: 370, height: 83, borderRadius: 42, background: "rgba(255,255,255,0.46)", backdropFilter: "blur(14px) saturate(1.4)", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.62), 0 10px 30px rgba(255,107,157,0.14)" })} />
    <div style={abs({ left: 28, top: 753, width: 79, height: 59, borderRadius: 22, background: "linear-gradient(135deg, #FF6B9D 0%, #FF4D6D 58%, #E63956 100%)", boxShadow: "0 6px 14px rgba(230,57,86,0.30)", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2, color: C.white })}>
      <G name="heart" size={22} color={C.white} />
      <span style={{ fontSize: 12, fontWeight: 700 }}>{H.nav[0]}</span>
    </div>
    {([[156, "message"], [246, "gallery"], [334, "profile"]] as const).map(([x, name]) => (
      <div key={name} style={abs({ left: x - 13, top: 769 })}>
        <G name={name} size={26} color="#A79CB4" />
      </div>
    ))}
  </>
);

// ── the page ───────────────────────────────────────────────────────────────────────────────────────────────────────
export const HomeA2: React.FC<{ s: HomeState }> = ({ s }) => {
  const mH = lerp(HOME.moodH[0], HOME.moodH[1], s.match);
  const mY = moodY(s.qH), sY = sleepY(s.qH, mH);
  return (
    <div style={abs({ inset: 0, background: `linear-gradient(${diag(402, 874)}deg, ${C.dawn.join(", ")})` })}>
      <div style={abs({ inset: 0, clipPath: `inset(${HOME.view}px 0 0 0)` })}>
        <div style={abs({ left: 0, top: 0, width: 402, height: 874, transform: `translateY(${-s.scroll}px)` })}>
          {HOME.card.y + HOME.card.h > s.scroll + HOME.view && <CounterCard f={s.f} />}
          <TodayHeader s={s} />
          <QuestionCard s={s} />
          {mY - s.scroll < 874 && <MoodCard s={s} y={mY} />}
          {sY - s.scroll < 874 && <SleepCard y={sY} />}
          {s.carets.map((c, i) => (
            <div key={i} style={abs({ left: c.x - 1, top: c.y - 11, width: 2, height: 22, borderRadius: 1, background: C.rose, opacity: c.on ? 1 : 0 })} />
          ))}
        </div>
      </div>
      <Header />
      <StatusBar dark />
      <Nav />
    </div>
  );
};
