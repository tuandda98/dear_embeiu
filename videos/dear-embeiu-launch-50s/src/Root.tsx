import { Composition } from "remotion";
import { Film } from "./Film.tsx";
import { FPS, H, TOTAL, W } from "./timeline/grid.ts";

export const Root: React.FC = () => (
  <Composition id="Film" component={Film} durationInFrames={TOTAL} fps={FPS} width={W} height={H} />
);
