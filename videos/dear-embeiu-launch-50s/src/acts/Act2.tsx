// Act 2 · Người ấy (f 240–719). The partner's dot swoops into an iOS notification while the number steps back; three
// lavender leader lines pull the day's rows out of it into the today sheet (his side filled, yours empty with rose
// carets); you pick the same mood; Gửi opens both answers; the whole sheet compresses into one navy cell (H720).
// Every position is a pure function of the GLOBAL frame; the functions below are shared by the pieces and their blur.
import type { CSSProperties, ReactNode } from "react";
import { Easing, useCurrentFrame } from "remotion";
import { A2 } from "../timeline/cues.ts";
import { T } from "../copy/strings.ts";
import { C, RADIUS, colW, colX } from "../lib/tokens.ts";
import { ease, lerp, press, settle } from "../lib/ease.ts";
import { COUNTER, COUNTER_DOT, Counter } from "../story/Counter.tsx";
import { Blur } from "../components/Blur.tsx";
import { Dot } from "../components/Dot.tsx";
import { HEART_PATH, Heart } from "../components/Heart.tsx";
import { Pill } from "../components/Card.tsx";
import { Caption } from "../components/Text.tsx";
import { A1Caption, a1CaptionExit, Camera, dropY } from "./a1/shared.tsx";
import * as K from "./a2/timing.ts";

const IN_OUT = Easing.inOut(Easing.cubic);
const IN = Easing.in(Easing.cubic);
const SNAP = 20; // px/frame: above this a piece is motion-blurred (BRIEF §7.4)

type Rect = { x: number; y: number; w: number; h: number };
const mixRect = (a: Rect, b: Rect, t: number): Rect => ({ x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t), w: lerp(a.w, b.w, t), h: lerp(a.h, b.h, t) });
/** fastest corner of a moving rect, px per frame (sampled across the 180° shutter) */
const speedOf = (at: (f: number) => Rect, f: number) => {
  const a = at(f - 0.5), b = at(f + 0.5);
  return Math.max(Math.hypot(b.x - a.x, b.y - a.y), Math.hypot(b.x + b.w - a.x - a.w, b.y + b.h - a.y - a.h));
};
const hex = (c: string) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));
const rgba = (c: string, a: number) => `rgba(${hex(c).join(",")},${a})`;
const mix = (a: string, b: string, t: number) => `#${hex(a).map((v, i) => Math.round(lerp(v, hex(b)[i], t)).toString(16).padStart(2, "0")).join("")}`;

// ── geometry (film px) ────────────────────────────────────────────────────────────────────────────────────────────
const CELL: Rect = { x: 120, y: 540, w: 28, h: 28 }; // H720: the first streak cell (radius 6, navy)
const CARD: Rect = { x: 120, y: 520, w: 560, h: 124 }; // the notification, under the stepped-back number
const AV = { cx: CARD.x + 28 + 28, cy: CARD.y + CARD.h / 2, r: 28 }; // its 56 px app-icon slot = the dot's place
const SX = colX(5), SW = colW(7), SY = 250; // the today sheet: 830, 970 wide, top 250
const HB = 56, ROW_H = 120, PAD = 32; // header band, rows, inner padding (sheet-local)
const L_YOU = 312, L_OTHER = 612; // the BẠN / TUẤN lanes (sheet-local x), after the 260 px row label
const TAG_Y = 22, VALUE_CY = 76; // a lane's 16 px tag (top) and its 26 px value line (centre), row-local
const TILE = 112, PITCH = 120; // the mood tiles, 8 across the row
const tileX = (k: number) => (SW - 8 * TILE - 7 * (PITCH - TILE)) / 2 + k * PITCH;
const ANS = { top: 108, aH: 86, gap: 8, bH: 118, gap2: 12, bothH: 36, foot: 16, x: L_YOU, w: SW - PAD - L_YOU }; // the unfolded question row

