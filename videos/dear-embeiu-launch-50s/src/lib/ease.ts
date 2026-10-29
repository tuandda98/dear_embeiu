import { Easing, interpolate, spring } from "remotion";

/** the app's house easing: Curves.easeOutCubic (lib/theme/app_motion.dart) */
export const HOUSE = Easing.bezier(0.215, 0.61, 0.355, 1);
/** 0 -> 1 across [from, to] with the house easing, clamped both sides */
export const ease = (f: number, from: number, to: number, e: (t: number) => number = HOUSE) =>
  interpolate(f, [from, to], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
/**
 * physical objects: a damped spring from 0 to 1 starting at `from`. zeta 1 = critically damped (no overshoot);
 * zeta 0.7–0.8 = the one small overshoot the brief allows. Never go below 0.65.
 */
export const settle = (f: number, from: number, { stiffness = 180, zeta = 1, mass = 1 } = {}) =>
  spring({ frame: f - from, fps: 60, config: { stiffness, mass, damping: 2 * zeta * Math.sqrt(stiffness * mass) } });
/** pill press: scale 1 -> 0.96 in 6 f, back to 1 in 10 f (BRIEF §5 act 2) */
export const press = (f: number, at: number) =>
  f < at + 6 ? 1 - 0.04 * ease(f, at, at + 6) : 0.96 + 0.04 * ease(f, at + 6, at + 16);
/** a caret's blink: on for 30 f, off for 30 f, phase-locked to the beat */
export const blink = (f: number) => (Math.floor(f / 30) % 2 === 0 ? 1 : 0);
