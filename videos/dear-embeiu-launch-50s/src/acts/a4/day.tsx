// The day (BRIEF §5 ACT 4): a 24-hour ruler runs right-to-left through the playhead at x 1280, 80 px an hour, driven by
// hourAt(f); each event drops a card onto it as its hour crosses the playhead (the other's above the line in lavender,
// yours below it in rose) and stays attached; three counters roll under the ruler. Film px, global frames.
import { measureText } from "@remotion/layout-utils";
import { C, CHIP, FONT, colX, colW } from "../../lib/tokens.ts";
import { ease, press, settle } from "../../lib/ease.ts";
import { pad2 } from "../../lib/num.ts";
import { A4, hourAt } from "../../timeline/cues.ts";
import { T } from "../../copy/strings.ts";
import { Digits } from "../../components/Digits.tsx";
import { G, type GlyphName } from "./glyphs.tsx";
import { EVENT_F } from "./events.ts";
import { Roll, countAt, inOut } from "./parts.tsx";

export const PLAYHEAD = 1280;
const PX_H = 80;
export const LINE_Y = 647;
export const WINDOW_X = colX(4); // the past runs out under a soft mask at the text column (688)
/** a card is 420 wide, 132 tall for a title line + a body line, 32 taller for each line more */
const CARD = { w: 420, h: 132, more: 32, r: 24, bar: 6 };
const LANE = { otherBottom: LINE_Y - 16, youTop: LINE_Y + 45 } as const; // 631 · 692 (the ticks and hour labels hang between)
const DROP = 48;
const ABOVE = 260; // the window reaches this far above the line…
const BELOW = 270; // …and this far below it

// The tape's position in hours. hourAt() is the cue sheet's ramp; at the stop the tape coasts 5 px past 24:00 and
// springs back (the "4 f overshoot", peak on A4.stop). DESIGN §6 writes x = 1280 − (h − hourAt)·80, which would run the
// tape left-to-right with the hours reading backwards; the brief's "streams in from the right / runs right-to-left"
// needs x = 1280 + (h − hourAt)·80, used here.
const KICK = 5;
const kick = (f: number) => (f < A4.stop ? KICK * inOut(f, A4.stop - 7, A4.stop) : KICK * (1 - settle(f, A4.stop, { stiffness: 700, zeta: 0.7 })));
const tape = (f: number) => hourAt(f) + kick(f) / PX_H;
/** the ruler streams in from the right over A4.ruler and comes to rest with 00:00 under the playhead */
const STREAM = 700;
const stream = (f: number) => STREAM * (1 - inOut(f, A4.ruler[0], A4.ruler[1]));
export const hx = (h: number, f: number) => PLAYHEAD + (h - tape(f)) * PX_H + stream(f);

// ── the ruler: a 1 px line 00:00 → 24:00, a 24 px tick every hour hanging under it (40 px every 6 h), labels beside ──
const Ruler: React.FC<{ f: number }> = ({ f }) => {
  const x = (h: number) => hx(h, f) - WINDOW_X;
  return (
    <>
      <div style={{ position: "absolute", left: x(0), top: LINE_Y, width: x(24) - x(0) + 1, height: 1, background: "rgba(160,160,176,0.5)" /* C.ink3 at 50 % */ }} />
      {Array.from({ length: 25 }, (_, h) => (
        <div key={h} style={{ position: "absolute", left: x(h), top: LINE_Y, width: 1, height: h % 6 ? 24 : 40, background: C.ink3 }} />
      ))}
      {[0, 6, 12, 18, 24].map((h) => (
        <div key={h} style={{ position: "absolute", left: x(h) + 9, top: LINE_Y + 8, height: 26, lineHeight: "26px", fontSize: 22, fontWeight: 600, color: C.ink2, whiteSpace: "nowrap" }}>
          {`${pad2(h)}:00`}
        </div>
      ))}
    </>
  );
};

