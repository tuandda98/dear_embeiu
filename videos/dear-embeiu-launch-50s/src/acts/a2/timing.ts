// Act 2's in-between timings (global frames). The beats live in the cue sheet (A2); these are the durations around
// them. Plain .ts so events.ts (and Node) can read the same numbers the picture animates from.
import { A2 } from "../../timeline/cues.ts";

export const STEP = [242, 278] as const; // the number recoils back (scale 1 → 0.55 to (120,160), 100 → 60 %) 2 f after contact
export const CAM = [240, 300] as const; // the camera eases 104 → 100 %
export const OLD_OUT = [250, 262] as const; // A1's caption drops out of its mask
export const GROW = [279, 291] as const; // the dot swells into the card's 56 px app-icon slot as it arrives
export const OPEN = A2.card; // 283–300: the card body opens rightward from the dot, done as the first leader starts
export const LEADER = 8; // a leader line draws in 8 f
export const PULL = 22; // the sheet unrolls (row 0) / lengthens (rows 1, 2) over 22 f, the row's content drawn out with it
export const JUMP = 7; // carets jump between rows in 7 f
export const MARK = 510; // Tuấn's lavender mark lands on Nhớ (his pick, made earlier), on the 8th
export const RING = 12; // the rose ring draws in 12 f
export const MORPH = [558, 572] as const; // the picked tile folds down into the matched line's emoji
export const BACK = 570; // after the match the caret jumps back up into the question row (with the caption, on the beat)
export const SEND_IN = [578, 590] as const; // the Gửi pill unfolds beside the caret
export const UNFOLD = 22; // an answer unfolds in 22 f
export const CHECK = 12; // the check stroke draws in 12 f
export const CAP_OUT = [690, 702] as const; // the caption wipes out
export const CELL_AT = A2.compress[1] - 1; // 719: the sheet IS the one navy cell (H720), held for A3's first frame
