# Brand v2: sheet tasteskill đã chia

> Designer, 2026-10-20. Worktree `feature/daily-open-2`. File làm việc của skill ở `.taste-skill/` (gitignore).
> Bản này **chờ user duyệt**. `project/design-system.md` (v1) vẫn là nguồn sự thật cho tới khi user chốt.

## 1. Lệnh đã chạy, theo thứ tự

1. `draw.mjs --app --kind workspace --brief "<Dear Embeiu…>" --screens home,detail,list,settings,wallet --theme light --options 3`
   Skill chỉ chia **2 style** (thư viện chỉ có 2 style sáng hợp kind `workspace`):
   - `editorial-greeting`: lời chào là h1, mọi con số đặt ở weight thường trên panel tông xám.
   - `achromatic-ledger`: chrome không màu, một màu biểu đồ xanh `#1d5fbf`, hợp tiền và báo cáo.
2. Thử thêm kind `wallet` (vào scratchpad, không ghi đè sheet) để so trước khi chọn, vì Dear Embeiu là app tiêu dùng trên điện thoại: chia ra `achromatic-ledger` và `pastel-consumer`. Không chọn, xem §3.
3. `draw.mjs --app … --style editorial-greeting` → sheet nguyên văn ở §2. **seed 665763129.**
4. Không chạy `--keep` (user chốt 2026-10-20: làm lại cả màu và phông).

## 2. Sheet nguyên văn (`draw.mjs --show`)

```text
# APP SHEET — Editorial greeting
seed 665763129 · drawn 2026-10-20 · kind workspace · light
Brief: Dear Embeiu: app riêng của một cặp đôi trẻ Việt Nam trên điện thoại, mở mỗi ngày: đếm ngày yêu, câu hỏi hôm nay, tâm trạng, giấc ngủ, ảnh chung, chọc tim, thời tiết hai nơi, về đến nhà, quỹ chung, chơi cùng nhau

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
```css
:root {
  --ground: #ffffff;
  --surface: #f9f9f9;
  --raised: #ffffff;
  --border: #eaeaea;
  --rule: #f3f3f3;
  --control: #d9d9d6;
  --text: #1f201d;
  --muted: #636361;
  --accent: #1b6e66;
  --positive: #2e7d32;
  --negative: #b42318;
  --warning: #92400e;
  --chart-1: #1f201d;
  --chart-2: #1b6e66;
  --chart-3: #8c8c88;
  --pill-positive-bg: #dcfae5; --pill-positive-ink: #04250e;
  --pill-negative-bg: #fdecea; --pill-negative-ink: #7a1d14;
  --pill-warning-bg: #fffbeb; --pill-warning-ink: #92400e;
  --pill-neutral-bg: #f3f3f3; --pill-neutral-ink: #3d3d3a;
  --radius-card: 22px;
  --radius-control: 999px;
  --row-height: 63px;
  --sidebar-width: 224px;
  --gap: 16px;
  --pad: 20px;
  --control-height: 38px;
  --fs-title: 48px;
  --fs-section: 14px;
  --fs-kpi: 32px;
  --fs-body: 14px;
  --fs-small: 12px;
}
```
Density: sparse. One gap value, horizontally and vertically. No shadow on anything at rest.

## 3. Type — Instrument Sans
```html
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600&family=Instrument+Serif:wght@400;500&display=swap" rel="stylesheet">
```
`font-family: "Instrument Sans", Inter, system-ui, sans-serif`. Weights 400, 500, 600. Sizes: title 48px · section 14px · kpi 32px · body 14px · small 12px. The 48px title is the serif greeting; set in the sans it is 24/400. Every figure is 400. Second face: Instrument Serif, for the greeting only.
Numbers: `font-variant-numeric: tabular-nums` on every table, KPI and anything that updates. Sentence case; no tracked capitals.

## 4. Shell — Open plane
The labelled sidebar sits on the page ground with nothing or one hairline between it and the canvas; there is no top bar, and the page header and cards sit straight on the ground about 32-36px from the top. Workspace or account switcher at the top of the sidebar, primary nav on a 34px pitch, groups under 12-13px sentence-case grey labels with 22-56px of air above, utilities and the user row pushed to the bottom. Cards are white on the off-white ground (or the sidebar is white with a 1px border on a #f9fafb canvas). The canvas is fluid with one gutter value, or a centred column for personal homes.
Numbers: sidebarWidth 230-256 (230, 240, 256 in the study; 280 and 292 with a built-in icon rail); separation none, or one 1px hairline; the sidebar sits on the page ground or within 1-2% of it; navPitch 34; navRowHeight 32; navIcon 16px outline, about 1.5px stroke; navLabel 14px, 400, grey or ink; activeItem neutral grey pill, radius 6-12, inset 8-12px from the sidebar edges (#e9e9e9-#ededed); topBar none; canvas fluid with a 24-64px gutter, or a centred 1100px column.
On a phone: The sidebar folds into a 48px top bar holding the screen's name, a menu button that opens a full-screen sheet with the nav and the switcher, and at most one action. Content takes the full width with 16px margins.

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

Saved to /Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu-daily/.taste-skill/direction.json · reprint with `node draw.mjs --show`
```

## 3. Vì sao chọn `editorial-greeting`

Một dòng: **Home của Dear Embeiu là "nhà" của hai người, mở vài lần mỗi ngày để liếc xem hôm nay ra sao; style này mở bằng một câu chào viết từ dữ liệu của chính cặp đó, và mặt (face) nó gợi ý là "một cặp đôi và tài khoản chung thành ba làn" — đúng nguyên liệu app đã có (màu riêng mỗi người ở `person_palette.dart`).**

Đặt từng style trước bản kiểm kê (`project/design-system-v2.md` §1):

