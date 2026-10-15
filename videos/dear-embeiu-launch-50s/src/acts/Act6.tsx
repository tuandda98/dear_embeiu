// Act 6 · Mở rộng (2280–2640). Reads the GLOBAL frame.
// H2280: the first frame is Act 5's last (its scene drawn at A5.hold − 1); the light sheet then rises from the bottom
// edge with the conversation and the composer printed on it and covers the navy (never a fade). H2640: the last
// frame is the two dots touching.
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Blur } from "../components/Blur.tsx";
import { C } from "../lib/tokens.ts";
import { A5, A6 } from "../timeline/cues.ts";
import { A5Scene } from "./a5/Scene.tsx";
import { ChipLayer, ComposerLayer, SentLayer, ThreadLayer, TypingLayer, chipFast, panelFast, panelOffset, riseAt, sentFast, sinkFast, threadFast } from "./a6/Chat.tsx";
import { DotsLayer, GridLayer, TickerLayer, dotsFast, gridFast, tickerFast } from "./a6/Range.tsx";

const [UP0, UP1] = A6.composer;

/** the sheet: its top edge 40 px above the panel's content origin, so its 28 px corners leave the frame at rest */
const Sheet: React.FC = () => {
  const f = useCurrentFrame();
  return <div style={{ position: "absolute", left: 0, top: panelOffset(f) - 40, width: 1920, height: 1240, background: C.bg, borderRadius: "28px 28px 0 0" }} />;
};

export const Act6: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: C.bg }}>
      {f < UP1 && <A5Scene f={A5.hold - 1} back={riseAt(f)} />}
      {f < UP1 && (
        <Blur on={panelFast(f)}>
          <Sheet />
        </Blur>
      )}
      {f < A6.chatOut[1] && (
        <>
          <Blur on={threadFast(f)}>
            <ThreadLayer />
          </Blur>
          <Blur on={threadFast(f)}>
            <ComposerLayer />
          </Blur>
          {f >= A6.send && (
            <Blur on={sentFast(f)}>
              <SentLayer />
            </Blur>
          )}
          {f >= A6.typing[0] && (
            <Blur on={sinkFast(f)}>
              <TypingLayer />
            </Blur>
          )}
        </>
      )}
      {f < A6.chipsOut[1] &&
        [5, 4, 3, 2, 1, 0].map((k) =>
          f < A6.chips[k] ? null : (
            <Blur key={k} on={chipFast(k, f)}>
              <ChipLayer k={k} />
            </Blur>
          ),
        )}
      {f >= A6.glyphs[0] && (
        <Blur on={gridFast(f)}>
          <GridLayer />
        </Blur>
      )}
      {f >= A6.ticker[0] && (
        <Blur on={tickerFast(f)}>
          <TickerLayer />
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
