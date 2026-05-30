# 📁 project/ — Hệ thống quản lý dự án theo feature

> Đây là "trung tâm điều phối" của dự án Dear Embeiu. Mỗi tính năng (feature) có **một folder riêng** chứa đủ thông tin để **Designer, Dev, Tester dùng chung**, và **mỗi role tự ghi lại việc mình đã làm** cho feature đó.
> Bối cảnh tổng thể dự án nằm ở `../CLAUDE.md`. Folder này là nơi theo dõi *từng feature* chi tiết.

---

## Mục tiêu

1. Mở Claude trên bất kỳ máy nào → đọc folder này là biết **đang làm feature gì, tới đâu, ai đã làm gì**.
2. 3 vai (Designer/Dev/Tester) **chia sẻ cùng một nguồn sự thật** cho mỗi feature, không lạc nhau.
3. Mỗi khi có thay đổi liên quan feature → **tự cập nhật** file trong folder feature đó (không cần nhắc).

---

## Cấu trúc thư mục

```
project/
├── README.md                      ← file này (luật chơi)
├── ROADMAP.md                     ← PORTFOLIO: index TẤT CẢ feature + trạng thái (cấp dự án)
├── _templates/                    ← khuôn mẫu, copy khi tạo feature mới
│   ├── overview.md                (PO sở hữu)
│   ├── roadmap.md                 (PO — roadmap RIÊNG của feature)
│   ├── design.md                  (Designer ghi)
│   ├── dev.md                     (Dev ghi)
│   └── test.md                    (Tester ghi)
└── features/
    └── <ten-feature>/             ← 1 folder = 1 feature (vd: language, analytics)
        ├── overview.md            ← spec + quyết định + trạng thái + changelog (PO)
        ├── roadmap.md             ← roadmap RIÊNG feature: phase/version Now-Next-Later (PO)
        ├── design.md              ← design spec/handoff + nhật ký design (Designer)
        ├── dev.md                 ← kế hoạch + nhật ký implement (Dev)
        └── test.md                ← test case + kết quả + bug (Tester)
```

**Hai cấp roadmap:**
- `project/ROADMAP.md` = **portfolio** — toàn cảnh: có những feature nào, mỗi cái đang ở pha nào (cấp dự án).
- `features/<ten>/roadmap.md` = **roadmap riêng feature** — chi tiết bên trong 1 feature: chia phase/version, việc nào làm trước–sau, phụ thuộc gì.

**Quy ước đặt tên feature:** tên ngắn gọn không dấu theo chủ đề feature, dùng trực tiếp làm tên folder (vd `language`, `analytics`, `photo-reactions`, `daily-question`). Không tiền tố số. Nếu trùng tên thì thêm hậu tố phân biệt (vd `language`, `language-v2`).

---

## Ai sở hữu / ghi vào file nào

| File | Role sở hữu | Nội dung |
|------|-------------|----------|
| `overview.md` | **PO** | Vấn đề người dùng, value, phạm vi, **quyết định đã chốt (decision log)**, acceptance criteria, trạng thái tổng, changelog feature, link các file role. |
| `roadmap.md` | **PO** | Roadmap riêng feature: chia phase (Now/Next/Later), việc theo từng phase, mốc đã đạt, phụ thuộc. |
| `design.md` | **Designer** | Design spec/handoff (layout, token, state, copy VI+EN), nhật ký "đã thiết kế gì / ngày nào". |
| `dev.md` | **Dev** | Kế hoạch kỹ thuật, file/hàm đụng tới, model/Firestore/Function/native thay đổi, nhật ký "đã code gì / commit nào / deploy chưa". |
| `test.md` | **Tester** | Danh sách test case, kết quả PASS/FAIL, bug report (reproduce, expected vs actual), nhật ký lần test. |

> Tôn trọng ranh giới role (xem `../CLAUDE.md` mục 9): PO/Designer/Tester **không sửa code sản phẩm**; chỉ Dev implement. Nhưng **mọi role đều được ghi vào file của mình** trong folder feature.

