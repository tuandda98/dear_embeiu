// The love tree's night sky (ref/ios/love-tree-top.png + love-tree-flowers.png) as one sheet. First a complete card
// inside the frame (x 96–1824, y 600–1000, radius 28, the app's soft shadow, the chip clear above it) that rises into place: the app's branch
// sweeps across it in ruled steps, three flowers open along it, the moon sits top-right, the checks stack at the
// right. At A3.night the card grows to the whole frame (the constellation's sky); at A3.recede it drops away.
// Motion blur: the gradient is drawn once (summing ten 10 % copies of a dark gradient bands in 8 bit) and only its
// edges are feathered by the distance they travel in the 180° shutter; the details are sub-frame sampled by <Blur>.
import { Easing, useCurrentFrame } from "remotion";
import { Sky } from "../../components/Sky.tsx";
import { Blur } from "../../components/Blur.tsx";
import { C } from "../../lib/tokens.ts";
import { ease, lerp, settle } from "../../lib/ease.ts";
import { rng } from "../../lib/rand.ts";
import { T } from "../../copy/strings.ts";
import { A3 } from "../../timeline/cues.ts";

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));
const CARD = { left: 96, right: 1824, top: 600, bottom: 1000, r: 28 };
const FULL = { left: 0, right: 1920, top: -60, bottom: 1140 };
/** 0 while the sky is the card, 1 once it is the whole frame (A3.night) */
const grown = (f: number) => Easing.inOut(Easing.cubic)(clamp01((f - A3.night[0]) / (A3.night[1] - A3.night[0])));
const risen = (f: number) => {
  if (f < A3.sky[0]) return 0;
  const v = settle(f, A3.sky[0], { stiffness: 140, zeta: 0.85 });
  return Math.abs(1 - v) < 2e-3 ? 1 : v;
};
const away = Easing.in(Easing.cubic); // leaving accelerates
/** the sheet's vertical offset: it rises into place from below the frame (A3.sky), drops away at the end (A3.recede) */
const sheetDy = (f: number) => 540 * (1 - risen(f)) + 1140 * away(clamp01((f - A3.recede[0]) / (A3.recede[1] - A3.recede[0])));
/** the sheet's top edge in frame px (the counter and the label switch colour across it) */
export const skyEdge = (f: number) => lerp(CARD.top, FULL.top, grown(f)) + sheetDy(f);
const speed = (fn: (f: number) => number, f: number) => Math.abs(fn(f + 0.5) - fn(f - 0.5));

const BARK = "#8B5E3C"; // the app's branch
const PETAL = C.sunset[2];
// the branch (love-tree-flowers.png): one sweep from the card's bottom-left to its upper-right, 14 px tapering to 6
const B = [
  { x: 200, y: 1012 },
  { x: 520, y: 920 },
  { x: 960, y: 840 },
  { x: 1290, y: 650 },
];
const at = (t: number) => {
  const m = 1 - t;
  const [a, b, c, d] = [m * m * m, 3 * m * m * t, 3 * m * t * t, t * t * t];
  return { x: a * B[0].x + b * B[1].x + c * B[2].x + d * B[3].x, y: a * B[0].y + b * B[1].y + c * B[2].y + d * B[3].y };
};
const STEPS = [0, 1, 2, 3, 4, 5, 6].map((k) => k / 6); // six ruled steps, one per beat; node k at the end of step k
const NODES = STEPS.slice(1).map(at);
const FLOWER_NODE = [2, 3, 4]; // three flowers open up the branch toward its tip; the tip keeps a bud
const SEG = 72;
const ROW = { x: 1380, top: 724, step: 70, box: 44 }; // the checks, stacked at the right under the moon
const MOON = { x: 1748, y: 664, r: 40 };
const STARS = (() => {
  const r = rng(23);
  return Array.from({ length: 130 }, () => ({ x: r() * 1920, y: r() * 1200 - 60, s: 0.6 + r() * 1.5, a: 0.2 + r() * 0.45 }));
})();

