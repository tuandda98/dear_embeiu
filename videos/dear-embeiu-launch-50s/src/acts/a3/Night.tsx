// The love tree's night sky (ref/ios/love-tree-top.png) as one sheet: a dark card (radius 28, on the grid margins)
// rises from the bottom edge to y 600, the stem climbs it in ruled steps with the three checks beside it, three
// flowers open, then the card grows to the whole frame (the constellation's sky) and finally drops away downward.
// Motion blur: the gradient is drawn once (summing ten 10 % copies of a dark gradient bands in 8 bit) and only its
// edge is feathered by the distance it travels in the 180° shutter; the details are sub-frame sampled by <Blur>.
import { Easing, useCurrentFrame } from "remotion";
import { Sky } from "../../components/Sky.tsx";
import { Blur } from "../../components/Blur.tsx";
import { C, GRID, colX } from "../../lib/tokens.ts";
import { ease, settle } from "../../lib/ease.ts";
import { rng } from "../../lib/rand.ts";
import { T } from "../../copy/strings.ts";
import { A3 } from "../../timeline/cues.ts";

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));
const away = Easing.in(Easing.cubic); // leaving accelerates
/** 0 while the sky is a card on the grid margins, 1 once it is the whole frame (A3.night) */
const grown = (f: number) => Easing.inOut(Easing.cubic)(clamp01((f - A3.night[0]) / (A3.night[1] - A3.night[0])));
/** content offset: the card slides up from below (A3.sky), and the night drops away downward (A3.recede) */
const skyOffset = (f: number) =>
  480 * (1 - ease(f, A3.sky[0], A3.sky[1])) + 1140 * away(clamp01((f - A3.recede[0]) / (A3.recede[1] - A3.recede[0])));
/** the sheet's top edge in frame px: 600 as a card, then up past the top of the frame */
export const skyEdge = (f: number) => 600 - 660 * grown(f) + skyOffset(f);
const speed = (fn: (f: number) => number, f: number) => Math.abs(fn(f + 0.5) - fn(f - 0.5));

const BARK = "#8B5E3C"; // the app's branch
const PETAL = C.sunset[2];
/** the stem leans like the app's branch: six ruled 72 px steps; the top three nodes sit on the three check rows */
const BASE = { x: 500, y: 1096 };
const NODES = [
  { x: 522, y: 1022 },
  { x: 542, y: 950 },
  { x: 568, y: 878 },
  { x: 606, y: 806 },
  { x: 664, y: 734 },
  { x: 724, y: 662 },
];
const ROW = { x: colX(7), top: 640, step: 72, box: 44 }; // rows 640 / 712 / 784, centres 662 / 734 / 806 = nodes 5, 4, 3
const FLOWER_NODE = [5, 4, 3]; // flower k opens beside check k
const STARS = (() => {
  const r = rng(23);
  return Array.from({ length: 120 }, () => ({ x: r() * 1920, y: r() * 1200 - 60, s: 0.6 + r() * 1.6, a: 0.25 + r() * 0.55 }));
})();

const petal = (L: number) => {
  const w = L * 0.46;
  const n = L * 0.16;
  return `M0 ${-L * 0.06}C${-w} ${-L * 0.42} ${-w * 0.62} ${-L * 0.86} ${-w * 0.3} ${-L}Q0 ${-L + n} ${w * 0.3} ${-L}C${w * 0.62} ${-L * 0.86} ${w} ${-L * 0.42} 0 ${-L * 0.06}Z`;
};
const PETAL_D = petal(45); // ≈ 90 px across

/** a 5-petal flower opening petal by petal (6 f apart, each scaling out of the centre), turning slightly as it opens */
const Flower: React.FC<{ x: number; y: number; f: number; at: number; tilt: number }> = ({ x, y, f, at, tilt }) => {
  if (f < at) return null;
  const turn = ease(f, at, at + 36);
  return (
    <g transform={`translate(${x} ${y}) rotate(${tilt - 30 * (1 - turn)})`}>
      {[0, 1, 2, 3, 4].map((i) => {
        const s = f < at + i * 6 ? 0 : settle(f, at + i * 6, { stiffness: 240, zeta: 0.74 });
        return s > 0 && <path key={i} d={PETAL_D} transform={`rotate(${i * 72}) scale(${s})`} fill={PETAL} stroke="#FFFFFF" strokeOpacity={0.5} strokeWidth={1} />;
      })}
      <g transform={`scale(${settle(f, at, { stiffness: 300, zeta: 0.8 })})`}>
        {[0, 1, 2, 3, 4].map((i) => {
          const a = ((i * 72 + 36 - 90) * Math.PI) / 180;
          return <circle key={i} cx={17 * Math.cos(a)} cy={17 * Math.sin(a)} r={3} fill="#FFE6A8" />;
        })}
        <circle r={11} fill={C.rose} />
      </g>
    </g>
  );
};