---

## Quy trình (lifecycle 1 feature)

1. **PO khởi tạo:** copy `_templates/` → `features/<ten-feature>/`, điền `overview.md` (vấn đề, value, scope, quyết định, acceptance), thêm 1 dòng vào `ROADMAP.md`. Trạng thái: `📋 Spec`.
2. **Designer:** đọc `overview.md` → điền `design.md` (spec + handoff). Cập nhật trạng thái → `🎨 Design`.
3. **Dev:** đọc `overview.md` + `design.md` → điền `dev.md` (kế hoạch + nhật ký), implement. Trạng thái → `💻 Dev`.
4. **Tester:** đọc cả 3 → điền `test.md` (case + kết quả). Trạng thái → `🧪 Test`. FAIL thì trả về Dev.
5. **Xong:** mọi acceptance pass → trạng thái `✅ Done`. PO ghi dòng tổng kết vào changelog `overview.md`.

**Trạng thái chuẩn:** `📋 Spec` → `🎨 Design` → `💻 Dev` → `🧪 Test` → `✅ Done` (hoặc `⏸️ Paused`, `❌ Dropped`).

---

## Hai mode vận hành (chọn 1)

> Chi tiết & ranh giới đầy đủ ở `../CLAUDE.md` mục 9. Tóm tắt:

**🟦 Mode 1 — PO Orchestrator:** user **chỉ nói chuyện với PO**. PO tự spawn subagent Designer/Dev/Tester, điều phối cả pipeline, tự quyết câu hỏi nhỏ (theo spec/decision log/design system), chỉ hỏi user khi vượt thẩm quyền, rồi báo kết quả 1 lần khi xong.
- Kích hoạt: *"PO orchestrate feature X"* / *"PO tự điều phối làm feature X"*.
- Subagent đọc `features/<ten>/` để lấy ngữ cảnh + ghi vào file role mình → vẫn theo đúng hệ thống file này.
- **Quy tắc thực thi (để không giẫm chân, chính xác):** chạy **tuần tự 1 subagent/lúc** (Designer→Dev→Tester), không song song trong cùng feature; **1 file chỉ 1 agent chỉnh tại một thời điểm**; PO **gate verify giữa mỗi stage** bằng `flutter analyze` + đọc đĩa (đĩa là nguồn sự thật, không tin báo cáo suông); FAIL → 1 Dev-fix → re-verify (tối đa 2-3 vòng) → quá thì báo user. Đầy đủ ở `../CLAUDE.md` mục 9 ("Quy tắc thực thi orchestrator").

**🟩 Mode 2 — User tự điều phối (mặc định):** user tự gắn từng role (1 tab đổi vai, hoặc 4 tab) và tự chuyển tiếp theo "Giao thức bàn giao đa-tab" dưới đây.

| | Mode 1 (PO Orchestrator) | Mode 2 (Manual) |
|--|--------------------------|------------------|
| User nói chuyện với | Chỉ PO | Từng role |
| Ai điều phối | PO (spawn subagent) | User (chuyển tab/vai) |
| Kiểm soát từng bước | Thấp hơn | Cao nhất |
| Token | Cao hơn | Vừa |
| Hợp khi | Giao trọn việc | Tự tay kiểm soát |

**Ranh giới PO tự quyết vs hỏi user** (Mode 1): PO tự quyết chi tiết thực thi trong scope (có căn cứ spec/decision log/design system); PHẢI hỏi user khi đổi scope/giá trị, tiền bạc, đánh đổi lớn, bảo mật/quyền riêng tư, publish/deploy ra ngoài, việc khó hoàn tác. (Đầy đủ ở CLAUDE.md mục 9.)

---

## Giao thức bàn giao đa-tab (Mode 2 — khi mở 4 tab Claude cho 4 role)

