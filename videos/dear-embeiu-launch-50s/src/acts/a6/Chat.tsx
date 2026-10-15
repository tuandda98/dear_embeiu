// Act 6 · the chat, rebuilt from lib/screens/chat_screen.dart and ref/ios/chat.png. The light sheet rises with the
// seeded conversation and the composer printed on it; the composer types and sends; the new navy bubble lands under
// the thread (which moves up one message), the partner's typing bubble under that; the care sheet's quick picks are
// dealt across a row above. Every layer reads the frame itself (it may sit inside <Blur>); a moving piece is blurred
// on its own, because a static element inside an active Blur is re-composited from ten 10 % samples and its soft
// shadow grows a ring.
import { AbsoluteFill, Easing, interpolateColors, useCurrentFrame } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { Caption } from "../../components/Text.tsx";
import { T } from "../../copy/strings.ts";
import { blink, ease, lerp, press, settle } from "../../lib/ease.ts";
import { C, FONT } from "../../lib/tokens.ts";
import { A6 } from "../../timeline/cues.ts";
import { typed } from "../../timeline/typing.ts";
import { CHIPS, COMPOSER, DISC, FIELD, SPAN, STEP, THREAD } from "./layout.ts";

const PARTNER_GREY = "#E9E9EB"; // the app's incoming-bubble grey (chat_screen.dart `_kChatPartnerGrey`)
const COMPOSER_SHADOW = `${C.shadow}, 0 10px 16px rgba(26, 26, 46, 0.06)`; // + the composer card's own shadow in the app
const TYPING_W = 94; // 20 + three 12 px dots 9 px apart + 20
const SINK = 700; // px the thread and the composer travel down on their way out
const LIFT = CHIPS.y + CHIPS.h + 40; // px the quick picks travel up and out
const REST_TOP = THREAD.bottom - THREAD.h; // the newest message's top edge (798)

const width = (text: string, size: number, weight = 500) => measureText({ text, fontFamily: FONT, fontSize: size, fontWeight: weight }).width;
const speed = (fn: (x: number) => number, f: number) => Math.abs(fn(f + 0.25) - fn(f - 0.25)) * 2;
const bubbleW = (text: string) => Math.min(THREAD.maxW, Math.round(width(text, THREAD.size) + 2 * THREAD.padX));

/** the sheet presentation: everything printed on the panel rides it up (offset 1120 → 0, a strong ease-out) */
export const riseAt = (f: number) => ease(f, A6.composer[0], A6.composer[1], Easing.out(Easing.poly(5)));
export const panelOffset = (f: number) => 1120 * (1 - riseAt(f));
const sinkAt = (f: number) => ease(f, A6.chatOut[0], A6.chatOut[1], Easing.in(Easing.cubic));
const liftAt = (f: number) => ease(f, A6.chipsOut[0], A6.chipsOut[1], Easing.in(Easing.cubic));
const landed = (f: number) => settle(f, A6.send, { stiffness: 170, zeta: 0.86 }); // the sent bubble's flight
const answered = (f: number) => settle(f, A6.typing[0], { stiffness: 200, zeta: 0.9 }); // the typing bubble arrives
/** how far the thread has moved up: one message when the sent bubble lands, one more for the typing bubble */
const pushAt = (f: number) => STEP * (landed(f) + answered(f));

/** the sent bubble: lifts off the field at A6.send (its text growing 22 → 26 px), lands under the thread, then moves up one message */
function sentAt(f: number) {
  const w0 = Math.round(width(T.a6.typed, COMPOSER.size) + 2 * FIELD.padX);
  const w1 = bubbleW(T.a6.typed);
  const p = landed(f);
  const y1 = REST_TOP - STEP * answered(f);
  return { x: lerp(FIELD.x, THREAD.right - w1, p), y: lerp(FIELD.y, y1, p), w: lerp(w0, w1, p), h: lerp(FIELD.h, THREAD.h, p), p };
}

/** the six quick picks justified across the 12 columns (integer x, so the text rests crisp) */
function chipSlots() {
  const ws = T.a6.chips.map((c) => Math.round(width(c, CHIPS.size) + 2 * CHIPS.padX));
  const gap = (SPAN.right - SPAN.left - ws.reduce((a, b) => a + b, 0)) / (ws.length - 1);
  let x = SPAN.left;
  return ws.map((w) => {
    const slot = { x: Math.round(x), w };
    x += w + gap;
    return slot;
  });
}
/** chip k is dealt from behind chip k − 1 (wherever that one is), growing from 74 %: the fan opens left → right */
function chipAt(k: number, f: number, slots: { x: number; w: number }[]): { x: number; s: number } {
  const { x, w } = slots[k];
  if (k === 0) return { x, s: 1 };
  const prev = chipAt(k - 1, f, slots);
  const p = settle(f, A6.chips[k], { stiffness: 190, zeta: 0.9 });
  return { x: lerp(prev.x + (slots[k - 1].w - w) / 2, x, p), s: lerp(0.74, 1, p) };
}

