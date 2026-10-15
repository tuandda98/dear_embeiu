// The delivery (BRIEF §5 ACT 4, 30–32 s): the phone's screen wipes to a rebuilt iOS home screen, the counter card lifts
// off and lands as the medium widget, the small widget snaps in, the Android 2×2 lands beside the phone. Widgets from
// the product's own views: ios/DearEmbeiuWidget/DayCounterView.swift (over the couple photo, design P3) and
// android/res/layout/widget_day_small.xml + drawable/widget_bg.xml (the love tree's night sky, design M2).
import type { CSSProperties } from "react";
import { useCurrentFrame } from "remotion";
import { C } from "../../lib/tokens.ts";
import { ease, lerp, settle } from "../../lib/ease.ts";
import { T } from "../../copy/strings.ts";
import { A4 } from "../../timeline/cues.ts";
import { Heart } from "../../components/Heart.tsx";
import { StatusBar } from "../../components/Phone.tsx";
import { measureText } from "@remotion/layout-utils";
import { FONT } from "../../lib/tokens.ts";
import { CounterContent, HOME, NUMBER, Names, PhotoBack } from "./home.tsx";
import { FLY, WIPE } from "./events.ts";
import { diag, inOut } from "./parts.tsx";

const W = T.a4.widget;
const abs = (s: CSSProperties): CSSProperties => ({ position: "absolute", ...s });
const NAVY = C.ink;
const BLUSH = "#FF8FA3";
const INK_SHADOW = "0 1px 4px rgba(0,0,0,0.30)";
const R = 22; // iOS widget corner on this device

/** iOS slots (screen pt): the medium widget over the first two icon rows, the small one under it at the left */
export const MEDIUM = { x: 32, y: 74, w: 338, h: 158 } as const;
export const SMALL = { x: 32, y: 270, w: 158, h: 158 } as const;

// ── widget content (DayCounterView.swift) ──────────────────────────────────────────────────────────────────────────
const NamesChip: React.FC<{ dark: boolean }> = ({ dark }) => (
  <div
    style={{
      display: "inline-flex",
      alignItems: "center",
      height: 20,
      padding: "0 8px",
      borderRadius: 999,
      background: dark ? "rgba(255,255,255,0.14)" : "rgba(255,255,255,0.84)",
      boxShadow: dark ? "inset 0 0 0 1px rgba(255,255,255,0.22)" : undefined,
    }}
  >
    <Names size={10} heart={9} gap={5} color={dark ? C.white : NAVY} heartColor={dark ? BLUSH : C.roseDeep} upper tracking="0.1em" />
  </div>
);
/** the widget's number: 40 pt, its line box at (15, 81) of a 158-tall face */
const DAYS = { x: 15, top: 158 - 16 - 15 - 6 - 40, size: 40, tracking: -0.025 } as const;
/** the small counter: names chip, then "1250" and "ngày bên nhau" at the bottom (16 pt content margins) */
const SmallFace: React.FC<{ dark: boolean; number?: boolean }> = ({ dark, number = true }) => (
  <>
    <div style={abs({ left: 16, top: 16 })}>
      <NamesChip dark={dark} />
    </div>
    {number && (
      <div style={abs({ left: DAYS.x, top: DAYS.top, fontSize: DAYS.size, fontWeight: 700, lineHeight: 1, letterSpacing: `${DAYS.tracking}em`, color: C.white, textShadow: INK_SHADOW, whiteSpace: "nowrap" })}>
        {W.days}
      </div>
    )}
    <div style={abs({ left: 16, top: 158 - 16 - 15, fontSize: 12, fontWeight: 600, lineHeight: "15px", color: "rgba(255,255,255,0.92)", textShadow: INK_SHADOW, whiteSpace: "nowrap" })}>{W.caption}</div>
  </>
);
/** the medium counter: the small face, a hairline, then the milestone, the lavender bar, the days left, the start date */
const MediumFace: React.FC<{ number?: boolean }> = ({ number }) => (
  <>
    <SmallFace dark={false} number={number} />
    <div style={abs({ left: 16 + 150 + 14, top: 18, width: 1, height: 122, background: "rgba(255,255,255,0.28)" })} />
    <div style={abs({ left: 16 + 150 + 29, top: 16, width: 338 - 32 - 179, height: 126, color: C.white, textShadow: INK_SHADOW })}>
      <div style={{ fontSize: 12, fontWeight: 700, lineHeight: "15px" }}>{W.milestone}</div>
      <div style={{ marginTop: 8, height: 6, borderRadius: 999, background: "rgba(255,255,255,0.26)", overflow: "hidden" }}>
        <div style={{ width: `${(1250 / 1500) * 100}%`, height: "100%", borderRadius: 999, background: C.lavender }} />
      </div>
      <div style={{ marginTop: 8, fontSize: 12, fontWeight: 600, lineHeight: "15px", color: "rgba(255,255,255,0.92)" }}>{W.left}</div>
      <div style={abs({ left: 0, bottom: 0, width: 116, fontSize: 11, fontWeight: 500, lineHeight: "14px", color: "rgba(255,255,255,0.84)", textWrap: "balance" })}>{W.since}</div>
    </div>
  </>
);

