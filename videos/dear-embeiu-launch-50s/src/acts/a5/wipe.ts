import type { CSSProperties } from "react";

/**
 * A soft-edged left → right mask wipe over a box `w` px wide (p 0 → 1). The mask is dropped once the wipe is done, so
 * the text at rest is the plain, crisp element. Used for display lines (A5 headlines, A7 end card); film captions use
 * <Caption wipe> (hard edge).
 */
export function softWipe(p: number, w: number, feather = 80): CSSProperties {
  if (p >= 1) return {};
  const x = p * (w + feather);
  const g = `linear-gradient(90deg, #000 ${x - feather}px, transparent ${x}px)`;
  return { WebkitMaskImage: g, maskImage: g };
}
