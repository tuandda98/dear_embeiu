// ACT 3 · the streak (f 720–1199). From H720 (one navy cell + the counter) to H1200 (the app icon, its label, the two
// dots, the counter). The streak strip → the streak chip; the love tree's night sky rises under it with the stem, the
// checks and three flowers; the night grows to the whole frame for today's constellation, which resolves into the
// heart; the night recedes downward. The counter and the label are drawn twice, split at the sky's edge (navy on
// paper, white on the night), so they stay readable while the sheet passes behind them. Reads the GLOBAL frame.
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Counter } from "../story/Counter.tsx";
import { Dot } from "../components/Dot.tsx";
import { Blur } from "../components/Blur.tsx";
import { C } from "../lib/tokens.ts";
import { lerp, settle } from "../lib/ease.ts";
import { T } from "../copy/strings.ts";
import { A3 } from "../timeline/cues.ts";
import { typedCount } from "../timeline/typing.ts";
import { CHIP_MID, Strip, chipCell, stripSpeed } from "./a3/Strip.tsx";
import { Night, skyEdge } from "./a3/Night.tsx";
import { Constellation, HeartLine, HeartTile } from "./a3/Stars.tsx";

/** the two dots at H1200, born on chip cells 22 and 30 (today), the ones under their targets */
const DOTS = [
  { who: "you" as const, from: chipCell(22).x, x: 820, y: 150 },
  { who: "other" as const, from: chipCell(30).x, x: 1100, y: 150 },
];
const RISE = A3.dotsRise[0] + 4;
const rested = (v: number) => (Math.abs(1 - v) < 1e-4 ? 1 : v); // a settled spring lands exactly on H1200
const rise = (f: number) => (f < RISE ? 0 : rested(settle(f, RISE, { stiffness: 70, zeta: 0.78 })));

const Dots: React.FC = () => {
  const f = useCurrentFrame();
  if (f < A3.dotsRise[0]) return null;
  const r = 14 * rested(settle(f, A3.dotsRise[0], { stiffness: 300, zeta: 0.8 }));
  const t = rise(f);
  return (
    <>
      {DOTS.map((d) => (
        <Dot key={d.who} who={d.who} r={r} x={lerp(d.from, d.x, t)} y={lerp(CHIP_MID, d.y, t)} />
      ))}
    </>
  );
};
const dotSpeed = (f: number) => Math.abs(rise(f + 0.5) - rise(f - 0.5)) * (CHIP_MID - 150);

/** content above the sky's edge in its paper colours, below it in its night colours */
const Split: React.FC<{ edge: number; paper: React.ReactNode; night: React.ReactNode }> = ({ edge, paper, night }) =>
  edge >= 1080 ? (
    <>{paper}</>
  ) : (
    <>
      <AbsoluteFill style={{ clipPath: `inset(0 0 ${Math.min(1080, 1080 - edge)}px 0)` }}>{paper}</AbsoluteFill>
      <AbsoluteFill style={{ clipPath: `inset(${Math.max(0, edge)}px 0 0 0)` }}>{night}</AbsoluteFill>
    </>
  );

const BADGE = T.a3.labelBadge;
const REST = T.a3.labelFlowers;
/** T.a3.labelBadge + T.a3.labelFlowers: the badge tracked uppercase in ink2, the count in ink; typed in place */
const Label: React.FC<{ n: number; night?: boolean }> = ({ n, night }) => {
  const shown = (s: string, from: number) => {
    const k = Math.max(0, Math.min(s.length, n - from));
    return (
      <>
        {s.slice(0, k)}
        <span style={{ color: "transparent" }}>{s.slice(k)}</span>
      </>
    );
  };
  return (
    <div style={{ position: "absolute", left: 0, width: 1920, top: 660 - 12, height: 24, display: "flex", justifyContent: "center", alignItems: "baseline", fontSize: 18, lineHeight: "24px", fontWeight: 600, whiteSpace: "pre" }}>
      <span style={{ color: night ? "rgba(255,255,255,0.72)" : C.ink2, letterSpacing: "0.1em" }}>{shown(BADGE, 0)}</span>
      <span style={{ color: night ? C.white : C.ink }}>{" "}{shown(REST, BADGE.length + 1)}</span>
    </div>
  );
};

export const Act3: React.FC = () => {
  const f = useCurrentFrame();
  const edge = skyEdge(f);
  const typed = typedCount(A3.label, f);
  const counter = (night: boolean) => (
    <Counter x={120} y={160} scale={0.55} f={f} opacity={0.6} color={night ? C.white : C.ink} dim={night ? "rgba(255,255,255,0.72)" : C.ink2} />
  );
  return (
    <AbsoluteFill style={{ background: C.bg }}>
      {f < A3.night[0] + 20 && (
        <Blur on={stripSpeed(f) > 20}>
          <Strip />
        </Blur>
      )}
      <Night />
      <HeartTile f={f} />
      <Constellation f={f} />
      <HeartLine f={f} />
      {typed > 0 && <Split edge={edge} paper={<Label n={typed} />} night={<Label n={typed} night />} />}
      <Split edge={edge} paper={counter(false)} night={counter(true)} />
      <Blur on={dotSpeed(f) > 20}>
        <Dots />
      </Blur>
    </AbsoluteFill>
  );
};
