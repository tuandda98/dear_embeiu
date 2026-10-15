// Act 6 · the chat panel: ref/ios/chat.png as a white card printed on the rising sheet — the header chip, the seeded
// conversation, the composer typing and sending. Each new bubble rises out from behind the line above the composer
// while the thread moves up one message (under 20 px/frame, so no <Blur>). The care sheet's quick picks are dealt
// across one centred row above the panel. Panel and row leave together, sliding up out of the frame at A6.chatOut.
// Layers read the frame themselves (they may sit inside <Blur>).
import { AbsoluteFill, Easing, interpolateColors, useCurrentFrame } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { Caption } from "../../components/Text.tsx";
import { T } from "../../copy/strings.ts";
import { blink, ease, lerp, press, settle } from "../../lib/ease.ts";
import { C, FONT } from "../../lib/tokens.ts";
import { A6 } from "../../timeline/cues.ts";
import { typed } from "../../timeline/typing.ts";
import { CHIPS, COMPOSER, FIELD_W, HEADER, PANEL, STEP, THREAD } from "./layout.ts";

const PARTNER_GREY = "#E9E9EB"; // the app's incoming-bubble grey (chat_screen.dart `_kChatPartnerGrey`)
const TYPING_W = 88; // 20 + three 10 px dots 9 px apart + 20
const REST_TOP = THREAD.bottom - THREAD.h; // the newest message's top edge
const EXIT = PANEL.y + PANEL.h + 60; // px the panel and the chip row travel up and out

const width = (text: string, size: number, weight = 500) => measureText({ text, fontFamily: FONT, fontSize: size, fontWeight: weight }).width;
const speed = (fn: (x: number) => number, f: number) => Math.abs(fn(f + 0.25) - fn(f - 0.25)) * 2;
const bubbleW = (text: string) => Math.min(THREAD.maxW, Math.round(width(text, THREAD.size) + 2 * THREAD.padX));

/** the sheet presentation: everything printed on the sheet rides it up (offset 1120 → 0, a strong ease-out) */
export const riseAt = (f: number) => ease(f, A6.composer[0], A6.composer[1], Easing.out(Easing.poly(5)));
export const panelOffset = (f: number) => 1120 * (1 - riseAt(f));
const exitAt = (f: number) => ease(f, A6.chatOut[0], A6.chatOut[1], Easing.in(Easing.cubic));
const panelY = (f: number) => panelOffset(f) - EXIT * exitAt(f);
const landed = (f: number) => settle(f, A6.send, { stiffness: 170, zeta: 0.86 }); // the sent bubble rises in
const answered = (f: number) => settle(f, A6.typing[0], { stiffness: 200, zeta: 0.9 }); // the typing bubble rises in

/** the six quick picks in one centred row (integer x, so the text rests crisp) */
function chipSlots() {
  const ws = T.a6.chips.map((c) => Math.round(width(c, CHIPS.size) + 2 * CHIPS.padX));
  let x = 960 - (ws.reduce((a, b) => a + b, 0) + CHIPS.gap * (ws.length - 1)) / 2;
  return ws.map((w) => {
    const slot = { x: Math.round(x), w };
    x += w + CHIPS.gap;
    return slot;
  });
}
/** chip k is dealt from behind chip k − 1 (wherever that one is), growing from 74 %: the fan opens left → right */
function chipAt(k: number, f: number, slots: { x: number; w: number }[]): { x: number; s: number } {
  const { x, w } = slots[k];
  if (k === 0) return { x, s: 1 };
  const prev = chipAt(k - 1, f, slots);
  const p = settle(f, A6.chips[k], { stiffness: 170, zeta: 0.9 });
  return { x: lerp(prev.x + (slots[k - 1].w - w) / 2, x, p), s: lerp(0.74, 1, p) };
}

// fast = over 20 px/frame: only then does a layer go inside <Blur>
export const panelFast = (f: number) => f > A6.composer[0] && speed(panelY, f) > 20;
export const chipFast = (k: number, f: number) => {
  if (speed((x) => EXIT * exitAt(x), f) > 20) return true;
  if (k === 0 || f < A6.chips[k]) return false;
  const slots = chipSlots();
  return speed((x) => chipAt(k, x, slots).x, f) > 20;
};

