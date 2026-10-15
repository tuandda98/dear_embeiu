// Act 6 · the eight feature icons: white 2 px line glyphs inside each card's circle, animating once (60 f).
// Designed in a 64-unit box, drawn at CARDS.icon px (so a 2 px stroke is SW units). `ground` is the circle's colour,
// used where one shape must hide another (the front photo frame).
import { Easing } from "remotion";
import { ease, settle } from "../../lib/ease.ts";
import { C, DIGIT_EM } from "../../lib/tokens.ts";
import { CARDS } from "./layout.ts";

type G = React.FC<{ t: number; ground: string }>;
const K = CARDS.icon / 64; // px per design unit
const SW = 2 / K; // a 2 px stroke, in design units
const INK = C.white;
const pr = (t: number, a: number, b: number) => ease(t, a, b, Easing.inOut(Easing.cubic));
/** drawn in over [a, b], held, drawn back out over [c, d] */
const inOut = (t: number, a: number, b: number, c: number, d: number) => (t < c ? pr(t, a, b) : 1 - pr(t, c, d));

const rr = (x: number, y: number, w: number, h: number, r: number) =>
  `M ${x + r} ${y} H ${x + w - r} A ${r} ${r} 0 0 1 ${x + w} ${y + r} V ${y + h - r} A ${r} ${r} 0 0 1 ${x + w - r} ${y + h} H ${x + r} A ${r} ${r} 0 0 1 ${x} ${y + h - r} V ${y + r} A ${r} ${r} 0 0 1 ${x + r} ${y} Z`;
const circle = (cx: number, cy: number, r: number) => `M ${cx} ${cy - r} A ${r} ${r} 0 1 1 ${cx} ${cy + r} A ${r} ${r} 0 1 1 ${cx} ${cy - r}`;
/** a speech bubble with a small tail off its bottom-left or bottom-right corner */
const speech = (x: number, y: number, w: number, h: number, r: number, tail: "left" | "right") => {
  const b = y + h;
  return tail === "left"
    ? `M ${x + r} ${y} H ${x + w - r} A ${r} ${r} 0 0 1 ${x + w} ${y + r} V ${b - r} A ${r} ${r} 0 0 1 ${x + w - r} ${b} H ${x + 11} L ${x + 1} ${b + 7} L ${x + 3} ${b - 3} A ${r} ${r} 0 0 1 ${x} ${b - r} V ${y + r} A ${r} ${r} 0 0 1 ${x + r} ${y} Z`
    : `M ${x + r} ${y} H ${x + w - r} A ${r} ${r} 0 0 1 ${x + w} ${y + r} V ${b - r} A ${r} ${r} 0 0 1 ${x + w - 3} ${b - 3} L ${x + w - 1} ${b + 7} L ${x + w - 11} ${b} H ${x + r} A ${r} ${r} 0 0 1 ${x} ${b - r} V ${y + r} A ${r} ${r} 0 0 1 ${x + r} ${y} Z`;
};
/** a finger: outline open at its base, rounded tip */
const finger = (x: number, top: number, w: number, base: number) => `M ${x} ${base} V ${top + w / 2} A ${w / 2} ${w / 2} 0 0 1 ${x + w} ${top + w / 2} V ${base}`;

/** a stroke drawn along its length (p 0 → 1); nothing at 0 (a round cap would leave a dot) */
const S: React.FC<{ d: string; p: number; fill?: string }> = ({ d, p, fill = "none" }) =>
  p <= 0 ? null : (
    <path d={d} fill={fill} stroke={INK} strokeWidth={SW} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray={p < 1 ? "1 1" : undefined} strokeDashoffset={p < 1 ? 1 - p : undefined} />
  );
const Svg: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <svg width={CARDS.icon} height={CARDS.icon} viewBox="0 0 64 64" style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }}>
    {children}
  </svg>
);

// 0 · Đếm ngày yêu — digits ticking: the day count rolls 1247 → 1250 (today)
const SEQ = ["1247", "1248", "1249", "1250"];
const TICKS = [20, 32, 44];
const Count: G = ({ t }) => {
  const size = Math.round(17 * (CARDS.icon / 40));
  const slot = size * DIGIT_EM;
  const win = { x: -5, y: Math.round(CARDS.icon * 0.2), w: CARDS.icon + 10, h: Math.round(CARDS.icon * 0.6) };
  const x0 = (win.w - 4 * slot) / 2;
  return (
    <div style={{ position: "absolute", left: win.x, top: win.y, width: win.w, height: win.h, overflow: "hidden" }}>
      {[0, 1, 2, 3].map((i) => {
        const vals = [SEQ[0][i]];
        let pos = pr(t, 0, 10) - 1; // the number rolls up into view…
        TICKS.forEach((tk, k) => {
          if (SEQ[k + 1][i] === SEQ[k][i]) return;
          vals.push(SEQ[k + 1][i]);
          pos += pr(t, tk, tk + 7); // …then ticks, one day per eighth
        });
        return (
          <div key={i} style={{ position: "absolute", left: x0 + i * slot, top: -pos * win.h, width: slot }}>
            {vals.map((v, j) => (
              <div key={j} style={{ height: win.h, lineHeight: `${win.h}px`, textAlign: "center", fontSize: size, fontWeight: 700, color: INK }}>
                {v}
              </div>
            ))}
          </div>
        );
      })}
    </div>
  );
};

