// The phone's screen in the demo: the REAL recordings (public/clips, iPhone 17 simulator) placed by the edit in
// timeline.ts. Reads the frame itself (useCurrentFrame) so the phone rise can sample it through <Blur>.
import type { CSSProperties } from "react";
import { Freeze, OffthreadVideo, staticFile, useCurrentFrame } from "remotion";
import { lerp } from "../lib/ease.ts";
import { PHONE } from "../lib/tokens.ts";
import { D } from "./strings.ts";
import { SHOTS, shotIndex, shotTime, snap, type ClipName } from "./timeline.ts";

const SW = PHONE.w;
const SH = PHONE.h;
/** the Home's scroll viewport: under the pinned greeting row, above the floating tab bar (measured on the clips) */
const VIEW = { top: 126, bottom: 736 } as const;

/** one frame of a recording at clip time t, filling the 402×874 pt screen */
const ClipFrame: React.FC<{ clip: ClipName; t: number }> = ({ clip, t }) => (
  <Freeze frame={snap(clip, t) * 60}>
    <OffthreadVideo src={staticFile(`clips/${clip}.mp4`)} muted style={{ position: "absolute", left: 0, top: 0, width: SW, height: SH, objectFit: "cover" }} />
  </Freeze>
);

/**
 * The simulator drew the app's inline emoji as "[?]" boxes (see D.emoji). Each patch covers one box (pt, measured on
 * the clip) with the colour around it and sets the app's emoji there, while the clip shows that still layout (`t`, clip
 * seconds). `tile` = the Oẳn tù tì icon tile, redrawn whole (its gradient read off the clip). `clipTop` keeps a patch
 * under the floating tab bar from painting over it.
 */
type Patch = { clip: ClipName; t: [number, number]; x: number; y: number; w: number; h: number; emoji: string; bg?: string; tile?: boolean; clipTop?: number; pad?: number };
const E = D.emoji;
const chip = (x: number, y: number, emoji: string, bg = "#FAF4F7"): Patch => ({ clip: "care", t: [0.95, 7.2], x, y, w: 10.7, h: 12.7, emoji, bg });
const PATCHES: Patch[] = [
  { clip: "home-scroll", t: [2, 5.567], x: 280, y: 511, w: 10, h: 12, emoji: E.sprout, bg: "#58544A" }, // streak chip on the counter card
  { clip: "home-scroll", t: [2, 5.567], x: 220, y: 819, w: 10, h: 12, emoji: E.eyes, bg: "#EBD6E0", clipTop: 823.7 }, // teaser, under the tab bar
  { clip: "question", t: [0.767, 1.867], x: 220, y: 345, w: 10, h: 12, emoji: E.eyes, bg: "#F6F3FE" }, // "Tuấn đã trả lời rồi đó 👀"
  { clip: "question", t: [13.167, 14.95], x: 204.7, y: 800, w: 10.7, h: 12.7, emoji: E.hearts, bg: "#18182D" }, // "Đã gửi câu trả lời của bạn 💞"
  { clip: "mood", t: [0.833, 1.8], x: 32.7, y: 653.3, w: 48, h: 48.4, emoji: E.rps, tile: true },
  { clip: "mood", t: [7.267, 9.6], x: 287.3, y: 395.3, w: 10, h: 12, emoji: E.hearts, bg: "#FDF3F5" }, // "Chúng mình cùng một tâm trạng 💞"
  { clip: "mood", t: [7.267, 9.6], x: 32.7, y: 806.3, w: 48, h: 48.4, emoji: E.rps, tile: true, clipTop: 823.7 },
  // "Em ăn cơm chưa? 🍚" rides under the frosted "THẢO ♥ TUẤN" chip: cover its ghost inside the chip, set the emoji below it
  { clip: "chat", t: [0, 4], x: 173.8, y: 90.6, w: 13.4, h: 6.5, emoji: "", bg: "#F7F2F3", pad: 0 },
  { clip: "chat", t: [0, 4], x: 174.3, y: 88.3, w: 12.4, h: 13.4, emoji: E.rice, bg: "#E8D9DF", clipTop: 97.3 },
  { clip: "chat", t: [0, 4], x: 319.7, y: 364, w: 12.3, h: 14.7, emoji: E.kiss, bg: "#18182D" }, // "Okii, em chọn phim nhé 😚"
  { clip: "chat", t: [0, 4], x: 319.7, y: 534, w: 12.3, h: 14.7, emoji: E.twoHearts, bg: "#18182D" }, // "Yêu anh 💕"
  chip(95.7, 193.7, E.twoHearts, "#FCF4F8"),
  chip(289.3, 193.7, E.drop),
  chip(133.7, 241.7, E.rice),
  chip(314, 241.7, E.moon),
  chip(133.7, 289.7, E.heart),
  chip(295.7, 289.7, E.muscle),
  { clip: "care", t: [0.95, 7.2], x: 245.3, y: 670.3, w: 12.3, h: 14.3, emoji: E.letter, bg: "#A182AD" }, // "Gửi cho người ấy 💌"
];
const EMOJI_FONT = '"Apple Color Emoji", "Noto Color Emoji", sans-serif';

