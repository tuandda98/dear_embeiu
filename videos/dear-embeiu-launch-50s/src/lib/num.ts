// Number helpers shared by the picture (Digits.tsx) and the Node scripts (srt.ts, audio): plain .ts so Node can import it.
/** an integer rolling from `from` to `to` over [f0, f1] (linear), as the string the digit boxes show */
export const roll = (from: number, to: number, f: number, f0: number, f1: number) => {
  const t = f <= f0 ? 0 : f >= f1 ? 1 : (f - f0) / (f1 - f0);
  return String(Math.round(from + (to - from) * t));
};
/** Vietnamese thousands grouping with "." (30009 → "30.009"), as the app's counter card draws it */
export const group = (n: number) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ".");
export const pad2 = (n: number) => String(n).padStart(2, "0");
