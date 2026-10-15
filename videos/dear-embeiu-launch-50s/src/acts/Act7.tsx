// Act 7 · Ký tên (2640–3000). Reads the GLOBAL frame. The end card is the film's only centred layout.
// H2640: the first frame is the two dots touching (Act 6's last). They rise into the heart through its open tip while
// the outline draws around them (rose, so it reads on the light ground), melt into it as it fills, the sunset tile
// blooms behind, the wordmark slides out from under the tile. The last frame (2999) is the poster.
import { AbsoluteFill, Easing, useCurrentFrame } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { Pill } from "../components/Card.tsx";
import { Dot } from "../components/Dot.tsx";
import { Heart } from "../components/Heart.tsx";
import { T } from "../copy/strings.ts";
import { ease, lerp, settle } from "../lib/ease.ts";
import { C, FONT, HEAD } from "../lib/tokens.ts";
import { A7 } from "../timeline/cues.ts";
import { softWipe } from "./a5/wipe.ts";
import { TOUCH } from "./a6/layout.ts";

const MARK = { x: 960, y: 390, size: 320 } as const; // the tile spans y 230 → 550
const MARK_BOTTOM = MARK.y + MARK.size / 2; // 550: the wordmark slides out from under this edge
const INSIDE = Math.round(MARK.y + ((420 - 512) / 1024) * MARK.size); // where the touching dots rest: the heart's interior centre
const CARD = { wordmark: 580, l1: 690, l2: 752, offer: 860, url: 912, legal: 1010 } as const; // tops of the line boxes
const PILL = { size: 20, padX: 32, h: 60 } as const; // the app's navy primary pill, at end-card size

const textW = (text: string, size: number, weight: number, letterSpacing?: string) => measureText({ text, fontFamily: FONT, fontSize: size, fontWeight: weight, letterSpacing }).width;

/** a centred end-card line that wipes in left → right */
const Line: React.FC<{ f: number; at: number; dur: number; text: string; y: number; size: number; weight: number; color: string; head?: boolean }> = ({ f, at, dur, text, y, size, weight, color, head }) => {
  if (f < at) return null;
  const ls = head ? HEAD.letterSpacing : undefined;
  const w = textW(text, size, weight, ls);
  return (
    <div style={{ position: "absolute", left: Math.round(960 - w / 2), top: y, fontSize: size, fontWeight: weight, lineHeight: 1.25, letterSpacing: ls, color, whiteSpace: "nowrap", ...softWipe(ease(f, at, at + dur), w, 72) }}>
      {text}
    </div>
  );
};

export const Act7: React.FC = () => {
  const f = useCurrentFrame();

  // the mark: outline draws (45 f) → fills white → the tile blooms behind → the rose rim thins away (the app icon)
  const draw = ease(f, A7.heart[0], A7.heart[1], Easing.bezier(0.45, 0, 0.2, 1));
  const rim = 28 * (1 - ease(f, A7.fill[1], A7.tile[1]));
  const fill = f < A7.fill[0] ? 0 : rim > 0 ? Math.min(0.999, ease(f, A7.fill[0], A7.fill[1])) : 1;
  const tile = f < A7.tile[0] ? 0 : f >= A7.lock ? 1 : settle(f, A7.tile[0], { stiffness: 150, zeta: 0.8 });

  // the two dots: rise together into the heart, then melt into its fill
  const rise = ease(f, A7.rise[0], A7.rise[1], Easing.inOut(Easing.cubic));
  const melt = ease(f, A7.fill[0], A7.fill[1], Easing.in(Easing.cubic));
  const dotY = lerp(TOUCH.you.y, INSIDE, rise);
  const dotR = TOUCH.r * (1 - melt);

  // the wordmark slides down out from behind the tile, clipped at the tile's bottom edge
  const wm = T.a7.wordmark;
  const wmW = textW(wm, 84, 700, HEAD.letterSpacing);
  const wmTop = CARD.wordmark - 124 * (1 - ease(f, A7.wordmark[0], A7.wordmark[1])); // starts wholly behind the tile

  // the url pill rises out of a slot whose floor is its own resting bottom edge
  const pillW = Math.ceil(textW(T.a7.url, PILL.size, 600, "0.02em") + 2 * PILL.padX);
  const pillH = PILL.h;
  const pillDrop = (pillH + 8) * (1 - settle(f, A7.url, { stiffness: 170, zeta: 0.8 }));

  return (
    <AbsoluteFill style={{ background: C.bg }}>
      {f >= A7.wordmark[0] && (
        <div
          style={{
            position: "absolute",
            left: Math.round(960 - wmW / 2),
            top: wmTop,
            fontSize: 84,
            lineHeight: 1.25,
            color: C.ink,
            whiteSpace: "nowrap",
            ...HEAD,
            clipPath: f < A7.lock ? `inset(${Math.max(0, MARK_BOTTOM - wmTop)}px 0 0 0)` : undefined,
          }}
        >
          {wm}
        </div>
      )}
      <Heart x={MARK.x} y={MARK.y} size={MARK.size} draw={draw} fill={fill} tile={tile} stroke={C.rose} strokeWidth={rim} />
      {dotR > 0.2 && (
        <>
          <Dot x={lerp(TOUCH.you.x, 960, melt)} y={dotY} r={dotR} who="you" />
          <Dot x={lerp(TOUCH.other.x, 960, melt)} y={dotY} r={dotR} who="other" />
        </>
      )}
      <Line f={f} at={A7.l1} dur={16} text={T.a7.l1} y={CARD.l1} size={52} weight={700} color={C.ink} head />
      <Line f={f} at={A7.l2} dur={18} text={T.a7.l2} y={CARD.l2} size={52} weight={700} color={C.rose} head />
      <Line f={f} at={A7.offer} dur={16} text={T.a7.offer} y={CARD.offer} size={28} weight={600} color={C.ink2} />
      {f >= A7.url && (
        <div style={{ position: "absolute", left: Math.round(960 - pillW / 2) - 6, top: CARD.url - 12, width: pillW + 12, height: pillH + 12, overflow: "hidden" }}>
          <Pill text={T.a7.url} size={PILL.size} style={{ left: 6, top: 12 + pillDrop, height: PILL.h }} />
        </div>
      )}
      <Line f={f} at={A7.legal} dur={24} text={T.a7.legal} y={CARD.legal} size={18} weight={500} color={C.ink2} />
    </AbsoluteFill>
  );
};