const petal = (L: number) => {
  const w = L * 0.46;
  const n = L * 0.16;
  return `M0 ${-L * 0.06}C${-w} ${-L * 0.42} ${-w * 0.62} ${-L * 0.86} ${-w * 0.3} ${-L}Q0 ${-L + n} ${w * 0.3} ${-L}C${w * 0.62} ${-L * 0.86} ${w} ${-L * 0.42} 0 ${-L * 0.06}Z`;
};
const PETAL_D = petal(45); // ≈ 90 px across

/** a 5-petal flower opening petal by petal (6 f apart, each scaling out of the centre), turning slightly as it opens */
const Flower: React.FC<{ x: number; y: number; f: number; at: number; tilt: number }> = ({ x, y, f, at: t0, tilt }) => {
  if (f < t0) return null;
  const turn = ease(f, t0, t0 + 36);
  return (
    <g transform={`translate(${x} ${y}) rotate(${tilt - 30 * (1 - turn)})`}>
      {[0, 1, 2, 3, 4].map((i) => {
        const s = f < t0 + i * 6 ? 0 : settle(f, t0 + i * 6, { stiffness: 240, zeta: 0.74 });
        return s > 0 && <path key={i} d={PETAL_D} transform={`rotate(${i * 72}) scale(${s})`} fill={PETAL} stroke="#FFFFFF" strokeOpacity={0.5} strokeWidth={1} />;
      })}
      <g transform={`scale(${settle(f, t0, { stiffness: 300, zeta: 0.8 })})`}>
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
  const t0 = A3.checks[k];
  if (f < t0) return null;
  const top = ROW.top + k * ROW.step;
  const mid = top + ROW.box / 2;
  const box = settle(f, t0, { stiffness: 320, zeta: 0.8 });
  const mark = ease(f, t0 + 5, t0 + 17);
  const rule = ease(f, t0 + 4, t0 + 24);
  const wipe = ease(f, t0 + 8, t0 + 24);
  const b = ROW.box;
  return (
    <>
      <div style={{ position: "absolute", left: ROW.x, top, width: b, height: b, borderRadius: 12, background: "rgba(255,255,255,0.16)", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.3)", transform: `scale(${box})` }} />
      <svg style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }} width={1} height={1}>
        <path d={`M${ROW.x + 11} ${mid + 1}L${ROW.x + 19} ${mid + 9}L${ROW.x + 33} ${mid - 8}`} fill="none" stroke="#FFFFFF" strokeWidth={3.5} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - mark} />
        <line x1={ROW.x} x2={ROW.x + (CARD.right - 32 - ROW.x) * rule} y1={top + b + 13.5} y2={top + b + 13.5} stroke="#FFFFFF" strokeOpacity={0.25} strokeWidth={1} />
      </svg>
      <div style={{ position: "absolute", left: ROW.x + b + 20, top: mid - 24, lineHeight: "48px", fontSize: 36, fontWeight: 600, color: C.white, whiteSpace: "nowrap", clipPath: `inset(-8px ${(1 - wipe) * 100}% -8px -8px)` }}>
        {T.a3.checks[k]}
      </div>
    </>
  );
};

