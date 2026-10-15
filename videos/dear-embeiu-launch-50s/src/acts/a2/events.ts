// Act 2 sound events, frame-exact to the picture (DESIGN §7 ids: unfold leader row jump mood pick matched caption
// press unfoldRow check compress; plus `tick` — the small counter keeps ticking at 60 %, sfx/build.ts already plays
// ticks after A1.land quieter). Plain .ts: Node imports it.
import { A2 } from "../../timeline/cues.ts";
import { BACK } from "./timing.ts";

export const A2_EVENTS: { f: number; id: string; data?: Record<string, number | string> }[] = [
  ...[240, 300, 360, 420, 480, 540, 600, 660].map((f) => ({ f, id: "tick" })), // clockAt() changes every 60 f
  { f: A2.card[0], id: "unfold" }, // the dot opens into the notification card (slides until A2.card[1])
  ...A2.rows.map((f, n) => ({ f, id: "leader", data: { n } })), // each lavender line starts drawing (8 f)
  ...A2.rowLand.map((f, n) => ({ f, id: "row", data: { n } })), // the row finishes unrolling into the sheet
  { f: A2.moodJump, id: "jump", data: { n: 0 } }, // the carets jump into the mood row
  ...A2.moods.map((f, n) => ({ f, id: "mood", data: { n } })), // each tile is dealt from the caret
  { f: A2.pick, id: "pick" }, // the rose ring starts around Nhớ
  { f: A2.matched, id: "matched" }, // the fan closes, the rose hairline draws round the row
  { f: BACK, id: "jump", data: { n: 1 } }, // the caret hops back up into the question row
  { f: A2.caption, id: "caption" }, // Cần cả hai. wipes in
  { f: A2.press, id: "press" }, // Gửi: down 6 f, up 10 f
  { f: A2.answerYou, id: "unfoldRow", data: { n: 0 } }, // Câu trả lời của bạn
  { f: A2.answerOther, id: "unfoldRow", data: { n: 1 } }, // Câu trả lời của Tuấn
  { f: A2.check, id: "check" }, // the check stroke under both answers
  { f: A2.compress[0], id: "compress" }, // everything runs into the first streak cell (arrives 719, A3 lands it at 720)
].sort((a, b) => a.f - b.f);
