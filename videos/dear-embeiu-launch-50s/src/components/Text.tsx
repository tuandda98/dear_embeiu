import type { CSSProperties, ReactNode } from "react";
import { C, HEAD } from "../lib/tokens.ts";
import { blink } from "../lib/ease.ts";

/** a film caption (BRIEF §7 rule 5): ≤ 7 words, Quicksand 600, never bounces or scales. Enters by a mask wipe (left → right). */
export const Caption: React.FC<{ text: string; x: number; y: number; size?: number; wipe?: number; color?: string; weight?: number; style?: CSSProperties }> = ({
  text,
  x,
  y,
  size = 34,
  wipe = 1,
  color = C.ink,
  weight = 600,
  style,
}) => (
  <div
    style={{
      position: "absolute",
      left: x,
      top: y,
      fontSize: size,
      fontWeight: weight,
      color,
      lineHeight: 1.2,
      whiteSpace: "nowrap",
      clipPath: `inset(0 ${(1 - wipe) * 100}% 0 0)`,
      ...style,
    }}
  >
    {text}
  </div>
);

/** a headline in the film's display type (Quicksand 700) */
export const Head: React.FC<{ children: ReactNode; x: number; y: number; size: number; color?: string; style?: CSSProperties; width?: number }> = ({
  children,
  x,
  y,
  size,
  color = C.ink,
  style,
  width,
}) => (
  <div style={{ position: "absolute", left: x, top: y, width, fontSize: size, lineHeight: 1.14, color, ...HEAD, ...style }}>{children}</div>
);

/** a blinking caret: 2 px wide, `h` tall, phase-locked to the beat (ease.blink) */
export const Caret: React.FC<{ x: number; y: number; h: number; f: number; color?: string; on?: boolean }> = ({ x, y, h, f, color = C.rose, on = true }) => (
  <div style={{ position: "absolute", left: x, top: y, width: 2, height: h, background: color, opacity: on ? blink(f) : 0 }} />
);
