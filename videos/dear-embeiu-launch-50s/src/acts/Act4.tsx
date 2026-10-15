// ACT 4 · "Một ngày" (f 1200–1919). From H1200 (the heart tile, its label, the two dots, the small counter) the heart
// shrinks into the top-left and the phone rises over it and over the counter, showing the app's Home; the two dots
// travel to the right third and stretch into the playhead; a 24-hour ruler streams in and the day runs through the
// playhead, each event dropping a card on it while the matching card lights on the phone; the tape stops at 24:00,
// the caption wipes in, and the counter card lifts off the phone to land as the home-screen widget. Hard cut at 1920.
// Reads the GLOBAL frame.
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { measureText } from "@remotion/layout-utils";
import { C, FONT, PHONE, colX } from "../lib/tokens.ts";
import { ease, lerp, settle } from "../lib/ease.ts";
import { A4 } from "../timeline/cues.ts";
import { typed } from "../timeline/typing.ts";
import { T } from "../copy/strings.ts";
import { Counter } from "../story/Counter.tsx";
import { Heart } from "../components/Heart.tsx";
import { Dot } from "../components/Dot.tsx";
import { Phone } from "../components/Phone.tsx";
import { Chip } from "../components/Card.tsx";
import { Caption } from "../components/Text.tsx";
import { Blur } from "../components/Blur.tsx";
import { inOut } from "./a4/parts.tsx";
import { HomeApp } from "./a4/home.tsx";
import { Counters, Day, PLAYHEAD, Readout } from "./a4/day.tsx";
import { AndroidWidget, LiftCard, SmallWidget, Springboard, liftSpeed } from "./a4/widgets.tsx";
import { WIPE } from "./a4/events.ts";

const F0 = A4.heartShrink[0]; // 1200

// ── H1200 → the heart shrinks into the top-left (behind the rising phone) and its label recedes ───────────────────
const BADGE = T.a3.labelBadge;
const REST = T.a3.labelFlowers;
/** the label's width, measured in render (the fonts are loaded by then; measureText caches) */
const labelW = () =>
  measureText({ text: BADGE, fontFamily: FONT, fontSize: 18, fontWeight: "600", letterSpacing: "0.1em" }).width +
  measureText({ text: ` ${REST}`, fontFamily: FONT, fontSize: 18, fontWeight: "600" }).width;
const heart = (f: number) => {
  const t = inOut(f, F0, A4.heartShrink[1]);
  // …then it slips down behind the phone's edge (ease-in: it falls in) and is gone by 1272
  return { x: lerp(960, 200, t), y: lerp(460, 120, t) + 64 * ease(f, A4.heartShrink[1] - 8, A4.heartShrink[1] + 12, (u) => u * u), size: lerp(300, 96, t) };
};
const heartSpeed = (f: number) => {
  const a = heart(f - 0.5);
  const b = heart(f + 0.5);
  return Math.hypot(b.x - a.x, b.y - a.y) + Math.abs(b.size - a.size) / 2;
};
const HeartExit: React.FC = () => {
  const f = useCurrentFrame();
  const h = heart(f);
  const k = h.size / 300;
  const gone = ease(f, F0, F0 + 26); // the label wipes out right → left while it follows the tile
  const lw = labelW();
  return (
    <>
      <Heart x={h.x} y={h.y} size={h.size} draw={1} fill={1} tile={1} />
      {gone < 1 && (
        // the same markup as Act 3's label at H1200, moved with the tile and clipped from the right
        <div
          style={{
            position: "absolute",
            left: 0,
            width: 1920,
            top: 660 - 12,
            height: 24,
            display: "flex",
            justifyContent: "center",
            alignItems: "baseline",
            fontSize: 18,
            lineHeight: "24px",
            fontWeight: 600,
            whiteSpace: "pre",
            transformOrigin: "960px 12px",
            transform: f > F0 ? `translate(${h.x - 960}px, ${h.y + 200 * k - 660}px) scale(${k})` : undefined,
            clipPath: `inset(0 ${960 - lw / 2 + lw * gone}px 0 0)`,
          }}
        >
          <span style={{ color: C.ink2, letterSpacing: "0.1em" }}>{BADGE}</span>
          <span style={{ color: C.ink }}>
            {" "}
            {REST}
          </span>
        </div>
      )}
    </>
  );
};