/** the playhead's readout: the hour the day is at, 56 px in fixed digit boxes, standing on the playhead */
export const Readout: React.FC<{ f: number }> = ({ f }) => {
  if (f < A4.ruler[1] - 18) return null;
  const r = inOut(f, A4.ruler[1] - 18, A4.ruler[1]);
  const m = Math.min(24 * 60, Math.floor(tape(Math.min(f, A4.stop)) * 60 + 1e-6));
  return (
    <div style={{ position: "absolute", left: PLAYHEAD - 110, top: 228, width: 220, height: 64, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 6 + (1 - r) * 60, display: "flex", justifyContent: "center", opacity: r }}>
        <Digits value={`${pad2(Math.floor(m / 60))}:${pad2(m % 60)}`} size={56} weight={700} color={C.ink} />
      </div>
    </div>
  );
};

// ── the day's cards ────────────────────────────────────────────────────────────────────────────────────────────────
const ICON_X = CARD.bar + 14;
const TEXT_X = ICON_X + 32 + 14;
const TEXT_W = CARD.w - TEXT_X - 14; // 340
const width = (s: string, size: number, weight: number) => measureText({ text: s, fontFamily: FONT, fontSize: size, fontWeight: String(weight) }).width;
/**
 * One line when it fits; otherwise two: after a colon if there is one (the reminder), else at the space that balances
 * the lines best, a little in favour of a punctuation break and of a first line no longer than the second.
 */
const lines = (s: string, size: number, weight: number): string[] => {
  if (width(s, size, weight) <= TEXT_W) return [s];
  const colon = s.indexOf(": ");
  if (colon > 0 && width(s.slice(0, colon + 1), size, weight) <= TEXT_W) return [s.slice(0, colon + 1), s.slice(colon + 2)];
  const words = s.split(" ");
  let best: string[] = [s];
  let score = Infinity;
  for (let i = 1; i < words.length; i++) {
    const a = words.slice(0, i).join(" ");
    const b = words.slice(i).join(" ");
    const [wa, wb] = [width(a, size, weight), width(b, size, weight)];
    if (wa > TEXT_W || wb > TEXT_W) continue;
    const sc = Math.max(wa, wb) * (wa > wb ? 1.05 : 1) * (/[,·]$/.test(a) ? 0.85 : 1);
    if (sc < score) [best, score] = [[a, b], sc];
  }
  return best;
};
let LAYOUT: { title: string[]; body: string[] }[] | null = null; // measured on first render (the fonts are loaded by then)
const cardLayout = (k: number) => (LAYOUT ??= T.a4.events.map((e) => ({ title: lines(e.title, 26, 600), body: lines(e.body, 20, 500) })))[k];
const cardH = (k: number) => {
  const { title, body } = cardLayout(k);
  return CARD.h + CARD.more * (title.length + body.length - 2);
};

const Card: React.FC<{ k: number; f: number }> = ({ k, f }) => {
  const e = T.a4.events[k];
  const fe = EVENT_F[k];
  const { title, body } = cardLayout(k);
  const h = cardH(k);
  const p = settle(f, fe, { stiffness: 240, zeta: 0.8 });
  const you = e.who === "you";
  const top = you ? LANE.youTop + DROP * (1 - p) : LANE.otherBottom - h - DROP * (1 - p);
  const block = title.length * 32 + 4 + body.length * 26;
  const pad = (h - block) / 2;
  const left = hx(e.hour, f) - 8 - CARD.w;
  // a card leaves as a whole: it fades while its left edge slides from 760 to 520, so the column edge never shows the
  // blank tail of a card whose words have already gone under the mask
  const away = ease(left, 520, 760);
  return (
    <div
      style={{
        position: "absolute",
        left: left - WINDOW_X,
        top: top - (LINE_Y - ABOVE),
        width: CARD.w,
        height: h,
        borderRadius: CARD.r,
        background: C.card,
        boxShadow: "0 10px 30px rgba(255,107,157,0.13), 0 2px 8px rgba(26,26,46,0.05)",
        overflow: "hidden",
        opacity: ease(f, fe, fe + 5) * away,
      }}
    >
      <div style={{ position: "absolute", left: 0, top: 0, width: CARD.bar, height: "100%", background: you ? C.rose : C.lavender }} />
      <G name={e.icon as GlyphName} size={32} color={you ? C.roseDeep : C.lavenderDeep} style={{ position: "absolute", left: ICON_X, top: pad }} />
      <div style={{ position: "absolute", left: TEXT_X, top: pad, width: TEXT_W, whiteSpace: "nowrap" }}>
        {title.map((l) => (
          <div key={l} style={{ fontSize: 26, fontWeight: 600, lineHeight: "32px", color: C.ink }}>
            {l}
          </div>
        ))}
        <div style={{ height: 4 }} />
        {body.map((l) => (
          <div key={l} style={{ fontSize: 20, fontWeight: 500, lineHeight: "26px", color: C.ink2 }}>
            {l}
          </div>
        ))}
      </div>
    </div>
  );
};

