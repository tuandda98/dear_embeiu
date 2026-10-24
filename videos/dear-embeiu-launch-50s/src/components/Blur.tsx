import { AbsoluteFill, Freeze, useCurrentFrame } from "remotion";

/**
 * 180° shutter motion blur by sub-frame sampling, CENTRED on the frame (−¼ … +¼ f), so switching it on/off
 * never shifts the element. Children must read useCurrentFrame() themselves. Wrap ONLY what moves faster than
 * 20 px/frame, only while it does: static text outside it stays pixel-exact. Not for WebGL (blur inside the GL scene).
 */
export const Blur: React.FC<{ on?: boolean; samples?: number; children: React.ReactNode }> = ({ on = true, samples = 10, children }) => {
  const f = useCurrentFrame();
  if (!on) return <>{children}</>;
  return (
    <AbsoluteFill style={{ isolation: "isolate" }}>
      {Array.from({ length: samples }, (_, i) => (
        <AbsoluteFill key={i} style={{ mixBlendMode: "plus-lighter", filter: `opacity(${1 / samples})` }}>
          <Freeze frame={f + 0.5 * ((i + 0.5) / samples - 0.5)}>{children}</Freeze>
        </AbsoluteFill>
      ))}
    </AbsoluteFill>
  );
};
