// Act 6 · the range: the ruled 4 × 2 glyph grid, the masked ticker between the two dots, the caption — and the recede,
// where everything scales into the centre while the dots travel to their touch (H2640). Layers read the frame
// themselves (they may sit inside <Blur>).
import { AbsoluteFill, Easing, useCurrentFrame } from "remotion";
import { Dot } from "../../components/Dot.tsx";
import { Caption } from "../../components/Text.tsx";
import { T } from "../../copy/strings.ts";
import { ease, lerp, settle } from "../../lib/ease.ts";
import { C } from "../../lib/tokens.ts";
import { A6 } from "../../timeline/cues.ts";
import { GLYPHS } from "./Glyphs.tsx";
import { CAPTION, CELLS, DOTS, TICKER, TOUCH } from "./layout.ts";

const HAIR = "rgba(160, 160, 176, 0.5)"; // DESIGN §4: C.ink3 at 50 % on light
const speed = (fn: (x: number) => number, f: number) => Math.abs(fn(f + 0.25) - fn(f - 0.25)) * 2;

/** the recede: 1 → 0 into the frame centre, accelerating, gone by A6.recede[0] + 34 */
export const recedeAt = (f: number) => 1 - ease(f, A6.recede[0], A6.recede[0] + 34, Easing.in(Easing.cubic));
const recedeStyle = (s: number): React.CSSProperties | undefined => (s < 1 ? { transformOrigin: "960px 540px", transform: `scale(${s})` } : undefined);
const recedeFast = (f: number) => speed(recedeAt, f) * 900 > 20; // the grid's far corners sit ~900 px from the centre

/** the ticker's travel: a quick flick in from behind the lavender dot, easing into a slow readable drift */
const tickerTravel = (f: number) => {
  const t = Math.max(0, f - A6.ticker[0]);
  return 1100 * (1 - Math.exp(-0.11 * t)) + 2.6 * t;
};
export const tickerFast = (f: number) => (f > A6.ticker[0] && speed(tickerTravel, f) > 20) || recedeFast(f);
export const gridFast = recedeFast;

/** the dots: in from the frame edges to the ticker's ends, then together to the touch, landing at rest on 2639 */
function dotsAt(f: number) {
  const m = ease(f, A6.recede[0] - 2, A6.recede[1] - 1, Easing.inOut(Easing.cubic));
  if (m >= 1) return { you: TOUCH.you, other: TOUCH.other };
  const a = settle(f, A6.dots[0], { stiffness: 150, zeta: 0.78 });
  const you = lerp(-3 * TOUCH.r, DOTS.you, a);
  const other = lerp(1920 + 3 * TOUCH.r, DOTS.other, a);
  return {
    you: { x: lerp(you, TOUCH.you.x, m), y: lerp(DOTS.y, TOUCH.you.y, m) },
    other: { x: lerp(other, TOUCH.other.x, m), y: lerp(DOTS.y, TOUCH.other.y, m) },
  };
}
export const dotsFast = (f: number) => Math.max(speed((x) => dotsAt(x).you.x, f), speed((x) => dotsAt(x).you.y, f)) > 20;

const Cell: React.FC<{ k: number; f: number }> = ({ k, f }) => {
  const g = A6.glyphs[k];
  if (f < g) return null;
  const x = CELLS.cols[k % 4];
  const y = CELLS.rows[Math.floor(k / 4)];
  const Glyph = GLYPHS[k];
  return (
    <>
      <div style={{ position: "absolute", left: x, top: y + CELLS.glyphTop, width: 96 * CELLS.k, height: 64 * CELLS.k }}>
        <Glyph t={f - g} />
      </div>
      <Caption text={T.a6.glyphs[k]} x={x} y={y + CELLS.labelTop} size={28} weight={600} color={C.ink} wipe={ease(f, g + 6, g + 20)} />
      <div style={{ position: "absolute", left: x, top: y + CELLS.h, width: CELLS.rule, height: 1, background: HAIR, transformOrigin: "0 0", transform: `scaleX(${ease(f, g, g + 14)})` }} />
    </>
  );
};

export const GridLayer: React.FC = () => {
  const f = useCurrentFrame();
  const s = recedeAt(f);
  if (s <= 0.004) return null;
  return (
    <AbsoluteFill style={recedeStyle(s)}>
      {GLYPHS.map((_, k) => (
        <Cell key={k} k={k} f={f} />
      ))}
      {f >= A6.caption && <Caption text={T.a6.caption} x={CAPTION.x} y={CAPTION.y} wipe={ease(f, A6.caption, A6.caption + 16)} />}
    </AbsoluteFill>
  );
};

export const TickerLayer: React.FC = () => {
  const f = useCurrentFrame();
  const s = recedeAt(f);
  if (f < A6.ticker[0] || s <= 0.004) return null;
  const { maskL, maskR, fade } = TICKER;
  const m = `linear-gradient(90deg, transparent ${maskL}px, #000 ${maskL + fade}px, #000 ${maskR - fade}px, transparent ${maskR}px)`;
  return (
    <AbsoluteFill style={recedeStyle(s)}>
      <div style={{ position: "absolute", left: 0, top: TICKER.y, width: 1920, height: TICKER.line, WebkitMaskImage: m, maskImage: m }}>
        <div style={{ position: "absolute", left: maskR - tickerTravel(f), top: 0, fontSize: TICKER.size, fontWeight: 500, lineHeight: `${TICKER.line}px`, color: C.ink2, whiteSpace: "nowrap" }}>
          {T.a6.ticker.join(" · ")}
        </div>
      </div>
    </AbsoluteFill>
  );
};

export const DotsLayer: React.FC = () => {
  const f = useCurrentFrame();
  if (f < A6.dots[0]) return null;
  const d = dotsAt(f);
  return (
    <>
      <Dot x={d.you.x} y={d.you.y} r={TOUCH.r} who="you" />
      <Dot x={d.other.x} y={d.other.y} r={TOUCH.r} who="other" />
    </>
  );
};
