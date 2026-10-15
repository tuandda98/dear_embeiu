// audio/music/score.ts — the film's one score: D, 120 BPM (beat 30 f = 24 000 samples, bar 120 f, eighth 15 f).
// ONE theme, typed before it is ever heard whole:
//   MOTIF   D5 A5 G5 F#5 E5   a rising fifth that sighs back down (the lonely number)
//   ANSWER  A4 E5 F#5 E5 D5   the same rising fifth, a fifth lower, that comes home (the other one)
// Act 1 types it, one note per finished word, in a minor shadow (F♮ for F♯ over a D–A pedal) and stops short of home.
// The partner's landing turns the world D major (first kick + D1 sub). The theme is played complete and harmonised only
// from A7.lock. Beds change on their downbeats, never crossfaded:
//   Clock 0–240 · Paper 240–720 (a sus swell resolves on the unlock) · Garden 720–1200 · Day 1200–1920 (warm; cut dead) ·
//   Silence 1920–2280 · Range 2280–2640 · Resolve 2640–2988 (gone by A7.end).
// Every placement comes from audio/events.ts (the picture's cue sheet / act events) and the 120 BPM grid.
import { LEN, SPF, smp, stereo, place, placeStereo, peakDb, type Stereo } from "../core.ts";
import { rng } from "../../src/lib/rand.ts";
import { BAR, BEAT, EIGHTH } from "../../src/timeline/grid.ts";
import { hourAt } from "../../src/timeline/cues.ts";
import { evs, num, str, A1, A2, A3, A4, A5, A6, A7 } from "../events.ts";
import { db, ms, hz, n, notes, clamp, svf, fadeEdges, reverb, tapeStop } from "./dsp.ts";
import { feltPiano, marimba, pluck, kick, hat, clap, sideStick, bassNote, padChord, glassPad, chime, glassTone, subPulse, subHold, grainCloud } from "./instruments.ts";

export const MOTIF = notes("D5", "A5", "G5", "F#5", "E5");
export const ANSWER = notes("A4", "E5", "F#5", "E5", "D5");
const THEME = [...MOTIF, ...ANSWER];
/** Act 1's typing: the minor shadow, and an answer that never comes home */
const TYPED = [...notes("D5", "A5", "G5", "F5", "E5"), ...notes("A4", "E5", "F5", "E5", "A4")];

const S = smp;
const S16 = (BEAT * SPF) / 4; // a sixteenth: 6000 samples, sample-exact (7.5 f)
const CUT = S(A4.cut); // the hard cut: every voice that starts before it stops dead on it
const END = S(A7.end); // digital zero from here
const LEGATO = S(EIGHTH) + ms(90); // a melody note held into the next one, not through it
const PEAK_DB = -6; // the stem's peak before mastering (DESIGN §7: never above −1); the master normalises the sum
/** the hero SFX frames the whole score dips under (a short duck, so their transients clear the bed) */
const HERO = ["land", "unlock", "ting", "widget", "lock"];
const DUCK_DB = -4;
const nextBar = (f: number) => Math.ceil(f / BAR) * BAR; // the first bar line at or after f
const beatOf = (f: number) => Math.round(f / BEAT) % 4; // 0–3: the beat of the bar a frame on the beat falls on

type Put = (x: Float32Array, at: number, gdb: number, pan?: number, sendDb?: number) => void;
type Warm = { root: number; piano: number[]; cells: number[][] };

/** the warm bed (Day, and its echo in Resolve) from f0 to f1: a marimba ostinato in 8ths, one felt-piano chord, a muted
 *  bass in half notes, a soft kick on 1 and 3 and the side-stick on 2 and 4 (drums only where `drums(f)` allows) */
