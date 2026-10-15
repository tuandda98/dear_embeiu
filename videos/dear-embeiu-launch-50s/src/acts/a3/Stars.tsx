// Today's heart constellation (lib/widgets/today_constellation.dart) and its resolve into the app icon: the six stars
// light by halves (rose = you, lavender = the other), dashed lines join them down to the tip, then the stars settle on
// the icon's outline while one white stroke draws through them (each star folds into the line as it passes), the
// sunset tile fills behind, the heart fills white from the tip up and one light sweep crosses the tile.
import { Easing } from "remotion";
import { Heart, TILE } from "../../components/Heart.tsx";
import { C } from "../../lib/tokens.ts";
import { ease, lerp, settle } from "../../lib/ease.ts";
import { T } from "../../copy/strings.ts";
import { A3 } from "../../timeline/cues.ts";
import { DIP, HEART, STARS, TIP, at, length, lerpPoint, star, type P, type Vertex } from "./geo.ts";

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));
const COLOR = { you: C.rose, other: C.lavender } as const;
const SKY_INK = "#231F45"; // the label's knock-out outline, in the sky's colour (as the app does)
const R = 28; // star radius: the four-point stars are 56 px tip to tip

/** convergence of the constellation onto the icon's outline */
const conv = (f: number) => ease(f, A3.heart[0] - 6, A3.heart[0] + 10);
/** the white stroke's progress along the heart path (0 = tip, up the left lobe first) */
const drawAt = (f: number) => Easing.inOut(Easing.sin)(clamp01((f - A3.heart[0]) / (A3.heart[1] - A3.heart[0])));

const sparkle = (c: P, r: number) => {
  const q = 0.16 * r;
  return `M${c.x} ${c.y - r}Q${c.x + q} ${c.y - q} ${c.x + r} ${c.y}Q${c.x + q} ${c.y + q} ${c.x} ${c.y + r}Q${c.x - q} ${c.y + q} ${c.x - r} ${c.y}Q${c.x - q} ${c.y - q} ${c.x} ${c.y - r}Z`;
};

const [Lq, Rq, Lm, Rm, Ls, Rs] = [star("you", 0), star("other", 0), star("you", 1), star("other", 1), star("you", 2), star("other", 2)];
const lit = (s: Vertex) => A3.stars[STARS.indexOf(s as (typeof STARS)[number])];
/** the outline in the heart path's order; each dashed segment draws from `from` (a star) in its window */
const SEGS: { a: Vertex; b: Vertex; from: "a" | "b"; win: [number, number] }[] = [
  { a: TIP, b: Ls, from: "b", win: [lit(Ls) + 4, lit(Ls) + 14] },
  { a: Ls, b: Lm, from: "b", win: [lit(Lm) + 4, lit(Ls)] },
  { a: Lm, b: Lq, from: "b", win: [lit(Lq) + 4, lit(Lm)] },
  { a: Lq, b: DIP, from: "a", win: [lit(Ls) + 14, lit(Ls) + 24] },
  { a: DIP, b: Rq, from: "b", win: [lit(Ls) + 14, lit(Ls) + 24] },
  { a: Rq, b: Rm, from: "a", win: [lit(Rq) + 4, lit(Rm)] },
  { a: Rm, b: Rs, from: "a", win: [lit(Rm) + 4, lit(Rs)] },
  { a: Rs, b: { ...TIP, d: 1 }, from: "a", win: [lit(Rs) + 4, lit(Rs) + 13] },
];
const TIP_LIT = lit(Rs) + 13; // both halves have met at the tip

/** a star's label opens out of its star (masked) and closes back into it as the heart begins */
const Label: React.FC<{ s: (typeof STARS)[number]; p: P; f: number; k: number }> = ({ s, p, f, k }) => {
  const on = lit(s);
  const out = A3.heart[0] - 10 + 0.6 * k; // all six are back in their stars before the stroke starts
  const show = f < out ? ease(f, on + 2, on + 10) : 1 - ease(f, out, out + 6);
  if (show <= 0) return null;
  const left = s.who === "you";
  const mood = s.task === 1;
  const hide = `${(1 - show) * 100}%`;
  const half = `${(1 - show) * 50}%`; // the mood labels sit under their star: open from the centre
  const clip = mood ? `inset(-6px ${half} -6px ${half})` : left ? `inset(-6px -6px -6px ${hide})` : `inset(-6px ${hide} -6px -6px)`;
  const outline = [-1.5, 0, 1.5].flatMap((dx) => [-1.5, 0, 1.5].map((dy) => `${dx}px ${dy}px 0 ${SKY_INK}`)).join(", ");
  return (
    <div
      style={{
        position: "absolute",
        left: mood ? p.x : left ? p.x - R - 14 : p.x + R + 14,
        top: mood ? p.y + R + 6 : p.y,
        transform: mood ? "translateX(-50%)" : left ? "translate(-100%, -50%)" : "translateY(-50%)",
        fontSize: 24,
        lineHeight: "32px",
        fontWeight: 600,
        color: C.white,
        whiteSpace: "nowrap",
        textShadow: outline,
        clipPath: clip,
      }}
    >
      {T.a3.stars[s.task]}
    </div>
  );
};