// ── the counter card lifting off and landing as the medium widget ─────────────────────────────────────────────────
const lift = (f: number) => inOut(f, A4.lift[0], FLY);
const fly = (f: number) => (f < FLY ? 0 : settle(f, FLY, { stiffness: 95, zeta: 0.8 }));
const box = (f: number) => {
  const p = fly(f);
  const l = lift(f) * (1 - p);
  const c = HOME.card;
  return { x: lerp(c.x, MEDIUM.x, p), y: lerp(c.y - 8 * l, MEDIUM.y, p), w: lerp(c.w, MEDIUM.w, p), h: lerp(c.h, MEDIUM.h, p), r: lerp(28, R, p), s: 1 + 0.035 * l, l, p };
};
/** the fastest edge of the flying card, in film px per frame (the phone is drawn at 1.1×) */
export const liftSpeed = (f: number) => {
  const a = box(f - 0.5);
  const b = box(f + 0.5);
  return Math.max(Math.abs(b.y + b.h - a.y - a.h), Math.abs(b.y - a.y)) * 1.1;
};
/** "1250" never leaves: it travels from the card's centre (76 pt) to the widget's corner (40 pt) while the rest swaps */
const MorphNumber: React.FC<{ w: number; q: number }> = ({ w, q }) => {
  const w76 = measureText({ text: T.a1.days, fontFamily: FONT, fontSize: NUMBER.size, fontWeight: "800", letterSpacing: `${NUMBER.tracking}em` }).width;
  const a = w / 370; // the card's content scale in this box
  const z = w / 338; // the widget's
  const x = lerp(((370 - w76) / 2) * a, DAYS.x * z, q);
  const y = lerp(NUMBER.top * a, DAYS.top * z, q);
  const k = lerp(NUMBER.size * a, DAYS.size * z, q) / NUMBER.size;
  const [sy, sb, sa] = NUMBER.shadow;
  return (
    <div
      style={abs({
        left: 0,
        top: 0,
        transformOrigin: "0 0",
        transform: `translate(${x}px, ${y}px) scale(${k})`,
        fontSize: NUMBER.size,
        fontWeight: 800,
        lineHeight: 1,
        letterSpacing: `${lerp(NUMBER.tracking, DAYS.tracking, q)}em`,
        color: C.white,
        whiteSpace: "nowrap",
        textShadow: `0 ${lerp(sy, 1 / k, q)}px ${lerp(sb, 4 / k, q)}px rgba(0,0,0,${lerp(sa, 0.3, q)})`,
      })}
    >
      {T.a1.days}
    </div>
  );
};
const LANDED = A4.widgetMedium + 6; // from here the widget draws its own number
export const LiftCard: React.FC = () => {
  const f = useCurrentFrame();
  if (f < A4.lift[0]) return null;
  const b = box(f);
  const out = 1 - ease(f, FLY, FLY + 16);
  const inn = ease(f, FLY + 12, A4.widgetMedium - 12);
  const flying = f >= FLY && f < LANDED;
  return (
    <div
      style={abs({
        left: b.x,
        top: b.y,
        width: b.w,
        height: b.h,
        borderRadius: b.r,
        transform: `scale(${b.s})`,
        // at rest this is exactly the card's CARD_SHADOW; it deepens with the lift and is gone once it is a widget
        boxShadow: [
          `0 ${16 + 22 * b.l}px ${36 + 30 * b.l}px rgba(255,107,157,${0.36 * (1 - b.p)})`,
          `0 ${24 + 20 * b.l}px ${48 + 24 * b.l}px rgba(167,139,250,${0.18 * (1 - b.p)})`,
          `0 ${30 * b.l}px ${60 * b.l}px rgba(26,26,46,${0.16 * b.l})`,
        ].join(", "),
      })}
    >
      <div style={abs({ inset: 0, borderRadius: b.r, overflow: "hidden" })}>
        <PhotoBack top={lerp(0.26, 0.18, b.p)} bottom={lerp(0.46, 0.6, b.p)} radius={b.r} rim={1 - b.p} />
        {out > 0 && (
          <div style={abs({ left: 0, top: 0, width: 370, height: 392, transformOrigin: "0 0", transform: `scale(${b.w / 370})`, opacity: out })}>
            <CounterContent f={f} number={f < FLY} />
          </div>
        )}
        {inn > 0 && (
          <div style={abs({ left: 0, top: 6 * (1 - inn), width: 338, height: 158, transformOrigin: "0 0", transform: `scale(${b.w / 338})`, opacity: inn })}>
            <MediumFace number={!flying} />
          </div>
        )}
        {flying && <MorphNumber w={b.w} q={Math.min(1, b.p)} />}
      </div>
    </div>
  );
};

