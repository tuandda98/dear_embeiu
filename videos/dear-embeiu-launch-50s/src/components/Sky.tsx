import { rng } from "../lib/rand.ts";

/**
 * The love tree's night sky (ref/ios/love-tree-top.png, android widget M2): navy → indigo with faint stars.
 * Deterministic star field (seeded). `opacity` fades the whole sky; stars never twinkle on their own.
 */
export const Sky: React.FC<{ x: number; y: number; w: number; h: number; radius?: number; opacity?: number; stars?: number; seed?: number }> = ({
  x,
  y,
  w,
  h,
  radius = 0,
  opacity = 1,
  stars = 70,
  seed = 7,
}) => {
  const r = rng(seed);
  const pts = Array.from({ length: stars }, () => ({ x: r() * w, y: r() * h, s: 0.6 + r() * 1.6, a: 0.25 + r() * 0.55 }));
  return (
    <div style={{ position: "absolute", left: x, top: y, width: w, height: h, borderRadius: radius, overflow: "hidden", opacity, background: "linear-gradient(180deg, #1E1B3A 0%, #2A2550 55%, #3B2F6B 100%)" }}>
      <svg width={w} height={h}>
        {pts.map((p, i) => (
          <circle key={i} cx={p.x} cy={p.y} r={p.s} fill="#FFFFFF" fillOpacity={p.a} />
        ))}
      </svg>
    </div>
  );
};
