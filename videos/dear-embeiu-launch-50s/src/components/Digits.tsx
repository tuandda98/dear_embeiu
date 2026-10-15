import type { CSSProperties } from "react";
import { DIGIT_EM } from "../lib/tokens.ts";

/**
 * Numbers in fixed boxes (BRIEF §4: Quicksand has no tabular figures). Every digit sits in a box DIGIT_EM wide; "." ":"
 * and " " get narrower boxes, so a rolling number never shifts the glyphs around it. `size` = font size in px.
 */
export const Digits: React.FC<{ value: string; size: number; weight?: number; color?: string; style?: CSSProperties; align?: "left" | "right" }> = ({
  value,
  size,
  weight = 700,
  color,
  style,
  align = "left",
}) => (
  <div style={{ display: "inline-flex", justifyContent: align === "right" ? "flex-end" : "flex-start", fontSize: size, fontWeight: weight, lineHeight: 1, color, ...style }}>
    {[...value].map((ch, i) => {
      const em = /\d/.test(ch) ? DIGIT_EM : ch === " " ? 0.3 : ch === "." || ch === ":" ? 0.3 : 0.5;
      return (
        <span key={i} style={{ display: "inline-block", width: `${em}em`, textAlign: "center" }}>
          {ch}
        </span>
      );
    })}
  </div>
);

/** the width of a digit string in px at `size`, for layout */
export const digitsWidth = (value: string, size: number) =>
  [...value].reduce((w, ch) => w + (/\d/.test(ch) ? DIGIT_EM : ch === " " || ch === "." || ch === ":" ? 0.3 : 0.5) * size, 0);

export { roll, group, pad2 } from "../lib/num.ts";