// ── timing as pure functions ──────────────────────────────────────────────────────────────────────────────────────
const camAt = (f: number) => 1.04 - 0.04 * ease(f, K.CAM[0], K.CAM[1], IN_OUT);
const stepAt = (f: number) => {
  const e = ease(f, K.STEP[0], K.STEP[1], Easing.out(Easing.sin)); // a recoil: quick off the contact, settling
  return { y: lerp(COUNTER.hero.y, 160, e), s: lerp(1, 0.55, e), o: lerp(1, 0.6, e) };
};
const counterRect = (f: number): Rect => {
  const { y, s } = stepAt(f);
  return { x: COUNTER.hero.x, y, w: 800 * s, h: 560 * s }; // the number's far corner leads the step-back
};
const dotR = (f: number) => lerp(14, AV.r, ease(f, K.GROW[0], K.GROW[1]));
/** the dot's swoop: a quadratic arc from its landing spot, under the small number, arriving level into the slot */
const dotAt = (f: number) => {
  const t = ease(f, A2.fly[0], A2.fly[1], IN_OUT), u = 1 - t;
  const [x0, y0, cx, cy] = [COUNTER_DOT.x, dropY(f), 560, AV.cy];
  return { x: u * u * x0 + 2 * u * t * cx + t * t * AV.cx, y: u * u * y0 + 2 * u * t * cy + t * t * AV.cy };
};
const dotRect = (f: number): Rect => {
  const p = dotAt(f), r = dotR(f);
  return { x: p.x - r, y: p.y - r, w: 2 * r, h: 2 * r };
};
const C0 = A2.compress[0];

const uA = (f: number) => ease(f, A2.answerYou, A2.answerYou + K.UNFOLD);
const uB = (f: number) => ease(f, A2.answerOther, A2.answerOther + K.UNFOLD);
const uC = (f: number) => ease(f, A2.check, A2.check + 16);
/** the question row grows as it unfolds: + your answer (and the row's foot), + his answer, + the check line */
const row0H = (f: number) => ROW_H + (ANS.top + ANS.aH + ANS.foot - ROW_H) * uA(f) + (ANS.gap + ANS.bH) * uB(f) + (ANS.gap2 + ANS.bothH) * uC(f);
/** row k is pulled in: the sheet lengthens by a row (k ≥ 1) and the row's content is drawn out from the line's tip */
const pull = (k: number, f: number) => (k === 0 ? 1 : ease(f, A2.rows[k], A2.rows[k] + K.PULL));
const drawOut = (k: number, f: number) => ease(f, A2.rowLand[k] - K.PULL, A2.rowLand[k]);
const rowTop = (k: number, f: number) => HB + (k >= 1 ? row0H(f) + 1 : 0) + (k >= 2 ? ROW_H + 1 : 0);
const sheetH = (f: number) => HB + row0H(f) + (ROW_H + 1) * (pull(1, f) + pull(2, f));
const sheetHome = (f: number): Rect => ({ x: SX, y: SY, w: SW * drawOut(0, f), h: sheetH(f) });

/** the compress. The whole picture (card + lines + sheet) shrinks uniformly about its centre while sliding left onto
 *  the cell's centre — a miniature of the day — then its two pieces merge into the cell and turn navy as they land.
 *  Ends exactly on CELL_AT (719). */
const G = { cx: (CARD.x + SX + SW) / 2, cy: (SY + SY + sheetH(C0)) / 2 };
const shrink = (f: number) => ease(f, C0, K.CELL_AT - 3, IN_OUT);
const groupScale = (f: number) => lerp(1, 0.035, shrink(f));
const inGroup = (r: Rect, f: number): Rect => {
  const e = shrink(f), s = groupScale(f);
  const cx = lerp(G.cx, CELL.x + CELL.w / 2, e), cy = lerp(G.cy, CELL.y + CELL.h / 2, e);
  return { x: cx + (r.x - G.cx) * s, y: cy + (r.y - G.cy) * s, w: r.w * s, h: r.h * s };
};
const merge = (f: number) => ease(f, K.CELL_AT - 12, K.CELL_AT, IN_OUT);
const squeeze = (home: Rect, f: number) => mixRect(inGroup(home, f), CELL, merge(f));
const navy = (f: number) => ease(f, K.CELL_AT - 13, K.CELL_AT - 3); // white → navy while still a miniature
const sheetRect = (f: number): Rect => (f >= C0 ? squeeze(sheetHome(C0), f) : sheetHome(f));
const cardRect = (f: number): Rect => (f >= C0 ? squeeze(CARD, f) : mixRect(dotRect(f), CARD, ease(f, K.OPEN[0], K.OPEN[1])));
/** a sheet-local point → world, through the sheet's current rect (identity until the compress) */
const sheetPoint = (x: number, y: number, f: number) => {
  const home = sheetHome(Math.min(f, C0)), r = sheetRect(f);
  return { x: r.x + x * (r.w / SW), y: r.y + y * (r.h / home.h) };
};

