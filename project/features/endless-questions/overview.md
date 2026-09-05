# Endless questions — Câu hỏi không bao giờ hết, theo thời gian & theo lịch sử của chính cặp đôi

> File PO sở hữu. **Trạng thái: 📋 Brainstorm 2026-09-05 — chờ user chốt phạm vi.** Mở rộng feature [daily-question](../daily-question/overview.md).

## 1. Hiện trạng & vì sao sẽ hết
- Bank tĩnh **229 câu** (`lib/data/daily_questions.dart`), chọn = hoán vị cố định theo `coupleId` rồi lấy `daysSinceEpoch % 229`. Không lặp trong 1 chu kỳ, **sau 229 ngày lặp lại y nguyên**. Cặp dùng từ đầu tháng 6/2026 → **lặp từ khoảng giữa tháng 1/2027**.
- ⚠️ Bẫy đã ghi trong code: **thêm câu vào bank = đổi `n` = xáo trộn hoán vị của MỌI cặp** (câu đã hỏi có thể hỏi lại ngay, câu chưa hỏi bị nhảy). Không thể "cứ thêm câu" mà không đổi cơ chế chọn.
- Câu hỏi hiện là "vô thời gian" (không biết hôm nay thứ mấy, tuần này có gì, mood hôm nay, sắp tới mốc nào). Không dùng gì từ 90+ ngày câu trả lời đã có trong `dailyAnswers`.
- Điểm mạnh giữ lại: marker `dailyAnswers/{date}` **snapshot `questionVi/En`** lúc trả lời (quyết định PO A: không derive lại) → Journal luôn đúng dù engine đổi.

## 2. Kiến trúc đề xuất: "Question Engine" 4 tầng, chọn theo lịch tuần

**Nguyên tắc cốt lõi:** *marker là nguồn sự thật câu hỏi hôm nay.* Máy nào mở card đầu tiên sẽ **tạo marker với câu hỏi** (rule hiện đã cho member ghi `date/questionVi/questionEn`); máy kia đọc marker thay vì tự derive. Nhờ vậy câu hỏi được phép phụ thuộc dữ liệu động (mood, streak, ảnh tuần này, lịch sử) mà 2 máy vẫn thấy y hệt nhau. Thêm field `source` (`bank|template|revisit|ai`) + `questionId`/`refDate` để phân tích.

### Tầng 0 — Bank tĩnh (giữ) + chuyển sang chọn theo trạng thái
- Bỏ `% n`. Lưu `couples/{id}/questionState` = `{askedBankIds: [...], lastTemplateKeys: [...], aiEnabled}`; chọn câu chưa hỏi (seed ngày để deterministic), hết thì mới cho lặp câu **cũ hơn 180 ngày** và ưu tiên đóng khung "nhìn lại" (tầng 2). Từ đây thêm câu vào bank an toàn.
- Migration: hoán vị cũ vẫn tính được → backfill `askedBankIds` cho các ngày đã qua = tập chỉ số đã dùng từ ngày couple bắt đầu (hoặc từ marker có `questionVi` khớp).

### Tầng 1 — Template theo thời gian & ngữ cảnh (ưu tiên làm trước, 1–2 ngày)
- `khung thời gian` × `chủ đề` sinh câu: khung = hôm nay / mấy ngày qua / tuần này / cuối tuần vừa rồi / tháng này / từ đầu năm; chủ đề = cảm thấy thế nào · có gì vui · điều gì làm mệt · biết ơn điều gì ở người ấy · khoảnh khắc nhỏ cùng nhau · điều muốn làm cùng nhau sắp tới · điều học được về nhau · điều muốn được nghe từ người ấy…  (~6×15 = 90 tổ hợp, thêm 2–3 cách diễn đạt/tổ hợp → vài trăm câu tự nhiên, vi+en).
- **Hook theo lịch:** Thứ Hai "tuần mới…", Chủ nhật "nhìn lại tuần qua…", ngày 1 / cuối tháng, Tết – 14/2 – 8/3 – 20/10 – Noel – sinh nhật (nếu có), **mốc ngày yêu sắp tới** ("còn 3 ngày là 500 ngày yêu, muốn làm gì?"), **mood hôm nay** của người ấy ("hôm nay người ấy chọn 'mệt' — điều gì em có thể làm cho anh/em nhẹ lòng hơn?"), **ảnh tuần này** (chưa có ảnh nào → "khoảnh khắc nào tuần này đáng lưu lại?"), **chuỗi** (mốc 100/365).
- Lịch tuần gợi ý: T2 template-tuần-mới · T3 bank · T4 template-cảm-xúc · T5 bank · T6 revisit · T7 bank · CN recap-tuần. Ngày lễ/mốc ghi đè.

