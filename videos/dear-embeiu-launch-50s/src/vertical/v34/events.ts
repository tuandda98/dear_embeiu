// Sound-worthy moments of V3–V4 (frame-exact with V34.tsx): { f, id, data? }. Ids follow the film's kit (A5 headline ·
// dotsIn · A6 composerIn / recede · A7 touch heartDraw heartFill wordmark lock line url). Spec: VERTICAL.md.
import type { VEvent } from "../v12/events.ts";
import { V34_CUES as Q } from "./cues.ts";

export const V34_EVENTS: VEvent[] = [
  ...Q.lines.map((f, n) => ({ f, id: "headline", data: { n } })), // the five lines (n 4 = "Không quảng cáo.", rose)
  { f: Q.dots[0], id: "dotsIn" }, // the two dots glide in; they rest after "Chỉ hai người." at Q.dots[1]
  { f: Q.sheet[0], id: "composerIn" }, // the light sheet rises (the film's Act 6 sheet sound)
  { f: Q.travel[0], id: "recede" }, // the dots travel to the centre
  { f: Q.touch, id: "touch" },
  { f: Q.heart[0], id: "heartDraw" },
  { f: Q.fill[0], id: "heartFill" }, // the heart fills; the dots melt into it; the tile blooms at Q.tile[0]
  { f: Q.wordmark[0], id: "wordmark" },
  { f: Q.lock, id: "lock" },
  { f: Q.l1, id: "line", data: { n: 0 } },
  { f: Q.l2, id: "line", data: { n: 1 } },
  { f: Q.offer, id: "line", data: { n: 2 } },
  { f: Q.url, id: "url" },
];