// ── type and small pieces ─────────────────────────────────────────────────────────────────────────────────────────
const abs = (x: number, y: number, extra?: CSSProperties): CSSProperties => ({ position: "absolute", left: x, top: y, ...extra });
/** a one-line text block vertically centred on a line (row-local) */
const Line: React.FC<{ x: number; cy: number; h?: number; style?: CSSProperties; children: ReactNode }> = ({ x, cy, h = 44, style, children }) => (
  <div style={{ position: "absolute", left: x, top: cy - h / 2, height: h, display: "flex", alignItems: "center", whiteSpace: "nowrap", ...style }}>{children}</div>
);
const LABEL: CSSProperties = { fontSize: 28, fontWeight: 600, color: C.ink, letterSpacing: "-0.01em" };
const VALUE: CSSProperties = { fontSize: 26, fontWeight: 500, color: C.lavenderDeep, gap: 10 };
const TAG: CSSProperties = { fontSize: 16, fontWeight: 600, color: C.ink2, letterSpacing: "0.1em", lineHeight: "20px", whiteSpace: "nowrap" };
/** 🥹 Nhớ → two spans, so the emoji and its word keep a real gap; other values pass through */
const words = (v: string) => (/^\p{Extended_Pictographic}/u.test(v) ? v.split(" ").map((w, i) => <span key={i}>{w}</span>) : v);
const RowLabel: React.FC<{ k: number }> = ({ k }) => (
  <Line x={PAD} cy={ROW_H / 2} style={LABEL}>
    {T.a2.rows[k].label}
  </Line>
);
/** a lane's tag: BẠN / TUẤN, 16 px tracked, its role dot hanging in the gutter so the word aligns with the value */
const Tag: React.FC<{ x: number; who: "you" | "other" }> = ({ x, who }) => (
  <div style={abs(x, TAG_Y, { ...TAG })}>
    <div style={abs(-16, 6, { width: 8, height: 8, borderRadius: 4, background: who === "you" ? C.rose : C.lavender })} />
    {who === "you" ? T.couple.youLabel : T.couple.otherLabel}
  </div>
);
const Hairline: React.FC<{ y: number; draw: number; color?: string }> = ({ y, draw, color = "rgba(160,160,176,0.5)" }) => (
  <div style={abs(PAD, y, { width: (SW - 2 * PAD) * draw, height: 1, background: color })} />
);

/** a white card whose rect animates; content is laid out for `home` and either revealed (fixed) or, from C0, squeezed */
const Sheet: React.FC<{ rect: Rect; home: Rect; f: number; radius: number; alpha?: number; children: ReactNode }> = ({ rect, home, f, radius, alpha = 1, children }) => {
  const squeezing = f >= C0;
  const fade = squeezing ? 1 - ease(f, K.CELL_AT - 9, K.CELL_AT - 4) : 1;
  const s = squeezing ? Math.min(rect.w / home.w, rect.h / home.h) : 1;
  const n = navy(f);
  const [r, g, b] = hex(C.white).map((v, i) => Math.round(lerp(v, hex(C.ink)[i], n)));
  const k = squeezing ? groupScale(f) : 1;
  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: Math.max(0, rect.w),
        height: Math.max(0, rect.h),
        borderRadius: squeezing ? lerp(radius * k, 6, merge(f)) : radius,
        background: `rgba(${r},${g},${b},${lerp(alpha, 1, n)})`,
        boxShadow: fade > 0.01 ? `0 ${8 * k}px ${24 * k}px rgba(255, 107, 157, ${0.12 * fade})` : undefined,
        overflow: "hidden",
      }}
    >
      <div
        style={{
          position: "absolute",
          left: squeezing ? 0 : home.x - rect.x,
          top: squeezing ? (rect.h - home.h * s) / 2 : home.y - rect.y,
          width: home.w,
          height: home.h,
          transformOrigin: "0 0",
          transform: squeezing ? `scale(${s})` : undefined,
          opacity: fade,
        }}
      >
        {children}
      </div>
    </div>
  );
};