> Mỗi role thường chạy ở 1 tab Claude riêng (4 tab = 4 context độc lập). Các tab KHÔNG tự gọi nhau và KHÔNG chia sẻ trí nhớ — chúng "nói chuyện" qua **file trên đĩa** trong `features/<ten>/`. User là người chuyển tab. Để không lệch nhau, mọi role tuân thủ giao thức 3 bước:

**① BẮT ĐẦU — luôn đọc file mới nhất trước khi làm**
- Mỗi role, ngay khi nhận việc, **đọc lại file liên quan trên đĩa** (đừng dựa vào trí nhớ của tab — tab khác có thể đã sửa). Đọc theo vai:
  - 🎨 Designer đọc: `overview.md`
  - 💻 Dev đọc: `overview.md` + `design.md`
  - 🧪 Tester đọc: `overview.md` + `design.md` + `dev.md`
  - 🧭 PO đọc: cả folder + `ROADMAP.md` khi cần chốt/điều phối.
- Nếu file mâu thuẫn / thiếu thông tin → hỏi lại (hoặc báo PO), KHÔNG đoán.

**② TRONG KHI LÀM — ghi vào đúng file của mình**
- Chỉ ghi file role mình sở hữu (overview=PO · design=Designer · dev=Dev · test=Tester). Ghi nhật ký `- [YYYY-MM-DD] [role] <việc>`. Cập nhật trạng thái phase ở `roadmap.md` + dòng ở `ROADMAP.md` (portfolio).

**③ KẾT THÚC — chốt bằng "câu bàn giao chuẩn"**
- Kết thúc lượt, role nói đúng mẫu để user biết chuyển tab nào & tab kế đọc gì:

  > ✅ [Role] đã xong [feature]. Đã cập nhật: `<file>`. → Chuyển sang **[Role kế]** (tab tương ứng), đọc `<file cần đọc>`.

  Ví dụ: *"✅ Designer đã xong language. Đã cập nhật: design.md. → Chuyển sang **Dev** (tab Dev), đọc overview.md + design.md."*
- Nếu Tester FAIL: *"❌ Tester: language có 2 case fail (xem test.md). → Quay lại **Dev**, đọc test.md mục Bug report."*

**Quy tắc vàng đa-tab:** *đầu lượt đọc đĩa — cuối lượt ghi đĩa + câu bàn giao.* Nhờ vậy 4 tab luôn đồng bộ qua file, dù không chia sẻ context.

> 💡 Mẹo: nếu thấy rối khi điều phối 4 tab, có thể dùng **1 tab đổi role tuần tự** (pipeline vốn tuần tự) — cùng giao thức file này, chỉ khác là không phải chuyển tab.

---

## Ai quyết định "Done" (Definition of Done)

> Không role nào tự tuyên bố feature "done" cho chính mình. "Hoàn thành" đi qua nhiều cửa:

| Cấp "xong" | Ai quyết định | Căn cứ |
|------------|---------------|--------|
| **Xong phần của mình** (task trong dev.md / design.md) | **Chính role đó** | Đã làm xong việc được giao → tick task + ghi nhật ký. Đây chỉ là "giao nộp", CHƯA phải feature done. |
| **Đạt chất lượng** (PASS/FAIL) | **Tester** | Chạy hết test case → verdict. Tester KHÔNG sửa code, chỉ phán xét. FAIL → trả về Dev. |
| **Feature DONE** (đóng ✅) | **PO** | Đối chiếu **acceptance criteria** trong `overview.md`. Đủ hết + Tester PASS → PO đổi trạng thái `✅ Done`. |
| **Duyệt release / ship** | **User (chủ sản phẩm)** | PO đề xuất; quyết định phát hành cuối cùng là của user. |

**Luồng done chuẩn:**
`Dev "xong gap A" (tự tick)` → `Tester chạy case → PASS/FAIL` → (PASS) `PO FINAL VERIFY → ✅ Done` → `User duyệt ship`.

