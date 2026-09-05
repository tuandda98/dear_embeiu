# Custom question — Tự đặt câu hỏi hằng ngày hôm nay

> File PO sở hữu. **Trạng thái: 📋 Brainstorm 2026-09-05 — chờ user chốt.** Mở rộng [endless-questions](../endless-questions/overview.md) / [daily-question](../daily-question/overview.md).

## 1. Yêu cầu
Nếu **chưa ai trả lời** câu hỏi hôm nay, một trong hai người được **tự đặt câu hỏi cho hôm nay** thay câu của engine. Có người trả lời rồi thì khoá.

## 2. Trải nghiệm đề xuất
- Trên thẻ "Hôm nay của chúng mình", **khi chưa ai trả lời**: hàng phụ nhỏ "✎ Đổi câu hỏi hôm nay". Chạm → sheet "Câu hỏi của bạn cho hôm nay": ô nhập ≤200 ký tự, 3 chip gợi ý nhẹ ("Điều gì làm em cười hôm nay?", "Cuối tuần này mình đi đâu?", "Anh muốn được nghe điều gì?"), nút "Đặt câu hỏi".
- Đặt xong: thẻ đổi câu ngay trên **cả hai máy**, kèm nhãn "Câu hỏi do Anh Test đặt ✎". **Đặt là CHỐT — không ai sửa/đổi đè nữa, kể cả người đặt** (user chốt 2026-09-05: "không ai được sửa câu hỏi"). Sheet đặt câu có bước xác nhận "Đặt xong sẽ không sửa được" trước khi ghi.
- Người ấy nhận **push** "Anh Test vừa đặt câu hỏi hôm nay: <câu>" (câu hỏi không riêng tư nên hiện nội dung) + inbox `custom_question` → tap về Home.
- Hàng "✎ Đặt câu hỏi hôm nay" chỉ hiện khi **chưa có câu custom VÀ chưa ai trả lời**; đã có 1 trong 2 điều kiện đó thì ẩn. Ai đang mở sheet mà bị người kia đặt/trả lời trước thì báo "Câu hỏi hôm nay đã chốt" và đóng sheet.
- Nhật ký & revisit & AI-context: câu tự đặt là câu của ngày đó, có nhãn "✎ do X đặt".

## 3. Kỹ thuật
- **Marker là nguồn sự thật** (đã có): đặt câu = ghi `dailyAnswers/{today}` `{questionVi: text, questionEn: text, source:'custom', customByUid, customLang, customAt, updatedAt}` (1 ngôn ngữ, hiện y nguyên ở máy kia).
- **Rules** hiện khoá `questionVi/En` khi đã có ⇒ cần **ngoại lệ có kiểm soát**. Rules không đọc được subcollection `responses` ⇒ thêm trường **`answeredBy: [uid…]`** trên marker: client `submitAnswer` merge `arrayUnion(uid)` (cả nhánh transaction lẫn fallback) và CF `notifyDailyAnswer` stamp `arrayUnion(uid)` (authoritative). Rule đặt câu (ngoại lệ DUY NHẤT của bất biến): `request.resource.data.source=='custom' && request.resource.data.customByUid==auth.uid && resource.data.get('source','')!='custom' && resource.data.get('answeredBy',[]).size()==0`. Sau khi `source=='custom'` thì `questionVi/En` **bất biến tuyệt đối** (rơi về rule cũ). `answeredBy` chỉ được **mở rộng** (`hasAll` cái cũ), không được xoá. Test emulator: đặt được khi chưa ai trả lời & chưa custom · DENY sau khi có `answeredBy` · DENY sửa câu custom (cả tác giả lẫn người kia) · client cũ không ảnh hưởng.
- **Provider**: thêm **listener marker** (hiện chỉ resolve 1 lần) → câu hỏi đổi realtime trên máy kia; sheet trả lời đang mở thì cập nhật câu + banner "Câu hỏi vừa được đổi"; `submit` kiểm câu trên marker == câu đang hiển thị, lệch thì hỏi lại. (Lợi phụ: mọi thay đổi marker khác cũng live.)
- **Engine**: `source=='custom'` → `_fromMarker` như thường; không ghi `askedBankIds`.
- **CF `notifyCustomQuestion`** (onWrite marker, khi `source` chuyển thành `custom` hoặc text đổi bởi cùng author): push + inbox cho người kia; skip nếu người kia chính là author. Additive.
- **Race:** A đặt câu đúng lúc B gửi trả lời: ai commit trước thắng nhờ rule (`answeredBy`); bên thua nhận lỗi rõ ràng ("Người ấy vừa trả lời / vừa đổi câu"), thẻ tự cập nhật.
- **Giới hạn:** ≤200 ký tự, không `{}`/`<>`; **đúng 1 lần/ngày, đặt là chốt**; couple phải active.

## 4. Ước lượng
1–1.5 ngày Dev (sheet + provider marker watch + rules/test + CF push) + deploy DEV/PROD (rules + CF). Rủi ro chính: thay đổi rule bất biến vừa thêm — phải test kỹ mixed-version.

## 5. Quyết định
- [2026-09-05] user: **KHÔNG AI được sửa câu hỏi** sau khi đặt (kể cả tác giả) — bỏ hẳn nhánh "sửa/đổi đè". Còn lại theo đề xuất: có push khi đặt câu; 1 lần/ngày.
