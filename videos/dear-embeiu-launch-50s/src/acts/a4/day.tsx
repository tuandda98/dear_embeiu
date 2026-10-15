// The day (V3.md § A4): a ruler 06:00 → 24:00 runs right-to-left under the playhead at x 1280, 80 px an hour, driven by
// hourAt(f), which comes to rest on each of the seven events. One event card at a time hangs under the ruler; when the
// next one drops, the old one slides up and scales into its dot on the ruler. Event 2's photo pops out of its card and
// flies into the phone. Three counters roll at the bottom. Film px, global frames.
import { measureText } from "@remotion/layout-utils";
import { Img, staticFile, useCurrentFrame } from "remotion";
import { C, CHIP, FONT, colX } from "../../lib/tokens.ts";
import { ease, lerp, press, settle } from "../../lib/ease.ts";
import { pad2 } from "../../lib/num.ts";
import { A4, hourAt } from "../../timeline/cues.ts";
import { T } from "../../copy/strings.ts";
import { Digits } from "../../components/Digits.tsx";
import { G, type GlyphName } from "./glyphs.tsx";
import { EVENT_F, OUT_F, OUT_LEN } from "./events.ts";
import { Roll, countAt, inOut } from "./parts.tsx";

export const PLAYHEAD = 1280;
const PX_H = 80;
export const LINE_Y = 290;
/** the playhead stands on the ruler: the readout, then a 2 px needle (rose above lavender) down to the line */
export const HEAD = { top: 232, mid: 261, bottom: LINE_Y } as const;
export const WINDOW_X = colX(4); // the past runs out under a soft mask at the text column (688)
/** the card stage under the ruler (the caption takes it at the end) */
export const SLOT = { x: colX(4), y: 368, w: 656 } as const;
const CARD = { h: 170, title: 48, body: 38, r: 24, edge: 6, icon: 36 } as const;

// The tape's position in hours. hourAt() is the cue sheet's knot curve (06:00 → 24:00, at rest on each event); at the
// stop the tape coasts 5 px past 24:00 and springs back (the "4 f overshoot", peak on A4.stop). x = 1280 + (h − hour)·80:
// the brief's "streams in from the right / runs right-to-left" (DESIGN §6 writes the sign the other way).
const KICK = 5;
const kick = (f: number) => (f < A4.stop ? KICK * inOut(f, A4.stop - 7, A4.stop) : KICK * (1 - settle(f, A4.stop, { stiffness: 700, zeta: 0.7 })));
const tape = (f: number) => hourAt(f) + kick(f) / PX_H;
/** the ruler streams in from the right over A4.ruler (00:00 never shows: the day starts at 06:00) */
const STREAM = 720;
const stream = (f: number) => STREAM * (1 - inOut(f, A4.ruler[0], A4.ruler[1]));
export const hx = (h: number, f: number) => PLAYHEAD + (h - tape(f)) * PX_H + stream(f);
/** the tape's speed in px/f (for the motion blur while it streams in) */
export const tapeSpeed = (f: number) => Math.abs(hx(6, f + 0.5) - hx(6, f - 0.5));

// ── the ruler: a 1 px line 06:00 → 24:00, a 24 px tick every hour hanging under it (40 px every 6 h), labels beside ──
const Ruler: React.FC<{ f: number }> = ({ f }) => {
  const x = (h: number) => hx(h, f) - WINDOW_X;
  return (
    <>
      <div style={{ position: "absolute", left: x(6), top: LINE_Y, width: x(24) - x(6) + 1, height: 1, background: "rgba(160,160,176,0.5)" /* C.ink3 at 50 % */ }} />
      {Array.from({ length: 19 }, (_, i) => i + 6).map((h) => (
        <div key={h} style={{ position: "absolute", left: x(h), top: LINE_Y, width: 1, height: h % 6 ? 24 : 40, background: C.ink3 }} />
      ))}
      {[6, 12, 18, 24].map((h) => (
        <div key={h} style={{ position: "absolute", left: x(h) + 9, top: LINE_Y + 4, height: 34, lineHeight: "34px", fontSize: 28, fontWeight: 600, color: C.ink2, whiteSpace: "nowrap" }}>
          {`${pad2(h)}:00`}
        </div>
      ))}
    </>
  );
};