// ── the number, stepping back ─────────────────────────────────────────────────────────────────────────────────────
const SteppedCounter: React.FC = () => {
  const f = useCurrentFrame();
  const { y, s, o } = stepAt(f);
  return <Counter x={COUNTER.hero.x} y={y} scale={s} opacity={o} f={f} />;
};

// ── the partner's dot → the notification ──────────────────────────────────────────────────────────────────────────
const FlyingDot: React.FC = () => {
  const f = useCurrentFrame();
  const p = dotAt(f);
  return <Dot x={p.x} y={p.y} r={dotR(f)} who="other" glow={0.35 * (1 - ease(f, K.GROW[0], K.OPEN[0]))} />;
};
const Notification: React.FC = () => {
  const f = useCurrentFrame();
  const rect = cardRect(f);
  const r = f >= C0 ? AV.r : dotR(f);
  const p = T.a2.push;
  const [ax, ay] = [AV.cx - CARD.x, AV.cy - CARD.y];
  return (
    <Sheet rect={rect} home={CARD} f={f} radius={f >= C0 ? RADIUS.card : Math.min(RADIUS.card, rect.h / 2)} alpha={0.92}>
      <div style={abs(ax - r, ay - r, { width: 2 * r, height: 2 * r, borderRadius: "50%", background: C.lavender })} />
      <div style={abs(ax + 20 - 14, ay + 20 - 14, { width: 28, height: 28, borderRadius: 8, background: C.white })} />
      <Heart x={ax + 20} y={ay + 20} size={23} />
      <div style={abs(102, 30, { width: CARD.w - 102 - 28, height: 30, display: "flex", alignItems: "baseline", justifyContent: "space-between", whiteSpace: "nowrap" })}>
        <span style={{ fontSize: 24, fontWeight: 600, color: C.ink }}>{p.title}</span>
        <span style={{ fontSize: 18, fontWeight: 500, color: C.ink3 }}>{p.when}</span>
      </div>
      <div style={abs(102, 66, { fontSize: 22, fontWeight: 500, color: C.ink2, whiteSpace: "nowrap", lineHeight: "28px" })}>{p.body}</div>
    </Sheet>
  );
};

// ── leader lines (1 px lavender) from the card's right edge to each row's left edge ───────────────────────────────
const Leaders: React.FC<{ f: number }> = ({ f }) => {
  const c = cardRect(f);
  const gone = ease(f, K.CELL_AT - 14, K.CELL_AT - 8, IN); // they let go as the pieces merge, from the card's end
  return (
    <svg style={abs(0, 0)} width={1920} height={1080}>
      {A2.rows.map((start, k) => {
        if (f < start) return null;
        const end = sheetPoint(0, rowTop(k, Math.min(f, C0)) + ROW_H / 2, f);
        const [x0, y0, x1, y1] = [c.x + c.w, c.y + c.h / 2, end.x, end.y];
        const d = (x1 - x0) * 0.55;
        return (
          <path
            key={k}
            d={`M ${x0} ${y0} C ${x0 + d} ${y0}, ${x1 - d} ${y1}, ${x1} ${y1}`}
            fill="none"
            stroke={C.lavender}
            strokeWidth={1}
            pathLength={1}
            strokeDasharray="1 1"
            strokeDashoffset={gone > 0 ? -gone : 1 - ease(f, start, start + K.LEADER)}
          />
        );
      })}
    </svg>
  );
};

// ── the mood row ──────────────────────────────────────────────────────────────────────────────────────────────────
const CARET_LX = L_YOU; // a caret's x in its lane (sheet-local); its line is VALUE_CY
const foldEnd = (k: number) => A2.matched + 5 + 0.6 * Math.abs(k - T.a2.picked);
const foldAt = (k: number, f: number) => (k === T.a2.picked ? 0 : ease(f, A2.matched, foldEnd(k), IN)); // the fan closes into the pick
const dealAt = (k: number, f: number) => settle(f, A2.moods[k], { stiffness: 520 });
const tileCx = (k: number, f: number) => lerp(lerp(CARET_LX, tileX(k) + TILE / 2, dealAt(k, f)), tileX(T.a2.picked) + TILE / 2, foldAt(k, f));
const EMOJI = { x: L_YOU, size: 34 }; // the matched line's emoji slot (row-local), centred on VALUE_CY
const morph = (f: number) => ease(f, K.MORPH[0], K.MORPH[1], IN_OUT);

