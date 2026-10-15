// Act 6 · the eight things the two of you do here: one line glyph each, animating 60 f from its cue (A6.glyphs).
// Designed in a 64-unit box (Oẳn tù tì: 96 units), drawn at CELLS.k = 1.5 (96 px tall) with 2 px strokes.
// Colour roles: navy ink; rose + lavender only where the glyph shows the two of you (two frames, two bubbles).
import { Easing } from "remotion";
import { ease, settle } from "../../lib/ease.ts";
import { C, DIGIT_EM } from "../../lib/tokens.ts";
import { CELLS } from "./layout.ts";

const K = CELLS.k; // px per design unit
const SW = 2 / K; // a 2 px stroke, in design units

type G = React.FC<{ t: number }>;
const pr = (t: number, a: number, b: number) => ease(t, a, b, Easing.inOut(Easing.cubic));

const rr = (x: number, y: number, w: number, h: number, r: number) =>
  `M ${x + r} ${y} H ${x + w - r} A ${r} ${r} 0 0 1 ${x + w} ${y + r} V ${y + h - r} A ${r} ${r} 0 0 1 ${x + w - r} ${y + h} H ${x + r} A ${r} ${r} 0 0 1 ${x} ${y + h - r} V ${y + r} A ${r} ${r} 0 0 1 ${x + r} ${y} Z`;
const circle = (cx: number, cy: number, r: number) => `M ${cx} ${cy - r} A ${r} ${r} 0 1 1 ${cx} ${cy + r} A ${r} ${r} 0 1 1 ${cx} ${cy - r}`;
/** a speech bubble: rounded rect with a small tail off its bottom-left or bottom-right corner */
const speech = (x: number, y: number, w: number, h: number, r: number, tail: "left" | "right") => {
  const b = y + h;
  return tail === "left"
    ? `M ${x + r} ${y} H ${x + w - r} A ${r} ${r} 0 0 1 ${x + w} ${y + r} V ${b - r} A ${r} ${r} 0 0 1 ${x + w - r} ${b} H ${x + 9} L ${x + 1} ${b + 6} L ${x + 2} ${b - 3} A ${r} ${r} 0 0 1 ${x} ${b - r} V ${y + r} A ${r} ${r} 0 0 1 ${x + r} ${y} Z`
    : `M ${x + r} ${y} H ${x + w - r} A ${r} ${r} 0 0 1 ${x + w} ${y + r} V ${b - r} A ${r} ${r} 0 0 1 ${x + w - 2} ${b - 3} L ${x + w - 1} ${b + 6} L ${x + w - 9} ${b} H ${x + r} A ${r} ${r} 0 0 1 ${x} ${b - r} V ${y + r} A ${r} ${r} 0 0 1 ${x + r} ${y} Z`;
};

/** a 2 px stroke drawn along its length (p 0 → 1); nothing at 0 (a round cap would leave a dot) */
const S: React.FC<{ d: string; p: number; c?: string; fill?: string }> = ({ d, p, c = C.ink, fill = "none" }) =>
  p <= 0 ? null : (
    <path d={d} fill={fill} stroke={c} strokeWidth={SW} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray={p < 1 ? "1 1" : undefined} strokeDashoffset={p < 1 ? 1 - p : undefined} />
  );
const Svg: React.FC<{ w?: number; children: React.ReactNode }> = ({ w = 64, children }) => (
  <svg width={w * K} height={64 * K} viewBox={`0 0 ${w} 64`} style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }}>
    {children}
  </svg>
);

// 0 · Đếm ngày yêu — digits ticking in a box: the day count rolls 1247 → 1250 (today)
const SEQ = ["1247", "1248", "1249", "1250"];
const TICKS = [26, 38, 50];
const Count: G = ({ t }) => {
  const size = 20 * K;
  const slot = size * DIGIT_EM;
  const inner = { x: 3 * K, y: 15 * K, w: 58 * K, h: 34 * K };
  const x0 = (inner.w - 4 * slot) / 2;
  return (
    <>
      <Svg>
        <S d={rr(2.5, 14.5, 59, 35, 8)} p={pr(t, 0, 20)} />
      </Svg>
      <div style={{ position: "absolute", left: inner.x, top: inner.y, width: inner.w, height: inner.h, overflow: "hidden" }}>
        {[0, 1, 2, 3].map((i) => {
          const vals = [SEQ[0][i]];
          let pos = pr(t, 8, 18) - 1; // the number rolls up into the box…
          TICKS.forEach((tk, k) => {
            if (SEQ[k + 1][i] === SEQ[k][i]) return;
            vals.push(SEQ[k + 1][i]);
            pos += pr(t, tk, tk + 7); // …then ticks, one day per eighth
          });
          return (
            <div key={i} style={{ position: "absolute", left: x0 + i * slot, top: -pos * inner.h, width: slot }}>
              {vals.map((v, j) => (
                <div key={j} style={{ height: inner.h, lineHeight: `${inner.h}px`, textAlign: "center", fontSize: size, fontWeight: 700, color: C.ink }}>
                  {v}
                </div>
              ))}
            </div>
          );
        })}
      </div>
    </>
  );
};