/** the playhead's readout: the hour the day is at, 56 px in fixed digit boxes, wiped in as the ruler arrives */
export const Readout: React.FC<{ f: number }> = ({ f }) => {
  if (f < A4.ruler[0] + 8) return null;
  const w = ease(f, A4.ruler[0] + 8, A4.ruler[0] + 28);
  const m = Math.min(24 * 60, Math.round(tape(Math.min(f, A4.stop)) * 60)); // the knots are decimal hours (6.833 = 06:50)
  return (
    <div style={{ position: "absolute", left: PLAYHEAD - 110, top: 160, width: 220, height: 64, display: "flex", justifyContent: "center", clipPath: `inset(0 ${(1 - w) * 50}% 0 ${(1 - w) * 50}%)` }}>
      <Digits value={`${pad2(Math.floor(m / 60))}:${pad2(m % 60)}`} size={56} weight={700} color={C.ink} style={{ marginTop: 4 }} />
    </div>
  );
};

// ── the cards: one at a time ───────────────────────────────────────────────────────────────────────────────────────
const TEXT_X = CARD.edge + 26 + CARD.icon + 18; // 86
const TEXT_W = SLOT.w - TEXT_X - 26; // 544
const width = (s: string, size: number, weight: number) => measureText({ text: s, fontFamily: FONT, fontSize: size, fontWeight: String(weight) }).width;
/**
 * One line when it fits; otherwise two at the space that balances them best (a little in favour of a punctuation
 * break and of a first line no longer than the second).
 */
const lines = (s: string, size: number, weight: number): string[] => {
  if (width(s, size, weight) <= TEXT_W) return [s];
  const words = s.split(" ");
  let best: string[] = [s];
  let score = Infinity;
  for (let i = 1; i < words.length; i++) {
    const a = words.slice(0, i).join(" ");
    const b = words.slice(i).join(" ");
    const [wa, wb] = [width(a, size, weight), width(b, size, weight)];
    if (wa > TEXT_W || wb > TEXT_W) continue;
    const sc = Math.max(wa, wb) * (wa > wb ? 1.05 : 1) * (/[,·:]$/.test(a) ? 0.85 : 1);
    if (sc < score) [best, score] = [[a, b], sc];
  }
  return best;
};
let LAYOUT: { title: string[]; body: string[] }[] | null = null; // measured on first render (the fonts are loaded by then)
const cardLayout = (k: number) => (LAYOUT ??= T.a4.events.map((e) => ({ title: lines(e.title, 40, 600), body: lines(e.body, 30, 500) })))[k];
const cardH = (k: number) => {
  const { title, body } = cardLayout(k);
  return CARD.h + CARD.title * (title.length - 1) + CARD.body * (body.length - 1);
};

/** the dot an event leaves on the ruler: it lands with its card and swells once when the card folds into it */
const EventDot: React.FC<{ k: number; f: number }> = ({ k, f }) => {
  const s = settle(f, EVENT_F[k], { stiffness: 420, zeta: 0.7 });
  const take = f >= OUT_F[k] + OUT_LEN - 2 ? 0.45 * (1 - settle(f, OUT_F[k] + OUT_LEN - 2, { stiffness: 300, zeta: 0.75 })) : 0;
  return (
    <div
      style={{
        position: "absolute",
        left: hx(T.a4.events[k].hour, f) - 6 - WINDOW_X,
        top: LINE_Y - 6 - 150, // the window starts at y 150
        width: 12,
        height: 12,
        borderRadius: 6,
        background: T.a4.events[k].who === "you" ? C.rose : C.lavender,
        boxShadow: "0 0 0 3px #FAFAFC",
        transform: `scale(${s * (1 + take)})`,
      }}
    />
  );
};