const MoodTile: React.FC<{ k: number }> = ({ k }) => {
  const f = useCurrentFrame();
  const [emoji, label] = T.a2.moods[k];
  const picked = k === T.a2.picked;
  const deal = dealAt(k, f), fold = foldAt(k, f), m = picked ? morph(f) : 0;
  const s = lerp(0.3, 1, deal) * lerp(1, 0.55, fold);
  // the picked tile folds down into the emoji slot of the matched line: its box shrinks away, its emoji stays
  const home: Rect = { x: tileCx(k, f) - TILE / 2, y: (ROW_H - TILE) / 2, w: TILE, h: TILE };
  const slot: Rect = { x: EMOJI.x, y: VALUE_CY - EMOJI.size / 2, w: EMOJI.size, h: EMOJI.size };
  const r = mixRect(home, slot, m);
  const tint = picked ? mix(C.tint, "#FFE8EE", ease(f, A2.pick, A2.pick + 8)) : C.tint;
  return (
    <div
      style={abs(r.x, r.y, {
        width: r.w,
        height: r.h,
        borderRadius: lerp(24, 8, m),
        background: rgba(tint, 1 - m), // the box melts away, the emoji stays
        opacity: picked ? 1 : 1 - ease(f, A2.matched + 2, foldEnd(k), IN),
        transform: `scale(${s})`,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: lerp(8, 0, m),
      })}
    >
      <div style={{ position: "relative", fontSize: lerp(44, 28, m), lineHeight: 1 }}>{emoji}</div>
      {m < 1 && (
        <div style={{ position: "relative", fontSize: 18, fontWeight: 600, lineHeight: "22px", color: picked ? mix(C.ink2, C.roseDeep, ease(f, A2.pick, A2.pick + 8)) : C.ink2, opacity: 1 - ease(f, K.MORPH[0], K.MORPH[0] + 6), height: lerp(22, 0, m), overflow: "hidden" }}>
          {label}
        </div>
      )}
    </div>
  );
};
const tileSpeed = (k: number, f: number) => Math.abs(tileCx(k, f + 0.5) - tileCx(k, f - 0.5));

const MoodRow: React.FC<{ f: number }> = ({ f }) => {
  const base = f < A2.moodJump + 6;
  const out = ease(f, A2.moodJump, A2.moodJump + 5, IN); // leaves as the carets jump in (exits are quicker than entries)
  const back = ease(f, K.MORPH[0] + 4, K.MORPH[1] + 2);
  const pick = T.a2.picked;
  const ring = ease(f, A2.pick, A2.pick + K.RING);
  const m = morph(f);
  const mark = f >= K.MARK ? settle(f, K.MARK, { zeta: 0.75, stiffness: 420 }) : 0;
  const read = ease(f, K.MORPH[1] - 6, K.MORPH[1] + 12);
  const ringBox = mixRect({ x: tileX(pick) - 3, y: 1, w: TILE + 6, h: ROW_H - 2 }, { x: EMOJI.x - 3, y: VALUE_CY - EMOJI.size / 2 - 3, w: EMOJI.size + 6, h: EMOJI.size + 6 }, m);
  return (
    <>
      {base && (
        <div style={abs(0, -56 * out, { width: SW, height: ROW_H, opacity: 1 - out })}>
          <RowLabel k={1} />
          <Tag x={L_YOU} who="you" />
          <Tag x={L_OTHER} who="other" />
          <Line x={L_OTHER} cy={VALUE_CY} style={VALUE}>{words(T.a2.rows[1].other)}</Line>
        </div>
      )}
      {f >= K.MORPH[0] + 4 && (
        <div style={abs(0, 44 * (1 - back), { width: SW, height: ROW_H })}>
          <RowLabel k={1} />
          {/* the two tags become one: BẠN ♥ TUẤN, as the app's matched card writes it */}
          <div style={abs(L_YOU, TAG_Y, { ...TAG, display: "flex", alignItems: "center", gap: 10 })}>
            {T.couple.youLabel}
            <svg width={16} height={16} viewBox="150 150 724 620">
              <path d={HEART_PATH} fill={C.rose} />
            </svg>
            {T.couple.otherLabel}
          </div>
        </div>
      )}
      {f >= A2.moods[0] &&
        T.a2.moods.map((_, k) => (
          <Blur key={k} on={tileSpeed(k, f) > SNAP}>
            <MoodTile k={k} />
          </Blur>
        ))}
      {f >= A2.pick && m < 1 && (
        <svg style={abs(0, 0, { opacity: 1 - ease(f, K.MORPH[0], K.MORPH[1] - 4) })} width={SW} height={ROW_H}>
          <rect x={ringBox.x} y={ringBox.y} width={ringBox.w} height={ringBox.h} rx={lerp(27, 11, m)} fill="none" stroke={C.rose} strokeWidth={2} pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - ring} />
        </svg>
      )}
      {mark > 0 && (
        <div style={abs(lerp(tileX(pick) + TILE - 12, EMOJI.x + EMOJI.size - 4, m) - 10, lerp((ROW_H - TILE) / 2 + 12, VALUE_CY - EMOJI.size / 2 + 4, m) - 10, { width: 20, height: 20, borderRadius: "50%", background: C.white, transform: `scale(${mark * lerp(1, 0.7, m)})`, display: "flex", alignItems: "center", justifyContent: "center" })}>
          <div style={{ width: 14, height: 14, borderRadius: "50%", background: C.lavender }} />
        </div>
      )}
      {f >= K.MORPH[1] - 6 && (
        <Line x={EMOJI.x + EMOJI.size + 14} cy={VALUE_CY} style={{ gap: 18, clipPath: `inset(-10px ${(1 - read) * 100}% -10px 0)` }}>
          <span style={{ fontSize: 26, fontWeight: 600, color: C.ink }}>{T.a2.moods[pick][1]}</span>
          <span style={{ fontSize: 26, fontWeight: 600, color: C.rose }}>{T.a2.matched}</span>
        </Line>
      )}
    </>
  );
};

