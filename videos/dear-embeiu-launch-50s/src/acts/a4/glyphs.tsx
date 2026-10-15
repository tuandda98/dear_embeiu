// Act 4's line glyphs (DESIGN §4: simple 1.5 px line icons, never an icon font): the event icons of the day cards and
// the rebuilt Home's chrome. 24-unit boxes, round caps and joins, `color` strokes (or fills the solid ones).

const BUBBLE = "M12 20.2c4.8 0 8.7-3.4 8.7-7.6S16.8 5 12 5 3.3 8.4 3.3 12.6c0 1.7.6 3.2 1.7 4.5L4.2 20.4l3.7-1.1c1.2.6 2.6.9 4.1.9z";
const HEART = "M12 20s-7.6-4.4-7.6-9.6A4.1 4.1 0 0 1 12 8a4.1 4.1 0 0 1 7.6 2.4C19.6 15.6 12 20 12 20z";

type Name =
  | "moon"
  | "photo"
  | "care"
  | "question"
  | "chat"
  | "bell"
  | "mood"
  | "sun"
  | "message"
  | "heart"
  | "heartLine"
  | "gallery"
  | "profile"
  | "lock"
  | "pen"
  | "chevron"
  | "arrowCircle"
  | "flag"
  | "star"
  | "plus"
  | "faceNeutral"
  | "faceTile";

const dots = (ys: number, xs: number[], r: number, c: string) => xs.map((x) => <circle key={x} cx={x} cy={ys} r={r} fill={c} stroke="none" />);

