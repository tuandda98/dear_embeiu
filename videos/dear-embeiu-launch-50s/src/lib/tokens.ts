// Colours are the app's own tokens (lib/theme/app_colors.dart). Name by ROLE, never by hue.
export const C = {
  bg: "#FAFAFC", // bgLight: the ground of every light frame
  tint: "#F5F0F5", // surfaceLight: section dividers, input fill
  card: "#FFFFFF", // cardSurface
  ink: "#1A1A2E", // textPrimary — also the app's "black" (Act 5 ground, the primary pill)
  ink2: "#6B6B7B", // textSecondary
  ink3: "#A0A0B0", // textTertiary
  white: "#FFFFFF",
  rose: "#FF4D6D", // accentLove: YOU, love actions, the one CTA
  roseDeep: "#E63956", // accentLoveDeep
  lavender: "#A78BFA", // accentLavender: THE OTHER (the partner's label colour in the app)
  lavenderDeep: "#7C5CD6", // accentLavenderDeep
  success: "#66BB6A",
  error: "#EF5350",
  sunset: ["#FF6B9D", "#FF8FA3", "#FFB6C1"], // sunsetRomance: counter card, icon tile
  dawn: ["#FFC1CC", "#E8B4D8", "#C8A8E9"], // dawnBlush: Home/Auth background, sheet headers
  mint: ["#FFD6E0", "#E0D4F7", "#C6E5D9"], // dreamyMint: gallery, milestones
  /** the app's soft card shadow (AppColors.softCardShadow) */
  shadow: "0 8px 24px rgba(255, 107, 157, 0.12)",
} as const;

export const gradient = (stops: readonly string[], deg = 135) => `linear-gradient(${deg}deg, ${stops.join(", ")})`;

export const FONT = "Quicksand";

export const W = 1920;
export const H = 1080;
/** 12-column grid, 120 px margins, 24 px gutters. Text is left-aligned on column edges; only the end card is centred. */
export const GRID = { margin: 120, gutter: 24, cols: 12 } as const;
export const colW = (n: number) => ((W - 2 * GRID.margin - (GRID.cols - 1) * GRID.gutter) / GRID.cols) * n + GRID.gutter * (n - 1);
export const colX = (i: number) => GRID.margin + i * (colW(1) + GRID.gutter);

/** film headline type: Quicksand 700 */
export const HEAD = { fontFamily: FONT, fontWeight: 700, letterSpacing: "-0.01em" } as const;
/** chips: Quicksand 600 uppercase tracked (the app's EyebrowChip) */
export const CHIP = { fontFamily: FONT, fontWeight: 600, letterSpacing: "0.1em", textTransform: "uppercase" } as const;
/** product UI rebuilt in the film keeps the app's own sizes × the phone scale */
export const RADIUS = { card: 28, input: 20, pill: 999 } as const;
/** the phone: iPhone screen 402×874 pt; hero scale 1.1, side scale 0.72 (BRIEF §4) */
export const PHONE = { w: 402, h: 874, radius: 55, hero: 1.1, side: 0.72 } as const;
/** Quicksand has no tabular figures: a rolling number sits in boxes this wide (em) per digit */
export const DIGIT_EM = 0.62;