**🔒 PO FINAL VERIFY (bắt buộc — Tester PASS KHÔNG tự động = Done):**
Sau khi Tester báo PASS, PO **không mark Done ngay**. PO tự kiểm độc lập rồi mới đổi `✅ Done`:
1. **Đối chiếu acceptance criteria** trong `overview.md` — từng tiêu chí đã đạt thật chưa (không chỉ tin verdict Tester).
2. **Verify ground-truth trên đĩa** — chạy `flutter analyze` (sạch), đọc lại điểm Tester báo + vùng nghi ngờ. Báo cáo mâu thuẫn → lệnh của đĩa thắng.
3. **Kiểm "case cần runtime"** — nếu còn case Tester đánh ⏳ (cần thiết bị thật / 2 máy / deploy) mà CHƯA chạy → **CHƯA Done**, vẫn ở 🧪 Test; PO nói rõ còn gì chặn.
4. **Kiểm việc cần user** — nếu Done phụ thuộc bước user duyệt (deploy/ship) → PO để ở trạng thái "chờ user", không tự đóng.
5. Chỉ khi (1-4) đều ổn → PO đổi `✅ Done` + ghi changelog `overview.md` + cập nhật `ROADMAP.md`, rồi báo user.

> Nếu PO final verify phát hiện lỗi/thiếu → KHÔNG Done: trả lại Dev (fix) hoặc Tester (test tiếp), ghi rõ lý do. PO là cửa cuối trước user — thà giữ ở Test còn hơn đóng Done non.

**Nguyên tắc chống "tự khen":**
- Dev KHÔNG tự tuyên bố feature done — chỉ "đã implement xong, sẵn sàng test" (người viết code dễ bỏ sót lỗi của mình).
- Tester gác cổng chất lượng, nhưng KHÔNG quyết định "đủ giá trị sản phẩm chưa" — đó là việc PO (so acceptance).
- PO chốt done dựa trên acceptance đã viết sẵn (không cảm tính) → vì vậy `overview.md` phải có acceptance rõ từ đầu.
- User có quyền phủ quyết cao nhất; PO chỉ đề xuất.
- **Vì Claude đóng nhiều role:** khi ở vai Tester phải đánh giá độc lập & nghiêm khắc, kể cả code do chính Claude (vai Dev) vừa viết — báo FAIL thẳng nếu có; khi ở vai PO chỉ đóng ✅ khi acceptance thật sự đủ; luôn trình kết quả để user duyệt, không tự đóng ✅ rồi im.

---

## Quy tắc TỰ ĐỘNG cập nhật (quan trọng)

- Bất cứ khi nào làm việc gì **liên quan tới một feature đã có folder** (sửa code, đổi thiết kế, test lại, đổi quyết định) → **tự cập nhật file tương ứng** trong `features/<ten-feature>/` + dòng trạng thái trong `ROADMAP.md`. Không cần user nhắc, không hỏi xin phép từng lần.
- Mỗi lần ghi nhật ký dùng format dòng: `- [YYYY-MM-DD] [role] <việc đã làm / đổi gì>`.
- Nếu là **feature mới chưa có folder** → tự tạo folder mới `features/<ten-feature>/` từ `_templates/` trước khi làm.
- Nếu thay đổi đụng tới bối cảnh chung dự án (kiến trúc, backend, design system…) → cập nhật cả `../CLAUDE.md` (theo quy ước ở đó).

### Update roadmap hay thêm tiếp? (quy tắc cho mọi thay đổi feature)

> Roadmap (`features/<ten>/roadmap.md`) là **sổ sống** — không xoá trắng lịch sử. Tuỳ bản chất thay đổi, chọn 1 (đôi khi cả 2):

