// 60 fps, 120 BPM: a beat is 30 frames, a bar 120, an eighth 15. The clock's second = 2 beats = 60 frames.
export const FPS = 60;
export const W = 1920;
export const H = 1080;
export const TOTAL = 3000; // 50.000 s
export const BEAT = 30;
export const EIGHTH = 15;
export const BAR = 120;
export const sec = (s: number) => Math.round(s * FPS);
export const bar = (n: number) => (n - 1) * BAR; // first frame of bar n (1-based)

/** the seven acts of the film (BRIEF §5). One act is mounted per frame: the one whose [from, to) holds it. */
export const ACTS = [
  { id: "a1", name: "Một con số", from: 0, to: 240 },
  { id: "a2", name: "Người ấy", from: 240, to: 720 },
  { id: "a3", name: "Chuỗi", from: 720, to: 1200 },
  { id: "a4", name: "Một ngày", from: 1200, to: 1920 },
  { id: "a5", name: "Nói trước", from: 1920, to: 2280 },
  { id: "a6", name: "Mở rộng", from: 2280, to: 2640 },
  { id: "a7", name: "Ký tên", from: 2640, to: 3000 },
] as const;