/** card k: drops 28 px into the stage with `settle`; leaves by sliding up and scaling into its dot */
const Card: React.FC<{ k: number; f: number }> = ({ k, f }) => {
  const e = T.a4.events[k];
  const { title, body } = cardLayout(k);
  const h = cardH(k);
  const you = e.who === "you";
  const p = settle(f, EVENT_F[k], { stiffness: 400, zeta: 0.8 }); // opaque and settled by its drop + 4
  const out = ease(f, OUT_F[k], OUT_F[k] + OUT_LEN, (t) => t * t); // ease-in: it is drawn into the dot
  const cx = SLOT.x + SLOT.w / 2;
  const cy = SLOT.y + h / 2 - 28 * (1 - p);
  const dx = lerp(cx, hx(e.hour, f), out);
  const dy = lerp(cy, LINE_Y, out);
  const sc = lerp(1, 0.04, out);
  const block = title.length * CARD.title + 8 + body.length * CARD.body;
  const pad = (h - block) / 2;
  return (
    <div
      style={{
        position: "absolute",
        left: dx - SLOT.w / 2,
        top: dy - h / 2,
        width: SLOT.w,
        height: h,
        borderRadius: CARD.r,
        background: C.card,
        boxShadow: "0 14px 36px rgba(255,107,157,0.14), 0 2px 8px rgba(26,26,46,0.05)",
        overflow: "hidden",
        transform: `scale(${sc})`,
        opacity: ease(f, EVENT_F[k], EVENT_F[k] + 4) * (1 - ease(f, OUT_F[k] + OUT_LEN - 4, OUT_F[k] + OUT_LEN)),
      }}
    >
      <div style={{ position: "absolute", left: 0, top: 0, width: CARD.edge, height: "100%", background: you ? C.rose : C.lavender }} />
      <G name={e.icon as GlyphName} size={CARD.icon} stroke={2} color={you ? C.roseDeep : C.lavenderDeep} style={{ position: "absolute", left: CARD.edge + 26, top: pad + 6 }} />
      <div style={{ position: "absolute", left: TEXT_X, top: pad, width: TEXT_W, whiteSpace: "nowrap" }}>
        {title.map((l) => (
          <div key={l} style={{ fontSize: 40, fontWeight: 600, lineHeight: `${CARD.title}px`, color: C.ink, letterSpacing: "-0.01em" }}>
            {l}
          </div>
        ))}
        <div style={{ height: 8 }} />
        {body.map((l) => (
          <div key={l} style={{ fontSize: 30, fontWeight: 500, lineHeight: `${CARD.body}px`, color: C.ink2 }}>
            {l}
          </div>
        ))}
      </div>
    </div>
  );
};

/** the ruler, its dots and the one card on stage, in a window from the text column to the right edge */
export const Day: React.FC = () => {
  const f = useCurrentFrame();
  if (f < A4.ruler[0]) return null;
  const mask = "linear-gradient(90deg, transparent 0px, #000 64px)";
  return (
    <>
      <div style={{ position: "absolute", left: WINDOW_X, top: 150, width: 1920 - WINDOW_X, height: 200, overflow: "hidden", WebkitMaskImage: mask, maskImage: mask }}>
        <div style={{ position: "absolute", left: 0, top: -150, width: 1920, height: 1080 }}>
          <Ruler f={f} />
        </div>
        {T.a4.events.map((_, k) => f >= EVENT_F[k] && <EventDot key={k} k={k} f={f} />)}
      </div>
      {T.a4.events.map((_, k) => f >= EVENT_F[k] && f < OUT_F[k] + OUT_LEN && <Card key={k} k={k} f={f} />)}
    </>
  );
};

