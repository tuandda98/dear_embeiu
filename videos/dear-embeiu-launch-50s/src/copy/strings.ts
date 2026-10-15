// Every on-screen string of the film. Product strings are verbatim from the app (lib/l10n/app_vi.arb — key in the
// comment — or functions/index.js for push copy, or the seeded mock data as captured in ref/); "film" marks the film's
// own copy (few, short, every claim checked against BRIEF §1). Never inline a Vietnamese string in an act: read it from T.
// Voice: "chúng mình" / "người ấy", never "hai đứa" (BRIEF §1 Voice).

export const LANG = "vi";

const vi = {
  /** the mock couple (dev-seed-widget-accounts.js + dev-seed-promo.js) */
  couple: { you: "Thảo", other: "Tuấn", names: "Thảo ♥ Tuấn", youLabel: "BẠN", otherLabel: "TUẤN" },

  a1: {
    eyebrow: "HAI BẠN ĐÃ BÊN NHAU", // youveBeenTogetherFor
    days: "1250", // 14/05/2023 → 15/10/2026
    unit: "NGÀY", // daysUnit (uppercase as the card draws it)
    /** the live clock at 09:41:07 of day 1250 (hours since the anniversary · minutes · seconds, as the card draws it) */
    clock: { hours: 30009, minutes: 41, seconds: 7, labels: ["GIỜ", "PHÚT", "GIÂY"] as const },
    caption: "Mỗi app đếm ngày yêu đều có con số này.", // film
  },

  a2: {
    push: { title: "Tâm trạng hôm nay 💗", body: "Tuấn đang thấy Nhớ", app: "Dear Embeiu", when: "bây giờ" }, // PARTNER_MOOD_COPY.vi
    header: "HÔM NAY CỦA CHÚNG MÌNH", // homeTodaySectionTitle, uppercased as the sheet header
    rows: [
      { label: "Câu hỏi hôm nay", other: "Tuấn đã trả lời rồi đó 👀", you: "" }, // dailyQuestionLabel · dailyPartnerAnsweredTeaser
      { label: "Tâm trạng", other: "🥹 Nhớ", you: "" }, // moodCardTitle (short) · moodMissing
      { label: "Đêm qua", other: "23:10 → 06:00", you: "" }, // sleepCardTitle · the seeded night
    ],
    sheetTitle: "Hôm nay bạn thế nào?", // moodSheetTitle
    noteHint: "Thêm đôi lời (không bắt buộc)", // moodNoteHint
    save: "Lưu tâm trạng", // moodSaveCta
    moods: [
      ["😄", "Vui"],
      ["🥰", "Hạnh phúc"],
      ["🥹", "Nhớ"],
      ["😌", "Bình yên"],
      ["😐", "Bình thường"],
      ["😪", "Mệt"],
      ["😢", "Buồn"],
      ["😣", "Căng thẳng"],
    ] as const, // kMoodOptions + moodHappy…moodStressed
    picked: 2, // "Nhớ"
    matched: "Chúng mình cùng một tâm trạng 💞", // moodMatched
    caption: "Cần cả hai.", // introSlide3Title
    send: "Gửi", // dailyQuestionSend
    question: "Điều nhỏ nhặt nào người ấy làm khiến bạn thấy được yêu thương?", // seeded TODAY_Q
    answerYou: { label: "Câu trả lời của bạn", text: "Anh luôn nhắn \"về chưa\" dù biết em về rồi" }, // dailyQuestionYourAnswerLabel · typed when captured
    answerOther: { label: "Câu trả lời của Tuấn", text: "Em hay để lại mẩu giấy nhỏ trong túi áo anh, mỗi lần lấy ra là cười một mình." }, // dailyQuestionPartnerAnswerLabel · seeded TODAY_A
    both: "Hôm nay cả hai đã trả lời", // dailyBothAnsweredToday
  },

  a3: {
    streak: 31, // 30 revealed days before today + today's reveal
    chip: "31 ngày kết nối · hôm nay xong rồi", // streakChipActiveToday
    checks: ["1000 ngày bên nhau", "Chuỗi 30 ngày", "10 ảnh kỷ niệm"], // loveTreeMilestoneDays/Streak/Photos — the last milestone crossed of each kind
    stars: ["Câu hỏi", "Tâm trạng", "Nhắn tin"], // the constellation's three stars per person (today_constellation)
    labelBadge: "CÂY TÌNH YÊU", // loveTreeBadge
    labelFlowers: "· 12 bông hoa đã nở", // loveTreeFlowerCount, as captured
  },

  a4: {
    label: "HÔM NAY · 15/10/2026 · 00:00 → 24:00", // film (the date as captured)
    /** the day's events in order; `who` = who it comes from (rose = you, lavender = the other); hour = decimal hours */
    events: [
      { hour: 6.0, who: "other", icon: "moon", title: "Tuấn dậy · 6g 50p", body: "23:10 → 6:00" },
      { hour: 7.133, who: "you", icon: "moon", title: "Bạn dậy · 7g 23p", body: "23:45 → 7:08" },
      { hour: 8.2, who: "other", icon: "photo", title: "Tuấn vừa đăng ảnh mới 💞", body: "Ghế quen ở hồ Gươm" }, // PHOTO_NOTIFICATION_COPY · caption as captured
      { hour: 12.5, who: "other", icon: "care", title: "Ăn cơm chưa? 🍚", body: "Nhớ ăn cơm đúng bữa, đừng bỏ bữa nha." }, // careQuick3Title/Body
      { hour: 15.083, who: "other", icon: "question", title: "Tuấn đã trả lời câu hỏi hôm nay 💞", body: "Tới lượt bạn." }, // DAILY_QUESTION_COPY, first sentence (BRIEF §5)
      { hour: 15.5, who: "you", icon: "question", title: "Bạn đã trả lời · mở cả hai 💞", body: "Hôm nay cả hai đã trả lời" }, // film + dailyBothAnsweredToday
      { hour: 19.667, who: "other", icon: "chat", title: "Tin nhắn mới 💬", body: "Tuấn vừa nhắn cho bạn 💌" }, // CHAT_MESSAGE_COPY
      { hour: 21.0, who: "other", icon: "bell", title: "Lời nhắc từ người ấy ⏰", body: "Tuấn đặt lời nhắc cho bạn lúc 21:00: Uống nước nha" }, // PARTNER_REMINDER_SET_COPY
      { hour: 22.683, who: "other", icon: "mood", title: "Tâm trạng hôm nay 💗", body: "Tuấn đang thấy Nhớ" }, // PARTNER_MOOD_COPY
      { hour: 22.75, who: "you", icon: "mood", title: "Bạn: Nhớ 🥹", body: "Chúng mình cùng một tâm trạng 💞" }, // film + moodMatched
      { hour: 23.167, who: "other", icon: "moon", title: "Tuấn đi ngủ", body: "23:10" },
    ] as const,
    counters: [
      { label: "Ảnh", from: 11, to: 12 }, // 12 khoảnh khắc after the day's photo
      { label: "Sao hôm nay", from: 2, to: 6 }, // the constellation pill 2/6 → 6/6
      { label: "Chuỗi", from: 30, to: 31 },
    ] as const,
    caption: ["Con số vẫn có.", "Chỉ là không còn trơ trọi."], // film (approved 15/10/2026)
    /** the rebuilt Home (ref/ios/home-top.png) */
    home: {
      greeting: "CHÀO BUỔI SÁNG, THẢO", // homeGreetingMorning + name, uppercased by the chip
      milestone: "Cột mốc 1500 ngày", // milestoneNextLabel
      milestoneLeft: "còn 250 ngày", // milestoneDaysLeft
      today: "Hôm nay của chúng mình", // homeTodaySectionTitle
      pill: (n: number) => `${n}/6`,
      question: "Điều nhỏ nhặt nào người ấy làm khiến bạn thấy được yêu thương?",
      unlock: "Trả lời để mở khoá câu trả lời của người ấy", // dailyAnswerToReveal
      mood: "Tâm trạng hôm nay", // moodCardTitle
      sleep: "Đêm qua", // sleepCardTitle
      sleepYou: ["7g 23p", "23:45 – 7:08"],
      sleepOther: ["6g 50p", "23:10 – 6:00"],
      sleepTogether: "Ngủ cùng lúc 6g 15p · Tuấn ngủ trước 35p", // as captured
      memories: "Kỷ niệm gần đây", // recentMemoriesTitle
      nav: ["Trang chủ", "Trò chuyện", "Kỷ niệm", "Hồ sơ"], // navHome…navProfile
      streakBefore: "30 ngày kết nối · chờ trả lời hôm nay 🌸", // streakChipInProgress(30); after the reveal: a3.chip
      tapToAnswer: "Chạm để trả lời…", // dailyTapToAnswer (nobody answered yet)
      reactHint: "Thả cảm xúc cho câu trả lời của người ấy", // answerReactionHint
      collapse: "Thu gọn", // dailyCollapse
      moodYouEmpty: "Chạm để chia sẻ", // moodNotSharedYou
      moodOtherEmpty: "Tuấn chưa chia sẻ hôm nay", // moodPartnerEmpty(Tuấn)
      moodShare: "Chia sẻ tâm trạng", // moodShareCta
      moodUpdate: "Đổi tâm trạng", // moodUpdateCta
      moodNote: "Nhớ em quá, tối gọi nha", // Tuấn's seeded mood note (BRIEF §1)
    },
    /** the home-screen widget (ios/DearEmbeiuWidget, android widget_day_*.xml) */
    widget: { days: "1250", unit: "ngày", names: "Thảo ♥ Tuấn", milestone: "Cột mốc 1500 ngày", left: "còn 250 ngày", empty: "Dear Embeiu",
      caption: "ngày bên nhau", // the widget's line under the number (preview_days_label / widget_preview_caption = daysTogether, lowered)
      since: "Bắt đầu từ 14 thg 5, 2023", // the medium widget's last line (preview_since = guestCounterStartFrom + fullDateFormat)
    },
  },

  a5: {
    facts: [
      ["Miễn phí", "Không quảng cáo"], // dearembeiu.com: "Miễn phí. Không quảng cáo."
      ["Chỉ hai người", "ghép bằng mã mời 6 ký tự"], // invite code, 6 characters
      ["Ảnh, tin nhắn, câu trả lời", "chỉ hai người thấy"], // PLAY_CONSOLE_CONTENT: "Chỉ hai người được ghép cặp…"
      ["Không bạn bè", "không bảng tin · không ai khác"], // dearembeiu.com
      ["Xoá tài khoản", "ngay trong app"], // deleteAccountBtn · Settings → Tài khoản
      ["Tiếng Việt · English", "iOS 14+ · Android 6+"], // supportedLocales · dearembeiu.com
    ] as const,
    footer: "dearembeiu.com",
    h1: "Không bạn bè. Không mạng xã hội.", // dearembeiu.com, as two sentences
    h2: "Chỉ hai người.",
    h3: ["Miễn phí.", "Không quảng cáo."], // the second sentence in rose
  },

  a6: {
    placeholder: "Nhắn gì đó cho người ấy…", // chatComposerHint
    /** the seeded chat already on screen above the composer (dev-seed-widget-accounts.js CHAT; ref/ios/chat.png): who 0 = Tuấn (left, grey), 1 = Thảo (right, navy) */
    history: [
      [0, "Em ăn cơm chưa? 🍚"],
      [1, "Em ăn rồi nè, anh thì sao?"],
      [0, "Anh vừa xong, tối nay xem phim nha"],
      [1, "Okii, em chọn phim nhé 😚"],
    ] as const,
    typed: "Tối nay xem phim nha", // film (the seeded chat: "Anh vừa xong, tối nay xem phim nha")
    typing: "đang soạn…", // the typing indicator
    chips: ["Nhớ quá 💕", "Uống nước nha 💧", "Ăn cơm chưa? 🍚", "Ngủ sớm nha 🌙", "Yêu nhiều lắm ❤️", "Cố lên nha 💪"], // careQuick1…6Title
    glyphs: ["Đếm ngày yêu", "Ảnh chung", "Câu hỏi mỗi ngày", "Tâm trạng", "Giấc ngủ", "Trò chuyện", "Lời nhắc", "Oẳn tù tì"], // the eight things (intro/guestCounterTitle, gallery, dailyQuestion, mood, sleep, navChat, reminders, rpsGameTitle)
    ticker: ["Widget màn hình chính", "Cây tình yêu", "Lịch âm", "Nhật ký câu hỏi", "Gửi quan tâm", "Mã QR mời"], // home-widget · loveTree · lunarSectionTitle · journalBadge · careMessageEntryTitle · inviteQrBtn
    caption: "Miễn phí trên App Store & Google Play", // dearembeiu.com
  },

  /** Spaceti-style act titles (2–3 words), drawn by src/story/Titles.tsx over the acts; none on Act 1 (its caption is the title) and Act 7 */
  titles: [
    { from: 300, to: 700, text: "Hôm nay của chúng mình", dark: false }, // homeTodaySectionTitle
    { from: 740, to: 1140, text: "Chuỗi & cây tình yêu", dark: false }, // streak + loveTreeBadge
    { from: 1300, to: 1780, text: "Một ngày của chúng mình", dark: false }, // film
    { from: 1965, to: 2090, text: "Riêng tư", dark: true }, // film
    { from: 2420, to: 2600, text: "Và còn nữa", dark: false }, // film
  ] as const,

  a7: {
    wordmark: "Dear Embeiu",
    l1: "Đếm ngày yêu.", // guestCounterTitle, as a sentence
    l2: "Và mọi thứ sau con số.", // film
    offer: "Miễn phí · App Store & Google Play", // dearembeiu.com
    url: "dearembeiu.com",
    legal: "Chỉ hai người đã ghép đôi xem được dữ liệu của nhau. iOS 14 trở lên · Android 6 trở lên.", // PLAY_CONSOLE_CONTENT + dearembeiu.com
  },
} as const;

export const T = vi;
export type Strings = typeof vi;
