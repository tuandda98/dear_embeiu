# Frame packet: 01-notification

## Project inputs

- Project: /Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu/videos/dear-embeiu-threads-promo
- Design tokens: /Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu/videos/dear-embeiu-threads-promo/frame.md
- RULES_DIR: /Users/dodaoanhtuan/.claude/skills/hyperframes-animation/rules

## Assigned storyboard block

## Frame 1 — Một thông báo

- scene: Dark iPhone lock screen at 22:41; one Dear Embeiu notification drops in — "Tuấn đang thấy Nhớ 🥹"
- voiceover: "22:41" · "Dear Embeiu — Tuấn đang thấy Nhớ 🥹"
- duration: 3.4s
- poster: 2.4s
- transition_in: cut
- status: outline
- src: compositions/frames/01-notification.html
- type: hook
- persuasion: Curiosity gap (a private, specific signal from the partner before any product is named)
- beat: intrigue + tenderness
- blueprint: compose
- registry: notification-cascade (installed at compositions/notification-cascade.html — use its banner CSS as reference only; hand-build ONE banner)
- asset_candidates: assets/bg-lock.jpg — portrait Unsplash couple photo, used as the lock-screen wallpaper under a dark scrim; assets/app_icon.png — the app icon inside the notification banner
- focal: assets/app_icon.png
- roles: bg-lock = background (dim ~55% navy scrim, slight blur) · app_icon = cutout (inside the banner)

narrativeRole: The hook. A real-looking lock screen and a single, oddly intimate notification make the feed stop scrolling before anything is sold.
keyMessage: Someone's phone just told them how their person feels tonight.

