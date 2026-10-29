import type { CSSProperties, ReactNode } from "react";
import { C, RADIUS } from "../lib/tokens.ts";

/** the app's white card: radius 28, soft rose shadow (AppColors.softCardShadow), no outline (BRIEF §4) */
export const Card: React.FC<{ style?: CSSProperties; children?: ReactNode; radius?: number; shadow?: boolean }> = ({
  style,
  children,
  radius = RADIUS.card,
  shadow = true,
}) => (
  <div style={{ position: "absolute", background: C.card, borderRadius: radius, boxShadow: shadow ? C.shadow : undefined, ...style }}>{children}</div>
);

/** the app's EyebrowChip: a frosted pill, uppercase tracked 600 text, optional leading glyph */
export const Chip: React.FC<{ text: string; style?: CSSProperties; color?: string; bg?: string; size?: number }> = ({
  text,
  style,
  color = C.ink,
  bg = "rgba(255,255,255,0.72)",
  size = 14,
}) => (
  <div
    style={{
      position: "absolute",
      display: "inline-flex",
      alignItems: "center",
      padding: `${size * 0.55}px ${size * 1.2}px`,
      borderRadius: 999,
      background: bg,
      boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.65), 0 4px 12px rgba(255,107,157,0.10)",
      color,
      fontSize: size,
      fontWeight: 600,
      letterSpacing: "0.1em",
      textTransform: "uppercase",
      whiteSpace: "nowrap",
      ...style,
    }}
  >
    {text}
  </div>
);

/** the app's primary button: a navy pill, white 600 text; `scale` for the press (ease.press) */
export const Pill: React.FC<{ text: string; style?: CSSProperties; scale?: number; bg?: string; color?: string; size?: number }> = ({
  text,
  style,
  scale = 1,
  bg = C.ink,
  color = C.white,
  size = 15,
}) => (
  <div
    style={{
      position: "absolute",
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      height: size * 3.47,
      padding: `0 ${size * 1.6}px`,
      borderRadius: 999,
      background: bg,
      color,
      fontSize: size,
      fontWeight: 600,
      letterSpacing: "0.02em",
      whiteSpace: "nowrap",
      transform: `scale(${scale})`,
      ...style,
    }}
  >
    {text}
  </div>
);
