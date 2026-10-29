// The 9:16 cut (composition "Vertical": 1080×1920, 60 fps, 1200 f = 20.0 s, 120 BPM → beat 30 f, bar 120 f). Plain TS:
// the picture (src/vertical/**) and the soundtrack (audio/vertical/build.ts) read the same frames. Spec: VERTICAL.md.
export const VERT = { w: 1080, h: 1920, fps: 60, total: 1200, beat: 30, bar: 120 } as const;

/** section starts; 600 is the cut's one HARD CUT (music dead, 15 f of digital silence after it) */
export const VS = { hook: 0, question: 120, cut: 600, said: 600, sign: 900, end: 1200 } as const;
export const VSILENCE = [[600, 615], [1190, 1200]] as const; // digital zero (frames)

/** where everything that must be read lives (TikTok / Reels overlay the right edge and the bottom) */
export const SAFE = { left: 80, right: 940, top: 200, bottom: 1500 } as const;
