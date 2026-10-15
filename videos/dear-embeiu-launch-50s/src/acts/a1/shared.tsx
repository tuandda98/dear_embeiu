// Pieces that cross the A1 → A2 boundary (H240). Both acts draw them from these functions, so frame 239 (Act 1) and
// frame 240 (Act 2) are one continuous motion.
import type { ReactNode } from "react";
import { AbsoluteFill, Easing } from "remotion";
import { A1 } from "../../timeline/cues.ts";
import { typed } from "../../timeline/typing.ts";
import { blink, ease, lerp, settle } from "../../lib/ease.ts";
import { C } from "../../lib/tokens.ts";
import { COUNTER_DOT } from "../../story/Counter.tsx";

/** the one virtual camera: a uniform scale around the frame centre */
export const Camera: React.FC<{ s: number; children: ReactNode }> = ({ s, children }) => (
  <AbsoluteFill style={{ transform: `scale(${s})`, transformOrigin: "50% 50%" }}>{children}</AbsoluteFill>
);
/** A1: 100 → 104 %, already moving at f0, arriving at rest on the landing (A2 eases back from rest) */
export const cameraA1 = (f: number) => 1 + 0.04 * ease(f, A1.push[0], A1.push[1], Easing.out(Easing.quad));

// The drop: settle(zeta 0.75) from dropStart. Stiffness is solved so the first contact (the spring's first crossing
// of 1) falls exactly on A1.land: ωd·t = π − atan(√(1−ζ²)/ζ) at t = (land − dropStart)/60 s. Contact = the thock.
const Z = 0.75;
const WD = (Math.PI - Math.atan(Math.sqrt(1 - Z * Z) / Z)) / ((A1.land - A1.dropStart) / 60);
const DROP_K = (WD / Math.sqrt(1 - Z * Z)) ** 2; // ≈ 148.6 for an 18 f fall
export const DROP_FROM = -40;
export const dropY = (f: number) => lerp(DROP_FROM, COUNTER_DOT.y, settle(f, A1.dropStart, { zeta: Z, stiffness: DROP_K }));

/** the caption under the clock (v3: 64 px, weight 700), typed; a rose caret rides after the last letter, solid while
 *  typing and for 15 f after, then blinks (beat-locked) until the landing, after which it is gone. `exit` 0 → 1 drops
 *  the line out of its mask. */
export const A1_CAPTION = { x: 120, y: 860, size: 64, weight: 700 } as const; // y 760 (V3) runs into the clock labels (778–798)
const LAST_KEY = A1.caption.frames[A1.caption.frames.length - 1];
export const A1Caption: React.FC<{ f: number; exit?: number }> = ({ f, exit = 0 }) => {
  const caret = f >= A1.caption.frames[0] && f < A1.land && (f <= LAST_KEY + 15 || blink(f) === 1);
  const { x, y, size, weight } = A1_CAPTION;
  const pad = 14; // room inside the mask for the stacked marks (ỗ) and descenders
  return (
    <div style={{ position: "absolute", left: x, top: y - pad, height: size * 1.2 + 2 * pad, width: 1500, overflow: "hidden" }}>
      <div
        style={{
          position: "absolute",
          left: 0,
          top: pad,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: "-0.01em",
          lineHeight: 1.2,
          whiteSpace: "nowrap",
          color: C.ink,
          transform: `translateY(${exit * (size * 1.2 + pad)}px)`,
        }}
      >
        {typed(A1.caption, f)}
        <span
          style={{
            display: "inline-block",
            width: 4,
            height: size * 1.0,
            marginLeft: 8,
            verticalAlign: "-0.2em",
            background: C.rose,
            opacity: caret ? 1 : 0,
          }}
        />
      </div>
    </div>
  );
};
/** exit of the line in A2: accelerates out (exits leave faster than they came) */
export const a1CaptionExit = (f: number, from: number, to: number) => ease(f, from, to, Easing.in(Easing.cubic));