/** everything on the sheet but its gradient, in frame px; reads the frame itself so <Blur> can sample it */
const Details: React.FC = () => {
  const f = useCurrentFrame();
  // how far up the branch has grown: step k runs from STEPS[k] to STEPS[k + 1] in 8 f on its beat
  let reach = 0;
  A3.nodes.forEach((t0, k) => {
    if (f >= t0) reach = lerp(STEPS[k], STEPS[k + 1], ease(f, t0, t0 + 8));
  });
  const segs: { a: { x: number; y: number }; b: { x: number; y: number }; w: number }[] = [];
  for (let i = 0; i < SEG && i / SEG < reach; i++) {
    const t = i / SEG;
    segs.push({ a: at(t), b: at(Math.min((i + 1) / SEG, reach)), w: lerp(14, 6, t) });
  }
  const moonGlow = "radial-gradient(circle, rgba(255,246,214,0.34) 0%, rgba(255,246,214,0) 64%)";
  return (
    <div style={{ position: "absolute", left: 0, top: sheetDy(f), width: 1920, height: 1080 }}>
      <svg style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }} width={1920} height={1080}>
        {STARS.map((p, i) => (
          <circle key={i} cx={p.x} cy={p.y} r={p.s} fill="#FFFFFF" fillOpacity={p.a} />
        ))}
        {segs.map((s, i) => (
          <line key={i} x1={s.a.x} y1={s.a.y} x2={s.b.x} y2={s.b.y} stroke={BARK} strokeWidth={s.w} strokeLinecap="round" />
        ))}
        {/* the bark's lit upper edge (the app's branch has one) */}
        {segs.map((s, i) => (
          <line key={`h${i}`} x1={s.a.x - 1} y1={s.a.y - s.w * 0.28} x2={s.b.x - 1} y2={s.b.y - s.w * 0.28} stroke="#E8B48C" strokeOpacity={0.45} strokeWidth={Math.max(1.5, s.w * 0.22)} strokeLinecap="round" />
        ))}
        {NODES.map((p, k) => {
          const t0 = A3.nodes[k] + 7;
          if (f < t0) return null;
          return <circle key={k} cx={p.x} cy={p.y} r={7 * settle(f, t0, { stiffness: 320, zeta: 0.75 })} fill={PETAL} />;
        })}
        {FLOWER_NODE.map((n, k) => (
          <Flower key={k} x={NODES[n].x} y={NODES[n].y} f={f} at={A3.flowers[k]} tilt={[8, -12, 18][k]} />
        ))}
      </svg>
      <div style={{ position: "absolute", left: MOON.x - 112, top: MOON.y - 112, width: 224, height: 224, borderRadius: "50%", background: moonGlow }} />
      <div style={{ position: "absolute", left: MOON.x - MOON.r, top: MOON.y - MOON.r, width: MOON.r * 2, height: MOON.r * 2, borderRadius: "50%", background: "#FFF6D6" }} />
      {[0, 1, 2].map((k) => (
        <Check key={k} k={k} f={f} />
      ))}
    </div>
  );
};

export const Night: React.FC = () => {
  const f = useCurrentFrame();
  if (f < A3.sky[0]) return null;
  const g = grown(f);
  const dy = sheetDy(f);
  const box = {
    left: lerp(CARD.left, FULL.left, g),
    right: lerp(CARD.right, FULL.right, g),
    top: lerp(CARD.top, FULL.top, g) + dy,
    bottom: lerp(CARD.bottom, FULL.bottom, g) + dy,
  };
  if (box.top >= 1080) return null;
  const r = CARD.r * (1 - g);
  const w = box.right - box.left;
  const h = box.bottom - box.top;
  const feather = Math.min(40, speed(skyEdge, f) / 2); // the edges' travel during the shutter
  const mask = feather > 2 ? `linear-gradient(to bottom, transparent 0, #000 ${feather}px, #000 calc(100% - ${feather}px), transparent 100%)` : undefined;
  return (
    <>
      {g < 1 && <div style={{ position: "absolute", left: box.left, top: box.top, width: w, height: h, borderRadius: r, boxShadow: C.shadow }} />}
      <div style={{ position: "absolute", left: box.left, top: box.top - feather / 2, width: w, height: h + feather, borderRadius: r, overflow: "hidden", maskImage: mask }}>
        <div style={{ position: "absolute", left: -box.left, top: -(box.top - feather / 2), width: 1920, height: 1080 }}>
          <Sky x={0} y={dy - 60} w={1920} h={1200} stars={0} />
          <Blur on={speed(sheetDy, f) > 20}>
            <Details />
          </Blur>
        </div>
      </div>
    </>
  );
};