// 1 · Ảnh chung — two frames overlapping: yours (rose) slides over the other's (lavender) into one album
const Album: G = ({ t }) => {
  const m = pr(t, 32, 54);
  const bx = 29.5 - 5 * m;
  const fx = 0.5 + 5 * m;
  const fy = 18.5;
  const done = t >= 26;
  return (
    <Svg>
      <S d={rr(bx, 6.5, 33, 39, 5)} p={pr(t, 0, 20)} c={C.lavender} />
      {done && <path d={rr(fx, fy, 33, 39, 5)} fill={C.bg} />}
      <S d={rr(fx, fy, 33, 39, 5)} p={pr(t, 6, 26)} c={C.rose} />
      <S d={`M ${fx + 5} ${fy + 32} L ${fx + 13} ${fy + 22} L ${fx + 19} ${fy + 28} L ${fx + 23} ${fy + 24} L ${fx + 28} ${fy + 32}`} p={pr(t, 26, 42)} />
      <S d={circle(fx + 24, fy + 10, 3)} p={pr(t, 30, 42)} />
    </Svg>
  );
};

// 2 · Câu hỏi mỗi ngày — two bubbles (yours, the other's) over a lock; the lock opens, both answers show
const Question: G = ({ t }) => {
  const lift = 5 * settle(t, 40, { stiffness: 220, zeta: 0.8 });
  return (
    <Svg>
      <S d={speech(0.5, 2.5, 28, 20, 8, "left")} p={pr(t, 0, 20)} c={C.rose} />
      <S d={speech(35.5, 2.5, 28, 20, 8, "right")} p={pr(t, 6, 26)} c={C.lavender} />
      <S d={rr(23.5, 45.5, 18, 15, 3)} p={pr(t, 14, 30)} />
      <S d="M 32.5 50.5 V 55.5" p={pr(t, 26, 32)} />
      <g transform={`translate(0 ${-lift})`}>
        <S d="M 27.5 45.5 V 40.5 A 5 5 0 0 1 37.5 40.5 V 45.5" p={pr(t, 20, 36)} />
      </g>
      <S d="M 7.5 12.5 H 21.5" p={pr(t, 46, 56)} c={C.rose} />
      <S d="M 42.5 12.5 H 56.5" p={pr(t, 48, 58)} c={C.lavender} />
    </Svg>
  );
};

// 3 · Tâm trạng — a face that smiles
const Mood: G = ({ t }) => {
  const smile = pr(t, 32, 50);
  return (
    <Svg>
      <S d={circle(32, 32, 23.5)} p={pr(t, 0, 24)} />
      <S d="M 24.5 25.5 V 29.5" p={pr(t, 18, 24)} />
      <S d="M 39.5 25.5 V 29.5" p={pr(t, 20, 26)} />
      <S d={`M 23 40 Q 32 ${40 + 9 * smile} 41 40`} p={pr(t, 24, 32)} />
    </Svg>
  );
};

// 4 · Giấc ngủ — a moon filling: crescent → full (the app's moon calendar: the fuller, the longer the night).
// The lit part is ruled with 1 px lines, so even the full moon stays a hairline drawing, never a blot.
const Moon: G = ({ t }) => {
  const r = 22.5;
  const p = 0.12 + 0.88 * pr(t, 20, 58);
  const rx = Math.max(0.01, Math.abs(1 - 2 * p) * r);
  const lit = `M 32 ${32 - r} A ${r} ${r} 0 0 1 32 ${32 + r} A ${rx} ${r} 0 0 ${p < 0.5 ? 0 : 1} 32 ${32 - r} Z`;
  return (
    <Svg>
      <defs>
        <pattern id="a6-moon-rule" width={4} height={4} patternUnits="userSpaceOnUse">
          <path d="M 0 1.5 H 4" stroke={C.ink} strokeWidth={SW} />
        </pattern>
      </defs>
      {t >= 20 && <path d={lit} fill="url(#a6-moon-rule)" />}
      <S d={circle(32, 32, r)} p={pr(t, 0, 22)} />
    </Svg>
  );
};

