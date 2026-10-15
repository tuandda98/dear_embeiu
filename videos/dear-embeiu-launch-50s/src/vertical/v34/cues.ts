// V3 said up front (600–900) + V4 sign-off (900–1200) of the 9:16 cut: every key frame (global frames of the
// "Vertical" composition, 60 fps, beat 30 f). Plain TS: the picture (V34.tsx) and the sound (events.ts → audio) read
// the same numbers. Spec: VERTICAL.md.
export const V34_CUES = {
  silence: [600, 615], // pure C.ink after the hard cut, digital zero
  lines: [620, 650, 700, 770, 800], // "Không bảng tin." · "Không người lạ." · "Chỉ hai người." · "Miễn phí." · "Không quảng cáo." (rose)
  dots: [712, 746], // the two dots glide in from the left / right frame edges and rest just after "Chỉ hai người."
  sheet: [900, 930], // the light sheet rises from the bottom edge and covers the navy; the dots stay on top of it
  travel: [930, 960], // the dots travel to the centre and touch
  touch: 960,
  heart: [960, 1000], // the heart's outline draws (rose) …
  rise: [964, 994], // … while the touching dots rise into it through its open tip
  fill: [1000, 1012], // it fills white; the dots melt into the fill
  tile: [1000, 1018], // the sunset tile blooms behind (set before the wordmark leaves it)
  wordmark: [1012, 1036], // "Dear Embeiu" slides out from under the set tile
  lock: 1020, // lock-up on the downbeat: the tile is set, the wordmark is on its way out
  l1: 1050, // "Đếm ngày yêu."
  l2: 1080, // "Và mọi thứ sau con số." (rose)
  offer: 1110, // "Miễn phí · App Store & Google Play"
  url: 1125, // the navy pill "dearembeiu.com/get" rises
  hold: 1199, // the poster
} as const;