/** a check row: the frosted box pops, its mark draws itself, the words wipe in, the rule draws */
const Check: React.FC<{ k: number; f: number }> = ({ k, f }) => {
  const at = A3.checks[k];
  if (f < at) return null;
  const top = ROW.top + k * ROW.step;
  const mid = top + ROW.box / 2;
  const box = settle(f, at, { stiffness: 320, zeta: 0.8 });
  const mark = ease(f, at + 5, at + 17);
  const rule = ease(f, at + 4, at + 24);
  const wipe = ease(f, at + 8, at + 24);
  const b = ROW.box;
  return (
    <>
      <div style={{ position: "absolute", left: ROW.x, top, width: b, height: b, borderRadius: 12, background: "rgba(255,255,255,0.16)", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.3)", transform: `scale(${box})` }} />
      <svg style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }} width={1} height={1}>
        <path
          d={`M${ROW.x + 11} ${mid + 1}L${ROW.x + 19} ${mid + 9}L${ROW.x + 33} ${mid - 8}`}
          fill="none"
          stroke="#FFFFFF"
          strokeWidth={3.5}
          strokeLinecap="round"
          strokeLinejoin="round"
          pathLength={1}
          strokeDasharray={1}
          strokeDashoffset={1 - mark}
        />
        <line x1={ROW.x} x2={ROW.x + (1920 - GRID.margin - ROW.x) * rule} y1={top + b + 14.5} y2={top + b + 14.5} stroke="#FFFFFF" strokeOpacity={0.25} strokeWidth={1} />
      </svg>
      <div style={{ position: "absolute", left: ROW.x + b + 20, top: mid - 24, lineHeight: "48px", fontSize: 36, fontWeight: 600, color: C.white, whiteSpace: "nowrap", clipPath: `inset(-8px ${(1 - wipe) * 100}% -8px -8px)` }}>
        {T.a3.checks[k]}
      </div>
    </>
  );
};

/** everything on the sheet but its gradient; reads the frame itself so <Blur> can sample it */
const Details: React.FC = () => {
  const f = useCurrentFrame();
  const pts = [BASE, ...NODES];
  let d = `M${BASE.x} ${BASE.y}`;
  NODES.forEach((p, k) => {
    const g = ease(f, A3.nodes[k], A3.nodes[k] + 8); // one ruled step per beat, drawn in 8 f
    if (g <= 0) return;
    const a = pts[k];
    d += `L${a.x + (p.x - a.x) * g} ${a.y + (p.y - a.y) * g}`;
  });
  return (
    <div style={{ position: "absolute", left: 0, top: skyOffset(f), width: 1920, height: 1080 }}>
      <svg style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }} width={1920} height={1080}>
        {STARS.map((p, i) => (
          <circle key={i} cx={p.x} cy={p.y} r={p.s} fill="#FFFFFF" fillOpacity={p.a} />
        ))}
        <circle cx={1660} cy={200} r={84} fill="url(#a3-moon)" />
        <circle cx={1660} cy={200} r={26} fill="#FFF6D6" />
        <defs>
          <radialGradient id="a3-moon">
            <stop offset="0%" stopColor="#FFF6D6" stopOpacity={0.32} />
            <stop offset="100%" stopColor="#FFF6D6" stopOpacity={0} />
          </radialGradient>
        </defs>
        <path d={d} fill="none" stroke={BARK} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" />
        {/* the bark's lit edge (the app's branch has one), so the stem holds on the night sky */}
        <path d={d} transform="translate(-2 0)" fill="none" stroke="#E8B48C" strokeOpacity={0.4} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" />
        {NODES.map((p, k) => {
          const at = A3.nodes[k] + 7;
          if (f < at) return null;
          return <circle key={k} cx={p.x} cy={p.y} r={7 * settle(f, at, { stiffness: 320, zeta: 0.75 })} fill={PETAL} />;
        })}
        {FLOWER_NODE.map((n, k) => (
          <Flower key={k} x={NODES[n].x} y={NODES[n].y} f={f} at={A3.flowers[k]} tilt={[8, -12, 18][k]} />
        ))}
      </svg>
      {[0, 1, 2].map((k) => (
        <Check key={k} k={k} f={f} />
      ))}
    </div>
  );
};

export const Night: React.FC = () => {
  const f = useCurrentFrame();
  if (f < A3.sky[0]) return null;
  const edge = skyEdge(f);
  if (edge >= 1080) return null;
  const g = grown(f);
  const side = GRID.margin * (1 - g); // a card on the grid margins, then the whole frame
  const radius = 28 * (1 - g);
  const feather = speed(skyEdge, f) / 2; // the edge's travel during the shutter
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        clipPath: `inset(${Math.max(0, edge - feather)}px ${side}px 0 ${side}px round ${radius}px ${radius}px 0 0)`,
        maskImage: feather > 2 ? `linear-gradient(to bottom, transparent ${edge - feather / 2}px, #000 ${edge + feather / 2}px)` : undefined,
      }}
    >
      <Sky x={0} y={skyOffset(f) - 60} w={1920} h={1200} stars={0} />
      <Blur on={speed(skyOffset, f) > 20}>
        <Details />
      </Blur>
    </div>
  );
};
