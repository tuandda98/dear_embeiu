// Sound-worthy moments of V1–V2 (frame-exact): { f, id, data? }. Spec: VERTICAL.md. Ids follow the film's
// (DESIGN §7 + the v3 Act 2 ones): tick key word drop land swoop unfold phoneRise scroll leave lift press unlock
// caption; plus `sink` (the phone sinks to the bottom under the cards) and `sendIn` (the Gửi pill unfolds).
import { HOOK, TYPED, V } from "./timing.ts";

export type VEvent = { f: number; id: string; data?: Record<string, number | string> };

const wordEnds = HOOK.frames.filter((_, i) => i === HOOK.frames.length - 1 || HOOK.text[i + 1] === " ");

export const V12_EVENTS: VEvent[] = [
  ...[0, 60, 120, 180, 240, 300, 360, 420, 480, 540].map((f) => ({ f, id: "tick" })), // clockAt(): seconds change every 60 f
  ...HOOK.frames.map((f) => ({ f, id: "key", data: { n: 0 } })), // the hook, letter by letter
  ...wordEnds.map((f, n) => ({ f, id: "word", data: { n } })), // the motif: one note per word (17 … 75)
  { f: V.dropStart, id: "drop" }, // the lavender dot leaves the top edge
  { f: V.land, id: "land" }, // first contact beside the number
  { f: V.swoop[0], id: "swoop" }, // the dot swoops into the notification's avatar
  { f: V.card[0], id: "unfold" }, // the dot opens into the notification card
  { f: V.phone[0], id: "phoneRise" }, // the Home phone rises from the bottom
  { f: V.scroll[0], id: "scroll" }, // the Home scrolls to today's question
  { f: V.leave[0], id: "leave" }, // the notification slides out
  { f: V.lift[0], id: "lift" }, // the question card lifts out of the phone
  { f: V.sink[0], id: "sink" }, // the phone sinks to the bottom edge
  ...TYPED.frames.map((f) => ({ f, id: "key", data: { n: 1 } })), // your answer, letter by letter
  { f: V.sendIn[0], id: "sendIn" }, // the Gửi pill unfolds
  { f: V.press, id: "press" }, // Gửi: down 6 f, up 10 f
  { f: V.unlock, id: "unlock" }, // UNLOCK (6.0 s): both answers open, both edges glow once
  { f: V.caption, id: "caption" }, // "Cần cả hai." wipes in
  { f: V.mirror, id: "unfoldRow" }, // the phone's question card opens both answers too
].sort((a, b) => a.f - b.f);