Scene 1 (0.0–0.6s): Full-bleed lock screen — `bg-lock.jpg` under a 55% navy scrim with a faint blur, iOS-style lock clock `22:41` (white, thin, ≈ 14cqw) with the date line `Thứ Tư, 15 tháng 10` above it, upper-third; the small lock glyph above the date. Nothing else. Layered-depth: photo → scrim → clock. The clock fades in over the first 0.4s (`spring-pop-entrance`, smooth settle, from 96% scale); then still.
Scene 2 (0.6–1.6s): The notification banner (`notification-cascade` adapted to ONE card: white 85% frosted pill-card, radius 28, app icon left, title `Dear Embeiu` + grey `bây giờ` right-aligned, body `Tuấn đang thấy Nhớ 🥹`) drops in from above the clock to just under it — centered, ≈ 88% canvas width, 3 depth layers (wallpaper, scrim, card). Entrance via `spring-pop-entrance` on a long-tail settle (no overshoot); at the moment it lands the scrim darkens 10% more and the wallpaper nudges 1% scale (the "phone lit up" feel — one tiny scale tween, then locked).
Scene 3 (1.6–3.5s): Hold. The card reads still; the only life is a soft rose radial glow (8%) behind the card that fades up once over 0.6s (one opacity tween) and stays. No breathing, no drift. (The harness `zoom-through` into Frame 2 is this frame's exit.)

## Selected motion rule: spring-pop-entrance

---
name: spring-pop-entrance
description: The canonical entrance pop — an element (or staggered group) arrives by scaling 0 → 1 on a smooth long-tail settle (power3 default); bouncy overshoot is a rare, explicitly-playful exception. fromTo so it's correct at t=0 under seek.
metadata:
  tags: spring, entrance, pop, scale, power3, settle, stagger, reveal, arrival
---

# Spring-Pop Entrance

> **Smooth beats bouncy.** This entrance defaults to a smooth long-tail settle — `power3.out` (or `expo.out` for a faster front) — that decelerates cleanly into the resting size with **no overshoot**. Bouncy `back.out` is the **#1 instant turn-off** in agent-made videos and is almost never executed well; it is a rare, explicitly-playful exception (consumer / fun brand), never the default. When unsure, settle smoothly.

THE entrance primitive: an element (or staggered group) arrives by springing from nothing — `scale: 0 → 1`, optional small `y` rise — and settles without bouncing. This is **arrival**, not reaction: distinct from [press-release-spring.md](press-release-spring.md) (a click/press → release feedback chain on an element that already rests on screen). Many blueprints used to borrow that rule to fake an entrance; reach for this instead.

## How It Works

One `fromTo` carries the whole arrival: from `{ scale: 0, opacity: 0 }` (explicit, so t=0 is correct under seek) to `{ scale: 1, opacity: 1, ease: "power3.out" }`. For a **group**, the same `fromTo` runs per element at `i * STAGGER`, capped so the group reads as one arriving beat. The `scale` grow is load-bearing; the `y` rise is garnish — drop everything else and it must still read as a clean entrance. Let the ease produce the settle: never hand-key a `scale: 1.1` mid-state (it double-bounces against the curve).

## Recipe

```html
<!-- inside a standard scene clip (hyperframes-core) -->
<div class="pop-hero" id="hero">{heroLabel}</div>

<div class="pop-grid">
  <div class="pop-item">{itemA}</div>
  <div class="pop-item">{itemB}</div>
  <div class="pop-item">{itemC}</div>
</div>
```

```css
.pop-hero,
.pop-item {
  transform-origin: 50% 50%; /* in-place pop; move to the source point for the anchored variation */
  will-change: transform;
}
.pop-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: GRID_GAP;
  place-items: center;
}
```

```js
// Single hero pop — smooth long-tail settle, no overshoot.
tl.fromTo(
  "#hero",
  { scale: 0, opacity: 0 },
  { scale: 1, opacity: 1, duration: POP_DUR, ease: "power3.out" },
  ENTRY_AT,
);

// Staggered group pop — one arriving beat.
gsap.utils.toArray(".pop-item").forEach((el, i) => {
  tl.fromTo(
    el,
    { scale: 0, opacity: 0, y: Y_RISE },
    { scale: 1, opacity: 1, y: 0, duration: POP_DUR, ease: "power3.out" },
    GROUP_ENTRY_AT + i * STAGGER,
  );
});
```

## Variations

- **Calm settle** (premium / enterprise): `power3.out`, no rotation, `Y_RISE` 0–12px — a weighted, confident landing for a hero wordmark or product shot.
- **Firm settle** (everyday default): `power3.out` or `expo.out` for a punchier front, `Y_RISE` ~24px — cards, icons, callouts.
- **Exact-physics settle**: when the settle IS the shot, swap the ease for `springEase({ response: 0.4 })` (critically damped) from `../adapters/gsap-easing-and-stagger.md` → Spring Eases; take `duration` from the helper.
- **Origin-anchored pop**: a callout growing out of a specific point (marker, pointer tip) sets `transform-origin` to that point (e.g. `0% 100%`) so `scale: 0 → 1` reads as "emerging from the source", not "inflating in place".
- **Pop into a held slot**: land the pop and hold still — no idle loop baked into the entrance. If the held frame genuinely needs life, hand off to [sine-wave-loop.md](sine-wave-loop.md) for subtle jitter on a separate later tween; prefer revealing the next element on its VO cue.
- **Bouncy pop (RARE — explicitly-playful only)**: swap the ease for `back.out(OVERSHOOT)` and optionally settle a small `rotation: ROT_FROM → 0` so elements look hand-placed. Only for a deliberately playful register — never product / enterprise / serious tone:

```js
tl.fromTo(
  el,
  { scale: 0, opacity: 0, rotation: ROT_FROM },
  { scale: 1, opacity: 1, rotation: 0, duration: POP_DUR, ease: `back.out(${OVERSHOOT})` },
  GROUP_ENTRY_AT + i * STAGGER,
);
```

Even here keep `OVERSHOOT ≤ ~2` — past that it reads as cartoon wobble. Better still: the baked spring at `dampingFraction: 0.6–0.7` (same adapters doc) gives ~5–10% overshoot that reads physical where `back.out` reads cartoon.

## Values

| token      | range                                     | notes                                                            |
| ---------- | ----------------------------------------- | ---------------------------------------------------------------- |
| EASE       | `power3.out` default; `expo.out` punchier | `back.out(OVERSHOOT)` only in the playful variant                |
| POP_DUR    | 0.4–0.7s                                  | shorter = tight snap; hero must be visible by **t ≤ 0.5s**       |
| STAGGER    | 0.04–0.08s                                | `min(0.06, 0.5 / ITEM_COUNT)` — self-caps the window             |
| ITEM_COUNT | 3–9                                       | >9 makes the stagger vanish — switch to a wipe/sweep reveal      |
| Y_RISE     | 0–32px                                    | small; never large enough to read as a slide-up                  |
| ROT_FROM   | −10°–+10°                                 | playful variant only; alternate sign by index (`i % 2 ? 6 : -6`) |
| ENTRY_AT   | 0–0.4s                                    | a beat of quiet, but keep the subject landing by t ≤ 0.5s        |

## Critical Constraints

- Default ease `power3.out` (no overshoot); `back.out` only in the explicitly-playful variant, and there `OVERSHOOT ≤ ~2`.
- `ITEM_COUNT × STAGGER ≤ ~0.5s` — the group must land inside one beat.
- Entrances state the collapsed from-state in `fromTo` — never rely on a CSS-hidden start (it renders visible before the tween claims it under seek).
- `transform-origin: 50% 50%` for an in-place pop; the source point only for the anchored variation.
- This is a finite arrival — idle motion on a held element is a separate, later `sine-wave-loop` tween.

## See also

`center-outward-expansion` (pop while radiating to slots) · `press-release-spring` (the click-feedback counterpart) · `sine-wave-loop` (post-arrival jitter, sparingly).