### Tầng 2 — "Nhìn lại" từ chính lịch sử của cặp (rule-based, không AI, 2–3 ngày)
- Chọn 1 câu trả lời cũ (cả hai đã trả lời, đủ dài, 30/100/365 ngày trước hoặc cùng ngày tháng năm ngoái) → hỏi tiếp bằng template + trích dẫn: *"30 ngày trước em viết 'muốn đi Đà Lạt cùng anh' — mình đã đi chưa, hay lên kế hoạch nhé?"*, *"Năm ngoái hôm nay hai người biết ơn điều '…' — giờ điều đó còn không?"*
- Dữ liệu đã có sẵn trong `dailyAnswers/{date}/responses`, đọc từ client (member read OK). Deterministic theo seed ngày. Trích dẫn cắt 60 ký tự, mỗi người thấy trích dẫn CỦA CHÍNH MÌNH (tránh lộ sớm câu người kia — cùng nguyên tắc reveal).

### Tầng 3 — AI sinh câu hỏi cá nhân hoá (3–5 ngày, đã nằm trong roadmap NEXT "Daily question AI")
- Cloud Function (callable idempotent, gọi khi máy đầu tiên mở card và marker chưa có; hoặc scheduled đêm) gửi cho Claude: ~30 cặp Q&A gần nhất (ẩn tên thật → "A"/"B"), thứ ngày, streak, mốc sắp tới, mood, số ảnh tuần → yêu cầu JSON `{vi, en, tags}` 1 câu ấm áp, không trùng chủ đề 14 ngày gần nhất, ≤200 ký tự, không `{}`. Ghi vào marker `source:'ai'`; lỗi/timeout → fallback tầng 1/0 (fail-open, không bao giờ trống card).
- Model gợi ý `claude-haiku-4-5` (rẻ, đủ) hoặc `claude-sonnet-5` cho chất lượng; ~1 call/cặp/ngày × ~2k token ⇒ chi phí không đáng kể. ⚠️ Khi implement PHẢI nạp skill `claude-api` để lấy model id/giá/param chuẩn.
- **Riêng tư:** câu trả lời là dữ liệu nhạy cảm → toggle **opt-in** trong Settings "Câu hỏi cá nhân hoá bằng AI" (mặc định tắt cho user cũ, hỏi 1 lần khi lên bản mới), ghi rõ dữ liệu chỉ dùng để sinh câu hỏi, không lưu ở bên thứ ba; cập nhật privacy policy. Rate-limit qua marker (1/ngày/cặp) + App Check.
- Bonus: **recap tuần Chủ nhật** do AI viết 2–3 dòng từ mood + ảnh + câu trả lời tuần, kèm 1 câu hỏi tổng kết.

## 3. Lộ trình đề xuất
| Pha | Việc | Kết quả |
|---|---|---|
| 0 | Marker = nguồn sự thật + `questionState` + chọn theo `askedBankIds` (bỏ `% n`) | Thêm câu an toàn, không lặp toàn lịch sử |
| 1 | Template thời gian/ngữ cảnh + hook lịch/mood/mốc, lịch tuần | Vài trăm câu "đúng lúc", hết lo cạn trong nhiều năm |
| 2 | "Nhìn lại" từ lịch sử (rule-based) | Cá nhân hoá không cần AI, không lo riêng tư |
| 3 | AI (opt-in) + recap tuần | Endless thật sự, càng dùng càng "hiểu" cặp đôi |

## 4. Câu hỏi chờ user chốt
- Có làm pha 3 (AI) ngay hay dừng ở pha 1–2 trước? (Mình nghiêng: 0+1 trước, đo tỉ lệ trả lời, rồi 2, rồi 3.)
- AI mặc định BẬT hay opt-in? (Mình đề xuất opt-in vì đọc câu trả lời riêng tư.)
- Ngôn ngữ template: viết tay vi trước, en dịch song song như bank hiện tại?
