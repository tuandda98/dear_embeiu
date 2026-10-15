// Voice-over lines (vi-VN, edge-tts HoaiMy — scripts/vo.sh renders them to public/vo/<set>/NN.mp3 + .wav and writes
// public/vo/<set>/index.json with the measured durations). `at` = the frame the line starts (60 fps); a line must end
// before the next one starts — scripts/vo.sh checks that against the measured durations and prints any overlap.
// Voice: "chúng mình" / "người ấy"; every claim is in BRIEF §1. The film's lines read what is on screen (BRIEF §5).
export type VoLine = { id: string; at: number; text: string };

/** the 50 s film (option 1): lines placed on the cue sheet */
export const FILM_VO: VoLine[] = [
  { id: "a1-number", at: 30, text: "Mỗi app đếm ngày yêu đều có con số này." },
  { id: "a2-arrive", at: 250, text: "Rồi người ấy xuất hiện." },
  { id: "a2-mood", at: 530, text: "Bạn chọn cùng một tâm trạng." },
  { id: "a2-answer2", at: 624, text: "Trả lời xong là cùng mở." },
  { id: "a3-streak2", at: 760, text: "Mỗi ngày cùng trả lời, chuỗi dài thêm." },
  { id: "a3-tree2", at: 1000, text: "Mỗi cột mốc nở một bông hoa trên cây tình yêu." },
  { id: "a4-day", at: 1230, text: "Một ngày của chúng mình trong Dear Embeiu." },
  { id: "a4-events2", at: 1400, text: "Người ấy dậy, đăng ảnh, gửi lời quan tâm, nhắn tin, chia sẻ tâm trạng." },
  { id: "a4-caption", at: 1706, text: "Con số vẫn có. Chỉ là không còn trơ trọi." },
  { id: "a5-facts2", at: 1960, text: "Miễn phí, không quảng cáo. Chỉ hai người, ghép bằng mã mời." },
  { id: "a6-range2", at: 2300, text: "Trò chuyện riêng, lời quan tâm, lời nhắc, oẳn tù tì." },
  { id: "a6-free", at: 2525, text: "Miễn phí trên App Store và Google Play." },
  { id: "a7-sign2", at: 2700, text: "Dear Embeiu. Đếm ngày yêu, và mọi thứ sau con số." },
];

/** the 45 s product demo (option 2, composition "Demo"): one line per segment */
export const DEMO_VO: VoLine[] = [
  { id: "d1-hello", at: 30, text: "Đây là Dear Embeiu, không gian riêng của hai người." },
  { id: "d2-counter", at: 240, text: "Mở app là thấy đã bên nhau bao nhiêu ngày, tới từng giây, trên chính ảnh của hai bạn." },
  { id: "d3-question", at: 600, text: "Mỗi ngày một câu hỏi cho cả hai. Trả lời xong mới thấy người ấy viết gì." },
  { id: "d4-mood", at: 1020, text: "Hôm nay người ấy thấy sao? Chọn tâm trạng, trùng nhau là app nói cho bạn biết." },
  { id: "d5-sleep", at: 1380, text: "Đêm qua người ấy ngủ lúc mấy giờ? Trăng càng tròn, ngủ càng tròn giấc." },
  { id: "d6-more", at: 1740, text: "Ảnh chung, trò chuyện riêng, lời quan tâm gửi thẳng lên màn hình khoá." },
  { id: "d7-tree", at: 2100, text: "Cây tình yêu nở hoa theo từng cột mốc của chúng mình." },
  { id: "d8-cta", at: 2400, text: "Miễn phí trên App Store và Google Play. Dear Embeiu." },
];