// ── the question row ──────────────────────────────────────────────────────────────────────────────────────────────
const SEND = { x: L_YOU + 26, w: 92, h: 56 };
const QuestionRow: React.FC<{ f: number }> = ({ f }) => {
  const lanesOut = ease(f, A2.answerYou - 6, A2.answerYou, IN); // sent: the lanes scroll away as the pill springs back…
  const qIn = ease(f, A2.answerYou - 1, A2.answerYou + 11); // …then the question rises into the row
  const send = ease(f, K.SEND_IN[0], K.SEND_IN[1]);
  const block = (u: number) => ({ transform: `translateY(${-16 * (1 - u)}px)` });
  const check = ease(f, A2.check, A2.check + K.CHECK);
  const both = ease(f, A2.check + 2, A2.check + 14); // read before the compress takes it
  const field = (tint: string, top: number, h: number, u: number, label: string, labelColor: string, text: string) => (
    <div style={abs(ANS.x, top, { width: ANS.w, height: h, borderRadius: 20, background: tint, padding: "14px 22px", boxSizing: "border-box", ...block(u) })}>
      <div style={{ fontSize: 18, fontWeight: 600, color: labelColor, lineHeight: "23px" }}>{label}</div>
      <div style={{ marginTop: 4, fontSize: 24, fontWeight: 500, color: C.ink, lineHeight: "31px", whiteSpace: "nowrap" }}>
        {text.split(/(?<=,) /).map((part, i) => (
          <div key={i}>{part}</div>
        ))}
      </div>
    </div>
  );
  return (
    <>
      <RowLabel k={0} />
      <div style={abs(0, 0, { width: SW, height: ROW_H, overflow: "hidden" })}>
        {lanesOut < 1 && (
          <div style={abs(0, -60 * lanesOut, { width: SW, height: ROW_H, opacity: 1 - lanesOut })}>
            <Tag x={L_YOU} who="you" />
            {f >= K.SEND_IN[0] && (
              <Pill
                text={T.a2.send}
                size={20}
                scale={press(f, A2.press)}
                style={{ left: SEND.x, top: VALUE_CY - SEND.h / 2, width: lerp(SEND.h, SEND.w, send), height: SEND.h, padding: 0, overflow: "hidden", transformOrigin: "50% 50%" }}
              />
            )}
            <Tag x={L_OTHER} who="other" />
            <Line x={L_OTHER} cy={VALUE_CY} style={VALUE}>{T.a2.rows[0].other}</Line>
          </div>
        )}
        {f >= A2.answerYou - 1 && (
          <div style={abs(L_YOU, 0, { width: SW - PAD - L_YOU, height: ROW_H, display: "flex", alignItems: "center", transform: `translateY(${24 * (1 - qIn)}px)` })}>
            <div style={{ fontSize: 24, fontWeight: 600, color: C.ink, lineHeight: "31px", textWrap: "balance" } as CSSProperties}>{T.a2.question}</div>
          </div>
        )}
      </div>
      {f >= A2.answerYou && field("#FFEDF0", ANS.top, ANS.aH, uA(f), T.a2.answerYou.label, C.roseDeep, T.a2.answerYou.text)}
      {f >= A2.answerOther && field("#F6F3FE", ANS.top + ANS.aH + ANS.gap, ANS.bH, uB(f), T.a2.answerOther.label, C.lavenderDeep, T.a2.answerOther.text)}
      {f >= A2.check && (
        <div style={abs(ANS.x, ANS.top + ANS.aH + ANS.gap + ANS.bH + ANS.gap2, { height: ANS.bothH, display: "flex", alignItems: "center", gap: 12 })}>
          <svg width={32} height={32} viewBox="0 0 32 32" fill="none">
            <path d="M6 16.5l6.6 6.6L26 9.5" stroke={C.rose} strokeWidth={2.75} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - check} />
          </svg>
          <span style={{ fontSize: 22, fontWeight: 600, color: C.ink, whiteSpace: "nowrap", clipPath: `inset(-8px ${(1 - both) * 100}% -8px 0)` }}>{T.a2.both}</span>
        </div>
      )}
    </>
  );
};