const paths = (n: Name, c: string): React.ReactNode => {
  switch (n) {
    case "moon":
      return <path d="M19.6 14.6A8.2 8.2 0 1 1 9.4 4.4a6.6 6.6 0 0 0 10.2 10.2z" />;
    case "photo":
      return (
        <>
          <rect x="3.5" y="4.5" width="17" height="15" rx="3.5" />
          <path d="M4 16.5l4.6-4.4 3.6 3.4 2.4-2.2 5.4 5" />
          <circle cx="9" cy="9.4" r="1.6" />
        </>
      );
    case "care":
      return (
        <>
          <path d={BUBBLE} />
          <path d="M12 15.6s-3.1-1.8-3.1-3.9a1.6 1.6 0 0 1 3.1-.7 1.6 1.6 0 0 1 3.1.7c0 2.1-3.1 3.9-3.1 3.9z" />
        </>
      );
    case "question":
      return (
        <>
          <path d={BUBBLE} />
          <path d="M10 10.6a2 2 0 1 1 2.9 1.8c-.6.3-.9.8-.9 1.4v.2" />
          {dots(16.4, [12], 0.9, c)}
        </>
      );
    case "chat":
      return (
        <>
          <path d={BUBBLE} />
          {dots(12.6, [8.4, 12, 15.6], 1, c)}
        </>
      );
    case "bell":
      return (
        <>
          <path d="M6.2 16.4V11a5.8 5.8 0 0 1 11.6 0v5.4l1.6 2.1H4.6z" />
          <path d="M10.1 20.6a2 2 0 0 0 3.8 0" />
        </>
      );
    case "mood":
      return (
        <>
          <circle cx="12" cy="12" r="8.6" />
          {dots(10.2, [9.1, 14.9], 1.05, c)}
          <path d="M8.7 14.2a3.9 3.9 0 0 0 6.6 0" />
        </>
      );
    case "sun":
      return (
        <>
          <circle cx="12" cy="12" r="3.9" />
          {[0, 45, 90, 135, 180, 225, 270, 315].map((a) => {
            const r = (a * Math.PI) / 180;
            return <path key={a} d={`M${12 + 6.6 * Math.cos(r)} ${12 + 6.6 * Math.sin(r)}L${12 + 8.6 * Math.cos(r)} ${12 + 8.6 * Math.sin(r)}`} />;
          })}
        </>
      );
    case "message": // the header's care entry (iconsax message_favorite): a chat bubble with a heart on its shoulder
      return (
        <>
          <path d="M20.5 12.8c0 4.1-3.8 7.4-8.5 7.4-1.4 0-2.8-.3-4-.8L3.9 20.5l1.2-3.6a7 7 0 0 1-1.6-4.1c0-4.1 3.8-7.4 8.5-7.4" />
          {dots(12.9, [8.2, 12, 15.8], 1, c)}
          <path d="M18 9.4s-3-1.7-3-3.8a1.5 1.5 0 0 1 3-.7 1.5 1.5 0 0 1 3 .7c0 2.1-3 3.8-3 3.8z" />
        </>
      );
    case "heart":
      return <path d={HEART} fill={c} stroke="none" />;
    case "heartLine":
      return <path d={HEART} />;
    case "gallery":
      return (
        <>
          <rect x="3.5" y="3.5" width="17" height="17" rx="4.5" />
          <circle cx="9.2" cy="9.2" r="1.7" />
          <path d="M4 17.4l4.4-3.4c.6-.5 1.5-.5 2.1 0l1.8 1.5c.6.5 1.5.5 2.1 0L20 11.6" />
        </>
      );
    case "profile":
      return (
        <>
          <circle cx="12" cy="8.2" r="3.7" />
          <path d="M4.8 20.2c.6-3.6 3.6-6 7.2-6s6.6 2.4 7.2 6" />
        </>
      );
    case "lock":
      return (
        <>
          <rect x="4.8" y="10.3" width="14.4" height="10.2" rx="3" />
          <path d="M8 10.3V8a4 4 0 0 1 8 0v2.3" />
          {dots(15.4, [9.6, 12, 14.4], 0.85, c)}
        </>
      );
    case "pen":
      return (
        <>
          <path d="M14.6 5.6l3.8 3.8M5 19l.9-4.2L15.8 4.9a2 2 0 0 1 2.9 0l.4.4a2 2 0 0 1 0 2.9L9.2 18.1z" />
          <path d="M13 19.5h6.5" />
        </>
      );
    case "chevron":
      return <path d="M9.4 5.8l6.2 6.2-6.2 6.2" />;
    case "arrowCircle":
      return (
        <>
          <circle cx="12" cy="12" r="8.6" />
          <path d="M10.6 8.6l3.4 3.4-3.4 3.4" />
        </>
      );
    case "flag": // iconsax flag: a pole and a swallow-tailed pennant
      return <path d="M5.2 2.5v19M5.2 4h11c2.6 0 3.2 1.5 1.4 3.3l-1.2 1.2c-.8.8-.8 2.1 0 2.8l1.2 1.2c1.8 1.8 1.2 3.3-1.4 3.3h-11" />;
    case "star":
      return <path d="M12 3.6l2.5 5.3 5.8.7-4.3 4 1.1 5.7L12 16.5l-5.1 2.8 1.1-5.7-4.3-4 5.8-.7z" fill={c} stroke="none" />;
    case "plus":
      return <path d="M12 6.5v11M6.5 12h11" />;
    case "faceNeutral":
      return (
        <>
          <circle cx="12" cy="12" r="8.6" />
          {dots(10.2, [9.1, 14.9], 1.05, c)}
          <path d="M9 15.2h6" />
        </>
      );
    case "faceTile": // the mood card's leading glyph (iconsax emoji_happy, bold): a solid face, its features cut out
      return (
        <>
          <rect x="3.6" y="3.6" width="16.8" height="16.8" rx="5.6" fill={c} stroke="none" />
          {dots(10.4, [9.2, 14.8], 1.25, "#FFFFFF")}
          <path d="M8.6 14a3.9 3.9 0 0 0 6.8 0" stroke="#FFFFFF" />
        </>
      );
  }
};

export const G: React.FC<{ name: Name; size?: number; color?: string; stroke?: number; style?: React.CSSProperties }> = ({
  name,
  size = 24,
  color = "currentColor",
  stroke = 1.5,
  style,
}) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={(stroke * 24) / size} strokeLinecap="round" strokeLinejoin="round" style={{ display: "block", flex: "none", ...style }}>
    {paths(name, color)}
  </svg>
);
export type GlyphName = Name;
