import type { CSSProperties, ReactNode } from "react";
import { PHONE } from "../lib/tokens.ts";

/**
 * The phone (BRIEF §4): an iPhone-shaped vector frame around a 402×874 pt screen, drawn at `scale`. `x`, `y` place the
 * OUTER top-left corner in film pixels. Children are the screen content in screen points (a 402×874 box, clipped,
 * radius 55); the Dynamic Island is drawn above the content. Vectors only — never a screenshot.
 */
export const Phone: React.FC<{ x: number; y: number; scale?: number; children?: ReactNode; style?: CSSProperties }> = ({
  x,
  y,
  scale = PHONE.hero,
  children,
  style,
}) => {
  const bezel = 12;
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: (PHONE.w + 2 * bezel) * scale,
        height: (PHONE.h + 2 * bezel) * scale,
        ...style,
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          transformOrigin: "0 0",
          transform: `scale(${scale})`,
          width: PHONE.w + 2 * bezel,
          height: PHONE.h + 2 * bezel,
          borderRadius: PHONE.radius + bezel,
          background: "#1B1D22",
          boxShadow: "inset 0 0 0 1px #343740, 0 30px 60px rgba(26, 26, 46, 0.18)",
        }}
      >
        <div
          style={{
            position: "absolute",
            left: bezel,
            top: bezel,
            width: PHONE.w,
            height: PHONE.h,
            borderRadius: PHONE.radius,
            overflow: "hidden",
            background: "#FAFAFC",
          }}
        >
          {children}
          {/* Dynamic Island */}
          <div style={{ position: "absolute", left: (PHONE.w - 126) / 2, top: 11, width: 126, height: 37, borderRadius: 999, background: "#000" }} />
        </div>
      </div>
    </div>
  );
};

/** the iOS status bar as the captures show it (ref/ios/*.png): 09:41, 4 bars, wifi, a charging battery — vectors */
export const StatusBar: React.FC<{ dark?: boolean }> = ({ dark = true }) => {
  const c = dark ? "#1A1A2E" : "#FFFFFF";
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 54, color: c, fontWeight: 600, fontSize: 17 }}>
      <div style={{ position: "absolute", left: 40, top: 16 }}>09:41</div>
      <svg style={{ position: "absolute", right: 32, top: 18 }} width="78" height="16" viewBox="0 0 78 16" fill={c}>
        <rect x="0" y="9" width="3" height="5" rx="1" />
        <rect x="5" y="7" width="3" height="7" rx="1" />
        <rect x="10" y="4" width="3" height="10" rx="1" />
        <rect x="15" y="1" width="3" height="13" rx="1" />
        <path d="M31 13.5a1.6 1.6 0 1 0 0-3.2 1.6 1.6 0 0 0 0 3.2zM26.6 9.3l1.5 1.5a4.1 4.1 0 0 1 5.8 0l1.5-1.5a6.2 6.2 0 0 0-8.8 0zM23.6 6.4l1.5 1.5a8.4 8.4 0 0 1 11.8 0l1.5-1.5a10.5 10.5 0 0 0-14.8 0z" />
        <rect x="47" y="1.5" width="25" height="12" rx="3.5" fill="none" stroke={c} strokeOpacity="0.4" />
        <rect x="49" y="3.5" width="21" height="8" rx="2" fill="#34C759" />
        <rect x="74" y="5" width="2" height="5" rx="1" fillOpacity="0.4" />
      </svg>
    </div>
  );
};