const PatchView: React.FC<{ p: Patch }> = ({ p }) => {
  const pad = p.pad ?? 1.5;
  const body = p.tile ? (
    <div
      style={{
        position: "absolute",
        left: p.x,
        top: p.y,
        width: p.w,
        height: p.h,
        borderRadius: 13,
        background: "linear-gradient(135deg, #FDA168, #FD689C)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: EMOJI_FONT,
        fontSize: 11.5,
        letterSpacing: -1,
        lineHeight: 1,
      }}
    >
      {p.emoji}
    </div>
  ) : (
    <>
      <div style={{ position: "absolute", left: p.x - pad, top: p.y - pad, width: p.w + 2 * pad, height: p.h + 2 * pad, borderRadius: pad, background: p.bg, boxShadow: pad ? `0 0 ${pad}px ${pad}px ${p.bg}` : undefined }} />
      <div style={{ position: "absolute", left: p.x - 0.5, top: p.y + p.h / 2, transform: "translateY(-50%)", fontFamily: EMOJI_FONT, fontSize: p.h / 0.85, lineHeight: 1 }}>{p.emoji}</div>
    </>
  );
  return p.clipTop ? <div style={{ position: "absolute", inset: 0, clipPath: `inset(${p.clipTop}px 0 0 0)` }}>{body}</div> : body;
};

/** a recording frame + the patches that belong to it */
const Layer: React.FC<{ clip: ClipName; t: number; style?: CSSProperties }> = ({ clip, t, style }) => {
  const ts = snap(clip, t);
  return (
    <div style={{ position: "absolute", left: 0, top: 0, width: SW, height: SH, ...style }}>
      <ClipFrame clip={clip} t={ts} />
      {PATCHES.filter((p) => p.clip === clip && ts >= p.t[0] && ts <= p.t[1]).map((p, i) => (
        <PatchView key={i} p={p} />
      ))}
    </div>
  );
};

/** a horizontal band of the screen, [y0, y1) pt */
const Band: React.FC<{ y0: number; y1: number; children: React.ReactNode }> = ({ y0, y1, children }) => (
  <div style={{ position: "absolute", left: 0, top: 0, width: SW, height: SH, clipPath: `inset(${y0}px 0 ${SH - y1}px 0)` }}>{children}</div>
);

/** sine in-out: p(u) and its slope (the peak speed is π/2 × the mean) */
const glide = (u: number) => (1 - Math.cos(Math.PI * u)) / 2;
const glideSlope = (u: number) => (Math.PI / 2) * Math.sin(Math.PI * u);

/**
 * Vertical motion blur for layers moving v pt/frame: a Gaussian with the spread of the 180° shutter's half-frame box
 * (σ = v/2 · 1/√12). Cheaper than sub-frame sampling the video layers and it does not strobe at push speeds.
 */
const Shutter: React.FC<{ v: number }> = ({ v }) => (
  <svg width={0} height={0} style={{ position: "absolute" }}>
    <filter id="demo-shutter" x="0" y="-60%" width="100%" height="220%" colorInterpolationFilters="sRGB">
      <feGaussianBlur stdDeviation={`0 ${(Math.abs(v) / 2 / Math.sqrt(12)).toFixed(2)}`} />
    </filter>
  </svg>
);
/** the filter only while the layer actually moves: a filtered layer is rasterised apart, so a still one would soften */
const shutter = (v: number) => (Math.abs(v) > 1 ? "url(#demo-shutter)" : undefined);

/** the screen content: the shot at this frame, or the join into it */
export const Screen: React.FC = () => {
  const f = useCurrentFrame();
  const i = shotIndex(f);
  const s = SHOTS[i];
  const j = s.join;
  if (!j || i === 0 || f >= s.from + j.dur) return <Layer clip={s.clip} t={shotTime(s, f)} />;
  const prev = SHOTS[i - 1];
  const a = { clip: prev.clip, t: shotTime(prev, s.from) }; // the outgoing screen, held on its last frame
  const b = { clip: s.clip, t: s.t0 }; // the incoming one, held on its first
  const u = Math.min(1, Math.max(0, (f - s.from) / j.dur));
  const p = glide(u);
  const v = ((j.kind === "push" ? SH : j.delta) * glideSlope(u)) / j.dur; // pt per frame
  const blur = shutter(v);
  if (j.kind === "push")
    return (
      <>
        <Shutter v={v} />
        <Layer {...a} style={{ transform: `translateY(${-SH * p}px)`, filter: blur }} />
        <Layer {...b} style={{ transform: `translateY(${SH * (1 - p)}px)`, filter: blur }} />
      </>
    );
  // scroll: both frames ride the same content offset. A's rows [L, U] are where B has the same cards (the app's fixed
  // backdrop differs between the two scroll positions); the A→B seam slides from U to L, soft in the middle and hard
  // at both ends, so the first frame is pure A and the last pure B. The pinned header and the tab-bar band dissolve.
  const o = j.delta * p;
  const L = VIEW.top + j.delta;
  const U = VIEW.bottom;
  const c = lerp(U, L, p);
  const h = 0.25 * (U - L) * Math.sin(Math.PI * p);
  const mask = `linear-gradient(180deg, #000 ${c - h}px, transparent ${c + h + 0.01}px)`;
  return (
    <>
      <Shutter v={v} />
      <Band y0={VIEW.top} y1={VIEW.bottom}>
        <Layer {...b} style={{ transform: `translateY(${j.delta - o}px)`, filter: blur }} />
        <Layer {...a} style={{ transform: `translateY(${-o}px)`, filter: blur, WebkitMaskImage: mask, maskImage: mask }} />
      </Band>
      {[
        [0, VIEW.top],
        [VIEW.bottom, SH],
      ].map(([y0, y1]) => (
        <Band key={y0} y0={y0} y1={y1}>
          <Layer {...a} />
          <Layer {...b} style={{ opacity: p }} />
        </Band>
      ))}
    </>
  );
};