// ── event 2's photo: a print pops out of its card, holds, then flies into the phone's Kỷ niệm tab ──────────────────
export const PRINT = { x: 1364, y: SLOT.y, w: 436, h: 536, border: 16, caption: 70 } as const;
/** the phone's Kỷ niệm tab on screen: screen pt (246, 782) on the phone at (120, 90) × 1.1, bezel 12 */
export const GALLERY_TAB = { x: 120 + 13.2 + 246 * 1.1, y: 90 + 13.2 + 782 * 1.1 } as const;
const printAt = (f: number) => {
  const { pop, hold, fly, land } = A4.photo;
  const home = { x: PRINT.x + PRINT.w / 2, y: PRINT.y + PRINT.h / 2 };
  if (f < hold) {
    // out of the card's right end, growing into its place (one small overshoot)
    const p = settle(f, pop, { stiffness: 260, zeta: 0.8 });
    const from = { x: SLOT.x + SLOT.w, y: SLOT.y + cardH(1) / 2 };
    return { x: lerp(from.x, home.x, p), y: lerp(from.y, home.y, p), s: lerp(0.12, 1, p) };
  }
  if (f < fly) return { ...home, s: 1 };
  const MID = fly + 8; // first it shrinks where it is, then it flies, under the card on stage, into the tab
  if (f < MID) return { ...home, s: lerp(1, 0.34, inOut(f, fly, MID)) };
  const t = ease(f, MID, land, (u) => u * u * (3 - 2 * u));
  const via = { x: 1060, y: 700 };
  const bx = (1 - t) * (1 - t) * home.x + 2 * t * (1 - t) * via.x + t * t * GALLERY_TAB.x;
  const by = (1 - t) * (1 - t) * home.y + 2 * t * (1 - t) * via.y + t * t * GALLERY_TAB.y;
  return { x: bx, y: by, s: lerp(0.34, 0.06, t) };
};
export const printSpeed = (f: number) => {
  const a = printAt(f - 0.5);
  const b = printAt(f + 0.5);
  return Math.hypot(b.x - a.x, b.y - a.y) + Math.abs(b.s - a.s) * PRINT.h * 0.5;
};
export const Print: React.FC = () => {
  const f = useCurrentFrame();
  if (f < A4.photo.pop || f >= A4.photo.land) return null;
  const p = printAt(f);
  return (
    <div
      style={{
        position: "absolute",
        left: p.x - PRINT.w / 2,
        top: p.y - PRINT.h / 2,
        width: PRINT.w,
        height: PRINT.h,
        transform: `scale(${p.s})`,
        background: C.white,
        borderRadius: 6,
        boxShadow: "0 24px 60px rgba(26,26,46,0.18), 0 6px 16px rgba(255,107,157,0.14)",
        opacity: ease(f, A4.photo.pop, A4.photo.pop + 4),
      }}
    >
      <div style={{ position: "absolute", left: PRINT.border, top: PRINT.border, right: PRINT.border, bottom: PRINT.caption, overflow: "hidden", borderRadius: 2 }}>
        <Img src={staticFile("photos/11.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "40% 50%" }} />
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: PRINT.caption, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 30, fontWeight: 600, color: C.ink }}>
        {T.a4.events[1].body}
      </div>
    </div>
  );
};

// ── the counters: 58 px numbers on colX(4 · 6 · 8), their labels (28 px) under them ──────────────────────────────
export const COUNTER_X = [colX(4), colX(6), colX(8)];
export const COUNTER_Y = 900;
export const Counters: React.FC<{ f: number }> = ({ f }) => (
  <>
    {T.a4.counters.map((c, n) => {
      const t0 = A4.ruler[0] + 8 + n * 5;
      if (f < t0) return null;
      const r = inOut(f, t0, t0 + 20);
      return (
        <div key={c.label} style={{ position: "absolute", left: COUNTER_X[n], top: COUNTER_Y - 6, height: 112, width: 260, overflow: "hidden" }}>
          <div style={{ position: "absolute", left: 0, top: 6 + (1 - r) * 60, opacity: r }}>
            <div style={{ transformOrigin: "0 50%", transform: `scale(${press(f, A4.stop + 2 * n)})` }}>
              <Roll v={countAt(n, f)} size={58} color={C.ink} style={{ marginLeft: -3 }} />
            </div>
            <div style={{ ...CHIP, marginTop: 8, fontSize: 28, lineHeight: "34px", color: C.ink2, whiteSpace: "nowrap" }}>{c.label}</div>
          </div>
        </div>
      );
    })}
  </>
);