// ── the small widget: snaps into its slot ──────────────────────────────────────────────────────────────────────────
export const SmallWidget: React.FC<{ f: number }> = ({ f }) => {
  if (f < A4.widgetSmall) return null;
  const s = 0.84 + 0.16 * settle(f, A4.widgetSmall, { stiffness: 320, zeta: 0.72 });
  return (
    <div style={abs({ left: SMALL.x, top: SMALL.y, width: SMALL.w, height: SMALL.h, borderRadius: R, overflow: "hidden", transform: `scale(${s})`, opacity: ease(f, A4.widgetSmall, A4.widgetSmall + 4) })}>
      <PhotoBack top={0.18} bottom={0.6} radius={R} rim={0} />
      <SmallFace dark={false} />
    </div>
  );
};

// ── the iOS home screen ────────────────────────────────────────────────────────────────────────────────────────────
const COLS = [32, 123.33, 214.67, 306];
const ROWS = [74, 172, 270, 368, 466, 564];
const ICON = 64;
const Square: React.FC<{ x: number; y: number }> = ({ x, y }) => (
  <div style={abs({ left: x, top: y, width: ICON, height: ICON, borderRadius: ICON * 0.225, background: "rgba(255,255,255,0.40)", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.55), 0 4px 10px rgba(124,92,214,0.06)" })} />
);
/** Dawn Blush wallpaper, a 4×6 grid of plain rounded squares (the widgets take the top-left ones), the dock */
export const Springboard: React.FC<{ f: number }> = ({ f }) => {
  const z = 1.06 - 0.06 * inOut(f, WIPE[0], WIPE[1] + 12);
  const icons: [number, number][] = [];
  ROWS.forEach((y, r) => COLS.forEach((x, c) => (r < 2 || (r < 4 && c < 2) ? null : icons.push([x, y]))));
  return (
    <div style={abs({ inset: 0, background: `linear-gradient(${diag(402, 874)}deg, ${C.dawn.join(", ")})` })}>
      <div style={abs({ inset: 0, transform: `scale(${z})`, transformOrigin: "50% 45%" })}>
        {icons.map(([x, y]) => (
          <Square key={`${x}-${y}`} x={x} y={y} />
        ))}
        <div style={abs({ left: 14, top: 776, width: 374, height: 88, borderRadius: 34, background: "rgba(255,255,255,0.32)", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.5)" })} />
        <Heart x={COLS[0] + ICON / 2} y={788 + ICON / 2} size={ICON} />
        {COLS.slice(1).map((x) => (
          <Square key={x} x={x} y={788} />
        ))}
      </div>
      <StatusBar dark />
    </div>
  );
};

// ── the Android 2×2 widget: the love tree's night sky with today's heart constellation ─────────────────────────────
const STARS: [number, number, number, number][] = [
  [0.19, 0.38, 2, 0.7],
  [0.41, 0.22, 1.5, 0.6],
  [0.79, 0.47, 1.5, 0.6],
  [0.13, 0.63, 1.5, 0.6],
  [0.55, 0.72, 1.5, 0.5],
];
const SKY_PTS: [number, number][] = [[26, 44], [8, 26], [10, 10], [26, 16], [42, 10], [44, 26]];
const SKY_DOTS: [number, string][] = [[2.6, C.white], [2.2, C.white], [2.6, C.lavender], [2, C.white], [2.6, BLUSH], [2.2, C.white]];
/** the 2×2 widget in dp (158), drawn at `scale` film px per dp */
export const AndroidWidget: React.FC<{ scale: number; style?: CSSProperties }> = ({ scale, style }) => (
  <div style={abs({ width: 158 * scale, height: 158 * scale, ...style })}>
    <div
      style={abs({
        left: 0,
        top: 0,
        width: 158,
        height: 158,
        transformOrigin: "0 0",
        transform: `scale(${scale})`,
        borderRadius: 28,
        overflow: "hidden",
        background: [
          "radial-gradient(110px circle at 85% 10%, rgba(167,139,250,0.35), rgba(167,139,250,0) 100%)",
          "radial-gradient(120px circle at 5% 100%, rgba(255,107,157,0.28), rgba(255,107,157,0) 100%)",
          "linear-gradient(135deg, #1A1A2E 0%, #241F45 55%, #352A5E 100%)",
        ].join(", "),
        boxShadow: "0 18px 40px rgba(26,26,46,0.22)",
      })}
    >
      <svg width={158} height={158} style={abs({ left: 0, top: 0 })}>
        {STARS.map(([x, y, r, a]) => (
          <circle key={x} cx={x * 158} cy={y * 158} r={r} fill="#FFFFFF" fillOpacity={a} />
        ))}
        <g transform={`translate(${158 - 14 - 52} 12)`}>
          <polygon points={SKY_PTS.map((p) => p.join(",")).join(" ")} fill="none" stroke="rgba(255,255,255,0.35)" strokeWidth={1} strokeLinejoin="round" />
          {SKY_PTS.map(([x, y], i) => (
            <circle key={i} cx={x} cy={y} r={SKY_DOTS[i][0]} fill={SKY_DOTS[i][1]} />
          ))}
        </g>
      </svg>
      <SmallFace dark />
    </div>
  </div>
);