| Style | Hợp ở đâu | Vướng ở đâu | Kết luận |
|---|---|---|---|
| `editorial-greeting` | Home cá nhân, lời chào là h1, số ở weight thường (nhẹ nhàng, không "dashboard"), panel tông không viền không bóng. Mặt "ba làn" khớp cặp đôi. | Lưới 12 cột 1100px là của desktop; trên 390px thành một cột, chỉ giữ ý "nhịp ngang hàng chung lề". Phông Instrument không có tiếng Việt (§4). | **Chọn** |
| `achromatic-ledger` | Hợp màn tiền (sổ chung, báo cáo tháng). | Chrome không một chút màu: với app tình cảm thì lạnh như sổ kế toán. | Không chọn cho app. Ghi nhận cho màn tiền (§5). |
| `pastel-consumer` (kind wallet) | Mỗi người một hue, tile pastel, bo lớn, hợp tiêu dùng di động. | Toàn bộ "move" xoay quanh tiền (cực tính thu/chi, số dư lớn); Home của mình không phải ví. Màu cobalt chia sẵn là của ví. | Không chọn cho app. Ứng viên số 1 cho màn tiền (§5). |

## 4. Redraw và thay thế (ghi đủ)

- **Không redraw style, shell hay screen.**
- **Phông: phải thay, lý do = ràng buộc tiếng Việt.** Kiểm bằng fontTools trên file thật tải từ `github.com/google/fonts` (`ofl/instrumentsans`, `ofl/instrumentserif`):
  - Instrument Sans: **50/146** ký tự tiếng Việt (thiếu 96, gồm ơ ư ĩ ũ và toàn bộ ạ ả ấ ầ ẩ ẫ ậ ắ ằ ẳ ẵ ặ ẹ ẻ ẽ ế…). METADATA chỉ có subset `latin`, `latin-ext`.
  - Instrument Serif: **50/146**, cùng thiếu.
  - App sheet (`draw.mjs --app`) **không có slot `--redraw type`** (chỉ `style|shell|screen:<name>`; xem `scripts/lib/app-draw.mjs` dòng 96–99). Nên thay theo đúng vai trò sheet giao ("một grotesk + một serif chỉ cho lời chào"), lấy ứng viên từ chính thư viện của skill (`library/type.json` + họ phông của 7 app style), lọc subset `vietnamese`, rồi kiểm file thật:
    - **Hanken Grotesk** (`library/type.json` → `hanken-medium`), thay Instrument Sans: **146/146**, OFL 1.1, biến thiên `wght` 100–900, chữ số **mặc định đã đều độ rộng** (0–9 cùng 560 đơn vị) nên số trong làn, đồng hồ, tiền không nhảy.
    - **Newsreader** (`library/type.json` → `newsreader-light`), thay Instrument Serif cho lời chào: **146/146**, OFL 1.1, trục `opsz` 6–72 + `wght` 200–800, có `tnum`.
  - Đã loại: Geist, Inter (skill coi là "mặt của bộ kit"), DM Sans/Schibsted/Albert Sans/Instrument (không có tiếng Việt), Be Vietnam Pro / Quicksand (là nhận diện cũ, user muốn đổi).
- **Màu: giữ nguyên bảng sheet chia.** Nhấn `#1b6e66` (xanh mòng két đậm). Không lấy lại hồng: user chốt bỏ `#FF6B9D`, và sheet ghi rõ đỏ/hồng-đỏ làm nhấn bị đọc như báo động.

## 5. Ghi chú cho màn tiền sau này (theo yêu cầu Lead 2026-10-20)

Feature `expenses` mở rộng thành quản lý tiền đầy đủ. Hai style cho kind `wallet`/`finance`:

- `pastel-consumer` **hợp nhất** cho màn tiền: tile danh mục pastel với mực cùng hue, số tiền nằm trong thẻ giải thích nó, "mỗi người một hue cách nhau ≥ 60°" — trùng khớp màu riêng mỗi người. Khi làm, giữ phông + nền + nhấn của v2 (`--keep palette,type` với v2), chỉ lấy cách tổ chức: thu dương có dấu "+", chi bằng mực, không tô đỏ khoản chi thường.
- `achromatic-ledger` hợp cho **báo cáo tháng** (biểu đồ một màu, số in mực, chỉ đổi màu chỗ thay đổi).
- Home chỉ có **một hàng "Sổ chung tháng này"** (số của sổ chung, không bao giờ số của sổ riêng người ấy). Không thiết kế màn tiền ở đợt này.

## 6. Mockup

| File | Nội dung |
|---|---|
| `mock/home.html` | Home v2, cặp đã ghép (Tuấn ♥ Thảo, 20/10/2026 12:20) |
| `mock/home-waiting.html` | Home v2, cặp đang chờ người ấy (Minh, chờ Ngọc) |
| `mock/home-states.html` | Khối "Hôm nay" + các khối khác ở trạng thái tải, ngày mới (số 0), lỗi, mất mạng, trống |
| `mock/profile.html` | Hồ sơ đổi sang v2 (chứng minh hệ thống đứng được ngoài Home) |
| `mock/data.js` | Dữ liệu mẫu + 21 `console.assert` |
| `mock/v2.css`, `mock/ui.js` | Token v2 + khung (thanh trên, thanh tab, icon nét) |
| `mock/fonts/` | Hanken Grotesk + Newsreader (OFL, kèm `OFL-*.txt`) |
| `mock/img/` | 6 ảnh Unsplash (giấy phép Unsplash, đã dùng làm ảnh seed DEV `scripts/dev-seed-widget-accounts.js`); chỉ đứng thay ảnh của người dùng |

Mở thẳng `home.html` bằng trình duyệt là xem được (font và ảnh để offline).
