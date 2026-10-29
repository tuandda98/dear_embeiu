import { AbsoluteFill, useCurrentFrame } from "remotion";
import { useFonts } from "./lib/useFonts.ts";
import { C, FONT } from "./lib/tokens.ts";
import { ACTS } from "./timeline/grid.ts";
import { Act1 } from "./acts/Act1.tsx";
import { Act2 } from "./acts/Act2.tsx";
import { Act3 } from "./acts/Act3.tsx";
import { Act4 } from "./acts/Act4.tsx";
import { Act5 } from "./acts/Act5.tsx";
import { Act6 } from "./acts/Act6.tsx";
import { Act7 } from "./acts/Act7.tsx";
import { Titles } from "./story/Titles.tsx";

const ACT = [Act1, Act2, Act3, Act4, Act5, Act6, Act7];

/** one act is mounted per frame (its [from, to) range); acts read the GLOBAL frame via useCurrentFrame() */
export const Film: React.FC = () => {
  const f = useCurrentFrame();
  const ready = useFonts();
  const Act = ACT[ACTS.findIndex((a) => f >= a.from && f < a.to)];
  return (
    <AbsoluteFill style={{ background: C.bg, color: C.ink, fontFamily: FONT, WebkitFontSmoothing: "antialiased" }}>
      {ready && <Act />}
      {ready && <Titles />}
    </AbsoluteFill>
  );
};
