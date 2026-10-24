// Act 2 sound events (v3), frame-exact to the picture. Ids from DESIGN §7 where they fit (unfold, press, caption,
// compress, unfoldRow) and from A4's vocabulary (phoneRise, lift, key); `tick` — the small counter keeps ticking, quieter.
// New ids (v3): swoop (the dot leaves its landing spot for the notification), leave (the notification slides out),
// sendIn (the Gửi pill unfolds), unlock (THE hero beat: both answers open at once), scroll (the Home scrolls in the
// phone). Dropped (v3): leader, row, jump, sheet, mood, pick, matched, check. Plain .ts: Node imports it.
import { A2 } from "../../timeline/cues.ts";
import { TYPED } from "./timing.ts";

export const A2_EVENTS: { f: number; id: string; data?: Record<string, number | string> }[] = [
  ...[240, 300, 360, 420, 480, 540, 600, 660].map((f) => ({ f, id: "tick" })), // clockAt() changes every 60 f
  { f: A2.fly[0], id: "swoop" }, // the dot swoops under the corner into the notification's avatar slot
  { f: A2.card[0], id: "unfold" }, // the dot opens into the notification (slides until A2.card[1])
  { f: A2.phone[0], id: "phoneRise" }, // the phone rises at the right (settles ≈ 336)
  { f: A2.scroll[0], id: "scroll" }, // the Home scrolls down to today's question card
  { f: A2.leave[0], id: "leave" }, // the notification slides out to the left
  { f: A2.lift[0], id: "lift" }, // the question card lifts out of the phone into the left column (lands A2.lift[1])
  ...TYPED.frames.map((f) => ({ f, id: "key" })), // your answer, letter by letter, into your card
  { f: A2.sendIn[0], id: "sendIn" }, // the Gửi pill unfolds
  { f: A2.press, id: "press" }, // Gửi: down 6 f, up 10 f
  { f: A2.unlock, id: "unlock" }, // UNLOCK: his text unmasks, both edges glow once
  { f: A2.caption, id: "caption" }, // Cần cả hai. wipes in
  { f: A2.mirror, id: "unfoldRow" }, // the phone's card opens both answers too
  { f: A2.compress[0], id: "compress" }, // everything runs into the first streak cell (arrives 719, A3 lands it at 720)
].sort((a, b) => a.f - b.f);