const SleepRow: React.FC = () => (
  <>
    <RowLabel k={2} />
    <Tag x={L_YOU} who="you" />
    <Tag x={L_OTHER} who="other" />
    <Line x={L_OTHER} cy={VALUE_CY} style={VALUE}>{T.a2.rows[2].other}</Line>
  </>
);

// ── the today sheet: one card, a header band and three 120 px rows with 1 px rules, lengthening row by row ─────────
const TodaySheet: React.FC = () => {
  const f = useCurrentFrame();
  const g = Math.min(f, C0);
  const home = { ...sheetHome(g), w: SW };
  const matched = ease(f, A2.matched, A2.matched + 12);
  const band = (k: number, children: ReactNode, extra?: CSSProperties) => (
    <div style={abs(0, rowTop(k, g), { width: SW, height: k === 0 ? row0H(g) : ROW_H, overflow: "hidden", ...extra })}>
      <div style={{ position: "absolute", inset: 0, clipPath: k === 0 ? undefined : `inset(-2px ${(1 - drawOut(k, g)) * 100}% -2px 0)` }}>{children}</div>
    </div>
  );
  return (
    <Sheet rect={sheetRect(f)} home={home} f={f} radius={Math.min(RADIUS.card, sheetRect(f).w / 2)}>
      <div style={abs(PAD, 22, { fontSize: 18, fontWeight: 600, color: C.ink2, letterSpacing: "0.08em", lineHeight: "22px", whiteSpace: "nowrap" })}>{T.a2.header}</div>
      {band(0, <QuestionRow f={f} />)}
      {f >= A2.rows[1] && <Hairline y={rowTop(1, g) - 1} draw={drawOut(1, g)} />}
      {f >= A2.rows[1] && band(1, <MoodRow f={f} />, { background: mix("#FFFFFF", "#FFF6F8", matched) })}
      {f >= A2.rows[2] && <Hairline y={rowTop(2, g) - 1} draw={drawOut(2, g)} />}
      {/* the one rose hairline: drawn under the matched mood row, and it stays */}
      {f >= A2.matched && <Hairline y={rowTop(2, g) - 1} draw={ease(f, A2.matched, A2.matched + 14)} color={C.rose} />}
      {f >= A2.rows[2] && band(2, <SleepRow />)}
    </Sheet>
  );
};