const EventDot: React.FC<{ k: number; f: number }> = ({ k, f }) => {
  const s = settle(f, EVENT_F[k], { stiffness: 420, zeta: 0.7 });
  return (
    <div
      style={{
        position: "absolute",
        left: hx(T.a4.events[k].hour, f) - 5 - WINDOW_X,
        top: ABOVE - 5,
        width: 10,
        height: 10,
        borderRadius: 5,
        background: T.a4.events[k].who === "you" ? C.rose : C.lavender,
        boxShadow: "0 0 0 2px #FAFAFC",
        transform: `scale(${s})`,
      }}
    />
  );
};

/** the ruler and the cards, in a window from the text column to the right edge (the past leaves under a soft mask) */
export const Day: React.FC<{ f: number }> = ({ f }) => {
  if (f < A4.ruler[0]) return null;
  const mask = "linear-gradient(90deg, transparent 0px, #000 64px)";
  return (
    <div style={{ position: "absolute", left: WINDOW_X, top: LINE_Y - ABOVE, width: 1920 - WINDOW_X, height: ABOVE + BELOW, overflow: "hidden", WebkitMaskImage: mask, maskImage: mask }}>
      <div style={{ position: "absolute", left: 0, top: ABOVE - LINE_Y, width: 1920, height: 1080 }}>
        <Ruler f={f} />
      </div>
      {T.a4.events.map((_, k) => f >= EVENT_F[k] && <EventDot key={`d${k}`} k={k} f={f} />)}
      {T.a4.events.map((_, k) => f >= EVENT_F[k] && hx(T.a4.events[k].hour, f) - 8 - CARD.w > 520 && <Card key={k} k={k} f={f} />)}
    </div>
  );
};

// ── the counters: 72 px numbers on colX(9…11), their labels under them ────────────────────────────────────────────
export const COUNTER_X = [colX(9), colX(10), colX(11)];
const LABEL_ROOM = colW(1) + 8; // a label longer than its column breaks after its first word ("SAO / HÔM NAY")
const LABEL = { ...CHIP, fontSize: 20, lineHeight: "24px", color: C.ink2, whiteSpace: "nowrap" } as const;
const labelLines = (s: string) => {
  const w = measureText({ text: s.toUpperCase(), fontFamily: FONT, fontSize: 20, fontWeight: "600", letterSpacing: "0.1em" }).width;
  const i = s.indexOf(" ");
  return w <= LABEL_ROOM || i < 0 ? [s] : [s.slice(0, i), s.slice(i + 1)];
};
export const Counters: React.FC<{ f: number }> = ({ f }) => (
  <>
    {T.a4.counters.map((c, n) => {
      const t0 = A4.ruler[1] - 24 + n * 6;
      if (f < t0) return null;
      const r = inOut(f, t0, t0 + 18);
      return (
        <div key={c.label} style={{ position: "absolute", left: COUNTER_X[n], top: LANE.youTop - 6, height: 140, width: colW(1) + 24, overflow: "hidden" }}>
          <div style={{ position: "absolute", left: 0, top: 6 + (1 - r) * 60, opacity: r }}>
            <div style={{ transformOrigin: "0 50%", transform: `scale(${press(f, A4.stop + 2 * n)})` }}>
              <Roll v={countAt(n, f)} size={72} color={C.ink} style={{ marginLeft: -4 }} />
            </div>
            <div style={{ marginTop: 8 }}>
              {labelLines(c.label).map((l) => (
                <div key={l} style={LABEL}>
                  {l}
                </div>
              ))}
            </div>
          </div>
        </div>
      );
    })}
  </>
);
