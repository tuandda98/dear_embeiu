# APP SHEET — Editorial greeting
seed 1822703143 · drawn 2026-10-20 · kind workspace · light
Brief: Dear Embeiu: app riêng của một cặp đôi Việt, mở mỗi ngày để xem người ấy hôm nay ra sao (câu hỏi, tâm trạng, chạm tim, về nhà, thời tiết), chơi caro, ghi sổ tiền chung

This is the style for this product. Adopt it whole and keep its move intact; everything the sheet does not fix comes from the
shared defaults in references/app-screens.md. Redraw only for a reason you can state (it contradicts the brand, or the product is
used in a way the style does not suit) and say why in your report. The values were measured on real product screens: use them
as given rather than rounding them towards your habits.

## 1. The style
A personal or team home that opens with a typeset greeting in a centred column; every number below it is set at regular weight on tonal panels.

**The move:** The greeting is the h1, in a centred 1100px column on a real 12-column grid (77px columns, 16px gutters), with spans that change by row but share column lines (3/3/3/3, then 9/3, then 6/6, so every internal edge meets one above it). Every figure below is set at regular weight on tonal panels, one layer each: a panel one step off white holds its title and its content directly; a white inner card is used once, for the main chart.

**Colour budget:** under 2% for the accent; tonal panels carry the structure.
**Off-style here:** an emoji in the greeting; a tracked uppercase date above the greeting (put the date after it or in the grey line below); a 624-864px column on a desktop screen (both were flagged as wasted width); a tray around every card (a grey panel with a white card 6px inside it, on every block, read as a bento template in testing); red as the accent: in testing red marked a record week of upgrades and read as an alarm; red is for the failing fact only.
Distilled from 2 screens: a team workspace home and a personal insights home. One studied screen set its greeting in a serif at 48/700 and its counts in a mono; the other set the greeting at 24/400 in the sans. The red is the second screen's chart red moved two degrees of hue out of the house terracotta range. After testing, the studied red accent was replaced by a deep teal: red on good news read as an alarm.

**Its face.** Choose one of these (or one of your own of the same weight) before you build, write it in your notes next to
the screen's question, and check that it shows on the first screen. Without one the screen reads as a well-applied kit.
- The greeting names this team or household and today's one fact, set from the data ("Morning, Okoro house. The car is ready by 06:10."), never "Welcome back".
- Each person's stable hue as a pale tint on their avatar and their own lane or column (a couple and their joint account as three lanes): identity, not data, so it stays out of the chart legends.
- A surface from the product's world in place of #f9f9f9, one level toward its material (a sage for a garden, a stone for a kitchen, a blue-grey for a studio), with the page white kept.

## 2. Tokens
Kept from the brand: map its colours onto this style's roles (ground, surface, raised, border, rule, control, text, muted, accent, status pills, chart) and keep its proportions: under 2% for the accent; tonal panels carry the structure. Take the sizes, radii, row and control heights from the style as they are.

## 4. Shell — Tinted frame, white sheet
Sidebar and top bar share one tinted ground with no rule between them, forming an L; the page lives on a white sheet. Variant one: the sheet butts against the sidebar and the top bar and is inset 8px from the right and bottom edges, 16px radius, 1px edge. Variant two: a flush L-frame with no inset, the frame marked by one rule. Variant three: sidebar and content are two floating panels inset 12px from every edge with a 12px gutter. The top bar, when present, is 48px and holds a centred search, the account button and a help or AI icon. Inside the sheet the content has 24px padding and starts with the breadcrumb or title row.
Numbers: chrome #f6f6f6-#f9fbfc (a warm #f7f6f2 once); sheetInset 8px from the window's right and bottom edges (12 and 16 once each); sheetRadius 10-16, median 16; sheetEdge 1px #eaeaea-#ededed, no shadow; sidebarWidth 220-263 (228 on two screens); topBar 48px on the chrome ground with no rule; search 548x32 centred on the window with a shortcut hint; contentPadding 24; floatingVariant both panels inset 12px with a 12px gutter, radius 10.
On a phone: The frame disappears: the sheet becomes the screen, with a 48px top bar (menu button, title, one action) on the chrome tint. The search moves into the menu sheet or behind an icon.

## 5. Screens

### home — Workspace home with a greeting
A centred column on a real 12-column grid (77px columns, 16px gutters, 1100px), about 72px from the top. The greeting is the h1 (48/700 in a serif, or 24/400 in the sans), with the date after it or in a grey line under it, never as a tracked eyebrow, and no emoji. 50px below, 4 count tiles spanning 3 columns each (128px tall, 16px padding): label, value at regular weight in tabular or mono figures, a plain caption ('Ready when you are'), no deltas. Then spans that change by row but share column lines (9 + 3, then 6 + 6, so each internal edge meets one above it) for the main objects: panels with 20px padding, a 14/600 title, a count chip and a 'View all' link, holding row cards 63px tall with 8px gaps, one step lighter than the panel with a border one step darker. Pale tints may code the panels, each in the hue of the tile that counts it. Only a floating composer, if there is one, carries a shadow, and it must not cover the last rows.
On a phone: Greeting at 24-28px; tiles in a 2 x 2 grid; panels stack in reading order.

### detail
No pattern in the library for this screen. Compose it from the rules in references/app-screens.md.

### list
No pattern in the library for this screen. Compose it from the rules in references/app-screens.md.

### settings — Settings in two columns
A centred column of about 1152px. Each section is one row: a label column of about 450px (16/500 title, 14px grey description; the title's cap top 6-8px below the panel top, level with the panel's first line) beside a panel of about 700px with a #fafafa fill, 16px radius, 16px padding, no border and no shadow. Sections are split by a full-width 1px rule with 32px above and below. Inside a panel: field labels 14/500 above 40px white inputs (1px #e8e8e8, radius 10), 8px from label to field, 16px between fields, 24px from the description to the first label, 16px to the Save button; switch rows with a 14/500 title, a 20px status badge 8px after it, a 14px grey description and a 28x16 toggle 16px from the right edge, centred on the title line. A plan-gated feature shows a 48px tinted strip with a 32px button directly above its panel, and the panel stays readable. When a panel runs much taller than its label, put the section's help or a summary of the current values in the label column rather than 250px of nothing.
On a phone: Each section stacks: title and description, then the panel at full width. Inside, label, 8-10px, field, 16-26px to the next pair; toggles stay on the right of their title.

### wallet
No pattern in the library for this screen. Compose it from the rules in references/app-screens.md.

## 6. Always
Real data for this product, written before the markup: names, amounts that add up, dates in order, units on every figure,
honest zeros and dashes. One chart answers one question. No gradients, glows, glass, icons in tinted squares, sparklines on KPIs,
rainbow charts, emoji, lorem or Acme. `<skill>/assets/app.css` and `<skill>/assets/charts.js` are a neutral start set to these
rules. Check with `node <skill>/scripts/lint.mjs <files>` and `node <skill>/scripts/inspect.mjs <page>`: this sheet switches both
to app rules.

Saved to /Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu-daily/.taste-skill/batch2/direction.json · reprint with `node draw.mjs --show`