// fast = over 20 px/frame: only then does a piece go inside <Blur>
export const panelFast = (f: number) => f > A6.composer[0] && speed(panelOffset, f) > 20;
export const sinkFast = (f: number) => speed((x) => SINK * sinkAt(x), f) > 20;
export const threadFast = (f: number) => panelFast(f) || sinkFast(f);
export const sentFast = (f: number) => sinkFast(f) || Math.max(speed((x) => sentAt(x).x, f), speed((x) => sentAt(x).y, f)) > 20;
export const chipFast = (k: number, f: number) => {
  if (speed((x) => LIFT * liftAt(x), f) > 20) return true;
  if (k === 0 || f < A6.chips[k]) return false;
  const slots = chipSlots();
  return speed((x) => chipAt(k, x, slots).x, f) > 20;
};

const PLANE = "M7.4 6.32l8.49-2.83c3.81-1.27 5.88.81 4.62 4.62l-2.83 8.49c-1.9 5.71-5.02 5.71-6.92 0l-.84-2.52-2.52-.84c-5.71-1.9-5.71-5.01 0-6.92zM10.11 13.65l3.58-3.59"; // Iconsax send-2 (linear)

const Composer: React.FC<{ f: number }> = ({ f }) => {
  const k0 = A6.typed.frames[0];
  const draft = f < A6.send ? typed(A6.typed, f) : "";
  // the send disc: a quiet ghost while empty, navy once there is a draft (the app's AnimatedContainer, 180 ms)
  const navy = f < A6.send + 6 ? ease(f, k0, k0 + 10) : 1 - ease(f, A6.send + 6, A6.send + 16);
  const textTop = FIELD.y + (FIELD.h - COMPOSER.line) / 2;
  const textX = FIELD.x + FIELD.padX;
  const caretX = textX + (draft ? width(draft, COMPOSER.size) : 0) + 1;
  const caretOn = f >= k0 && f < A6.send ? 1 : blink(f); // solid while typing, beat-locked blink at rest
  const hint = f < k0 ? 1 : f >= A6.send ? ease(f, A6.send + 4, A6.send + 16) : 0; // the placeholder wipes back after sending
  const type = { fontSize: COMPOSER.size, fontWeight: 500, lineHeight: `${COMPOSER.line}px` } as const;
  return (
    <>
      <div style={{ position: "absolute", left: COMPOSER.x, top: COMPOSER.y, width: COMPOSER.w, height: COMPOSER.h, borderRadius: COMPOSER.r, background: C.card, boxShadow: COMPOSER_SHADOW }} />
      <div style={{ position: "absolute", left: FIELD.x, top: FIELD.y, width: FIELD.w, height: FIELD.h, borderRadius: FIELD.h / 2, background: C.tint }} />
      {hint > 0 && (
        <div style={{ position: "absolute", left: textX, top: textTop, ...type, color: C.ink2, whiteSpace: "nowrap", clipPath: hint < 1 ? `inset(0 ${(1 - hint) * 100}% 0 0)` : undefined }}>{T.a6.placeholder}</div>
      )}
      {draft && <div style={{ position: "absolute", left: textX, top: textTop, ...type, color: C.ink, whiteSpace: "pre" }}>{draft}</div>}
      <div style={{ position: "absolute", left: caretX, top: textTop + 1, width: 2, height: COMPOSER.line - 2, borderRadius: 1, background: C.rose, opacity: caretOn }} />
      <div style={{ position: "absolute", left: DISC.x, top: DISC.y, width: COMPOSER.disc, height: COMPOSER.disc, borderRadius: COMPOSER.disc / 2, background: interpolateColors(navy, [0, 1], [C.tint, C.ink]), transform: `scale(${press(f, A6.send)})` }}>
        <svg style={{ position: "absolute", left: 10, top: 10 }} width={20} height={20} viewBox="0 0 24 24" fill="none">
          <path d={PLANE} stroke={interpolateColors(navy, [0, 1], [C.ink3, C.white])} strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
    </>
  );
};

const Message: React.FC<{ x: number; y: number; w: number; h?: number; mine: boolean; text: string; bg?: string; fg?: string; scale?: number }> = ({ x, y, w, h = THREAD.h, mine, text, bg, fg, scale = 1 }) => (
  <div style={{ position: "absolute", left: x, top: y, width: w, height: h, borderRadius: THREAD.r, background: bg ?? (mine ? C.ink : PARTNER_GREY) }}>
    <div
      style={{
        position: "absolute",
        left: THREAD.padX,
        top: (h - THREAD.line) / 2,
        fontSize: THREAD.size,
        fontWeight: 500,
        lineHeight: `${THREAD.line}px`,
        color: fg ?? (mine ? C.white : C.ink),
        whiteSpace: "nowrap",
        transformOrigin: "0 50%",
        transform: scale === 1 ? undefined : `scale(${scale})`,
      }}
    >
      {text}
    </div>
  </div>
);

