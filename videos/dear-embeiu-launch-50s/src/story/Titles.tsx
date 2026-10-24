// Act titles (Spaceti-style, 2–3 words) drawn over the acts by Film.tsx: top-right chip-style line, entering by a
// left→right clip-path wipe, leaving by a right→left wipe (never a fade). Dark variant for Act 5's navy ground.
import { useCurrentFrame } from "remotion";
import { T } from "../copy/strings.ts";
import { ease } from "../lib/ease.ts";
import { C, colX } from "../lib/tokens.ts";

const IN = 14;
const OUT = 12;

export const Titles: React.FC = () => {
  const f = useCurrentFrame();
  const t = T.titles.find((x) => f >= x.from && f < x.to);
  if (!t) return null;
  const wipeIn = ease(f, t.from, t.from + IN);
  const wipeOut = ease(f, t.to - OUT, t.to);
  const clip = `inset(0 ${(1 - wipeIn) * 100}% 0 ${wipeOut * 100}%)`;
  const color = t.dark ? C.white : C.ink;
  const line = t.dark ? "rgba(255,255,255,0.35)" : C.rose;
  return (
    <div style={{ position: "absolute", left: colX(8), top: 96, width: 1920 - colX(8) - 120, clipPath: clip }}>
      <div style={{ fontSize: 30, fontWeight: 600, letterSpacing: "0.1em", textTransform: "uppercase", color, whiteSpace: "nowrap", textAlign: "right" }}>{t.text}</div>
      <div style={{ marginTop: 12, marginLeft: "auto", width: 72, height: 3, background: line }} />
    </div>
  );
};
