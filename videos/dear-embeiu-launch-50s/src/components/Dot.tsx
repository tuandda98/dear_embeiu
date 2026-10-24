import { C } from "../lib/tokens.ts";

/**
 * THE TWO (BRIEF §2): a soft dot — rose = you, lavender = the other. `r` = radius in px. The glow is one bounded radial
 * gradient, never a blur filter. Both acts that share a dot must place it from the same cue so it never jumps.
 */
export const Dot: React.FC<{ x: number; y: number; r?: number; who: "you" | "other"; opacity?: number; glow?: number }> = ({
  x,
  y,
  r = 14,
  who,
  opacity = 1,
  glow = 0.35,
}) => {
  const color = who === "you" ? C.rose : C.lavender;
  return (
    <div style={{ position: "absolute", left: x - r * 3, top: y - r * 3, width: r * 6, height: r * 6, opacity, pointerEvents: "none" }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: `radial-gradient(circle, ${color}${alpha(glow)} 0%, ${color}00 60%)` }} />
      <div style={{ position: "absolute", left: r * 2, top: r * 2, width: r * 2, height: r * 2, borderRadius: "50%", background: color }} />
    </div>
  );
};
const alpha = (a: number) =>
  Math.round(Math.max(0, Math.min(1, a)) * 255)
    .toString(16)
    .padStart(2, "0");