// ── the two dots travel to the right third and meet at the playhead's middle (y 560), then stretch into it: one 2 px
// hairline, rose above (300–560), lavender below (560–820) ─────────────────────────────────────────────────────────
const TOP = 300;
const MID = 560;
const BOTTOM = 820;
const LINES = [
  { who: "you" as const, from: [820, 150], to: MID - 14, color: C.rose },
  { who: "other" as const, from: [1100, 150], to: MID + 14, color: C.lavender },
];
const Playhead: React.FC<{ f: number }> = ({ f }) => {
  const u = inOut(f, F0, F0 + 50);
  const s = inOut(f, F0 + 46, F0 + 90); // fully stretched on the beat the phone settles (1290)
  const thin = ease(f, F0 + 44, F0 + 66);
  return (
    <>
      {LINES.map((d) => {
        const cx = lerp(d.from[0], PLAYHEAD, u);
        const cy = lerp(d.from[1], d.to, u);
        if (f < F0 + 44) return <Dot key={d.who} who={d.who} x={cx} y={cy} r={14} />;
        const w = lerp(28, 2, thin);
        const top = d.who === "you" ? lerp(cy - 14, TOP, s) : MID;
        const bottom = d.who === "you" ? MID : lerp(cy + 14, BOTTOM, s);
        const glow = 0.35 * (1 - thin);
        return (
          <div key={d.who}>
            {glow > 0.01 && <Dot who={d.who} x={cx} y={cy} r={14 * (1 - thin) + 0.5} glow={glow} opacity={1 - thin} />}
            <div style={{ position: "absolute", left: cx - w / 2, top, width: w, height: bottom - top, borderRadius: 999 * (1 - thin), background: d.color }} />
          </div>
        );
      })}
    </>
  );
};

// ── the phone ──────────────────────────────────────────────────────────────────────────────────────────────────────
const RISE = 1050; // px below its rest: fully out of frame at H1200
const phoneY = (f: number) => 90 + RISE * (1 - settle(f, A4.phone[0], { stiffness: 32, zeta: 1 }));
const phoneSpeed = (f: number) => Math.abs(phoneY(f + 0.5) - phoneY(f - 0.5));
const wipe = (f: number) => inOut(f, WIPE[0], WIPE[1]);
const Screen: React.FC = () => {
  const f = useCurrentFrame();
  const w = wipe(f);
  const mask = `linear-gradient(0deg, #000 ${w * 100}%, transparent ${w * 100 + 7}%)`;
  return (
    <>
      {w < 1 && <HomeApp f={f} card={f < A4.lift[0]} />}
      {w > 0 && (
        <div style={{ position: "absolute", inset: 0, WebkitMaskImage: mask, maskImage: mask }}>
          <Springboard f={f} />
        </div>
      )}
      <SmallWidget f={f} />
      <Blur on={liftSpeed(f) > 20}>
        <LiftCard />
      </Blur>
    </>
  );
};
const PhoneRig: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <Phone x={120} y={phoneY(f)} scale={PHONE.hero}>
      <Screen />
    </Phone>
  );
};

// ── the Android 2×2 (240 px) lands beside the phone: the text column, centred on the iOS medium widget ─────────────
const ANDROID = { size: 240, x: colX(4), y: 90 + 13.2 + (74 + 158 / 2) * 1.1 - 120 }; // the medium widget's centre on the phone
const Android: React.FC<{ f: number }> = ({ f }) => {
  if (f < A4.widgetAndroid) return null;
  const p = settle(f, A4.widgetAndroid, { stiffness: 260, zeta: 0.78 });
  return <AndroidWidget scale={ANDROID.size / 158} style={{ left: ANDROID.x, top: ANDROID.y - 44 * (1 - p), opacity: ease(f, A4.widgetAndroid, A4.widgetAndroid + 4) }} />;
};

// ── the cover: a navy sheet rises from the bottom edge over the resting widgets, top at y ≈ 20 on 1919, so the hard
// cut lands on Act 5's navy (critically damped, no bounce; blurred while it is fast) ─────────────────────────────────
const coverTop = (f: number) => 1080 * (1 - settle(f, A4.cover[0], { stiffness: 238, zeta: 1 }));
const coverSpeed = (f: number) => Math.abs(coverTop(f + 0.5) - coverTop(f - 0.5));
const Cover: React.FC = () => {
  const f = useCurrentFrame();
  if (f < A4.cover[0]) return null;
  return <div style={{ position: "absolute", left: 0, top: coverTop(f), width: 1920, height: 1120, borderRadius: "28px 28px 0 0", background: C.ink }} />;
};

export const Act4: React.FC = () => {
  const f = useCurrentFrame();
  const label = typed(A4.label, f);
  const [c1, c2] = T.a4.caption;
  return (
    <AbsoluteFill style={{ background: C.bg }}>
      {f < A4.phone[1] + 10 && <Counter x={120} y={160} scale={0.55} f={f} opacity={0.6} /> /* masked by the rising phone, not faded */}
      {f < A4.heartShrink[1] + 30 && (
        <Blur on={heartSpeed(f) > 20}>
          <HeartExit />
        </Blur>
      )}
      <Day f={f} />
      <Counters f={f} />
      {label && <Chip text={label} size={20} style={{ left: colX(4), top: 404 }} />}
      <Blur on={phoneSpeed(f) > 20}>
        <PhoneRig />
      </Blur>
      <Playhead f={f} />
      <Readout f={f} />
      {f >= A4.caption && (
        <>
          <Caption text={c1} x={colX(4)} y={880} size={56} weight={700} wipe={ease(f, A4.caption, A4.caption + 24)} />
          <Caption text={c2} x={colX(4)} y={947} size={56} weight={700} wipe={ease(f, A4.caption + 10, A4.caption + 36)} />
        </>
      )}
      <Android f={f} />
      <Blur on={coverSpeed(f) > 20}>
        <Cover />
      </Blur>
    </AbsoluteFill>
  );
};