function warm(put: Put, f0: number, f1: number, c: Warm, seed: number, drums: (f: number) => boolean = () => true) {
  for (let e = 0, f = f0; f < f1; e++, f += EIGHTH) {
    put(marimba(c.cells[Math.floor(e / 4) % c.cells.length][e % 4], e % 2 ? 0.4 : 0.52, seed + e), S(f), -17, e % 2 ? 0.25 : -0.15, -27);
    if (e % 4 === 0) put(bassNote(c.root, Math.min(S(2 * BEAT), S(f1) - S(f)) - ms(25), 0.7, { cut0: 600, cut1: 200, res: 0.2, sub: 0.55, rel: ms(40) }), S(f), -17);
    if ((f - f0) % BEAT || !drums(f)) continue;
    if (beatOf(f) % 2 === 0) put(kick(beatOf(f) === 0 ? 0.8 : 0.7, seed + 50 + e), S(f), -18);
    else put(sideStick(seed + 60 + e), S(f), -20, 0.15);
  }
  for (const m of c.piano) put(feltPiano(m, 0.45, S(f1) - S(f0) - ms(40), seed + m), S(f0), -20, (m - 60) / 30, -24);
}
/** the bus dips DUCK_DB at each frame: 3 ms down, held 40 ms, back over ~160 ms */
function duck(t: Stereo, frames: number[]) {
  const d = 1 - db(DUCK_DB);
  const g = new Float32Array(t.L.length).fill(1);
  for (const f of frames)
    for (let i = Math.max(0, S(f) - ms(3)), s0 = S(f); i < Math.min(g.length, s0 + ms(700)); i++) {
      const k = i < s0 ? (i - (s0 - ms(3))) / ms(3) : i < s0 + ms(40) ? 1 : Math.exp(-(i - s0 - ms(40)) / ms(160));
      g[i] = Math.min(g[i], 1 - d * k);
    }
  for (let i = 0; i < g.length; i++) {
    t.L[i] *= g[i];
    t.R[i] *= g[i];
  }
}
/** multiply a stereo voice by env(u), u = 0…1 over its length */
function shape(x: Stereo, env: (u: number) => number): Stereo {
  const len = x.L.length;
  for (let i = 0; i < len; i++) {
    const g = env(i / len);
    x.L[i] *= g;
    x.R[i] *= g;
  }
  return x;
}

