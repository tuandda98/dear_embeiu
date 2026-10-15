// THE NUMBER (BRIEF §2 INK): the counter block every act shares. Rendered at (x, y) = its top-left, at `scale`
// (1 = hero, A1). Layout at scale 1 (px): eyebrow row 0–20 · the number box 40–360 (320 px type) · "NGÀY" 392–424 ·
// the clock row 450–514 with its labels at 530. The block is 1000 wide. The clock ticks from the GLOBAL frame:
// seconds = 7 + ⌊f / 60⌋ — the film's metronome — so every act shows the same time at the same frame.
import { Digits, digitsWidth, group, pad2 } from "../components/Digits.tsx";
import { C } from "../lib/tokens.ts";
import { T } from "../copy/strings.ts";

export const COUNTER = { w: 1000, h: 560, numberTop: 40, numberSize: 320, hero: { x: 120, y: 250 } } as const;
/** where the lavender dot lands beside the number at the hero placement (A1.land / A2.land) */
export const COUNTER_DOT = { x: COUNTER.hero.x + digitsWidth(T.a1.days, COUNTER.numberSize) + 90, y: COUNTER.hero.y + COUNTER.numberTop + COUNTER.numberSize / 2 } as const;

export function clockAt(f: number) {
  const { hours, minutes, seconds } = T.a1.clock;
  const s = seconds + Math.floor(f / 60);
  const m = minutes + Math.floor(s / 60);
  const h = hours + Math.floor(m / 60);
  return { h, m: m % 60, s: s % 60, text: `${group(h)} : ${pad2(m % 60)} : ${pad2(s % 60)}` };
}

export const Counter: React.FC<{ x: number; y: number; scale?: number; f: number; opacity?: number; color?: string; dim?: string }> = ({
  x,
  y,
  scale = 1,
  f,
  opacity = 1,
  color = C.ink,
  dim = C.ink2,
}) => {
  const clock = clockAt(f);
  const clockSize = 64;
  const groups = [group(clock.h), pad2(clock.m), pad2(clock.s)];
  return (
    <div style={{ position: "absolute", left: x, top: y, width: COUNTER.w, height: COUNTER.h, transformOrigin: "0 0", transform: `scale(${scale})`, opacity, color }}>
      <div style={{ position: "absolute", left: 0, top: 0, fontSize: 20, fontWeight: 600, letterSpacing: "0.12em", color: dim }}>{T.a1.eyebrow}</div>
      <Digits value={T.a1.days} size={COUNTER.numberSize} weight={700} style={{ position: "absolute", left: -8, top: COUNTER.numberTop, letterSpacing: "-0.02em" }} />
      <div style={{ position: "absolute", left: 0, top: 390, fontSize: 30, fontWeight: 600, letterSpacing: "0.14em", color: dim }}>{T.a1.unit}</div>
      <div style={{ position: "absolute", left: 0, top: 450, display: "flex", alignItems: "flex-start" }}>
        {groups.map((g, i) => (
          <div key={i} style={{ display: "flex", alignItems: "flex-start" }}>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
              <Digits value={g} size={clockSize} weight={700} />
              <div style={{ marginTop: 14, fontSize: 16, fontWeight: 600, letterSpacing: "0.14em", color: dim }}>{T.a1.clock.labels[i]}</div>
            </div>
            {i < 2 && <div style={{ width: 44, textAlign: "center", fontSize: clockSize, fontWeight: 700, lineHeight: 1, color: dim }}>:</div>}
          </div>
        ))}
      </div>
    </div>
  );
};
