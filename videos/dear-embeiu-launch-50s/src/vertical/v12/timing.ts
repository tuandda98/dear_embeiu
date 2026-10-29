// V1–V2 frames (the 9:16 cut, composition "Vertical", 60 fps, beat 30 f). Plain .ts: V12.tsx and events.ts (and the
// audio build) read the same numbers. One or two things move at a time, in this order. Spec: VERTICAL.md.
import { even, schedule } from "../../timeline/typing.ts";
import { T } from "../../copy/strings.ts";

/** the hook "Mọi app đếm ngày yêu / chỉ biết đếm." (T.a1.caption), one word ≈ every 8 f, complete on 75, then it holds */
export const HOOK = schedule(T.a1.caption.split(" "), [17, 25, 34, 42, 50, 58, 67, 75], { seed: 20, minGap: 1, maxGap: 3 });

export const V = {
  dropStart: 102, // the lavender dot falls from the top edge…
  land: 120, // …and lands beside the number (the spring's first contact, solved onto this frame)
  step: [122, 150], // the number steps back into the top-left corner (2 f after contact)
  hookOut: [124, 136], // the hook drops out of its mask
  swoop: [140, 162], // the dot swoops into the notification's avatar
  card: [160, 176], // the dot opens into the notification card (top)
  phone: [166, 206], // the Home phone rises from the bottom, centred (a spring)
  scroll: [206, 226], // inside it the Home scrolls to today's question card
  leave: [228, 240], // the notification slides out to the left, completely
  lift: [236, 268], // the question card lifts out of the phone into the upper half
  sink: [250, 290], // the phone sinks to the bottom: only its top shows, under the cards
  type: [272, 328], // your answer types into your card (52 px)
  sendIn: [328, 336], // the "Gửi" pill unfolds beside it
  press: 340, // "Gửi" is pressed
  unlock: 360, // UNLOCK (6.0 s): both answers open at the same instant
  caption: 375, // "Cần cả hai." 96 px under the cards
  mirror: 395, // the phone's question card opens both answers too (its top shows under the caption)
  cut: 600, // hard cut (V34's first frame is pure navy)
} as const;

/** your answer, letter by letter at an even, quick pace */
export const TYPED = even(T.a2.answerYou.text, V.type[0], V.type[1]);