// 1 · Ảnh chung — two frames overlapping: they slide together into one album
const Album: G = ({ t, ground }) => {
  const m = pr(t, 24, 44);
  const bx = 26 - 4 * m;
  const fx = 8 + 4 * m;
  return (
    <Svg>
      <S d={rr(bx, 6, 30, 36, 6)} p={pr(t, 0, 18)} />
      {t >= 22 && <path d={rr(fx, 20, 30, 36, 6)} fill={ground} />}
      <S d={rr(fx, 20, 30, 36, 6)} p={pr(t, 4, 22)} />
      <S d={`M ${fx + 6} ${49} L ${fx + 14} ${39} L ${fx + 24} ${49}`} p={pr(t, 22, 34)} />
    </Svg>
  );
};

// 2 · Câu hỏi mỗi ngày — two bubbles over a lock that opens
const Question: G = ({ t }) => {
  const lift = 6 * settle(t, 38, { stiffness: 220, zeta: 0.8 });
  return (
    <Svg>
      <S d={speech(2, 4, 26, 19, 7, "left")} p={pr(t, 0, 16)} />
      <S d={speech(36, 4, 26, 19, 7, "right")} p={pr(t, 4, 20)} />
      <S d={rr(22, 40, 20, 17, 4)} p={pr(t, 14, 28)} />
      <g transform={`translate(0 ${-lift})`}>
        <S d="M 26.5 40 V 35 A 5.5 5.5 0 0 1 37.5 35 V 40" p={pr(t, 20, 32)} />
      </g>
    </Svg>
  );
};

// 3 · Tâm trạng — a face that smiles
const Mood: G = ({ t }) => {
  const smile = pr(t, 30, 48);
  return (
    <Svg>
      <S d={circle(32, 32, 25)} p={pr(t, 0, 22)} />
      <S d="M 24 25 V 29" p={pr(t, 16, 22)} />
      <S d="M 40 25 V 29" p={pr(t, 18, 24)} />
      <S d={`M 21 39 Q 32 ${39 + 10 * smile} 43 39`} p={pr(t, 22, 30)} />
    </Svg>
  );
};

// 4 · Giấc ngủ — a moon filling: crescent → a fat gibbous (the fuller, the longer the night; a full disc would read as a dot)
const Moon: G = ({ t }) => {
  const r = 24;
  const p = 0.12 + 0.72 * pr(t, 18, 56);
  const rx = Math.max(0.01, Math.abs(1 - 2 * p) * r);
  const lit = `M 32 ${32 - r} A ${r} ${r} 0 0 1 32 ${32 + r} A ${rx} ${r} 0 0 ${p < 0.5 ? 0 : 1} 32 ${32 - r} Z`;
  return (
    <Svg>
      {t >= 18 && <path d={lit} fill={INK} />}
      <S d={circle(32, 32, r)} p={pr(t, 0, 20)} />
    </Svg>
  );
};

// 5 · Trò chuyện — a bubble with three dots
const Chat: G = ({ t }) => (
  <Svg>
    <S d={speech(6, 10, 52, 36, 12, "left")} p={pr(t, 0, 20)} />
    {[0, 1, 2].map((k) => {
      const at = 22 + 6 * k;
      if (t < at) return null;
      const s = settle(t, at, { stiffness: 260, zeta: 0.8 });
      const ph = (t - at) % 24;
      const lift = ph < 14 ? 3 * Math.sin((Math.PI * ph) / 14) : 0;
      return <circle key={k} cx={20 + 12 * k} cy={28 - lift} r={3.6 * s} fill={INK} />;
    })}
  </Svg>
);

// 6 · Lời nhắc — a bell swinging once (out with the house ease, back with one small overshoot)
const Bell: G = ({ t }) => {
  const a = t < 26 ? 0 : t < 36 ? 16 * pr(t, 26, 36) : 16 * (1 - settle(t, 36, { stiffness: 160, zeta: 0.7 }));
  return (
    <Svg>
      <g transform={`rotate(${a} 32 8)`}>
        <S d="M 32 8 V 15" p={pr(t, 0, 6)} />
        <S d="M 16 46 C 20 42 20 38 20 29 C 20 20.5 25.5 15 32 15 C 38.5 15 44 20.5 44 29 C 44 38 44 42 48 46 Z" p={pr(t, 4, 22)} />
        <S d="M 27.5 46 A 4.5 4.5 0 0 0 36.5 46" p={pr(t, 18, 26)} />
      </g>
    </Svg>
  );
};

// 7 · Oẳn tù tì — ✌️ then ✊ then ✋, one hand at a time, each drawn in and back out (the last one stays)
const Rps: G = ({ t }) => {
  const v = inOut(t, 0, 12, 16, 20);
  const r = inOut(t, 20, 30, 34, 38);
  const p = pr(t, 38, 52);
  return (
    <Svg>
      {t < 20 && (
        <>
          <S d={rr(19, 34, 26, 22, 8)} p={v} />
          <g transform="rotate(-13 27 35)">
            <S d={finger(23, 6, 8, 35)} p={v} />
          </g>
          <g transform="rotate(13 37 35)">
            <S d={finger(33, 6, 8, 35)} p={v} />
          </g>
        </>
      )}
      {t >= 20 && t < 38 && (
        <>
          <S d={rr(16, 16, 32, 34, 10)} p={r} />
          <S d="M 26 16 V 25 M 32 16 V 25 M 38 16 V 25" p={r} />
          <S d="M 16 34 H 34" p={r} />
        </>
      )}
      {t >= 38 && (
        <>
          <S d={rr(18, 34, 30, 24, 7)} p={p} />
          {[
            [18, 10],
            [26, 5],
            [34, 6],
            [42, 12],
          ].map(([x, top], i) => (
            <S key={i} d={finger(x, top, 8, 35)} p={p} />
          ))}
          <g transform="rotate(-36 18 50)">
            <S d={finger(10, 32, 8, 50)} p={p} />
          </g>
        </>
      )}
    </Svg>
  );
};

export const GLYPHS: G[] = [Count, Album, Question, Mood, Moon, Chat, Bell, Rps];