const Thread: React.FC<{ f: number }> = ({ f }) => {
  const push = pushAt(f);
  const n = T.a6.history.length;
  return (
    <>
      {T.a6.history.map(([who, text], k) => {
        const w = bubbleW(text);
        const mine = who === 1;
        return <Message key={k} x={mine ? THREAD.right - w : THREAD.left} y={REST_TOP - (n - 1 - k) * STEP - push} w={w} mine={mine} text={text} />;
      })}
    </>
  );
};

const Sent: React.FC<{ f: number }> = ({ f }) => {
  if (f < A6.send) return null;
  const b = sentAt(f);
  return (
    <Message
      x={b.x}
      y={b.y}
      w={b.w}
      h={b.h}
      mine
      text={T.a6.typed}
      bg={interpolateColors(b.p, [0, 0.3], [C.tint, C.ink])}
      fg={interpolateColors(b.p, [0, 0.3], [C.ink, C.white])}
      scale={lerp(COMPOSER.size / THREAD.size, 1, Math.min(1, b.p))}
    />
  );
};

const Typing: React.FC<{ f: number }> = ({ f }) => {
  const at = A6.typing[0];
  if (f < at) return null;
  const s = settle(f, at, { stiffness: 260, zeta: 0.75 }); // pops from its tail corner: the one small overshoot
  return (
    <>
      <div style={{ position: "absolute", left: THREAD.left, top: REST_TOP, width: TYPING_W, height: THREAD.h, borderRadius: THREAD.r, background: PARTNER_GREY, transformOrigin: "0 100%", transform: `scale(${s})` }}>
        {[0, 1, 2].map((k) => {
          const ph = f - at - 8 * k; // the three dots rise one after another (A6_EVENTS typingDot)
          const lift = ph >= 0 && ph % 24 < 14 ? 6 * Math.sin((Math.PI * (ph % 24)) / 14) : 0;
          return <div key={k} style={{ position: "absolute", left: 20 + 21 * k, top: 25 - lift, width: 12, height: 12, borderRadius: 6, background: C.lavenderDeep }} />;
        })}
      </div>
      <Caption text={T.a6.typing} x={THREAD.left + TYPING_W + 16} y={REST_TOP + 18} size={22} weight={600} color={C.lavenderDeep} wipe={ease(f, at + 6, at + 20)} />
    </>
  );
};

/** chip k (draw them 5 → 0 so each one is dealt from under the one before) */
const Chip: React.FC<{ f: number; k: number }> = ({ f, k }) => {
  if (f < A6.chips[k]) return null;
  const slots = chipSlots();
  const c = chipAt(k, f, slots);
  const w = k === 0 ? slots[0].w * ease(f, A6.chips[0], A6.chips[0] + 12) : slots[k].w; // the first one unfolds
  return (
    <div style={{ position: "absolute", left: c.x, top: CHIPS.y - LIFT * liftAt(f), width: w, height: CHIPS.h, borderRadius: CHIPS.h / 2, background: C.card, boxShadow: C.shadow, overflow: "hidden", transform: c.s === 1 ? undefined : `scale(${c.s})` }}>
      <div style={{ position: "absolute", left: CHIPS.padX, top: 0, height: CHIPS.h, display: "flex", alignItems: "center", fontSize: CHIPS.size, fontWeight: 500, color: C.ink, whiteSpace: "nowrap" }}>{T.a6.chips[k]}</div>
    </div>
  );
};

/** the panel-borne layers ride the sheet up, then sink out together */
const OnPanel: React.FC<{ f: number; children: React.ReactNode }> = ({ f, children }) => {
  const sink = sinkAt(f);
  const dy = panelOffset(f) + SINK * sink;
  return <AbsoluteFill style={dy > 0 ? { transformOrigin: "960px 996px", transform: `translateY(${dy}px) scale(${1 - 0.06 * sink})` } : undefined}>{children}</AbsoluteFill>;
};

const layer = (Body: React.FC<{ f: number }>): React.FC => () => {
  const f = useCurrentFrame();
  return (
    <OnPanel f={f}>
      <Body f={f} />
    </OnPanel>
  );
};
export const ThreadLayer = layer(Thread);
export const ComposerLayer = layer(Composer);
export const SentLayer = layer(Sent);
export const TypingLayer = layer(Typing);
export const ChipLayer: React.FC<{ k: number }> = ({ k }) => <Chip f={useCurrentFrame()} k={k} />;
