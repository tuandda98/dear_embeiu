import { C } from "../lib/tokens.ts";

/** the app icon's heart (assets/branding/app_icon.svg, viewBox 1024): starts at the bottom tip, runs the left lobe first */
export const HEART_PATH =
  "M 512 752 C 512 752 182 566 182 338 C 182 240 256 166 346 166 C 410 166 467 199 512 250 C 557 199 614 166 678 166 C 768 166 842 240 842 338 C 842 566 512 752 512 752 Z";
/** the icon tile: Sunset Romance with the icon's own three stops, corner radius 22.5 % */
export const TILE = { radius: 230 / 1024, stops: ["#FF6B9D", "#FF7E9C", "#FF8FA3"] } as const;

/**
 * The logo (BRIEF §5 act 3 / act 7). `draw` 0 → 1 strokes the heart path (pathLength 1); `fill` 0 → 1 fills it white;
 * `tile` 0 → 1 fills the sunset tile behind it (from the centre). `size` = the tile's side in px, centred on (x, y).
 */
export const Heart: React.FC<{ x: number; y: number; size: number; draw?: number; fill?: number; tile?: number; stroke?: string; strokeWidth?: number }> = ({
  x,
  y,
  size,
  draw = 1,
  fill = 1,
  tile = 1,
  stroke = C.white,
  strokeWidth = 28,
}) => (
  <svg style={{ position: "absolute", left: x - size / 2, top: y - size / 2 }} width={size} height={size} viewBox="0 0 1024 1024">
    <defs>
      <linearGradient id="heart-tile" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stopColor={TILE.stops[0]} />
        <stop offset="55%" stopColor={TILE.stops[1]} />
        <stop offset="100%" stopColor={TILE.stops[2]} />
      </linearGradient>
      <radialGradient id="heart-shine" cx="30%" cy="22%" r="58%">
        <stop offset="0%" stopColor="#FFB6C1" stopOpacity="0.55" />
        <stop offset="100%" stopColor="#FFB6C1" stopOpacity="0" />
      </radialGradient>
    </defs>
    {tile > 0 && (
      <g transform={`translate(512 512) scale(${tile}) translate(-512 -512)`}>
        <rect width="1024" height="1024" rx={TILE.radius * 1024} fill="url(#heart-tile)" />
        <rect width="1024" height="1024" rx={TILE.radius * 1024} fill="url(#heart-shine)" />
      </g>
    )}
    {fill > 0 && <path d={HEART_PATH} fill={C.white} fillOpacity={fill} />}
    {draw > 0 && draw < 1 && (
      <path d={HEART_PATH} fill="none" stroke={stroke} strokeWidth={strokeWidth} strokeLinecap="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - draw} />
    )}
    {draw >= 1 && fill < 1 && <path d={HEART_PATH} fill="none" stroke={stroke} strokeWidth={strokeWidth} strokeLinecap="round" />}
  </svg>
);