const PLANE = "M7.4 6.32l8.49-2.83c3.81-1.27 5.88.81 4.62 4.62l-2.83 8.49c-1.9 5.71-5.02 5.71-6.92 0l-.84-2.52-2.52-.84c-5.71-1.9-5.71-5.01 0-6.92zM10.11 13.65l3.58-3.59"; // Iconsax send-2 (linear)

const Header: React.FC = () => (
  <div style={{ position: "absolute", left: PANEL.x, top: HEADER.y, width: PANEL.w, display: "flex", justifyContent: "center" }}>
    <div style={{ height: HEADER.h, padding: "0 22px", borderRadius: HEADER.h / 2, background: C.tint, display: "flex", alignItems: "center", fontSize: HEADER.size, fontWeight: 600, letterSpacing: "0.1em", textTransform: "uppercase", color: C.ink, whiteSpace: "nowrap" }}>
      {T.couple.you}&nbsp;<span style={{ color: C.rose }}>♥</span>&nbsp;{T.couple.other}
    </div>
  </div>
);

const Bubble: React.FC<{ x: number; y: number; w: number; mine: boolean; text: string; clip?: number }> = ({ x, y, w, mine, text, clip = 0 }) => (
  <div style={{ position: "absolute", left: x, top: y, width: w, height: THREAD.h, borderRadius: THREAD.r, background: mine ? C.ink : PARTNER_GREY, clipPath: clip > 0 ? `inset(0 0 ${clip}px 0)` : undefined }}>
    <div style={{ position: "absolute", left: THREAD.padX, top: (THREAD.h - THREAD.line) / 2, fontSize: THREAD.size, fontWeight: 500, lineHeight: `${THREAD.line}px`, color: mine ? C.white : C.ink, whiteSpace: "nowrap" }}>{text}</div>
  </div>
);
/** how much of a rising element (top y, height h) still sits behind the composer line */
const hidden = (y: number, h = THREAD.h) => Math.max(0, y + h - THREAD.mask);

const Thread: React.FC<{ f: number }> = ({ f }) => {
  const push = STEP * (landed(f) + answered(f));
  const n = T.a6.history.length;
  return (
    <>
      {T.a6.history.map(([who, text], k) => {
        const w = bubbleW(text);
        const mine = who === 1;
        return <Bubble key={k} x={mine ? THREAD.right - w : THREAD.left} y={REST_TOP - (n - 1 - k) * STEP - push} w={w} mine={mine} text={text} />;
      })}
      {f >= A6.send &&
        (() => {
          const w = bubbleW(T.a6.typed);
          const y = lerp(THREAD.mask, REST_TOP, landed(f)) - STEP * answered(f);
          return <Bubble x={THREAD.right - w} y={y} w={w} mine text={T.a6.typed} clip={hidden(y)} />;
        })()}
      {f >= A6.typing[0] &&
        (() => {
          const at = A6.typing[0];
          const y = lerp(THREAD.mask, REST_TOP, answered(f));
          return (
            <>
              <div style={{ position: "absolute", left: THREAD.left, top: y, width: TYPING_W, height: THREAD.h, borderRadius: THREAD.r, background: PARTNER_GREY, clipPath: hidden(y) > 0 ? `inset(0 0 ${hidden(y)}px 0)` : undefined }}>
                {[0, 1, 2].map((k) => {
                  const ph = f - at - 8 * k; // the three dots rise one after another (A6_EVENTS typingDot)
                  const lift = ph >= 0 && ph % 24 < 14 ? 5 * Math.sin((Math.PI * (ph % 24)) / 14) : 0;
                  return <div key={k} style={{ position: "absolute", left: 20 + 19 * k, top: 23 - lift, width: 10, height: 10, borderRadius: 5, background: C.lavenderDeep }} />;
                })}
              </div>
              <Caption text={T.a6.typing} x={THREAD.left + TYPING_W + 14} y={y + 15} size={22} weight={600} color={C.lavenderDeep} wipe={ease(f, at + 8, at + 22)} />
            </>
          );
        })()}
    </>
  );
};

