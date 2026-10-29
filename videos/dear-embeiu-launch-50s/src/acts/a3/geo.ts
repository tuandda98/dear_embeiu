// Act 3 geometry: the heart tile (H1200), the app icon's heart outline sampled by arc length, and the love tree's
// heart constellation (lib/widgets/today_constellation.dart: a 260×216 box, drawn here at 1.8×).
import { HEART_PATH } from "../../components/Heart.tsx";

export type P = { x: number; y: number };
const lerpP = (a: P, b: P, t: number): P => ({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t });
const dist = (a: P, b: P) => Math.hypot(b.x - a.x, b.y - a.y);

/** the heart tile at H1200 */
export const HEART = { x: 960, y: 460, size: 300 } as const;
const k = HEART.size / 1024;
const film = (u: number, v: number): P => ({ x: HEART.x - HEART.size / 2 + u * k, y: HEART.y - HEART.size / 2 + v * k });

// HEART_PATH = M + six cubics (tip → left lobe → dip → right lobe → tip). Sampled in film px, so the arc fraction
// matches the dash progress of <Heart draw> (pathLength 1).
const n = HEART_PATH.match(/-?\d+(\.\d+)?/g)!.map(Number);
const SAMPLES: { p: P; d: number }[] = [];
{
  let p0 = film(n[0], n[1]);
  const pts: P[] = [p0];
  for (let i = 2; i + 5 < n.length; i += 6) {
    const [c1, c2, p3] = [film(n[i], n[i + 1]), film(n[i + 2], n[i + 3]), film(n[i + 4], n[i + 5])];
    for (let s = 1; s <= 240; s++) {
      const t = s / 240;
      const m = 1 - t;
      pts.push({
        x: m * m * m * p0.x + 3 * m * m * t * c1.x + 3 * m * t * t * c2.x + t * t * t * p3.x,
        y: m * m * m * p0.y + 3 * m * m * t * c1.y + 3 * m * t * t * c2.y + t * t * t * p3.y,
      });
    }
    p0 = p3;
  }
  let len = 0;
  pts.forEach((p, i) => {
    if (i) len += dist(pts[i - 1], p);
    SAMPLES.push({ p, d: len });
  });
  SAMPLES.forEach((s) => (s.d /= len));
}
/** the point of the heart outline nearest to `q`, with its arc fraction d (0 = tip, ~0.5 = dip, 1 = tip again) */
const nearest = (q: P) => SAMPLES.reduce((a, b) => (dist(b.p, q) < dist(a.p, q) ? b : a));

// The constellation: the app's 260×216 box at 1.8× (room for 56 px stars and 24 px labels), its polygon centred on
// the heart outline so the stars settle straight onto the curve when the heart resolves.
const S = 1.8;
const CENTER: P = { x: 960, y: 444.5 }; // the outline's bbox centre
const BOX = { x: CENTER.x - 130 * S, y: CENTER.y - 123 * S }; // the polygon's bbox centre is (130, 123) in the box
const app = (x: number, y: number): P => ({ x: BOX.x + x * S, y: BOX.y + y * S });
const xs = SAMPLES.map((s) => s.p.x);
const SHRINK = (Math.max(...xs) - Math.min(...xs)) / (200 * S); // polygon width (200 box units) → outline width
const onHeart = (p: P) => nearest(lerpP(CENTER, p, SHRINK));

type Who = "you" | "other";
export type Vertex = { p: P; to: P; d: number };
const vertex = (p: P): Vertex => {
  const h = onHeart(p);
  return { p, to: h.p, d: h.d };
};
export const DIP = vertex(app(130, 66));
export const TIP: Vertex = { p: app(130, 206), to: SAMPLES[0].p, d: 0 };
/** task 0 question · 1 mood · 2 message (T.a3.stars); the app's positions */
const POS: Record<Who, P[]> = {
  you: [app(70, 40), app(30, 104), app(82, 162)],
  other: [app(190, 40), app(230, 104), app(178, 162)],
};
export type Star = Vertex & { who: Who; task: 0 | 1 | 2 };
/** lighting order: the two halves alternate top → bottom (question, mood, message) */
export const STARS: Star[] = ([0, 1, 2] as const).flatMap((task) => (["you", "other"] as const).map((who) => ({ ...vertex(POS[who][task]), who, task })));
export const star = (who: Who, task: number) => STARS.find((s) => s.who === who && s.task === task)!;

export const at = (v: Vertex, c: number) => lerpP(v.p, v.to, c); // c = convergence 0 → 1
export const lerpPoint = lerpP;
export const length = dist;
