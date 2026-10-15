import { Composition } from "remotion";
import { Film } from "./Film.tsx";
import { Demo } from "./demo/Demo.tsx";
import { DEMO } from "./demo/timeline.ts";
import { FPS, H, TOTAL, W } from "./timeline/grid.ts";

export const Root: React.FC = () => (
  <>
    <Composition id="Film" component={Film} durationInFrames={TOTAL} fps={FPS} width={W} height={H} />
    <Composition id="Demo" component={Demo} durationInFrames={DEMO.total} fps={DEMO.fps} width={W} height={H} />
  </>
);
