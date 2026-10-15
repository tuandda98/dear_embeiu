// Small shared pieces of Act 4: the odometer (numbers roll in fixed digit boxes), the app's corner-to-corner gradient
// angle, a symmetric ease, and the day's state read from the event table.
import type { CSSProperties } from "react";
import { Easing } from "remotion";
import { DIGIT_EM } from "../../lib/tokens.ts";
import { Digits } from "../../components/Digits.tsx";
import { ease } from "../../lib/ease.ts";
import { T } from "../../copy/strings.ts";
import { COUNT_STEPS, EVENT_F, STEP_LEN } from "./events.ts";

/** an S-curve 0 → 1 over [from, to] for travels that start and end at rest; a sine in-out peaks at π/2 × the average
 *  speed, which keeps the ruler's stream-in, the dots and the page scrolls under the 20 px/f blur threshold */
export const inOut = (f: number, from: number, to: number) => ease(f, from, to, Easing.inOut(Easing.sin));

/** Flutter's LinearGradient(topLeft → bottomRight) on a w×h box, as a CSS angle */
export const diag = (w: number, h: number) => 180 - (Math.atan(w / h) * 180) / Math.PI;

/** counter n (T.a4.counters) at frame f, continuous: each step eases over STEP_LEN frames from its event */
export const countAt = (n: number, f: number) =>
  T.a4.counters[n].from + COUNT_STEPS[n].reduce((s, k) => s + ease(f, EVENT_F[k], EVENT_F[k] + STEP_LEN), 0);

/** has event k (T.a4.events) landed by frame f? */
export const landed = (k: number, f: number) => f >= EVENT_F[k];

/**
 * A number that rolls like an odometer, in <Digits> boxes (Quicksand has no tabular figures): a digit that changes
 * between ⌊v⌋ and ⌊v⌋+1 slides up out of its box while the next one rises in, landing when v reaches the integer.
 */
export const Roll: React.FC<{ v: number; size: number; weight?: number; color?: string; style?: CSSProperties }> = ({ v, size, weight = 700, color, style }) => {
  const n = Math.floor(v + 1e-6);
  const t = v - n;
  const a = String(n);
  const b = String(n + 1).padStart(a.length, " ");
  return (
    <div style={{ display: "inline-flex", fontSize: size, lineHeight: 1, ...style }}>
      {[...a].map((ch, i) => {
        const next = b[i];
        const moving = t > 0.001 && next !== ch;
        const at = (y: number, d: string) => (
          <div style={{ position: "absolute", left: 0, top: `${y}em` }}>
            <Digits value={d} size={size} weight={weight} color={color} />
          </div>
        );
        return (
          <span key={i} style={{ position: "relative", display: "inline-block", width: `${DIGIT_EM}em`, height: "1.1em", overflow: "hidden" }}>
            {at(0.05 - (moving ? t * 1.1 : 0), ch)}
            {moving && at(0.05 + (1 - t) * 1.1, next)}
          </span>
        );
      })}
    </div>
  );
};
