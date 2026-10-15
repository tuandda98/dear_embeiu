// Act 6 · Mở rộng (2280–2640, v3). Reads the GLOBAL frame.
// H2280: the first frame is Act 5's last (its scene drawn at A5.hold − 1); the light sheet then rises from the bottom
// edge and covers the navy (never a fade). Eight feature cards land, hold, and recede into the two dots, which travel
// to their touch. H2640: the last frame is the two dots touching.
import { AbsoluteFill, Easing, useCurrentFrame } from "remotion";
import { Blur } from "../components/Blur.tsx";
import { ease } from "../lib/ease.ts";
import { C } from "../lib/tokens.ts";
import { A5, A6 } from "../timeline/cues.ts";
import { A5Scene } from "./a5/Scene.tsx";
import { DotsLayer, GridLayer, dotsFast, gridFast } from "./a6/Range.tsx";

const [UP0, UP1] = A6.composer;
/** the sheet presentation: a strong ease-out; its top edge leaves the frame (28 px corners and all) by UP1 */
const riseAt = (f: number) => ease(f, UP0, UP1, Easing.out(Easing.poly(5)));
const sheetTop = (f: number) => 1080 - 1120 * riseAt(f);
const sheetFast = (f: number) => f > UP0 && Math.abs(sheetTop(f + 0.25) - sheetTop(f - 0.25)) * 2 > 20;

const Sheet: React.FC = () => {
  const f = useCurrentFrame();
  return <div style={{ position: "absolute", left: 0, top: sheetTop(f), width: 1920, height: 1240, background: C.bg, borderRadius: "28px 28px 0 0" }} />;
};

export const Act6: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: C.bg }}>
      {f < UP1 && <A5Scene f={A5.hold - 1} dots back={riseAt(f)} />}
      {f < UP1 && (
        <Blur on={sheetFast(f)}>
          <Sheet />
        </Blur>
      )}
      {f >= A6.glyphs[0] && (
        <Blur on={gridFast(f)}>
          <GridLayer />
        </Blur>
      )}
      {f >= A6.dots[0] && (
        <Blur on={dotsFast(f)}>
          <DotsLayer />
        </Blur>
      )}
    </AbsoluteFill>
  );
};