// ── the rose carets: you, in each empty slot ──────────────────────────────────────────────────────────────────────
/** a caret: visible [from, to), solid through `solid` (a jump), otherwise blinking 30 on / 30 off from `since` */
type CaretPlan = { from: number; to: number; since: number; solid: readonly [number, number]; at: (f: number) => { x: number; y: number } };
const laneY = (k: number, f: number) => SY + rowTop(k, f) + VALUE_CY;
const hop = (a: { x: number; y: number }, b: { x: number; y: number }, t: number) => ({ x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t) - 22 * Math.sin(Math.PI * t) });
const jumpT = (f: number, at: number) => ease(f, at, at + K.JUMP, IN_OUT);
const CX = SX + CARET_LX;
const CARETS: CaretPlan[] = [
  ...[0, 2].map((k) => ({
    from: A2.carets,
    to: A2.moodJump + K.JUMP,
    since: A2.carets,
    solid: [A2.moodJump, A2.moodJump + K.JUMP] as const,
    at: (f: number) => hop({ x: CX, y: laneY(k, f) }, { x: CX, y: laneY(1, f) }, jumpT(f, A2.moodJump)),
  })),
  { from: A2.carets, to: A2.moodJump + K.JUMP + 3, since: A2.carets, solid: [A2.moodJump, A2.moodJump + K.JUMP + 3] as const, at: (f: number) => ({ x: CX, y: laneY(1, f) }) },
  {
    from: K.BACK,
    to: A2.press + 4,
    since: K.BACK + K.JUMP,
    solid: [K.BACK, K.BACK + K.JUMP] as const,
    at: (f: number) => hop({ x: SX + EMOJI.x + EMOJI.size / 2, y: laneY(1, f) - 24 }, { x: CX, y: laneY(0, f) }, jumpT(f, K.BACK)),
  },
];
const CaretMark: React.FC<{ plan: CaretPlan }> = ({ plan }) => {
  const f = useCurrentFrame();
  const p = plan.at(f);
  const on = (f >= plan.solid[0] && f < plan.solid[1]) || (f >= plan.since && Math.floor((f - plan.since) / 30) % 2 === 0);
  return <div style={abs(Math.round(p.x) - 1, p.y - 15, { width: 2, height: 30, background: C.rose, opacity: on ? 1 : 0 })} />;
};
const Carets: React.FC<{ f: number }> = ({ f }) => (
  <>
    {CARETS.filter((c) => f >= c.from && f < c.to).map((c, i) => {
      const a = c.at(f - 0.5), b = c.at(f + 0.5);
      return (
        <Blur key={i} on={Math.hypot(b.x - a.x, b.y - a.y) > SNAP}>
          <CaretMark plan={c} />
        </Blur>
      );
    })}
  </>
);

// ── the act ───────────────────────────────────────────────────────────────────────────────────────────────────────
export const Act2: React.FC = () => {
  const f = useCurrentFrame();
  if (f >= K.CELL_AT) {
    // H720: the sheet IS the cell now; the number stays small, dim and ticking. Nothing else.
    return (
      <Camera s={1}>
        <SteppedCounter />
        <div style={abs(CELL.x, CELL.y, { width: CELL.w, height: CELL.h, borderRadius: 6, background: C.ink })} />
      </Camera>
    );
  }
  const capIn = ease(f, A2.caption, A2.caption + 16);
  const capOut = ease(f, K.CAP_OUT[0], K.CAP_OUT[1], IN);
  return (
    <Camera s={camAt(f)}>
      <Blur on={speedOf(counterRect, f) > SNAP}>
        <SteppedCounter />
      </Blur>
      {f < K.OLD_OUT[1] && <A1Caption f={f} exit={a1CaptionExit(f, K.OLD_OUT[0], K.OLD_OUT[1])} />}
      <Leaders f={f} />
      {f >= A2.rows[0] + K.LEADER && (
        <Blur on={speedOf(sheetRect, f) > SNAP}>
          <TodaySheet />
        </Blur>
      )}
      <Carets f={f} />
      {f < K.OPEN[0] ? (
        <Blur on={speedOf(dotRect, f) > SNAP}>
          <FlyingDot />
        </Blur>
      ) : (
        <Blur on={speedOf(cardRect, f) > SNAP}>
          <Notification />
        </Blur>
      )}
      {f >= A2.caption && <Caption text={T.a2.caption} x={120} y={930} style={{ clipPath: `inset(-12px ${(1 - capIn) * 100}% -12px ${capOut * 100}%)` }} />}
    </Camera>
  );
};
