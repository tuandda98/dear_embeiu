// Act 1 · Một con số (f 0–239). The number is already alive at f0 (no entrance), the clock ticks, the caption types
// in under it, the camera creeps 100 → 104 %, and on the last beat the partner's lavender dot falls beside the number.
import { useCurrentFrame } from "remotion";
import { A1 } from "../timeline/cues.ts";
import { COUNTER, COUNTER_DOT, Counter } from "../story/Counter.tsx";
import { Blur } from "../components/Blur.tsx";
import { Dot } from "../components/Dot.tsx";
import { A1Caption, Camera, cameraA1, dropY } from "./a1/shared.tsx";

const FallingDot: React.FC = () => <Dot x={COUNTER_DOT.x} y={dropY(useCurrentFrame())} who="other" />;

export const Act1: React.FC = () => {
  const f = useCurrentFrame();
  const speed = Math.abs(dropY(f + 0.5) - dropY(f - 0.5));
  return (
    <Camera s={cameraA1(f)}>
      <Counter x={COUNTER.hero.x} y={COUNTER.hero.y} f={f} />
      <A1Caption f={f} />
      {f >= A1.dropStart && (
        <Blur on={speed > 20}>
          <FallingDot />
        </Blur>
      )}
    </Camera>
  );
};
