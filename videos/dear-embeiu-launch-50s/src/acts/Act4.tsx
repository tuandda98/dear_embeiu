// ACT 4 · "Một ngày" (f 1200–1919), v3 (V3.md § A4). From H1200 the heart tile and its label hold while the phone
// starts up at the left, then shrink away in place; the two dots descend and become the playhead; a ruler 06:00 →
// 24:00 streams in and the day comes to rest on seven moments, one large card at a time (event 2's photo pops out and
// flies into the phone); the tape stops at 24:00 and the caption takes the last card's place; the counter card lifts
// off the phone and lands as the home-screen widget, the small one and the Android 2×2 follow; a navy sheet covers
// the frame for the hard cut at 1920. Never more than two things move at once. Reads the GLOBAL frame.
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { C, PHONE, colX } from "../lib/tokens.ts";
import { ease, lerp, settle } from "../lib/ease.ts";
import { A4 } from "../timeline/cues.ts";
import { typed } from "../timeline/typing.ts";
import { T } from "../copy/strings.ts";
import { CORNER, Counter } from "../story/Counter.tsx";
import { Heart } from "../components/Heart.tsx";
import { Dot } from "../components/Dot.tsx";
import { Phone } from "../components/Phone.tsx";
import { Chip } from "../components/Card.tsx";
import { Caption } from "../components/Text.tsx";
import { Blur } from "../components/Blur.tsx";
import { inOut } from "./a4/parts.tsx";
import { HomeApp } from "./a4/home.tsx";
import { Counters, Day, HEAD, PLAYHEAD, Print, Readout, SLOT, printSpeed, tapeSpeed } from "./a4/day.tsx";
import { AndroidWidget, LiftCard, SmallWidget, Springboard, liftSpeed } from "./a4/widgets.tsx";
import { WIPE } from "./a4/events.ts";

// ── H1200: the heart tile and its label hold, then shrink away in place (about the tile's centre) ──────────────────
const BADGE = T.a3.labelBadge;
const REST = T.a3.labelFlowers;
const shrink = (f: number) => 1 - ease(f, A4.heartShrink[0], A4.heartShrink[1], (t) => t * t); // ease-in: it falls away
const HeartExit: React.FC<{ f: number }> = ({ f }) => {
  const k = shrink(f);
  if (k <= 0) return null;
  return (
    <>
      <Heart x={960} y={460} size={300 * k} draw={1} fill={1} tile={1} />
      {/* Act 3's label at H1200 (28 px, line 36, box top 642, centred on x 960), scaled with the tile */}
      <div
        style={{
          position: "absolute",
          left: 0,
          width: 1920,
          top: 642,
          height: 36,
          display: "flex",
          justifyContent: "center",
          alignItems: "baseline",
          fontSize: 28,
          lineHeight: "36px",
          fontWeight: 600,
          whiteSpace: "pre",
          transformOrigin: "960px -182px",
          transform: k < 1 ? `scale(${k})` : undefined,
        }}
      >
        <span style={{ color: C.ink2, letterSpacing: "0.1em" }}>{BADGE}</span>
        <span style={{ color: C.ink }}>
          {" "}
          {REST}
        </span>
      </div>
    </>
  );
};

// ── the two dots descend to the playhead and thin into its needle: rose above, lavender below, on the ruler line ─
const DOTS = [
  { who: "you" as const, from: [820, 150], to: HEAD.mid - 14, top: HEAD.top, bottom: HEAD.mid, color: C.rose },
  { who: "other" as const, from: [1100, 150], to: HEAD.mid + 14, top: HEAD.mid, bottom: HEAD.bottom, color: C.lavender },
];
const [D0, D1] = A4.dots;
const travel = (f: number) => inOut(f, D0, D1 - 6);
const dotSpeed = (f: number) => Math.abs(travel(f + 0.5) - travel(f - 0.5)) * 475;
const Playhead: React.FC = () => {
  const f = useCurrentFrame();
  const u = travel(f);
  const thin = ease(f, D1 - 10, D1);
  return (
    <>
      {DOTS.map((d) => {
        const cx = lerp(d.from[0], PLAYHEAD, u);
        const cy = lerp(d.from[1], d.to, u);
        if (thin <= 0) return <Dot key={d.who} who={d.who} x={cx} y={cy} r={14} />;
        const w = lerp(28, 2, thin);
        return (
          <div key={d.who}>
            {thin < 1 && <Dot who={d.who} x={cx} y={cy} r={14 * (1 - thin) + 1} glow={0.35 * (1 - thin)} opacity={1 - thin} />}
            <div style={{ position: "absolute", left: cx - w / 2, top: lerp(cy - 14, d.top, thin), width: w, height: lerp(28, d.bottom - d.top, thin), borderRadius: 999 * (1 - thin), background: d.color }} />
          </div>
        );
      })}
    </>
  );
};

// ── the phone ──────────────────────────────────────────────────────────────────────────────────────────────────────
const RISE = 1050; // px below its rest: out of frame until A4.phone[0]
const phoneY = (f: number) => 90 + RISE * (1 - settle(f, A4.phone[0], { stiffness: 35, zeta: 1 }));
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

// ── the Android 2×2 lands outside the phone, at its right: the text column, under the caption ─────────────────────
const ANDROID = { size: 300, x: colX(4), y: 560 };
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
      {f < A4.phone[1] + 10 && <Counter x={CORNER.x} y={CORNER.y} scale={CORNER.scale} f={f} opacity={CORNER.opacity} /> /* masked by the rising phone, not faded */}
      {f < A4.heartShrink[1] && <HeartExit f={f} />}
      <Blur on={tapeSpeed(f) > 20}>
        <Day />
      </Blur>
      <Counters f={f} />
      {label && <Chip text={label} size={28} style={{ left: colX(4), top: 162 }} />}
      <Blur on={phoneSpeed(f) > 20}>
        <PhoneRig />
      </Blur>
      <Blur on={dotSpeed(f) > 20}>
        <Playhead /* the dots wait at their H1200 places until A4.dots */ />
      </Blur>
      <Readout f={f} />
      <Blur on={printSpeed(f) > 20}>
        <Print />
      </Blur>
      {f >= A4.caption && (
        <>
          <Caption text={c1} x={SLOT.x} y={SLOT.y} size={64} weight={700} wipe={ease(f, A4.caption, A4.caption + 24)} />
          <Caption text={c2} x={SLOT.x} y={SLOT.y + 77} size={64} weight={700} wipe={ease(f, A4.caption + 10, A4.caption + 36)} />
        </>
      )}
      <Android f={f} />
      <Blur on={coverSpeed(f) > 20}>
        <Cover />
      </Blur>
    </AbsoluteFill>
  );
};
