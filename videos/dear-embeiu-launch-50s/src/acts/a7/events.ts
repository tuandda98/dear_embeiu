// Act 7 sound events, frame-exact with the picture (src/acts/Act7.tsx). Ids: DESIGN §7 (A7 `touch heartDraw heartFill
// wordmark lock line url`).
import { A7 } from "../../timeline/cues.ts";

export const A7_EVENTS: { f: number; id: string; data?: Record<string, number | string> }[] = [
  { f: A7.touch, id: "touch" }, // the dots touch (first frame of the act)
  { f: A7.heart[0], id: "heartDraw" }, // the outline starts at the heart's tip
  { f: A7.fill[0], id: "heartFill" }, // the outline closes; the dots melt into the white fill
  { f: A7.wordmark[0], id: "wordmark" }, // starts to slide out from under the tile
  { f: A7.lock, id: "lock" }, // lock-up on the downbeat (46.0 s)
  { f: A7.l1, id: "line", data: { n: 0 } }, // "Đếm ngày yêu." (+ the legal line)
  { f: A7.l2, id: "line", data: { n: 1 } }, // "Và mọi thứ sau con số."
  { f: A7.offer, id: "line", data: { n: 2 } }, // "Miễn phí · App Store & Google Play"
  { f: A7.url, id: "url" }, // the pill rises
];