const Composer: React.FC<{ f: number }> = ({ f }) => {
  const k0 = A6.typed.frames[0];
  const draft = f < A6.send ? typed(A6.typed, f) : "";
  // the send disc: a quiet ghost while empty, navy once there is a draft (the app's AnimatedContainer, 180 ms)
  const navy = f < A6.send + 6 ? ease(f, k0, k0 + 10) : 1 - ease(f, A6.send + 6, A6.send + 16);
  const textTop = COMPOSER.y + (COMPOSER.h - COMPOSER.line) / 2;
  const textX = COMPOSER.x + COMPOSER.padX;
  const caretX = textX + (draft ? width(draft, COMPOSER.size) : 0) + 1;
  const caretOn = f >= k0 && f < A6.send ? 1 : blink(f); // solid while typing, beat-locked blink at rest
  const hint = f < k0 ? 1 : f >= A6.send ? ease(f, A6.send + 4, A6.send + 16) : 0; // the placeholder wipes back after sending
  const type = { fontSize: COMPOSER.size, fontWeight: 500, lineHeight: `${COMPOSER.line}px` } as const;
  const discX = COMPOSER.x + FIELD_W + COMPOSER.gap;
  return (
    <>
      <div style={{ position: "absolute", left: COMPOSER.x, top: COMPOSER.y, width: FIELD_W, height: COMPOSER.h, borderRadius: COMPOSER.h / 2, background: C.tint }} />
      {hint > 0 && (
        <div style={{ position: "absolute", left: textX, top: textTop, ...type, color: C.ink2, whiteSpace: "nowrap", clipPath: hint < 1 ? `inset(0 ${(1 - hint) * 100}% 0 0)` : undefined }}>{T.a6.placeholder}</div>
      )}
      {draft && <div style={{ position: "absolute", left: textX, top: textTop, ...type, color: C.ink, whiteSpace: "pre" }}>{draft}</div>}
      <div style={{ position: "absolute", left: caretX, top: textTop + 1, width: 2, height: COMPOSER.line - 2, borderRadius: 1, background: C.rose, opacity: caretOn }} />
      <div style={{ position: "absolute", left: discX, top: COMPOSER.y, width: COMPOSER.disc, height: COMPOSER.disc, borderRadius: COMPOSER.disc / 2, background: interpolateColors(navy, [0, 1], [C.tint, C.ink]), transform: `scale(${press(f, A6.send)})` }}>
        <svg style={{ position: "absolute", left: 13, top: 13 }} width={22} height={22} viewBox="0 0 24 24" fill="none">
          <path d={PLANE} stroke={interpolateColors(navy, [0, 1], [C.ink3, C.white])} strokeWidth={1.7} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
    </>
  );
};

/** the panel and everything in it: rides the sheet up, later slides up and out */
export const PanelLayer: React.FC = () => {
  const f = useCurrentFrame();
  const dy = panelY(f);
  return (
    <AbsoluteFill style={dy !== 0 ? { transform: `translateY(${dy}px)` } : undefined}>
      <div style={{ position: "absolute", left: PANEL.x, top: PANEL.y, width: PANEL.w, height: PANEL.h, borderRadius: PANEL.r, background: C.card, boxShadow: C.shadow }} />
      <Header />
      <Thread f={f} />
      <Composer f={f} />
    </AbsoluteFill>
  );
};

/** quick pick k (draw them 5 → 0 so each one is dealt from under the one before); leaves with the panel */
export const ChipLayer: React.FC<{ k: number }> = ({ k }) => {
  const f = useCurrentFrame();
  if (f < A6.chips[k]) return null;
  const slots = chipSlots();
  const c = chipAt(k, f, slots);
  const w = k === 0 ? slots[0].w * ease(f, A6.chips[0], A6.chips[0] + 12) : slots[k].w; // the first one unfolds
  return (
    <div style={{ position: "absolute", left: c.x, top: CHIPS.y - EXIT * exitAt(f), width: w, height: CHIPS.h, borderRadius: CHIPS.h / 2, background: C.card, boxShadow: C.shadow, overflow: "hidden", transform: c.s === 1 ? undefined : `scale(${c.s})` }}>
      <div style={{ position: "absolute", left: CHIPS.padX, top: 0, height: CHIPS.h, display: "flex", alignItems: "center", fontSize: CHIPS.size, fontWeight: 500, color: C.ink, whiteSpace: "nowrap" }}>{T.a6.chips[k]}</div>
    </div>
  );
};