export function compose(): Stereo {
  const bus = stereo();
  const send = stereo();
  const r = rng(2026);
  let trim = 0; // the bed's level (dB), set at the head of each bed
  const fit = (x: Float32Array, at: number) => x.subarray(0, Math.max(0, Math.min(x.length, (at < CUT ? CUT : END) - at)));
  const v: Put = (x, at, gdb, pan = 0, sendDb = -Infinity) => {
    const y = fit(x, at);
    place(bus, y, at, db(gdb + trim), pan);
    if (sendDb > -90) place(send, y, at, db(sendDb + trim), pan);
  };
  const vs = (x: Stereo, at: number, gdb: number, sendDb = -Infinity) => {
    const y = { L: fit(x.L, at), R: fit(x.R, at) };
    placeStereo(bus, y, at, db(gdb + trim));
    if (sendDb > -90) placeStereo(send, y, at, db(sendDb + trim));
  };

  // ───────────── Clock · Act 1 (0 → A1.land): a D pedal in open fifths; the clock's tick (SFX) is the only pulse
  trim = -5;
  {
    const len = S(A1.land);
    v(subHold(n("D2"), len, ms(30), ms(20)), 0, -27);
    vs(glassPad(notes("D3", "A3", "E4"), len, { atk: ms(40), rel: ms(20), seed: 3 }), 0, -29, -30);
    // the motif, typed: one felt-piano (+ soft marimba) note per finished word; the last one hangs until the landing
    const words = evs("word", 0, A1.land);
    words.forEach((e, k) => {
      const i = Math.min(num(e, "n", k), TYPED.length - 1);
      const at = S(e.f);
      const last = k === words.length - 1;
      v(feltPiano(TYPED[i], (i % 5 === 0 ? 0.62 : 0.55) + 0.05 * r(), last ? S(A1.land) - at : LEGATO, 10 + i), at, -16, -0.15, -21);
      v(marimba(TYPED[i], 0.4 + 0.05 * r(), 20 + i), at, -27, -0.1, -29);
    });
  }
  trim = 0;
  // the partner lands: the first kick and a D1 sub pulse; from here the world is D major
  v(kick(0.95, 241), S(A1.land), -20);
  v(subPulse(n("D1"), 1.3), S(A1.land), -17);

  // ───────────── Paper · Act 2 (A2.land → A3.cell0): a muted plucked ostinato in 8ths, brushed side-stick on 2 and 4, a
  // rising bass. A small sus swell (no third) rises from the bar line into A2.unlock, the hero beat, where the major third
  // arrives with both answers; then IV – V into the streak's downbeat
  const PAPER = [
    { f: A2.land, bass: n("D2"), cell: notes("D4", "A4", "E5", "A4", "F#4", "A4", "E5", "A4"), piano: notes("D3", "A3", "F#4") }, // D(add9): he is here
    { f: A2.land + BAR, bass: n("F#2"), cell: notes("F#4", "C#5", "E5", "C#5", "A4", "C#5", "E5", "C#5"), piano: notes("F#3", "C#4", "A4") }, // F#m7: the question
    { f: A2.land + 2 * BAR, bass: n("G2"), cell: notes("G4", "D5", "F#5", "D5"), piano: notes("G3", "B3", "F#4") }, // Gmaj7: your answer
    { f: A2.unlock - BEAT, bass: n("A2"), cell: notes("A4", "E5", "D5", "E5"), piano: notes("A3", "D4", "E4") }, // Asus4: "Gửi"
    { f: A2.unlock, bass: n("D2"), cell: notes("D4", "A4", "F#5", "A4"), piano: notes("D3", "A3", "F#4", "E5") }, // D(add9): UNLOCK
    { f: A2.land + 3 * BAR, bass: n("G2"), cell: notes("G4", "D5", "F#5", "D5"), piano: notes("G3", "B3", "F#4") }, // Gmaj7: both answers read
    { f: A2.land + 3 * BAR + 2 * BEAT, bass: n("A2"), cell: notes("A4", "E5", "C#5", "E5"), piano: notes("A3", "C#4", "E4") }, // A: into the streak
  ].sort((a, b) => a.f - b.f);
  trim = 3;
  PAPER.forEach((c, k) => {
    const to = k + 1 < PAPER.length ? PAPER[k + 1].f : A3.cell0;
    for (let e = 0, f = c.f; f < to; e++, f += EIGHTH) {
      const onBeat = (f - A2.land) % BEAT === 0;
      v(pluck(c.cell[e % c.cell.length], (onBeat ? 0.62 : 0.5) + 0.01 * k, { t60: 0.2, tone: 0.22, exc: 1700, seed: 300 + f }), S(f), -15, onBeat ? -0.12 : 0.2, -30);
      if (e % 4 === 0) v(bassNote(c.bass, Math.min(S(2 * BEAT), S(to) - S(f)) - ms(25), 0.7, { cut0: 560, cut1: 180, res: 0.2, sub: 0.55, rel: ms(40) }), S(f), -16);
    }
    for (const m of c.piano) v(feltPiano(m, 0.4, S(to) - S(c.f) - ms(40), 450 + m + k), S(c.f), -22, (m - 60) / 30, -26);
  });
  for (let f = A2.land; f < A3.cell0; f += BEAT) {
    if (beatOf(f) % 2) v(sideStick(400 + f), S(f), -23, 0.18);
    else if (f > A2.land && beatOf(f) === 0) v(kick(0.7, 410 + f), S(f), -20);
  }
  {
    // the swell: A–D–E (a sus with no third, over the G and then the A bass) rising from the bar line, cut on the unlock
    const s0 = S(nextBar(A2.unlock) - BAR);
    const len = S(A2.unlock) - s0;
    vs(shape(glassPad(notes("A4", "D5", "E5"), len, { atk: ms(200), rel: ms(10), seed: 470 }), (u) => u ** 2.2), s0, -15, -20);
    vs(shape(padChord(notes("A3", "D4", "E4"), len, { atk: ms(200), rel: ms(10), cut: (i) => 500 + 1800 * (i / len), seed: 471 }), (u) => u ** 2.2), s0, -17, -24);
    // the unlock: the third arrives (a glass F#5 over the D chord) with a soft kick under it
    v(glassTone(n("F#5"), 0.6, 540), S(A2.unlock), -17, 0.1, -20);
    v(kick(0.75, 541), S(A2.unlock), -20);
  }

  // ───────────── Garden · Act 3 (A3.cell0 → A3.set): glass under a night sky; the streak climbs in glass, the stem in wood
  const GARDEN = [
    { pad: notes("D4", "F#4", "A4", "E5"), root: n("D2") }, // the streak strip
    { pad: notes("B3", "F#4", "A4", "D5"), root: n("B1") }, // the stem rises, the checks
    { pad: notes("G3", "D4", "F#4", "A4", "B4"), root: n("G1") }, // the bloom
    { pad: notes("A3", "D4", "E4", "A4"), root: n("A1") }, // Asus4 under the constellation…
  ];
  trim = -2;
  v(subPulse(n("D1"), 1.0), S(A3.cell0), -18); // the downbeat
  GARDEN.forEach((c, b) => {
    const f0 = A3.cell0 + b * BAR;
    if (f0 >= A3.set) return;
    const f1 = b === GARDEN.length - 1 ? A3.heart[0] : f0 + BAR;
    vs(glassPad(c.pad, S(f1) - S(f0) + ms(120), { atk: ms(120), rel: ms(120), seed: 500 + b }), S(f0), -17, -24);
    v(subHold(c.root, S(BAR) + ms(60), ms(60), ms(60)), S(f0), -22);
  });
  // …resolved to A when the heart resolves, ending dead on the set
  vs(glassPad(notes("A3", "C#4", "E4", "A4"), S(A3.set) - S(A3.heart[0]), { atk: ms(120), rel: ms(25), seed: 505 }), S(A3.heart[0]), -17, -24);
  // the day cells: every third of them rings, a glass tone climbing D4 → D6 along the strip (left → right)
  const CELL = notes("D4", "E4", "F#4", "A4", "B4", "D5", "E5", "F#5", "A5", "B5", "D6");
  const cells = evs("cell", A3.cell0, A3.set).filter((e) => num(e, "n") % 3 === 0);
  cells.forEach((e, k) => {
    const u = cells.length > 1 ? k / (cells.length - 1) : 1;
    v(glassTone(CELL[Math.round(u * (CELL.length - 1))], 0.4 + 0.25 * u, 600 + k), S(e.f), -18, -0.55 + 0.8 * u, -22);
  });
  // the stem's ruled steps: a damped wooden marimba knock per node, climbing
  const NODE = notes("A3", "B3", "D4", "E4", "F#4", "A4");
  evs("node", A3.cell0, A3.set).forEach((e, k) =>
    v(fadeEdges(marimba(NODE[Math.min(k, NODE.length - 1)], 0.5, 650 + k).slice(0, ms(110)), 0, ms(40)), S(e.f), -22, 0.05),
  );
  // the three checks: rising chimes D – F# – A
  const CHECK = notes("D5", "F#5", "A5");
  evs("treeCheck", A3.cell0, A3.set).forEach((e, k) => v(chime(CHECK[Math.min(k, 2)], 0.72, 700 + k), S(e.f), -16, 0.25, -18));
  // the filtered riser across bars 9–10: tonal, not noise — open fifths G then A (saws), low-pass and level rising into the set
  {
    const f0 = evs("riser", A3.cell0, A3.set)[0]?.f ?? A3.riser[0];
    const r0 = S(f0);
    const len = S(A3.set) - r0;
    const mid = S(A3.set - BAR) - r0;
    const cut = (i: number) => 260 * (5200 / 260) ** ((i / len) ** 1.4);
    const g5 = padChord(notes("G2", "D3", "G3", "D4"), mid + ms(15), { atk: ms(300), rel: ms(15), cut, seed: 710 });
    const a5 = padChord(notes("A2", "E3", "A3", "E4"), len - mid, { atk: ms(15), rel: ms(12), cut: (i) => cut(i + mid), seed: 711 });
    vs(shape(g5, (u) => ((u * g5.L.length) / len) ** 2), r0, -8, -24);
    vs(shape(a5, (u) => ((mid + u * a5.L.length) / len) ** 2), r0 + mid, -8, -24);
  }
  // the bloom: a granular shimmer in key from the first flower to the heart
  {
    const SH = notes("D6", "E6", "F#6", "A6", "B6", "D7");
    const len = S(A3.heart[0]) - S(A3.flowers[0]);
    vs(
      grainCloud({
        len,
        seed: 720,
        rate: (u) => 16 + 34 * Math.sin(Math.PI * Math.min(1, u * 1.3)),
        pitchHz: (_u, rr) => hz(SH[Math.floor(rr() * SH.length)]),
        grainLen: (u) => ms(70 - 30 * u),
        amp: (u) => Math.min(1, u / 0.25) * Math.min(1, (1 - u) / 0.35),
        width: 0.9,
      }),
      S(A3.flowers[0]),
      -25,
      -32,
    );
  }
  // the heart sets: the glass ting is the SFX's (audio/sfx 'ting', D6); the low boom under it is the score's
  evs("ting", A3.set, A3.set + 1).forEach((e) => v(subPulse(n("D1"), 1.5), S(e.f), -17));

  // ───────────── Day · Act 4 (A3.set → A4.cut): warm, not a tech ad. The warm bed (marimba ostinato, felt-piano chords, a
  // muted bass, a soft kick on 1 and 3, the side-stick on 2 and 4) behind a low-pass that opens across the day with the
  // playhead's hour (A4.ruler[1] → A4.stop); each event of the day is one note. The bed slows to a halt with the playhead
  // (tape-stop), breathes under the caption, comes back on the next bar line for the widgets and stops dead on the cut
  const DAY: Warm[] = [
    { root: n("D2"), piano: notes("D3", "A3", "F#4"), cells: [notes("D4", "A4", "F#5", "A4"), notes("D4", "A4", "E5", "A4")] }, // D(add9): the phone rises
    { root: n("D2"), piano: notes("D3", "G3", "B3"), cells: [notes("D4", "B4", "G5", "B4"), notes("D4", "B4", "F#5", "B4")] }, // G/D: the morning
    { root: n("B1"), piano: notes("B2", "F#3", "D4"), cells: [notes("B3", "F#4", "D5", "F#4"), notes("B3", "F#4", "A4", "F#4")] }, // Bm7: the afternoon
    { root: n("A1"), piano: notes("A2", "E3", "C#4"), cells: [notes("A3", "E4", "D5", "E4"), notes("A3", "E4", "C#5", "E4")] }, // Asus4 → A: the evening
  ];
  trim = 4;
  {
    const g0 = S(A3.set);
    const gb = stereo(S(A4.stop) - g0);
    const put: Put = (x, at, gdb, pan = 0) => place(gb, x, at - g0, db(gdb), pan);
    DAY.forEach((c, b) => {
      const f0 = A3.set + b * BAR;
      if (f0 < A4.stop) warm(put, f0, Math.min(f0 + BAR, A4.stop), c, 800 + 40 * b, (f) => f !== A3.set); // on the set, the boom is the downbeat
    });
    // the low-pass follows the day: closed until the first moment (A4.ruler[1]), then opening with the playhead's hour
    const h0 = hourAt(A4.ruler[1]);
    const lp = (i: number) => {
      const f = (g0 + i) / SPF;
      return f < A4.ruler[1] ? 650 : 650 * (14000 / 650) ** (clamp((hourAt(f) - h0) / (24 - h0), 0, 1) ** 0.6);
    };
    gb.L = svf(gb.L, lp, 0.15);
    gb.R = svf(gb.R, lp, 0.15);
    // the playhead stops: the bed slows to nothing over the last beat, silent on A4.stop
    tapeStop(gb, S(A4.stop - BEAT) - g0, S(A4.stop) - g0, 1.25);
    vs(gb, g0, 0);
  }
  // each event of the day is one note (marimba + felt piano), pitch by hour on the D-major pentatonic (hour 0 = D4,
  // hour 24 = D6); the rose "you" sits a fifth above the lavender other. Read from the event list, whatever its spacing
  const PENTA = [0, 2, 4, 7, 9];
  evs("event", A3.set, A4.stop).forEach((e) => {
    const step = clamp(Math.floor((num(e, "hour") / 24) * 10), 0, 10);
    const you = str(e, "who") === "you";
    const m = n("D4") + 12 * Math.floor(step / 5) + PENTA[step % 5] + (you ? 7 : 0);
    v(marimba(m, you ? 0.66 : 0.6, 960 + num(e, "n")), S(e.f), -14, you ? 0.35 : 0.15, -22);
    v(feltPiano(m, 0.5, LEGATO * 2, 970 + num(e, "n")), S(e.f), -19, you ? 0.35 : 0.15, -22);
  });
  // the playhead has stopped: under the caption the day breathes on G (IV), waiting for home (the next bar line)
  const D0 = nextBar(A4.lift[0]); // the delivery's downbeat
  evs("caption", A4.stop, A4.cut).forEach((e) => {
    const c0 = S(e.f);
    const len = S(D0) - c0;
    vs(glassPad(notes("G3", "B3", "D4", "F#4", "A4"), len, { atk: ms(450), rel: ms(40), seed: 980 }), c0, -21, -23);
    for (const [m, g, p] of [["G2", -17, -0.1], ["D3", -20, 0], ["B3", -21, 0.08], ["F#4", -22, 0.15]] as const)
      v(feltPiano(n(m), 0.45, len - ms(60), 990 + n(m)), c0, g, p, g - 6);
    v(subHold(n("G1"), len, ms(200), ms(40)), c0, -23);
  });
  // the delivery: the warm bed comes back open on D; a widget landing on a beat takes the drum's place; each widget is one
  // felt-piano note climbing A4 – D5 – F#5 under the SFX's pings (D6 – B5 – A5)
  {
    const widgets = evs("widget", A4.lift[0], A4.cut);
    const landed = new Set(widgets.map((e) => e.f));
    warm(v, D0, A4.cut, DAY[0], 1000, (f) => ![-2, -1, 0, 1, 2].some((d) => landed.has(f + d)));
    const WIDGET = notes("A4", "D5", "F#5");
    widgets.forEach((e, k) => {
      v(feltPiano(WIDGET[Math.min(k, 2)], 0.55, LEGATO * 2, 1020 + k), S(e.f), -17, -0.25 + 0.28 * k, -24);
      v(marimba(WIDGET[Math.min(k, 2)], 0.45, 1030 + k), S(e.f), -24, -0.25 + 0.28 * k);
    });
  }

  // ───────────── Silence · Act 5: digital zero to A5.silence[1]. The low felt-piano D2 enters with the first headline over a
  // faint open fifth that never lets the act drop out; a D-major swell on "Chỉ hai người."; the D2 again on the third
  trim = 0;
  {
    const hs = evs("headline", A5.silence[1], A5.hold).map((e) => e.f);
    const [h1, h2, h3] = [hs[0] ?? A5.h1, hs[1] ?? A5.h2, hs[2] ?? A5.h3];
    const s1 = S(A5.hold);
    vs(glassPad(notes("D3", "A3"), s1 - S(h1), { atk: ms(300), rel: ms(40), seed: 1955 }), S(h1), -24, -26);
    v(subHold(n("D2"), s1 - S(h1), ms(300), ms(40)), S(h1), -27);
    v(feltPiano(n("D2"), 0.62, S(h3) - S(h1) - ms(60), 1956), S(h1), -13, 0, -22);
    v(feltPiano(n("A2"), 0.45, S(h2) - S(h1) - ms(60), 1957), S(h1), -19, 0.05, -24);
    const len = s1 - S(h2);
    vs(padChord(notes("D3", "A3", "D4", "F#4", "A4"), len, { atk: ms(1200), rel: ms(40), cut: (i) => 500 + 1100 * (i / len), seed: 2040 }), S(h2), -19, -23);
    vs(glassPad(notes("F#4", "A4", "D5"), len, { atk: ms(1100), rel: ms(40), seed: 2041 }), S(h2), -25, -25);
    v(feltPiano(n("D2"), 0.56, s1 - S(h3) - ms(140), 2130), S(h3), -14, 0, -22);
    v(feltPiano(n("A2"), 0.42, s1 - S(h3) - ms(140), 2131), S(h3), -20, 0.05, -24);
  }

  // ───────────── Range · Act 6 (A6.composer[0] → A6.recede[1]): lighter and wider: IV – ii – V into the touch. Claps on 2
  // and 4, a plucked arp an octave up, the bass returns; each card landing rings one marimba note, climbing
  const RANGE = [
    { pad: notes("G3", "B3", "D4", "F#4", "A4"), root: n("G2"), arp: notes("G5", "B5", "D6", "F#6") }, // Gmaj9: the sheet, the cards
    { pad: notes("E3", "G3", "B3", "D4", "F#4"), root: n("E2"), arp: notes("E5", "G5", "B5", "D6") }, // Em9: the eight things
    { pad: notes("A3", "D4", "E4", "G4"), root: n("A2"), arp: notes("A5", "D6", "E6", "G6") }, // A7sus4: the dots…
  ];
  const TURN = { pad: notes("A3", "C#4", "E4", "G4"), arp: notes("A5", "C#6", "E6", "G6") }; // …A7 from beat 3
  const ARP = [0, 1, 2, 3, 2, 1];
  const BASS8: Array<[number, number]> = [[0, 0.75], [0, 0.5], [12, 0.6], [0, 0.5], [0, 0.7], [7, 0.5], [12, 0.6], [0, 0.5]];
  trim = 3;
  RANGE.forEach((c, b) => {
    const f0 = A6.composer[0] + b * BAR;
    if (f0 >= A6.recede[1]) return;
    const half = b === RANGE.length - 1 ? f0 + 2 * BEAT : f0 + BAR; // where the bar's chord turns (bar 22 only)
    for (const k of [0, 2]) v(kick(k === 0 ? 0.9 : 0.75, 1200 + 4 * b + k), S(f0 + k * BEAT), -16);
    for (const k of [1, 3]) vs(clap(1300 + 4 * b + k), S(f0 + k * BEAT), -19, -28);
    for (let e = 0; e < 8; e++) {
      const f = f0 + e * EIGHTH;
      if (e % 2) v(hat(true, 0.55, 1400 + 8 * b + e), S(f), -23, e % 4 === 1 ? -0.4 : 0.4);
      v(bassNote(c.root + BASS8[e][0], ms(e % 2 ? 140 : 200), BASS8[e][1], { cut0: 900, cut1: 220, sub: 0.4 }), S(f), -14);
    }
    for (let k = 0, s = S(f0); s < S(f0 + BAR); k++, s += S16) {
      const tones = s >= S(half) ? TURN.arp : c.arp;
      v(pluck(tones[ARP[(b * 16 + k) % ARP.length]], 0.5 + (k % 4 === 0 ? 0.12 : 0), { t60: 0.28, tone: 0.55, exc: 2600, seed: 1500 + 16 * b + k }), s, -22, k % 2 ? 0.5 : -0.5, -26);
    }
    vs(padChord(c.pad, S(half) - S(f0) + ms(30), { atk: ms(30), rel: ms(60), cut: () => 1500, seed: 1600 + b }), S(f0), -25, -28);
    if (half < f0 + BAR) vs(padChord(TURN.pad, S(f0 + BAR) - S(half) + ms(30), { atk: ms(30), rel: ms(60), cut: () => 1500, seed: 1610 }), S(half), -25, -28);
  });
  // the eight cards: one marimba note per landing (with a glass octave), climbing through the IV and the ii, panned by column
  const CARD = notes("B4", "D5", "E5", "F#5", "A5", "B5", "D6", "E6");
  evs("glyph", A6.composer[0], A6.recede[1]).forEach((e, k) => {
    const m = CARD[Math.min(num(e, "n", k), CARD.length - 1)];
    const pan = -0.45 + 0.3 * (num(e, "n", k) % 4);
    v(marimba(m, 0.55, 2310 + k), S(e.f), -18, pan, -25);
    v(glassTone(m + 12, 0.3, 2320 + k), S(e.f), -29, pan, -25);
  });

  // ───────────── Resolve · Act 7: the full arrangement for one bar (every bed's voice at once: the warm bed, Paper's pluck,
  // Range's claps and arp), then from A7.lock the theme complete for the first time, harmonised in D major; the final chord
  // is gone by A7.end
  trim = 1.5;
  {
    const f0 = A7.touch;
    const SEG = [
      { to: f0 + 2 * BEAT, w: DAY[0], pad: notes("D3", "F#3", "A3", "E4"), arp: notes("D5", "F#5", "A5", "E6"), ost: notes("D4", "A4", "E5", "A4") },
      { to: f0 + 3 * BEAT, w: { root: n("G2"), piano: notes("D3", "G3", "B3"), cells: [notes("D4", "B4", "G5", "B4")] }, pad: notes("D3", "G3", "B3", "F#4"), arp: notes("G5", "B5", "D6", "F#6"), ost: notes("G4", "D5", "F#5", "D5") },
      { to: A7.lock, w: { root: n("A2"), piano: notes("A2", "E3", "C#4"), cells: [notes("A3", "E4", "C#5", "E4")] }, pad: notes("C#3", "E3", "A3", "E4"), arp: notes("A5", "C#6", "E6", "A6"), ost: notes("A4", "E5", "C#5", "E5") },
    ];
    let from: number = f0;
    SEG.forEach((c, k) => {
      warm(v, from, c.to, c.w, 2000 + 40 * k);
      for (let f = from; f < c.to; f += BEAT) if (beatOf(f) % 2) vs(clap(2010 + f), S(f), -20, -28);
      for (let e = 0, s = S(from); s < S(c.to); e++, s += S16) {
        v(pluck(c.arp[ARP[e % ARP.length]], 0.5 + (e % 4 === 0 ? 0.12 : 0), { t60: 0.28, tone: 0.55, exc: 2600, seed: 2100 + 20 * k + e }), s, -23, e % 2 ? 0.5 : -0.5, -26);
        if (e % 2 === 0) v(pluck(c.ost[(e / 2) % 4], 0.56, { t60: 0.2, tone: 0.22, exc: 1700, seed: 2150 + 20 * k + e }), s, -18, e % 4 ? 0.2 : -0.12, -30);
      }
      vs(padChord(c.pad, S(c.to) - S(from) + ms(30), { atk: ms(25), rel: ms(50), cut: () => 1500, seed: 2200 + k }), S(from), -22, -27);
      vs(glassPad(c.pad.map((m) => m + 12), S(c.to) - S(from) + ms(30), { atk: ms(40), rel: ms(50), seed: 2210 + k }), S(from), -26, -24);
      from = c.to;
    });
  }
  trim = -0.5;
  {
    const L0 = A7.lock;
    v(subPulse(n("D1"), 1.6), S(L0), -18); // the soft sub boom (the glass ting is the SFX's 'lock')
    THEME.forEach((m, k) => {
      const at = S(L0 + k * EIGHTH);
      const last = k === THEME.length - 1;
      v(feltPiano(m, last ? 0.66 : k % 5 === 0 ? 0.68 : 0.6, last ? END - at : LEGATO, 2800 + k), at, -12, -0.05, -19);
      v(marimba(m, 0.48, 2820 + k), at, -20, 0.1, -25);
      v(glassTone(m + 12, 0.32, 2840 + k), at, -29, 0.2, -23);
    });
    // D – G/D – A/C# – D(add9): the melody's E is a ninth over the home chord and resolves to D on the last note
    const CAD = [
      { f: L0, bass: n("D2"), chord: notes("A3", "D4", "F#4"), glass: notes("D4", "F#4", "A4") },
      { f: L0 + BEAT, bass: NaN, chord: notes("B3", "D4", "G4"), glass: notes("D4", "G4", "B4") },
      { f: L0 + 2 * BEAT, bass: n("C#2"), chord: notes("A3", "C#4", "E4"), glass: notes("C#4", "E4", "A4") },
      { f: L0 + BAR, bass: n("D2"), chord: notes("F#3", "A3", "D4"), glass: notes("D4", "F#4", "A4", "D5") },
    ];
    CAD.forEach((c, k) => {
      const at = S(c.f);
      const to = k + 1 < CAD.length ? S(CAD[k + 1].f) : END;
      for (const m of c.chord) v(feltPiano(m, 0.46, to - at, 2900 + m), at, -20, (m - 60) / 30, -24);
      vs(glassPad(c.glass, to - at + ms(120), { atk: ms(80), rel: ms(150), seed: 2950 + k }), at, -20, -20);
      if (Number.isNaN(c.bass)) return;
      const next = CAD.slice(k + 1).find((d) => !Number.isNaN(d.bass));
      v(feltPiano(c.bass, 0.58, (next ? S(next.f) : END) - at, 2960 + k), at, k === 0 ? -17 : -14, -0.05, -22); // softer on the lock: the ting leads
    });
    vs(padChord(notes("D3", "F#3", "A3", "D4"), END - S(L0 + BAR), { atk: ms(60), rel: ms(200), cut: () => 1100, seed: 2970 }), S(L0 + BAR), -24, -24);
    v(subHold(n("D2"), END - S(L0 + BAR), ms(40), ms(300)), S(L0 + BAR), -22);
  }

  // ───────────── reverb (a fresh tail on each side of the hard cut, none after the end), the last fade, the level
  const wet = reverb(send, [[0, CUT], [S(A5.silence[1]), END]], { room: 0.84, damp: 0.32, lp: 6500 });
  for (let i = 0; i < LEN; i++) {
    bus.L[i] += wet.L[i];
    bus.R[i] += wet.R[i];
  }
  // the cut is dead, not a click: 3 ms to zero before it (every sample from CUT on is already zero)
  for (let i = CUT - ms(3); i < CUT; i++) {
    const g = (CUT - i) / ms(3);
    bus.L[i] *= g;
    bus.R[i] *= g;
  }
  const z0 = S(A7.lock + THEME.length * EIGHTH); // an eighth after the theme's last note
  for (let i = z0; i < LEN; i++) {
    const g = i >= END ? 0 : 0.5 + 0.5 * Math.cos((Math.PI * (i - z0)) / (END - z0));
    bus.L[i] *= g;
    bus.R[i] *= g;
  }
  duck(bus, HERO.flatMap((id) => evs(id).map((e) => e.f)));
  const g = db(PEAK_DB - peakDb(bus));
  for (let i = 0; i < LEN; i++) {
    bus.L[i] *= g;
    bus.R[i] *= g;
  }
  return bus;
}