export const Constellation: React.FC<{ f: number }> = ({ f }) => {
  if (f < A3.stars[0] || f >= A3.heart[1] + 2) return null;
  const c = conv(f);
  const D = drawAt(f);
  const pos = (v: Vertex) => at(v, c);
  const dashes = SEGS.map(({ a, b, from, win }, i) => {
    const td = ease(f, win[0], win[1]);
    if (td <= 0) return null;
    const e = clamp01((D - a.d) / Math.max(1e-6, b.d - a.d)); // erased by the white stroke, in path order
    const [lo, hi] = from === "a" ? [0, td] : [1 - td, 1];
    const u0 = Math.max(lo, e);
    if (u0 >= hi) return null;
    const A = pos(a);
    const B = pos(b);
    const L = length(A, B);
    const [p0, p1, off] = from === "a" ? [lerpPoint(A, B, u0), lerpPoint(A, B, hi), u0 * L] : [lerpPoint(A, B, hi), lerpPoint(A, B, u0), (1 - hi) * L];
    return <line key={i} x1={p0.x} y1={p0.y} x2={p1.x} y2={p1.y} stroke={C.white} strokeOpacity={0.35} strokeWidth={1} strokeDasharray="5 7" strokeDashoffset={off} />;
  });
  const tip = pos(TIP);
  const tipS = f < TIP_LIT ? 0 : settle(f, TIP_LIT, { stiffness: 320, zeta: 0.75 }) * (1 - clamp01((D - 0.95) / 0.05));
  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <svg style={{ position: "absolute", left: 0, top: 0 }} width={1920} height={1080}>
        {dashes}
        {STARS.map((s, i) => {
          const on = A3.stars[i];
          if (f < on) return null;
          const p = pos(s);
          const absorbed = clamp01((D - s.d) / 0.05);
          const outline = ease(f, on, on + 6);
          const body = (f < on + 2 ? 0 : settle(f, on + 2, { stiffness: 300, zeta: 0.72 })) * (1 - absorbed);
          const color = COLOR[s.who];
          return (
            <g key={i}>
              {body > 0 && <circle cx={p.x} cy={p.y} r={R * 2.1 * body} fill={`url(#a3-glow-${s.who})`} />}
              {absorbed < 1 && (
                <path d={sparkle(p, R * (1 - absorbed))} fill="none" stroke={color} strokeWidth={2} strokeLinejoin="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - outline} />
              )}
              {body > 0 && <path d={sparkle(p, R * body)} fill={color} />}
            </g>
          );
        })}
        {tipS > 0 && <path d={sparkle(tip, 13 * tipS)} fill="#FFF6D6" />}
        <defs>
          {(["you", "other"] as const).map((w) => (
            <radialGradient key={w} id={`a3-glow-${w}`}>
              <stop offset="0%" stopColor={COLOR[w]} stopOpacity={0.45} />
              <stop offset="100%" stopColor={COLOR[w]} stopOpacity={0} />
            </radialGradient>
          ))}
        </defs>
      </svg>
      {STARS.map((s, i) => f >= A3.stars[i] && <Label key={i} s={s} p={pos(s)} f={f} k={i} />)}
    </div>
  );
};

const { x, y, size } = HEART;
/** the sunset tile, under the constellation (the last stars stay visible on it until the stroke takes them); from the
 *  end of the sweep the whole mark is exactly H1200's <Heart draw fill tile> */
export const HeartTile: React.FC<{ f: number }> = ({ f }) => {
  if (f >= A3.sweep[1]) return <Heart x={x} y={y} size={size} draw={1} fill={1} tile={1} />;
  const tile = ease(f, A3.tile[0], A3.tile[1]);
  return tile > 0 ? <Heart x={x} y={y} size={size} draw={0} fill={0} tile={tile} /> : null;
};

/** the white stroke, the white fill (poured from the tip up), the light sweep */
export const HeartLine: React.FC<{ f: number }> = ({ f }) => {
  if (f < A3.heart[0] || f >= A3.sweep[1]) return null;
  const tile = ease(f, A3.tile[0], A3.tile[1]);
  const D = drawAt(f);
  const sw = 14 * (1 - ease(f, A3.fill[1], A3.fill[1] + 10));
  const pour = ease(f, A3.fill[0], A3.fill[1]);
  const top = y - size / 2 + 166 * (size / 1024) - 2; // the lobes' top
  const bottom = y - size / 2 + 752 * (size / 1024) + 2; // the tip
  const fillTop = lerp(bottom, top, pour);
  const sweep = ease(f, A3.sweep[0], A3.sweep[1], Easing.inOut(Easing.quad));
  const ts = size * tile;
  return (
    <>
      {pour > 0 && (
        <div style={{ position: "absolute", inset: 0, clipPath: `inset(${fillTop}px 0 0 0)` }}>
          <Heart x={x} y={y} size={size} draw={1} fill={1} tile={0} />
        </div>
      )}
      {sw > 0.05 && <Heart x={x} y={y} size={size} draw={D} fill={0} tile={0} stroke={C.white} strokeWidth={sw} />}
      {sweep > 0 && sweep < 1 && (
        <div style={{ position: "absolute", left: x - ts / 2, top: y - ts / 2, width: ts, height: ts, borderRadius: TILE.radius * ts, overflow: "hidden" }}>
          <div
            style={{
              position: "absolute",
              left: -ts * 0.91 + sweep * ts * 2.4, // the rotated band starts fully left of the tile and ends fully right
              top: -ts * 0.5,
              width: ts * 0.42,
              height: ts * 2,
              transform: "rotate(30deg)",
              background: "linear-gradient(90deg, rgba(255,255,255,0) 0%, rgba(255,255,255,0.34) 50%, rgba(255,255,255,0) 100%)",
            }}
          />
        </div>
      )}
    </>
  );
};