| Loại thay đổi | Cách xử lý roadmap |
|---------------|--------------------|
| **Hoàn thành 1 việc** ("đã xong gap A") | ✅ **Update tại chỗ** — tick `[x]`, đổi trạng thái phase, thêm vào "Mốc đã đạt". KHÔNG thêm phase mới. |
| **Thêm việc mới vào feature đang có** | ➕ **Thêm tiếp** — thêm task vào phase phù hợp hoặc tạo phase mới (Phase n / Later); phần cũ giữ nguyên. |
| **Sửa/đổi cách làm việc đã có** | 🔄 **Update tại chỗ** — sửa nội dung task + ghi changelog (đổi gì, vì sao); quyết định cũ trong decision log thì **gạch + ghi cái mới**, không xoá. |
| **Bỏ 1 việc** | 🚫 Đánh dấu `❌ Dropped` + lý do — KHÔNG xoá hẳn (giữ vết). |
| **Ý tưởng lớn lệch hẳn scope** | 🆕 Cân nhắc **tách feature mới** thay vì nhồi vào roadmap cũ (vd reactions → `photo-reactions`). |

**Quy tắc cố định:**
1. **Không xoá lịch sử.** Việc xong → tick + chuyển "Mốc đã đạt". Việc bỏ → `❌ Dropped` + lý do.
2. **Mọi thay đổi → ghi changelog** trong `overview.md` (`- [YYYY-MM-DD] [role] <việc>`).
3. **Đồng bộ 2 cấp:** đổi pha feature → cập nhật trạng thái ở `ROADMAP.md` (portfolio) luôn.
4. **Decision log chỉ append/gạch, không xoá** — để biết vì sao từng chọn vậy.

> User KHÔNG cần chỉ định "update hay thêm" — chỉ cần nói thay đổi, Claude tự chọn đúng cách và luôn để lại dấu vết.

---

## Cách dùng (user ↔ Claude)

> User KHÔNG cần thao tác file thủ công. Chỉ cần gắn **role** + nói ý định; Claude tự tạo/cập nhật đúng file. **Quy tắc vàng:** mở đầu bằng role (PO/Designer/Dev/Tester) + tên feature.

### A. Tạo feature mới
- **Nói:** `"PO, tạo feature mới: <tên + mô tả ngắn ý tưởng>"`
- **Claude tự động:** đặt tên folder theo chủ đề → tạo `features/<ten-feature>/` từ `_templates/` → nghiên cứu + điền `overview.md` (vấn đề, value, scope, quyết định, acceptance, giao việc 3 vai) → tạo sẵn `design.md`/`dev.md`/`test.md` → thêm dòng vào `ROADMAP.md` (📋 Spec) → trình tóm tắt để review.
- **Triển khai tiếp:** `"Designer, làm feature <tên>"` → điền design; `"Dev, implement feature <tên>"` → code + ghi dev.md; `"Tester, test feature <tên>"` → chạy case + ghi test.md.

### B. Sửa / cập nhật feature cũ
- **Nói:** `"<role>, <feature nào>: <thay đổi gì>"` — vd `"Dev, feature language: đã xong gap A"`, `"Tester, feature language: case 7 fail"`, `"PO, feature language: bỏ tiếng Anh"`.
- **Claude tự động:** mở đúng folder → cập nhật file của role tương ứng (overview=PO, design=Designer, dev=Dev, test=Tester) → ghi nhật ký `- [YYYY-MM-DD] [role] <việc>` → cập nhật trạng thái ở `ROADMAP.md` → nếu đổi quyết định lớn thì cập nhật decision log + `../CLAUDE.md`.
- Không nhớ ID/tên? Nói tên gần đúng ("phần ngôn ngữ") — Claude tra trong `ROADMAP.md`.

### Mẹo nhanh
| Muốn | Câu nói gọn |
|------|-------------|
| Xem tất cả feature & trạng thái | "liệt kê roadmap" |
| Tạo mới | "PO, tạo feature mới: …" |
| Sửa spec/quyết định | "PO, feature X: đổi …" |
| Thiết kế / Code / Test | "Designer\|Dev\|Tester, … feature X" |
| Đánh dấu xong | "feature X đã done" |

---

## Liên kết

- Bối cảnh toàn dự án: [`../CLAUDE.md`](../CLAUDE.md)
- Bảng tất cả feature: [`ROADMAP.md`](ROADMAP.md)
