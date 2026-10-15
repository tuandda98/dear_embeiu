import { AbsoluteFill, useCurrentFrame } from "remotion";
import { useFonts } from "../lib/useFonts.ts";
import { C, FONT } from "../lib/tokens.ts";
import { VS } from "./timeline.ts";
import { V12 } from "./v12/V12.tsx";
import { V34 } from "./v34/V34.tsx";

/** one section group per frame: V12 (hook + the question) before the cut, V34 (said up front + sign-off) from it */
export const Vertical: React.FC = () => {
  const f = useCurrentFrame();
  const ready = useFonts();
  return (
    <AbsoluteFill style={{ background: C.bg, color: C.ink, fontFamily: FONT, WebkitFontSmoothing: "antialiased" }}>
      {ready && (f < VS.cut ? <V12 /> : <V34 />)}
    </AbsoluteFill>
  );
};
