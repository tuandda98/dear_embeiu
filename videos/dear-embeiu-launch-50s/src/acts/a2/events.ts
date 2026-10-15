// Act 2 sound events, frame-exact to the picture (DESIGN §7 ids: unfold leader row jump mood pick matched caption
// press unfoldRow check compress; plus `tick` — the small counter keeps ticking at 60 %, sfx/build.ts plays ticks after
// A1.land quieter). New ids (coordinator, 15/10): `scroll` (the Home is flicked inside the phone) and `sheet` (a sheet
// rises inside the phone: n 0 the mood sheet, n 1 the answer sheet). `press` now comes twice: n 0 the question card's
// rose pill, n 1 "Gửi" on the answer sheet. Plain .ts: Node imports it.
import { A2 } from "../../timeline/cues.ts";

export const A2_EVENTS: { f: number; id: string; data?: Record<string, number | string> }[] = [
  ...[240, 300, 360, 420, 480, 540, 600, 660].map((f) => ({ f, id: "tick" })), // clockAt() changes every 60 f
  { f: A2.card[0], id: "unfold" }, // the dot opens into the notification card (slides until A2.card[1]); the phone rises
  { f: A2.scroll[0], id: "scroll" }, // the Home is flicked from the counter card down to today's cards
  ...A2.rows.map((f, n) => ({ f, id: "leader", data: { n } })), // each lavender line starts drawing (8 f)
  ...A2.rowLand.map((f, n) => ({ f, id: "row", data: { n } })), // its 10 px pin lands on his side of the card
  { f: A2.moodJump, id: "jump" }, // the carets hop into the mood card; the lines let go
  { f: A2.sheets[0], id: "sheet", data: { n: 0 } }, // the mood sheet rises
  ...A2.moods.map((f, n) => ({ f, id: "mood", data: { n } })), // each mood tile drops in
  { f: A2.pick, id: "pick" }, // the rose ring starts around Nhớ
  { f: A2.matched, id: "matched" }, // the sheet drops, the mood card reads the match
  { f: A2.caption, id: "caption" }, // Cần cả hai. wipes in
  { f: A2.press, id: "press", data: { n: 0 } }, // the question card's rose pill: down 6 f, up 10 f
  { f: A2.sheets[1], id: "sheet", data: { n: 1 } }, // the answer sheet rises
  { f: A2.send, id: "press", data: { n: 1 } }, // Gửi; the sheet drops 8 f later
  { f: A2.answerYou, id: "unfoldRow", data: { n: 0 } }, // your answer opens (in the card and large beside the phone)
  { f: A2.answerOther, id: "unfoldRow", data: { n: 1 } }, // his answer opens
  { f: A2.check, id: "check" }, // the check stroke under both answers
  { f: A2.compress[0], id: "compress" }, // everything runs into the first streak cell (arrives 719, A3 lands it at 720)
].sort((a, b) => a.f - b.f);
