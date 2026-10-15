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
    caption: "Mọi app đếm ngày yêu chỉ biết đếm.", // film — the old apps do one thing: count
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
    label: "HÔM NAY · 15/10/2026", // film (the date as captured); v3: the day runs 06:00 → 24:00
    /** v3: the day's six moments in order (V3.md § A4; the 21:00 reminder dropped in review, it is on an Act 6 card);
     *  `who` = who it comes from (rose = you, lavender = the other); hour = decimal hours (= A4.events) */
    events: [
      { hour: 6.0, who: "other", icon: "moon", title: "Tuấn dậy · 6g 50p", body: "23:10 → 6:00" }, // his night, seeded (6g 50p = its length)
      { hour: 10.667, who: "other", icon: "photo", title: "Tuấn vừa đăng ảnh mới 💞", body: "Ghế quen ở hồ Gươm" }, // PHOTO_NOTIFICATION_COPY · caption as captured
      { hour: 12.5, who: "other", icon: "care", title: "Ăn cơm chưa? 🍚", body: "Nhớ ăn cơm đúng bữa, đừng bỏ bữa nha." }, // careQuick3Title/Body
      { hour: 15.5, who: "you", icon: "question", title: "Hôm nay cả hai đã trả lời 💞", body: "31 ngày kết nối" }, // dailyBothAnsweredToday + streak
      { hour: 22.75, who: "you", icon: "mood", title: "Chúng mình cùng một tâm trạng 💞", body: "Bạn và Tuấn đều thấy Nhớ 🥹" }, // moodMatched
      { hour: 23.167, who: "other", icon: "moon", title: "Tuấn đi ngủ", body: "23:10" },
    ] as const,
    counters: [
      { label: "Ảnh", from: 11, to: 12 }, // 12 khoảnh khắc after the day's photo
      { label: "Sao hôm nay", from: 2, to: 6 }, // the constellation pill 2/6 → 6/6
      { label: "Chuỗi", from: 30, to: 31 },
    ] as const,
    caption: ["Con số vẫn thế.", "Chỉ là có thêm người ấy."], // film (revised 15/10/2026 evening: "trơ trọi" dropped)
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
    /** v3: dead (no fact grid on screen), kept for audio/scripts */
    facts: [
      ["Miễn phí", "Không quảng cáo"], // dearembeiu.com: "Miễn phí. Không quảng cáo."
      ["Chỉ hai người", "ghép bằng mã mời 6 ký tự"], // invite code, 6 characters
      ["Ảnh, tin nhắn, câu trả lời", "chỉ hai người thấy"], // PLAY_CONSOLE_CONTENT: "Chỉ hai người được ghép cặp…"
      ["Không bạn bè", "không bảng tin · không ai khác"], // dearembeiu.com
      ["Xoá tài khoản", "ngay trong app"], // deleteAccountBtn · Settings → Tài khoản
      ["Tiếng Việt · English", "iOS 14+ · Android 6+"], // supportedLocales · dearembeiu.com
    ] as const,
    footer: "dearembeiu.com", // v3: dead (no footer), kept for audio/scripts
    h1: "Không bảng tin. Không người lạ.", // V3 (BRIEF §1: no feed, only the two paired members) — "Không bạn bè" read as "having no friends"
    h2: "Chỉ hai người.",
    h3: ["Miễn phí.", "Không quảng cáo."], // the second sentence in rose
    fine: "Ghép đôi bằng mã mời · Xoá tài khoản ngay trong app · Tiếng Việt · English", // V3 fine print (BRIEF §1)
  },

  a6: {
    placeholder: "Nhắn gì đó cho người ấy…", // chatComposerHint — v3: dead (no chat on screen), kept for audio/scripts
    /** the seeded chat already on screen above the composer (dev-seed-widget-accounts.js CHAT; ref/ios/chat.png): who 0 = Tuấn (left, grey), 1 = Thảo (right, navy) */
    history: [
      [0, "Em ăn cơm chưa? 🍚"],
      [1, "Em ăn rồi nè, anh thì sao?"],
      [0, "Anh vừa xong, tối nay xem phim nha"],
      [1, "Okii, em chọn phim nhé 😚"],
    ] as const,
    typed: "Tối nay xem phim nha", // film — v3: dead, kept for audio/scripts
    typing: "đang soạn…", // the typing indicator — v3: dead, kept for audio/scripts
    chips: ["Nhớ quá 💕", "Uống nước nha 💧", "Ăn cơm chưa? 🍚", "Ngủ sớm nha 🌙", "Yêu nhiều lắm ❤️", "Cố lên nha 💪"], // careQuick1…6Title — v3: dead, kept for audio/scripts
    glyphs: ["Đếm ngày yêu", "Ảnh chung", "Câu hỏi mỗi ngày", "Tâm trạng", "Giấc ngủ", "Trò chuyện", "Lời nhắc", "Oẳn tù tì"], // the eight things (intro/guestCounterTitle, gallery, dailyQuestion, mood, sleep, navChat, reminders, rpsGameTitle)
    /** film: two lines per card ("\n" = the break), each a BRIEF §1 fact (live clock on the couple photo · both post,
     * only the two see · your answer unlocks theirs · "Chúng mình cùng một tâm trạng" · their bed time · private chat
     * with "đang soạn…" · "Cũng nhắc người ấy", in their time zone · both hands revealed together); each line ≤ 338 px
     * at 28 px (the card's inner width) */
    benefits: [
      "tới từng giây,\ntrên ảnh chúng mình",
      "cả hai cùng đăng,\nchỉ hai người thấy",
      "trả lời xong mới mở\ncâu của người ấy",
      "cùng một tâm trạng\nlà app báo ngay",
      "đêm qua người ấy\nngủ lúc mấy giờ",
      "chỉ hai người nhắn,\nthấy cả lúc đang soạn",
      "nhắc cả người ấy,\nđúng giờ bên ấy",
      "một ván với người ấy,\nhai tay mở cùng lúc",
    ],
    ticker: ["Widget màn hình chính", "Cây tình yêu", "Lịch âm", "Nhật ký câu hỏi", "Gửi quan tâm", "Mã QR mời"], // v3: dead (no ticker, G6), kept for audio/scripts
    caption: "Miễn phí trên App Store & Google Play", // v3: dead ("Miễn phí" said once, G6), kept for audio/scripts
  },

  /** Spaceti-style act titles (2–3 words), drawn by src/story/Titles.tsx over the acts; none on Act 1 (its caption is the title) and Act 7 */
  titles: [
    { from: 300, to: 700, text: "Hôm nay của chúng mình", dark: false }, // homeTodaySectionTitle
    { from: 740, to: 1050, text: "Chuỗi & cây tình yêu", dark: false }, // streak + loveTreeBadge; out before A3.night covers the corner
    { from: 1300, to: 1780, text: "Một ngày của chúng mình", dark: false }, // film
    { from: 1965, to: 2090, text: "Riêng tư", dark: true }, // film
    { from: 2325, to: 2580, text: "Và còn nữa", dark: false }, // film (v3: the cards are the whole act)
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