// 5 · Trò chuyện — a bubble with three dots
const Chat: G = ({ t }) => (
  <Svg>
    <S d={speech(8.5, 12.5, 47, 31, 10, "left")} p={pr(t, 0, 22)} />
    {[0, 1, 2].map((k) => {
      const at = 24 + 7 * k;
      if (t < at) return null;
      const s = settle(t, at, { stiffness: 260, zeta: 0.8 });
      const ph = (t - at) % 24;
      const lift = ph < 14 ? 3 * Math.sin((Math.PI * ph) / 14) : 0;
      return <circle key={k} cx={22 + 10 * k} cy={28 - lift} r={2.5 * s} fill={C.ink} />;
    })}
  </Svg>
);

// 6 · Lời nhắc — a bell swinging once (out with the house ease, back with one small overshoot)
const Bell: G = ({ t }) => {
  const a = t < 28 ? 0 : t < 38 ? 14 * pr(t, 28, 38) : 14 * (1 - settle(t, 38, { stiffness: 160, zeta: 0.7 }));
  return (
    <Svg>
      <g transform={`rotate(${a} 32 11)`}>
        <S d="M 32 11 V 17.5" p={pr(t, 0, 6)} />
        <S d="M 19 44.5 C 22 41 22 38 22 30 C 22 22.5 26.5 17.5 32 17.5 C 37.5 17.5 42 22.5 42 30 C 42 38 42 41 45 44.5 Z" p={pr(t, 4, 24)} />
        <S d="M 29 44.5 A 3 3 0 0 0 35 44.5" p={pr(t, 18, 26)} />
      </g>
    </Svg>
  );
};

// 7 · Oẳn tù tì — three strokes: ✌️ ✊ ✋ as line glyphs, drawn one after another
/** a finger: an outline open at its base (x, base) → rounded tip at `top`, `w` wide */
const finger = (x: number, top: number, w: number, base: number) => `M ${x} ${base} V ${top + w / 2} A ${w / 2} ${w / 2} 0 0 1 ${x + w} ${top + w / 2} V ${base}`;
const Rps: G = ({ t }) => (
  <Svg w={96}>
    {/* ✌️ two fingers in a V over a small fist */}
    <S d={rr(4.5, 38.5, 20, 18, 7)} p={pr(t, 0, 12)} />
    <g transform="rotate(-14 11 39)">
      <S d={finger(8, 13, 6, 39)} p={pr(t, 6, 16)} />
    </g>
    <g transform="rotate(14 18 39)">
      <S d={finger(15, 13, 6, 39)} p={pr(t, 8, 18)} />
    </g>
    {/* ✊ a fist: knuckles on top, the thumb across */}
    <S d={rr(35.5, 26.5, 26, 28, 7)} p={pr(t, 18, 30)} />
    <S d="M 42.5 26.5 V 32.5 M 48.5 26.5 V 32.5 M 54.5 26.5 V 32.5" p={pr(t, 26, 34)} />
    <S d="M 35.5 42.5 H 50.5" p={pr(t, 28, 34)} />
    {/* ✋ an open hand: four fingers and a thumb */}
    <S d={rr(70.5, 36.5, 22, 20, 5)} p={pr(t, 34, 44)} />
    {[
      [70.5, 19.5],
      [75.5, 15.5],
      [80.5, 16.5],
      [85.5, 20.5],
    ].map(([x, top], i) => (
      <S key={i} d={finger(x, top, 5, 37)} p={pr(t, 38 + 2 * i, 48 + 2 * i)} />
    ))}
    <g transform="rotate(-38 70.5 50)">
      <S d={finger(65.5, 36, 5, 50)} p={pr(t, 46, 54)} />
    </g>
  </Svg>
);

export const GLYPHS: G[] = [Count, Album, Question, Mood, Moon, Chat, Bell, Rps];
