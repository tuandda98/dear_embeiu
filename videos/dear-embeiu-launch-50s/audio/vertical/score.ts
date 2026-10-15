// audio/vertical/score.ts — the 9:16 cut's one short score (VERTICAL.md · Audio): 1200 f at 60 fps, D, 120 BPM, in the
// film's language, on its theme (MOTIF / ANSWER of audio/music/score.ts) and with its kit:
//   Clock 0–120: a D pedal (glass + sub); the motif typed by the hook's 8 words in the film's minor shadow (F♮); the
//     landing (sub + the first kick) turns the world D major.
//   Paper 120–600: muted plucked 8ths, side-stick on 2 and 4, felt-piano chords over a bass D–G–A; a sus swell (no third)
//     from two beats before the unlock resolves on it, where the major third arrives (the cut's hero beat); cut dead on the
//     dominant at 600. 600–615 digital zero.
//   Said up front 615–900: a felt-piano D2 with the first line over a soft D–A drone, the D-major swell on "Chỉ hai
//     người.", the D2 again on the fourth line.
//   Resolve 900–1190: IV – V under the sheet and the dots, then from the lock the motif complete in 8ths, harmonised in D
//     (D – G/D – A/C# – D(add9)) under the lines; the final chord is gone by 1190.
// Every placement comes from V12_EVENTS / V34_EVENTS and the vertical timeline (beat 30 f, bar 120 f).
import { SPF, smp, stereo, place, placeStereo, peakDb, type Stereo } from "../core.ts";
import { ANSWER, MOTIF } from "../music/score.ts";
import { db, ms, n, notes, reverb } from "../music/dsp.ts";
import { bassNote, clap, feltPiano, glassPad, glassTone, kick, marimba, padChord, pluck, sideStick, subHold, subPulse } from "../music/instruments.ts";
import { VERT, VS, VSILENCE } from "../../src/vertical/timeline.ts";
import { V12_EVENTS } from "../../src/vertical/v12/events.ts";
import { V34_EVENTS } from "../../src/vertical/v34/events.ts";

const LEN = VERT.total * SPF;
const BEAT = VERT.beat;
const BAR = VERT.bar;
const EIGHTH = BEAT / 2;
const S = smp;
const S16 = (BEAT * SPF) / 4; // a sixteenth: 6000 samples
const CUT = S(VS.cut); // the hard cut: every voice that starts before it stops dead on it
const BACK = S(VSILENCE[0][1]); // 615: sound may come back
const END = S(VSILENCE[1][0]); // 1190: digital zero from here
const PEAK_DB = -6; // the stem's peak before mastering, as the film's score
const LEGATO = S(EIGHTH) + ms(90); // a melody note held into the next one, not through it
const THEME = [...MOTIF, ...ANSWER];
/** the film's typing (audio/music/score.ts): the minor shadow, an answer that never comes home */
const TYPED = notes("D5", "A5", "G5", "F5", "E5", "A4", "E5", "F5", "E5", "A4");
const HERO = ["land", "unlock", "lock"]; // the SFX moments the whole score dips under
const EV = [...V12_EVENTS, ...V34_EVENTS];
const evs = (id: string) => EV.filter((e) => e.id === id).sort((a, b) => a.f - b.f);
const first = (id: string) => {
  const e = evs(id)[0];
  if (!e) throw new Error(`vertical score: no '${id}' event in V12_EVENTS / V34_EVENTS`);
  return e.f;
};
const beatOf = (f: number) => Math.round(f / BEAT) % 4; // 0–3: the beat of the bar a frame on the beat falls on

export function verticalMusic(): Stereo {
  const bus = stereo(LEN);
  const send = stereo(LEN);
  let trim = 0; // the section's level (dB)
  const fit = (x: Float32Array, at: number) => x.subarray(0, Math.max(0, Math.min(x.length, (at < CUT ? CUT : END) - at)));
  const v = (x: Float32Array, at: number, gdb: number, pan = 0, sendDb = -Infinity) => {
    const y = fit(x, at);
    place(bus, y, at, db(gdb + trim), pan);
    if (sendDb > -90) place(send, y, at, db(sendDb + trim), pan);
  };
  const vs = (x: Stereo, at: number, gdb: number, sendDb = -Infinity) => {
    const y = { L: fit(x.L, at), R: fit(x.R, at) };
    placeStereo(bus, y, at, db(gdb + trim));
    if (sendDb > -90) placeStereo(send, y, at, db(sendDb + trim));
  };
  /** a stereo voice rising as u^2.2 over its length (a swell into the frame it ends on) */
  const swell = (x: Stereo) => {
    for (let i = 0; i < x.L.length; i++) {
      const g = (i / x.L.length) ** 2.2;
      x.L[i] *= g;
      x.R[i] *= g;
    }
    return x;
  };
  const land = first("land");
  const unlock = first("unlock");
  const touch = first("touch");
  const lock = first("lock");
  const lines = evs("headline").map((e) => e.f); // "Không bảng tin." · "Không người lạ." · "Chỉ hai người." · "Miễn phí." · "Không quảng cáo."

  // ───────────── Clock (0 → land): the D pedal; the hook types the motif, the last note hangs until the landing
  trim = -5;
  v(subHold(n("D2"), S(land), ms(30), ms(20)), 0, -27);
  vs(glassPad(notes("D3", "A3", "E4"), S(land), { atk: ms(40), rel: ms(20), seed: 3 }), 0, -29, -30);
  const words = evs("word").filter((e) => e.f < land);
  words.forEach((e, k) => {
    const m = TYPED[Math.min(k, TYPED.length - 1)];
    const to = k + 1 < words.length ? S(words[k + 1].f) + ms(70) : S(land); // the hook types fast: no overlap past the next word
    v(feltPiano(m, k % 5 === 0 ? 0.62 : 0.55, to - S(e.f), 10 + k), S(e.f), -16, -0.15, -21);
    v(marimba(m, 0.4, 20 + k), S(e.f), -27, -0.1, -29);
  });
  trim = 0;
  v(kick(0.95, 241), S(land), -20); // the landing: the first kick and a D1 sub pulse
  v(subPulse(n("D1"), 1.3), S(land), -17);

  // ───────────── Paper (land → the cut)
  const PAPER = [
    { f: land, bass: n("D2"), cell: notes("D4", "A4", "E5", "A4", "F#4", "A4", "E5", "A4"), piano: notes("D3", "A3", "F#4") }, // D(add9): he is here
    { f: land + BAR, bass: n("G2"), cell: notes("G4", "D5", "F#5", "D5"), piano: notes("G3", "B3", "F#4") }, // Gmaj7: the question
    { f: unlock - 2 * BEAT, bass: n("A2"), cell: notes("A4", "E5", "D5", "E5"), piano: notes("A3", "D4", "E4") }, // Asus4: your answer, "Gửi"
    { f: unlock, bass: n("D2"), cell: notes("D4", "A4", "F#5", "A4"), piano: notes("D3", "A3", "F#4", "E5") }, // D(add9): UNLOCK
    { f: unlock + BAR, bass: n("G2"), cell: notes("G4", "D5", "F#5", "D5"), piano: notes("G3", "B3", "F#4") }, // Gmaj7: both answers read
    { f: unlock + BAR + 2 * BEAT, bass: n("A2"), cell: notes("A4", "E5", "C#5", "E5"), piano: notes("A3", "C#4", "E4") }, // A: cut dead on it
  ]
    .filter((c) => c.f < VS.cut)
    .sort((a, b) => a.f - b.f);
  trim = 3;
  PAPER.forEach((c, k) => {
    const to = k + 1 < PAPER.length ? PAPER[k + 1].f : VS.cut;
    for (let e = 0, f = c.f; f < to; e++, f += EIGHTH) {
      const onBeat = f % BEAT === 0;
      v(pluck(c.cell[e % c.cell.length], onBeat ? 0.62 : 0.5, { t60: 0.2, tone: 0.22, exc: 1700, seed: 300 + f }), S(f), -15, onBeat ? -0.12 : 0.2, -30);
      if (e % 4 === 0) v(bassNote(c.bass, Math.min(S(2 * BEAT), S(to) - S(f)) - ms(25), 0.7, { cut0: 560, cut1: 180, res: 0.2, sub: 0.55, rel: ms(40) }), S(f), -16);
    }
    for (const m of c.piano) v(feltPiano(m, 0.4, S(to) - S(c.f) - ms(40), 450 + m + k), S(c.f), -22, (m - 60) / 30, -26);
  });
  for (let f = land; f < VS.cut; f += BEAT) {
    if (beatOf(f) % 2) v(sideStick(400 + f), S(f), -23, 0.18);
    else if (f > land && f !== unlock && beatOf(f) === 0) v(kick(0.7, 410 + f), S(f), -20);
  }
  {
    // the swell: A–D–E (a sus with no third) rising from two beats before the unlock, cut on it
    const s0 = S(unlock - 2 * BEAT);
    const len = S(unlock) - s0;
    vs(swell(glassPad(notes("A4", "D5", "E5"), len, { atk: ms(200), rel: ms(10), seed: 470 })), s0, -15, -20);
    vs(swell(padChord(notes("A3", "D4", "E4"), len, { atk: ms(200), rel: ms(10), cut: (i) => 500 + 1800 * (i / len), seed: 471 })), s0, -17, -24);
    // the unlock: the third arrives (a glass F#5 over the D chord) with a soft kick under it
    v(glassTone(n("F#5"), 0.6, 540), S(unlock), -17, 0.1, -20);
    v(kick(0.75, 541), S(unlock), -20);
  }

  // ───────────── Said up front (615 → the sheet): never drops out on a phone
  trim = 0;
  {
    const [l0, , l2, l3] = lines;
    const s1 = S(VS.sign);
    vs(glassPad(notes("D3", "A3"), s1 - S(l0), { atk: ms(300), rel: ms(40), seed: 620 }), S(l0), -24, -26);
    v(subHold(n("D2"), s1 - S(l0), ms(300), ms(40)), S(l0), -27);
    v(feltPiano(n("D2"), 0.62, S(l3) - S(l0) - ms(60), 621), S(l0), -13, 0, -22);
    v(feltPiano(n("A2"), 0.45, S(l2) - S(l0) - ms(60), 622), S(l0), -19, 0.05, -24);
    const len = s1 - S(l2);
    vs(padChord(notes("D3", "A3", "D4", "F#4", "A4"), len, { atk: ms(1200), rel: ms(40), cut: (i) => 500 + 1100 * (i / len), seed: 700 }), S(l2), -19, -23);
    vs(glassPad(notes("F#4", "A4", "D5"), len, { atk: ms(1100), rel: ms(40), seed: 701 }), S(l2), -25, -25);
    v(feltPiano(n("D2"), 0.56, s1 - S(l3) - ms(140), 770), S(l3), -14, 0, -22);
    v(feltPiano(n("A2"), 0.42, s1 - S(l3) - ms(140), 771), S(l3), -20, 0.05, -24);
  }

  // ───────────── Resolve: IV (the sheet, the dots travel) – V (the touch: A7sus4 → A7) into the lock …
  trim = 1.5;
  const LIFT = [
    { f: VS.sign, to: touch, root: n("G2"), pad: notes("G3", "B3", "D4", "F#4", "A4"), arp: notes("G5", "B5", "D6", "F#6"), cell: notes("D4", "B4", "G5", "B4") },
    { f: touch, to: touch + BEAT, root: n("A2"), pad: notes("A3", "D4", "E4", "G4"), arp: notes("A5", "D6", "E6", "G6"), cell: notes("A3", "E4", "D5", "E4") },
    { f: touch + BEAT, to: lock, root: n("A2"), pad: notes("A3", "C#4", "E4", "G4"), arp: notes("A5", "C#6", "E6", "G6"), cell: notes("A3", "E4", "C#5", "E4") },
  ];
  LIFT.forEach((c, k) => {
    for (let e = 0, f = c.f; f < c.to; e++, f += EIGHTH) {
      v(marimba(c.cell[e % 4], e % 2 ? 0.4 : 0.52, 900 + 20 * k + e), S(f), -17, e % 2 ? 0.25 : -0.15, -27);
      if (e % 4 === 0) v(bassNote(c.root, Math.min(S(2 * BEAT), S(c.to) - S(f)) - ms(25), 0.7, { cut0: 700, cut1: 220, res: 0.2, sub: 0.5, rel: ms(40) }), S(f), -16);
      if (f % BEAT) continue;
      if (beatOf(f) % 2 === 0) v(kick(beatOf(f) === 0 ? 0.85 : 0.72, 950 + f), S(f), -17);
      else {
        v(sideStick(960 + f), S(f), -21, 0.15);
        vs(clap(970 + f), S(f), -21, -28);
      }
    }
    for (let e = 0, s = S(c.f); s < S(c.to); e++, s += S16)
      v(pluck(c.arp[[0, 1, 2, 3, 2, 1][e % 6]], 0.5 + (e % 4 === 0 ? 0.12 : 0), { t60: 0.28, tone: 0.55, exc: 2600, seed: 980 + 30 * k + e }), s, -23, e % 2 ? 0.5 : -0.5, -26);
    vs(padChord(c.pad, S(c.to) - S(c.f) + ms(30), { atk: ms(30), rel: ms(50), cut: () => 1500, seed: 1000 + k }), S(c.f), -23, -27);
  });
  // … and from the lock the motif complete, harmonised in D (the sub boom is the score's, the glass ting the SFX's)
  trim = -0.5;
  v(subPulse(n("D1"), 1.6), S(lock), -18);
  THEME.forEach((m, k) => {
    const at = S(lock + k * EIGHTH);
    const last = k === THEME.length - 1;
    v(feltPiano(m, last ? 0.66 : k % 5 === 0 ? 0.68 : 0.6, last ? END - at : LEGATO, 1100 + k), at, -12, -0.05, -19);
    v(marimba(m, 0.48, 1120 + k), at, -20, 0.1, -25);
    v(glassTone(m + 12, 0.32, 1140 + k), at, -29, 0.2, -23);
  });
  const CAD = [
    { f: lock, bass: n("D2"), chord: notes("A3", "D4", "F#4"), glass: notes("D4", "F#4", "A4") },
    { f: lock + BEAT, bass: NaN, chord: notes("B3", "D4", "G4"), glass: notes("D4", "G4", "B4") },
    { f: lock + 2 * BEAT, bass: n("C#2"), chord: notes("A3", "C#4", "E4"), glass: notes("C#4", "E4", "A4") },
    { f: lock + BAR, bass: n("D2"), chord: notes("F#3", "A3", "D4"), glass: notes("D4", "F#4", "A4", "D5") },
  ];
  CAD.forEach((c, k) => {
    const at = S(c.f);
    const to = k + 1 < CAD.length ? S(CAD[k + 1].f) : END;
    for (const m of c.chord) v(feltPiano(m, 0.46, to - at, 1200 + m), at, -20, (m - 60) / 30, -24);
    vs(glassPad(c.glass, to - at + ms(120), { atk: ms(80), rel: ms(150), seed: 1250 + k }), at, -20, -20);
    if (Number.isNaN(c.bass)) return;
    const next = CAD.slice(k + 1).find((d) => !Number.isNaN(d.bass));
    v(feltPiano(c.bass, 0.58, (next ? S(next.f) : END) - at, 1260 + k), at, k === 0 ? -17 : -14, -0.05, -22);
  });
  vs(padChord(notes("D3", "F#3", "A3", "D4"), END - S(lock + BAR), { atk: ms(60), rel: ms(200), cut: () => 1100, seed: 1270 }), S(lock + BAR), -24, -24);
  v(subHold(n("D2"), END - S(lock + BAR), ms(40), ms(300)), S(lock + BAR), -22);

  // ───────────── reverb (fresh on each side of the cut, none after the end), the cut's declick, the last fade, the level
  const wet = reverb(send, [[0, CUT], [BACK, END]], { room: 0.84, damp: 0.32, lp: 6500 });
  for (let i = 0; i < LEN; i++) {
    bus.L[i] += wet.L[i];
    bus.R[i] += wet.R[i];
  }
  for (let i = CUT - ms(3); i < CUT; i++) {
    const g = (CUT - i) / ms(3);
    bus.L[i] *= g;
    bus.R[i] *= g;
  }
  const z0 = S(lock + (THEME.length - 1) * EIGHTH); // from the theme's last note, gone by END
  for (let i = z0; i < LEN; i++) {
    const g = i >= END ? 0 : 0.5 + 0.5 * Math.cos((Math.PI * (i - z0)) / (END - z0));
    bus.L[i] *= g;
    bus.R[i] *= g;
  }
  // a short dip of the whole score at each hero SFX frame (3 ms down, held 40 ms, back over ~160 ms), as the film's
  const g = new Float32Array(LEN).fill(1);
  for (const f of HERO.flatMap((id) => evs(id).map((e) => e.f)))
    for (let i = Math.max(0, S(f) - ms(3)); i < Math.min(LEN, S(f) + ms(700)); i++) {
      const k = i < S(f) ? (i - (S(f) - ms(3))) / ms(3) : i < S(f) + ms(40) ? 1 : Math.exp(-(i - S(f) - ms(40)) / ms(160));
      g[i] = Math.min(g[i], 1 - (1 - db(-4)) * k);
    }
  for (let i = 0; i < LEN; i++) {
    bus.L[i] *= g[i];
    bus.R[i] *= g[i];
  }
  const level = db(PEAK_DB - peakDb(bus));
  for (let i = 0; i < LEN; i++) {
    bus.L[i] *= level;
    bus.R[i] *= level;
  }
  return bus;
}
