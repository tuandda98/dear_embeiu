/// Curated bank of "daily questions" for couples (feature #5).
///
/// One shared question per calendar day for both partners. Each couple gets its
/// own deterministic order (no two partners ever disagree, but different couples
/// see different sequences), and within one full cycle (== bank length) no
/// question repeats. See [questionForCouple] for the selection algorithm.
///
/// Each entry has a `vi` and `en` variant. Keep copy warm, light, and
/// couple-friendly; avoid ICU braces `{}` or other markup so the strings are
/// safe to render verbatim.
library;

const List<Map<String, String>> dailyQuestions = [
  // ── Original 58 (kept verbatim; do not reorder — call-site order no longer
  //    matters for selection, but keeping them stable avoids churn) ──────────
  {
    'vi': 'Khoảnh khắc nào khiến bạn nhận ra mình thích người ấy?',
    'en': 'What moment made you realize you liked your partner?',
  },
  {
    'vi': 'Hôm nay bạn biết ơn điều gì ở người ấy?',
    'en': 'What are you grateful for about your partner today?',
  },
  {
    'vi': 'Nếu được đi du lịch cùng nhau ngay bây giờ, bạn muốn đến đâu?',
    'en': 'If you could travel together right now, where would you go?',
  },
  {
    'vi': 'Món ăn nào luôn nhắc bạn nhớ đến người ấy?',
    'en': 'What food always reminds you of your partner?',
  },
  {
    'vi': 'Điều nhỏ nhặt nào người ấy làm khiến bạn thấy được yêu thương?',
    'en': 'What little thing your partner does makes you feel loved?',
  },
  {
    'vi': 'Bài hát nào bạn muốn dành tặng cho người ấy?',
    'en': 'What song would you dedicate to your partner?',
  },
  {
    'vi': 'Kỷ niệm nào của chúng mình khiến bạn mỉm cười mỗi khi nhớ lại?',
    'en': 'Which memory of the two of you makes you smile every time?',
  },
  {
    'vi': 'Nếu mô tả người ấy bằng một từ, bạn sẽ chọn từ gì?',
    'en': 'If you described your partner in one word, what would it be?',
  },
  {
    'vi': 'Bạn mong chúng mình cùng nhau làm gì trong năm nay?',
    'en': 'What do you hope the two of you do together this year?',
  },
  {
    'vi': 'Điều gì ở người ấy khiến bạn ngưỡng mộ nhất?',
    'en': 'What do you admire most about your partner?',
  },
  {
    'vi': 'Buổi hẹn hò trong mơ của bạn trông như thế nào?',
    'en': 'What does your dream date look like?',
  },
  {
    'vi': 'Người ấy đã thay đổi bạn theo cách tốt đẹp nào?',
    'en': 'How has your partner changed you for the better?',
  },
  {
    'vi': 'Có thói quen nhỏ nào của người ấy mà bạn thấy đáng yêu không?',
    'en': 'Is there a small habit of your partner you find adorable?',
  },
  {
    'vi': 'Nếu được tặng người ấy một món quà bất kỳ, bạn sẽ tặng gì?',
    'en': 'If you could give your partner any gift, what would it be?',
  },
  {
    'vi': 'Điều gì khiến bạn cảm thấy an toàn khi ở bên người ấy?',
    'en': 'What makes you feel safe when you are with your partner?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy học một điều mới nào?',
    'en': 'What new thing would you like to learn with your partner?',
  },
  {
    'vi': 'Lần gần nhất người ấy khiến bạn cười lớn là khi nào?',
    'en': 'When was the last time your partner made you laugh out loud?',
  },
  {
    'vi': 'Nếu chúng mình có một ngày nghỉ trọn vẹn, bạn muốn làm gì?',
    'en': 'If the two of you had a whole day off, what would you do?',
  },
  {
    'vi': 'Điều gì ở chuyện tình của chúng mình khiến bạn thấy tự hào?',
    'en': 'What about your love story makes you proud?',
  },
  {
    'vi': 'Bạn muốn nói lời cảm ơn nào với người ấy mà chưa kịp nói?',
    'en': 'What thank-you have you been meaning to say to your partner?',
  },
  {
    'vi': 'Mùi hương nào khiến bạn nghĩ đến người ấy?',
    'en': 'What scent makes you think of your partner?',
  },
  {
    'vi': 'Nếu viết một cuốn sách về chúng mình, tựa đề sẽ là gì?',
    'en': 'If you wrote a book about the two of you, what would the title be?',
  },
  {
    'vi': 'Điều gì khiến bạn tin rằng chúng mình hợp nhau?',
    'en': 'What makes you believe the two of you are a good match?',
  },
  {
    'vi': 'Có thói quen nhỏ nào của riêng chúng mình mà bạn muốn giữ mãi không?',
    'en': 'Is there a little habit of ours you’d love to keep forever?',
  },
  {
    'vi': 'Lần đầu hẹn hò, điều gì khiến bạn nhớ nhất?',
    'en': 'On your first date, what do you remember most?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy già đi như thế nào?',
    'en': 'How do you imagine growing old together?',
  },
  {
    'vi': 'Điều gì người ấy nói khiến bạn nhớ mãi?',
    'en': 'What is something your partner said that stuck with you?',
  },
  {
    'vi': 'Nếu được tua lại một khoảnh khắc bên nhau, bạn chọn lúc nào?',
    'en': 'If you could relive one moment together, which would it be?',
  },
  {
    'vi': 'Bạn thấy chúng mình giống nhau ở điểm nào nhất?',
    'en': 'In what way do you think the two of you are most alike?',
  },
  {
    'vi': 'Có việc gì nhờ có người ấy mà bạn thấy mình can đảm hơn?',
    'en': 'Is there something you feel braver doing because of your partner?',
  },
  {
    'vi': 'Bạn muốn dành buổi tối hôm nay bên người ấy như thế nào?',
    'en': 'How would you like to spend tonight with your partner?',
  },
  {
    'vi': 'Điều gì khiến bạn nhớ người ấy nhất khi xa nhau?',
    'en': 'What do you miss most about your partner when you are apart?',
  },
  {
    'vi': 'Nếu chúng mình nuôi một thú cưng, bạn muốn đặt tên là gì?',
    'en': 'If the two of you got a pet, what would you name it?',
  },
  {
    'vi': 'Bạn ước người ấy biết điều gì về cảm xúc của bạn?',
    'en': 'What do you wish your partner knew about how you feel?',
  },
  {
    'vi': 'Khoảnh khắc bình yên nhất bên người ấy là khi nào?',
    'en': 'What is your most peaceful moment with your partner?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy thử món ăn lạ nào?',
    'en': 'What unusual dish would you like to try with your partner?',
  },
  {
    'vi': 'Người ấy làm điều gì khiến bạn thấy mình được thấu hiểu?',
    'en': 'What does your partner do that makes you feel understood?',
  },
  {
    'vi': 'Nếu được hẹn hò ở một thời đại khác, bạn chọn thời nào?',
    'en': 'If you could date in another era, which one would you pick?',
  },
  {
    'vi': 'Bạn biết ơn vì đã gặp người ấy vào lúc nào trong đời?',
    'en': 'What about the timing of meeting your partner are you grateful for?',
  },
  {
    'vi': 'Câu nói yêu thương nào bạn muốn nghe người ấy nói hôm nay?',
    'en': 'What loving words would you like to hear from your partner today?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy xây dựng điều gì trong tương lai?',
    'en': 'What would you like to build together in the future?',
  },
  {
    'vi': 'Người ấy đã giúp bạn vượt qua khó khăn nào?',
    'en': 'What hardship has your partner helped you through?',
  },
  {
    'vi': 'Điều ngọt ngào bất ngờ nhất người ấy từng làm cho bạn là gì?',
    'en': 'What is the sweetest surprise your partner has ever done for you?',
  },
  {
    'vi': 'Bạn muốn chụp một bức ảnh kỷ niệm ở đâu cùng người ấy?',
    'en': 'Where would you like to take a keepsake photo with your partner?',
  },
  {
    'vi': 'Nếu chúng mình có một ngày hoàn toàn tự do, bạn ước làm gì?',
    'en': 'If the two of you had a completely free day, what would you wish to do?',
  },
  {
    'vi': 'Bạn thấy mình may mắn nhất ở điều gì trong mối quan hệ này?',
    'en': 'What do you feel luckiest about in this relationship?',
  },
  {
    'vi': 'Người ấy có biệt danh dễ thương nào bạn thích gọi không?',
    'en': 'Is there a cute nickname you love calling your partner?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy ngắm bình minh hay hoàng hôn hơn?',
    'en': 'Would you rather watch a sunrise or a sunset with your partner?',
  },
  {
    'vi': 'Điều gì khiến một ngày bình thường trở nên đặc biệt khi có người ấy?',
    'en': 'What makes an ordinary day special when your partner is around?',
  },
  {
    'vi': 'Bạn mong điều gì giữa hai người sẽ không bao giờ thay đổi?',
    'en': 'What do you hope never changes between the two of you?',
  },
  {
    'vi': 'Nếu cùng nhau viết một danh sách ước mơ, điều đầu tiên là gì?',
    'en': 'If you wrote a bucket list together, what would be the first item?',
  },
  {
    'vi': 'Bạn cảm thấy được yêu nhất qua lời nói hay hành động của người ấy?',
    'en': 'Do you feel most loved through your partner words or actions?',
  },
  {
    'vi': 'Một điều nhỏ bạn muốn làm cho người ấy vui hôm nay là gì?',
    'en': 'What is one small thing you could do to make your partner happy today?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy đón năm mới như thế nào?',
    'en': 'How would you like to welcome the new year with your partner?',
  },
  {
    'vi': 'Người ấy truyền cảm hứng cho bạn ở điều gì?',
    'en': 'In what way does your partner inspire you?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy xem lại bộ phim nào?',
    'en': 'What movie would you like to rewatch with your partner?',
  },
  {
    'vi': 'Điều gì khiến bạn tin tưởng người ấy hơn mỗi ngày?',
    'en': 'What makes you trust your partner more each day?',
  },
  {
    'vi': 'Nếu được gửi một lời nhắn tới người ấy của 10 năm sau, bạn nói gì?',
    'en': 'If you could message your partner 10 years from now, what would you say?',
  },

  // ── Kỷ niệm & quá khứ (memories / the past) ──────────────────────────────
  {
    'vi': 'Lần đầu nắm tay nhau, bạn còn nhớ cảm giác lúc đó không?',
    'en': 'Do you still remember how it felt the first time you held hands?',
  },
  {
    'vi': 'Tin nhắn đầu tiên chúng mình gửi cho nhau có nội dung gì?',
    'en': 'What did the very first message between you two say?',
  },
  {
    'vi': 'Ngày hẹn hò nào khiến bạn nhớ vì một chuyện buồn cười xảy ra?',
    'en': 'Which date stuck with you because something funny happened?',
  },
  {
    'vi': 'Ấn tượng đầu tiên của bạn về người ấy là gì?',
    'en': 'What was your very first impression of your partner?',
  },
  {
    'vi': 'Chuyến đi nào của chúng mình bạn muốn được trải lại?',
    'en': 'Which trip of yours would you love to do all over again?',
  },
  {
    'vi': 'Có món đồ nhỏ nào lưu giữ kỷ niệm của chúng mình mà bạn vẫn giữ?',
    'en': 'Is there a small keepsake from your story you still hold on to?',
  },
  {
    'vi': 'Lần đầu người ấy giới thiệu bạn với bạn bè, bạn cảm thấy sao?',
    'en': 'How did you feel when your partner first introduced you to friends?',
  },
  {
    'vi': 'Khoảnh khắc nào khiến bạn biết người ấy là người đặc biệt?',
    'en': 'What moment told you your partner was someone special?',
  },
  {
    'vi': 'Bức ảnh chụp chung nào là bức bạn thích nhất, vì sao?',
    'en': 'Which photo of the two of you is your favorite, and why?',
  },
  {
    'vi': 'Câu chuyện nào về chúng mình bạn hay kể lại nhất cho người khác?',
    'en': 'What story about the two of you do you tell others the most?',
  },

  // ── Biết ơn & trân trọng (gratitude / appreciation) ──────────────────────
  {
    'vi': 'Hôm nay người ấy làm điều gì khiến lòng bạn ấm lên?',
    'en': 'What did your partner do today that warmed your heart?',
  },
  {
    'vi': 'Bạn trân trọng điều gì ở người ấy mà ít khi nói thành lời?',
    'en': 'What do you appreciate about your partner but rarely say out loud?',
  },
  {
    'vi': 'Người ấy đã hy sinh điều gì cho bạn mà bạn luôn nhớ?',
    'en': 'What has your partner given up for you that you always remember?',
  },
  {
    'vi': 'Điều gì người ấy làm khiến cuộc sống của bạn dễ chịu hơn?',
    'en': 'What does your partner do that makes your life a little easier?',
  },
  {
    'vi': 'Khi mệt mỏi, điều gì ở người ấy giúp bạn thấy nhẹ lòng?',
    'en': 'When you are worn out, what about your partner lifts your mood?',
  },
  {
    'vi': 'Bạn biết ơn điều gì về cách người ấy lắng nghe bạn?',
    'en': 'What are you grateful for in the way your partner listens to you?',
  },
  {
    'vi': 'Người ấy đã tin tưởng bạn ở điều gì khiến bạn cảm động?',
    'en': 'What did your partner trust you with that touched you?',
  },
  {
    'vi': 'Có lần nào người ấy ở bên đúng lúc bạn cần nhất không?',
    'en': 'Was there a time your partner showed up exactly when you needed them?',
  },

  // ── Tương lai chung (a shared future) ────────────────────────────────────
  {
    'vi': 'Ngôi nhà trong mơ của chúng mình sẽ trông như thế nào?',
    'en': 'What would your dream home together look like?',
  },
  {
    'vi': 'Bạn hình dung một buổi sáng cuối tuần lý tưởng của chúng mình ra sao?',
    'en': 'How do you picture an ideal weekend morning for the two of you?',
  },
  {
    'vi': 'Có nơi nào bạn ước mỗi năm chúng mình cùng quay lại một lần?',
    'en': 'Is there a place you wish the two of you returned to once a year?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy tạo ra thói quen mới nào từ tuần này?',
    'en': 'What new habit would you like to start with your partner this week?',
  },
  {
    'vi': 'Mười năm nữa, bạn mong chúng mình vẫn cùng nhau làm điều gì?',
    'en': 'Ten years from now, what do you hope you two still do together?',
  },
  {
    'vi': 'Có kỹ năng nào bạn muốn chúng mình cùng thành thạo không?',
    'en': 'Is there a skill you would love the two of you to master together?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy chinh phục thử thách nào một lần trong đời?',
    'en': 'What challenge would you love to take on with your partner once?',
  },
  {
    'vi': 'Nếu chúng mình mở một quán nhỏ cùng nhau, đó sẽ là quán gì?',
    'en': 'If the two of you opened a little shop together, what would it be?',
  },
  {
    'vi': 'Bạn mong dịp kỷ niệm năm sau của chúng mình diễn ra thế nào?',
    'en': 'How do you hope your anniversary next year will go?',
  },
  {
    'vi': 'Có một giấc mơ lớn nào bạn muốn cùng người ấy theo đuổi?',
    'en': 'Is there a big dream you would like to chase together?',
  },

  // ── Sở thích & "thà rằng" (preferences / would you rather) ───────────────
  {
    'vi': 'Chúng mình thích ở nhà cùng nhau hay ra ngoài khám phá hơn?',
    'en': 'Do you two prefer cozy nights in or going out to explore?',
  },
  {
    'vi': 'Bạn thích buổi hẹn vào ban ngày hay buổi tối hơn, vì sao?',
    'en': 'Do you prefer daytime or evening dates, and why?',
  },
  {
    'vi': 'Cùng nhau đi biển hay lên núi, bạn chọn bên nào?',
    'en': 'Beach or mountains together — which would you choose?',
  },
  {
    'vi': 'Bạn thích được người ấy nấu cho ăn hay cùng nhau vào bếp hơn?',
    'en': 'Do you prefer your partner cooking for you or cooking together?',
  },
  {
    'vi': 'Một buổi tối yên tĩnh hay một buổi tiệc đông vui, bạn chọn gì?',
    'en': 'A quiet evening or a lively party — which suits you two better?',
  },
  {
    'vi': 'Bạn thích nhận hoa, đồ ăn vặt, hay một cái ôm bất ngờ hơn?',
    'en': 'Flowers, a snack, or a surprise hug — which do you like most?',
  },
  {
    'vi': 'Đi du lịch có kế hoạch chi tiết hay tùy hứng, bạn hợp kiểu nào?',
    'en': 'A planned trip or a spontaneous one — which fits you two?',
  },
  {
    'vi': 'Nhạc nhẹ hay nhạc sôi động khi đi chơi cùng nhau, bạn chọn gì?',
    'en': 'Mellow tunes or upbeat songs on a drive together — your pick?',
  },

  // ── "Nếu..." & tưởng tượng (if / imagination) ────────────────────────────
  {
    'vi': 'Nếu chúng mình có một ngày tàng hình, bạn muốn cùng làm gì?',
    'en': 'If the two of you were invisible for a day, what would you do?',
  },
  {
    'vi': 'Nếu được sống ở bất kỳ thành phố nào, chúng mình chọn nơi nào?',
    'en': 'If you could live in any city, which would the two of you pick?',
  },
  {
    'vi': 'Nếu trúng một chuyến đi miễn phí, bạn muốn rủ người ấy đi đâu?',
    'en': 'If you won a free trip, where would you take your partner?',
  },
  {
    'vi': 'Nếu chúng mình hoán đổi vai trò một ngày, bạn nghĩ sẽ thế nào?',
    'en': 'If you two swapped roles for a day, how do you think it would go?',
  },
  {
    'vi': 'Nếu được tạm dừng thời gian, bạn muốn kéo dài khoảnh khắc nào bên nhau?',
    'en': 'If you could pause time, which moment together would you stretch out?',
  },
  {
    'vi': 'Nếu chúng mình cùng vào một show truyền hình, đó sẽ là show gì?',
    'en': 'If the two of you joined a TV show together, which would it be?',
  },
  {
    'vi': 'Nếu được đặt tên một vì sao theo chúng mình, bạn muốn gọi là gì?',
    'en': 'If you could name a star after you two, what would you call it?',
  },
  {
    'vi': 'Nếu chúng mình lạc trên hoang đảo, bạn tin tưởng người ấy lo việc gì?',
    'en': 'If you were stranded on an island, what would you trust your partner with?',
  },
  {
    'vi': 'Nếu có một siêu năng lực để giúp người ấy, bạn chọn năng lực nào?',
    'en': 'If you had one superpower to help your partner, which would you pick?',
  },
  {
    'vi': 'Nếu được viết kịch bản cho một ngày hoàn hảo của chúng mình, sẽ ra sao?',
    'en': 'If you scripted one perfect day for the two of you, how would it look?',
  },

  // ── Thói quen nhỏ đáng yêu (sweet little habits) ─────────────────────────
  {
    'vi': 'Câu cửa miệng nào của người ấy mà bạn thấy dễ thương?',
    'en': 'What catchphrase of your partner do you find adorable?',
  },
  {
    'vi': 'Người ấy có cử chỉ nhỏ nào mỗi sáng khiến bạn vui cả ngày?',
    'en': 'Does your partner have a small morning gesture that makes your day?',
  },
  {
    'vi': 'Khi xem phim cùng nhau, người ấy thường có thói quen gì?',
    'en': 'When you watch a movie together, what habit does your partner have?',
  },
  {
    'vi': 'Người ấy hay làm điều gì khi vui mà bạn rất thích nhìn?',
    'en': 'What does your partner do when happy that you love to watch?',
  },
  {
    'vi': 'Có biểu cảm nào của người ấy chỉ bạn mới hiểu không?',
    'en': 'Is there an expression of your partner only you can read?',
  },
  {
    'vi': 'Người ấy hay nhắn tin kiểu gì khiến bạn bật cười?',
    'en': 'How does your partner text in a way that always makes you laugh?',
  },
  {
    'vi': 'Thói quen ăn uống nào của người ấy bạn thấy thú vị?',
    'en': 'What eating habit of your partner do you find amusing?',
  },
  {
    'vi': 'Khi buồn ngủ, người ấy thường làm gì đáng yêu?',
    'en': 'When sleepy, what cute thing does your partner usually do?',
  },

  // ── Mơ ước cá nhân & chia sẻ (dreams shared) ─────────────────────────────
  {
    'vi': 'Có ước mơ tuổi nhỏ nào bạn muốn kể cho người ấy nghe hôm nay?',
    'en': 'Is there a childhood dream you would like to share with your partner today?',
  },
  {
    'vi': 'Điều gì bạn vẫn muốn thử nhưng chưa dám, và muốn người ấy ở bên?',
    'en': 'What is something you still want to try but never dared, with your partner beside you?',
  },
  {
    'vi': 'Nếu có một năm để làm bất cứ điều gì, bạn muốn dành cho việc gì?',
    'en': 'If you had a year to do anything, what would you spend it on?',
  },
  {
    'vi': 'Bạn muốn mình ngày càng tốt hơn ở điểm nào, và người ấy giúp được gì?',
    'en': 'What do you want to get better at, and how does your partner help?',
  },
  {
    'vi': 'Có điều gì bạn luôn muốn học mà người ấy có thể dạy bạn?',
    'en': 'Is there something you have always wanted to learn that your partner could teach you?',
  },
  {
    'vi': 'Thành tựu nhỏ nào của bạn gần đây mà bạn muốn người ấy biết?',
    'en': 'What small win of yours lately would you like your partner to know about?',
  },

  // ── Du lịch & nơi chốn (travel / places) ─────────────────────────────────
  {
    'vi': 'Nơi nào ở Việt Nam bạn muốn cùng người ấy ghé một lần?',
    'en': 'Which place in Vietnam would you like to visit with your partner once?',
  },
  {
    'vi': 'Bạn thích một chuyến phượt dài hay một kỳ nghỉ thư giãn hơn?',
    'en': 'Do you prefer a long road trip or a relaxing getaway?',
  },
  {
    'vi': 'Quán cà phê nào chúng mình hay hẹn, và vì sao bạn thích nơi đó?',
    'en': 'Which café do you two often meet at, and why do you love it?',
  },
  {
    'vi': 'Nếu được ở một khu vườn yên tĩnh cả ngày cùng nhau, bạn sẽ làm gì?',
    'en': 'If you spent a whole day in a quiet garden together, what would you do?',
  },
  {
    'vi': 'Con đường nào chúng mình hay đi mà bạn thấy đẹp nhất?',
    'en': 'Which street that you two often walk feels the most beautiful?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy ngắm tuyết hay ngắm biển hơn?',
    'en': 'Would you rather watch the snow or the sea with your partner?',
  },
  {
    'vi': 'Có một góc nhỏ nào trở thành "địa điểm của riêng chúng mình" không?',
    'en': 'Is there a little spot that became a place just for the two of you?',
  },

  // ── Đồ ăn & vị giác (food / taste) ───────────────────────────────────────
  {
    'vi': 'Món tráng miệng nào bạn muốn cùng người ấy chia đôi hôm nay?',
    'en': 'What dessert would you love to split with your partner today?',
  },
  {
    'vi': 'Nếu chúng mình nấu chung một bữa, bạn muốn nấu món gì?',
    'en': 'If you two cooked one meal together, what would you make?',
  },
  {
    'vi': 'Món ăn vặt nào chúng mình luôn mua khi đi chơi cùng nhau?',
    'en': 'What snack do you two always grab when you go out together?',
  },
  {
    'vi': 'Người ấy nấu món gì khiến bạn nhớ mãi hương vị?',
    'en': 'Which dish your partner makes do you remember the taste of most?',
  },
  {
    'vi': 'Bữa sáng lý tưởng của chúng mình vào ngày cuối tuần là gì?',
    'en': 'What is your ideal weekend breakfast together?',
  },
  {
    'vi': 'Có món nào bạn ghét nhưng vì người ấy mà bắt đầu thử không?',
    'en': 'Is there a food you disliked but started trying because of your partner?',
  },
  {
    'vi': 'Nếu mở một thực đơn cho chúng mình, món chủ đạo sẽ là gì?',
    'en': 'If you wrote a menu just for you two, what would the signature dish be?',
  },

  // ── Âm nhạc & phim ảnh (music / movies) ──────────────────────────────────
  {
    'vi': 'Bài hát nào khiến bạn nghĩ ngay đến khoảng thời gian đầu yêu nhau?',
    'en': 'What song instantly reminds you of when you two first fell for each other?',
  },
  {
    'vi': 'Nếu chúng mình có một playlist chung, bài đầu tiên sẽ là gì?',
    'en': 'If you two had a shared playlist, what would the first song be?',
  },
  {
    'vi': 'Bộ phim nào bạn nghĩ phản chiếu chuyện tình của chúng mình?',
    'en': 'Which movie do you think mirrors your love story?',
  },
  {
    'vi': 'Nhân vật phim nào bạn thấy giống người ấy nhất?',
    'en': 'Which movie character reminds you most of your partner?',
  },
  {
    'vi': 'Có bài hát nào chúng mình từng hát cùng nhau mà bạn nhớ không?',
    'en': 'Is there a song you two once sang together that you remember?',
  },
  {
    'vi': 'Thể loại phim nào chúng mình luôn hợp gu khi xem chung?',
    'en': 'Which movie genre do you two always agree on?',
  },
  {
    'vi': 'Nếu cuộc đời chúng mình có nhạc nền, bạn muốn chọn giai điệu nào?',
    'en': 'If your life together had a soundtrack, what melody would you pick?',
  },

  // ── Hài hước nhẹ (light humor) ───────────────────────────────────────────
  {
    'vi': 'Trò đùa nào của người ấy luôn khiến bạn dở khóc dở cười?',
    'en': 'Which of your partner\'s jokes always leaves you half laughing, half groaning?',
  },
  {
    'vi': 'Lần nào chúng mình cãi nhau vì chuyện nhỏ xíu rồi tự thấy buồn cười?',
    'en': 'When did you two argue over something tiny and later find it hilarious?',
  },
  {
    'vi': 'Nếu chúng mình thi một môn kỳ quặc, ai sẽ thắng và môn gì?',
    'en': 'If you two competed in a quirky contest, who would win and at what?',
  },
  {
    'vi': 'Biệt danh nào chúng mình gọi nhau mà người ngoài nghe sẽ thấy lạ?',
    'en': 'What nickname do you two use that outsiders would find odd?',
  },
  {
    'vi': 'Thói quen nào của bạn khiến người ấy hay trêu, mà bạn cũng chịu thua?',
    'en': 'Which habit of yours does your partner tease you about, and you admit it?',
  },
  {
    'vi': 'Nếu chúng mình lập một đội, tên đội bá đạo nhất sẽ là gì?',
    'en': 'If you two formed a team, what is the most epic team name you would pick?',
  },
  {
    'vi': 'Khoảnh khắc vụng về nào của chúng mình giờ nghĩ lại vẫn thấy đáng yêu?',
    'en': 'What clumsy moment of yours still feels adorable when you look back?',
  },

  // ── "Anh/em nghĩ gì về..." (what do you think about) ─────────────────────
  {
    'vi': 'Bạn nghĩ điều gì làm nên một mối quan hệ bền lâu?',
    'en': 'What do you think makes a relationship last?',
  },
  {
    'vi': 'Với bạn, một ngày bình thường có nhau trông như thế nào?',
    'en': 'What does an ordinary day together look like to you?',
  },
  {
    'vi': 'Bạn nghĩ chúng mình làm gì tốt nhất khi giận nhau rồi làm hòa?',
    'en': 'What do you think you two do best when you make up after a quarrel?',
  },
  {
    'vi': 'Bạn nghĩ điều gì giúp chúng mình hiểu nhau hơn theo thời gian?',
    'en': 'What do you think helps the two of you understand each other better over time?',
  },
  {
    'vi': 'Khi hai người xa nhau, điều gì giúp tình cảm vẫn gần gũi?',
    'en': 'When you’re apart, what keeps the two of you feeling close?',
  },
  {
    'vi': 'Bạn nghĩ tình yêu của chúng mình đã trưởng thành ra sao?',
    'en': 'How do you think your love has grown up over time?',
  },
  {
    'vi': 'Khi cần làm hòa, bạn nghĩ nên mở lời xin lỗi thế nào cho chân thành?',
    'en': 'When making up, how do you think a sincere apology should start?',
  },

  // ── Cảm xúc & gần gũi (feelings / closeness) ─────────────────────────────
  {
    'vi': 'Hôm nay tâm trạng bạn thế nào, và bạn muốn người ấy biết điều gì?',
    'en': 'How is your mood today, and what would you like your partner to know?',
  },
  {
    'vi': 'Khi nào bạn cảm thấy gần gũi với người ấy nhất?',
    'en': 'When do you feel closest to your partner?',
  },
  {
    'vi': 'Người ấy làm điều gì khiến bạn thấy mình quan trọng với họ?',
    'en': 'What does your partner do that makes you feel important to them?',
  },
  {
    'vi': 'Cách nào người ấy an ủi bạn mà bạn thấy hiệu quả nhất?',
    'en': 'How does your partner comfort you in a way that works best?',
  },
  {
    'vi': 'Có điều gì bạn muốn chúng mình nói với nhau nhiều hơn không?',
    'en': 'Is there something you wish the two of you said to each other more?',
  },
  {
    'vi': 'Khi xa nhau, điều gì giúp bạn thấy vẫn được kết nối với người ấy?',
    'en': 'When apart, what helps you still feel connected to your partner?',
  },
  {
    'vi': 'Bạn muốn được người ấy hỏi thăm về điều gì nhiều hơn?',
    'en': 'What would you like your partner to ask you about more often?',
  },
  {
    'vi': 'Khi ở bên người ấy, điều gì khiến bạn thoải mái được là chính mình?',
    'en': 'When you’re with your partner, what lets you feel free to be yourself?',
  },

  // ── Cùng nhau phát triển (growing together) ──────────────────────────────
  {
    'vi': 'Chúng mình đã cùng vượt qua thử thách nào và học được gì?',
    'en': 'What challenge have you two overcome together, and what did you learn?',
  },
  {
    'vi': 'Bạn thấy mình tốt lên ở điểm nào nhờ ở bên người ấy?',
    'en': 'In what way have you become better because of your partner?',
  },
  {
    'vi': 'Có thói quen tốt nào bạn học được từ người ấy không?',
    'en': 'Is there a good habit you picked up from your partner?',
  },
  {
    'vi': 'Chúng mình cân bằng giữa thời gian riêng và thời gian chung thế nào?',
    'en': 'How do you two balance time alone and time together?',
  },
  {
    'vi': 'Bạn muốn chúng mình cùng cố gắng hơn ở điều gì trong tháng này?',
    'en': 'What would you like the two of you to work on together this month?',
  },
  {
    'vi': 'Mục tiêu nào của người ấy mà bạn muốn ủng hộ hết mình?',
    'en': 'Which goal of your partner do you want to support wholeheartedly?',
  },

  // ── Lãng mạn nhẹ nhàng (gentle romance) ──────────────────────────────────
  {
    'vi': 'Bạn muốn được người ấy ôm vào lúc nào trong ngày nhất?',
    'en': 'At what point in the day do you most want a hug from your partner?',
  },
  {
    'vi': 'Lời khen nào của người ấy khiến bạn nhớ mãi không quên?',
    'en': 'Which compliment from your partner do you never forget?',
  },
  {
    'vi': 'Nếu viết một lá thư tay cho người ấy, câu mở đầu sẽ là gì?',
    'en': 'If you wrote a handwritten letter to your partner, how would it begin?',
  },
  {
    'vi': 'Khoảnh khắc nào bạn thấy người ấy đẹp nhất, dù rất đời thường?',
    'en': 'In what plain everyday moment does your partner look most beautiful to you?',
  },
  {
    'vi': 'Có khung cảnh nào bạn muốn cùng người ấy lặng lẽ ngắm cùng nhau không?',
    'en': 'Is there a view you’d love to quietly take in beside your partner?',
  },
  {
    'vi': 'Câu nói nào của người ấy khiến tim bạn lỡ một nhịp?',
    'en': 'What did your partner say that made your heart skip a beat?',
  },
  {
    'vi': 'Hôm nay có khoảnh khắc nào bạn muốn ghi nhớ thật lâu không?',
    'en': 'Is there a moment from today you’d like to remember for a long time?',
  },

  // ── Khám phá lẫn nhau (getting to know each other) ───────────────────────
  {
    'vi': 'Có điều gì về tuổi thơ của người ấy bạn vẫn muốn biết thêm?',
    'en': 'Is there something about your partner childhood you still want to know?',
  },
  {
    'vi': 'Điều gì khiến người ấy cảm thấy được nạp lại năng lượng?',
    'en': 'What makes your partner feel recharged?',
  },
  {
    'vi': 'Bạn nghĩ người ấy sợ điều gì nhất, và muốn ở bên ra sao?',
    'en': 'What do you think your partner fears most, and how do you want to be there?',
  },
  {
    'vi': 'Có một câu hỏi nào bạn luôn muốn hỏi người ấy nhưng chưa hỏi?',
    'en': 'Is there a question you have always wanted to ask your partner but never did?',
  },
  {
    'vi': 'Điều gì khiến người ấy tự hào về bản thân mà bạn cũng tự hào lây?',
    'en': 'What makes your partner proud of themselves that you feel proud of too?',
  },
  {
    'vi': 'Bạn nghĩ điều gì là giá trị quan trọng nhất với người ấy?',
    'en': 'What do you think is the value that matters most to your partner?',
  },
  {
    'vi': 'Người ấy thư giãn kiểu gì sau một ngày dài?',
    'en': 'How does your partner unwind after a long day?',
  },

  // ── Chăm sóc & hành động nhỏ (caring / small acts) ───────────────────────
  {
    'vi': 'Cách chăm sóc nhỏ nào của người ấy khiến bạn thấy được nâng niu?',
    'en': 'What small act of care from your partner makes you feel cherished?',
  },
  {
    'vi': 'Bạn có thể làm gì hôm nay để giảm bớt một nỗi lo của người ấy?',
    'en': 'What could you do today to ease one of your partner worries?',
  },
  {
    'vi': 'Khi ốm, bạn muốn được người ấy chăm theo cách nào?',
    'en': 'When you are sick, how would you like your partner to take care of you?',
  },
  {
    'vi': 'Có việc nhà nào chúng mình làm cùng nhau mà bạn thấy vui không?',
    'en': 'Is there a chore you two do together that you actually enjoy?',
  },
  {
    'vi': 'Lần nào người ấy bất ngờ giúp bạn một việc khiến bạn nhẹ cả người?',
    'en': 'When did your partner surprise you with help that took a load off you?',
  },
  {
    'vi': 'Bạn muốn dành một buổi chiều chăm sóc bản thân cùng người ấy thế nào?',
    'en': 'How would you like to spend a self-care afternoon together?',
  },

  // ── Dịp đặc biệt & truyền thống (occasions / traditions) ─────────────────
  {
    'vi': 'Bạn muốn chúng mình có một nghi thức nhỏ nào mỗi dịp kỷ niệm?',
    'en': 'What little ritual would you like the two of you to keep on each anniversary?',
  },
  {
    'vi': 'Sinh nhật người ấy, bạn muốn làm một điều bất ngờ nào?',
    'en': 'For your partner birthday, what surprise would you love to plan?',
  },
  {
    'vi': 'Có ngày nào trong năm trở thành "ngày của riêng chúng mình" không?',
    'en': 'Is there a day each year that became "your day" as a couple?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy đón mùa nào trong năm nhất, vì sao?',
    'en': 'Which season would you most love to welcome with your partner, and why?',
  },
  {
    'vi': 'Nếu lập một truyền thống ăn uống hằng tháng, đó sẽ là gì?',
    'en': 'If you started a monthly food tradition, what would it be?',
  },
  {
    'vi': 'Dịp lễ nào bạn thấy chúng mình hợp nhau khi cùng đón nhất?',
    'en': 'Which holiday do you two enjoy celebrating together the most?',
  },

  // ── Lời nhắn nhủ & lời hứa nhẹ (gentle messages / soft promises) ─────────
  {
    'vi': 'Nếu được nhắn người ấy một câu trước khi ngủ, bạn muốn nói gì?',
    'en': 'If you could send your partner one message before bed, what would it be?',
  },
  {
    'vi': 'Có lời hứa nhỏ nào bạn muốn giữ với người ấy từ hôm nay?',
    'en': 'Is there a small promise you would like to keep to your partner from today?',
  },
  {
    'vi': 'Bạn muốn người ấy luôn nhớ điều gì trong những ngày khó khăn?',
    'en': 'What would you like your partner to always remember on hard days?',
  },
  {
    'vi': 'Một lời động viên nào bạn muốn dành cho người ấy lúc này?',
    'en': 'What words of encouragement would you give your partner right now?',
  },
  {
    'vi': 'Nếu hôm nay là dịp đặc biệt, bạn muốn cảm ơn người ấy vì điều gì?',
    'en': 'If today were a special occasion, what would you thank your partner for?',
  },
  {
    'vi': 'Bạn muốn nhắc người ấy nhớ về kỷ niệm nào để mỉm cười hôm nay?',
    'en': 'Which memory would you remind your partner of to make them smile today?',
  },

  // ── Sự nghiệp & cuộc sống thường ngày (work / daily life, light) ─────────
  {
    'vi': 'Hôm nay điều gì khiến bạn thấy vui, và muốn kể người ấy nghe?',
    'en': 'What made you happy today that you would like to tell your partner?',
  },
  {
    'vi': 'Có chuyện nhỏ nào trong ngày bạn muốn người ấy cùng ăn mừng không?',
    'en': 'Is there a little win today you would like your partner to celebrate with you?',
  },
  {
    'vi': 'Khi bận rộn, chúng mình làm gì để vẫn dành chút thời gian cho nhau?',
    'en': 'When busy, what do you two do to still make time for each other?',
  },
  {
    'vi': 'Bạn muốn người ấy giúp nhắc bạn nhớ điều gì trong tuần này?',
    'en': 'What would you like your partner to gently remind you about this week?',
  },
  {
    'vi': 'Điều gì trong ngày khiến bạn nghĩ "ước gì có người ấy ở đây"?',
    'en': 'What in your day made you think "I wish my partner were here"?',
  },
  {
    'vi': 'Chúng mình có thói quen chia sẻ chuyện trong ngày vào lúc nào?',
    'en': 'When do you two share how your days went?',
  },

  // ── Mơ mộng & tưởng tượng vui (playful daydreams) ────────────────────────
  {
    'vi': 'Nếu chúng mình có một ngôi nhà trên cây, bạn muốn trang trí thế nào?',
    'en': 'If you two had a treehouse, how would you decorate it?',
  },
  {
    'vi': 'Nếu chúng mình cùng nuôi một khu vườn, bạn muốn trồng gì đầu tiên?',
    'en': 'If you two grew a garden together, what would you plant first?',
  },
  {
    'vi': 'Nếu chúng mình có một chiếc thuyền nhỏ, bạn muốn chèo đi đâu?',
    'en': 'If you two had a little boat, where would you row to?',
  },
  {
    'vi': 'Nếu được vẽ một bức tranh về tương lai chúng mình, trong tranh có gì?',
    'en': 'If you painted a picture of your future together, what would be in it?',
  },
  {
    'vi': 'Nếu chúng mình có một cây cầu vồng, bạn muốn nó dẫn tới đâu?',
    'en': 'If the two of you had a rainbow, where would you want it to lead?',
  },
  {
    'vi': 'Nếu làm một hộp kỷ niệm để sau này mở lại, chúng mình sẽ bỏ gì vào?',
    'en': 'If you made a keepsake box to open years later, what would you two put inside?',
  },

  // ── Trân trọng khác biệt (appreciating differences) ──────────────────────
  {
    'vi': 'Điểm nào chúng mình khác nhau nhưng lại bổ sung cho nhau rất hay?',
    'en': 'Where are you two different in a way that complements each other beautifully?',
  },
  {
    'vi': 'Bạn học được điều gì từ cách nghĩ khác biệt của người ấy?',
    'en': 'What have you learned from your partner different way of thinking?',
  },
  {
    'vi': 'Có sở thích nào của người ấy mà bạn dần thấy hay theo không?',
    'en': 'Is there a hobby of your partner you have slowly grown to enjoy too?',
  },
  {
    'vi': 'Khi bất đồng, điều gì giúp chúng mình vẫn tôn trọng nhau?',
    'en': 'When you disagree, what helps the two of you still respect each other?',
  },
  {
    'vi': 'Bạn ngưỡng mộ điều gì ở cách người ấy đối xử với người khác?',
    'en': 'What do you admire in how your partner treats other people?',
  },
  {
    'vi': 'Có thế mạnh nào của người ấy mà bạn ước mình cũng có?',
    'en': 'Is there a strength of your partner you wish you had too?',
  },

  // ── Niềm vui đời thường cùng nhau (everyday joys together) ────────────────
  {
    'vi': 'Hoạt động đơn giản nào bên nhau khiến bạn thấy hạnh phúc nhất?',
    'en': 'What simple activity together makes you happiest?',
  },
  {
    'vi': 'Bạn thích nhất khoảnh khắc nào trong một buổi đi chơi của chúng mình?',
    'en': 'What is your favorite moment in one of your outings together?',
  },
  {
    'vi': 'Trò chơi nào chúng mình có thể chơi cùng nhau hàng giờ không chán?',
    'en': 'What game could the two of you play for hours without getting bored?',
  },
  {
    'vi': 'Có bài tập thể dục hay đi dạo nào chúng mình thích làm cùng nhau không?',
    'en': 'Is there a workout or a walk the two of you love doing together?',
  },
  {
    'vi': 'Một buổi tối cuối tuần "không làm gì cả" của chúng mình trông ra sao?',
    'en': 'What does a weekend evening of "doing nothing" look like for you two?',
  },
  {
    'vi': 'Điều nhỏ nào trong ngày khiến cả chúng mình cùng bật cười?',
    'en': 'What small thing in a day makes both of you laugh?',
  },

  // ── Hồi tưởng & nhìn lại (reflection / looking back) ─────────────────────
  {
    'vi': 'So với ngày đầu, bạn thấy chúng mình đã thay đổi điều gì đáng quý?',
    'en': 'Compared to day one, what precious thing has changed between you two?',
  },
  {
    'vi': 'Khi yêu người ấy, bạn học được điều quan trọng nhất là gì?',
    'en': 'What’s the most important thing loving your partner has taught you?',
  },
  {
    'vi': 'Có điều gì bạn từng lo lắng nhưng giờ thấy không còn đáng ngại?',
    'en': 'Is there something you once worried about that no longer feels like a worry?',
  },
  {
    'vi': 'Nếu kể cho người ấy của một năm trước, bạn muốn nói điều gì?',
    'en': 'If you could tell your partner from a year ago one thing, what would it be?',
  },
  {
    'vi': 'Khoảnh khắc nào năm nay khiến bạn thấy biết ơn vì có người ấy?',
    'en': 'Which moment this year made you grateful to have your partner?',
  },
  {
    'vi': 'Bạn muốn cảm ơn quá khứ của mình vì điều gì đã dẫn bạn tới người ấy?',
    'en': 'What in your past would you thank for leading you to your partner?',
  },
];

// ── Selection ──────────────────────────────────────────────────────────────

/// 32-bit FNV-1a hash of [input] as an unsigned int — a small, deterministic
/// string hash that (unlike `String.hashCode`) is stable across runs, isolates
/// and platforms. Used to seed a per-couple question order.
int _fnv1a(String input) {
  const int fnvPrime = 0x01000193;
  const int mask = 0xFFFFFFFF;
  int hash = 0x811C9DC5;
  for (final unit in input.codeUnits) {
    hash = (hash ^ unit) & mask;
    hash = (hash * fnvPrime) & mask;
  }
  return hash & mask;
}

/// Whole-day index for [local]: number of calendar days since a fixed epoch
/// (2020-01-01). Only the date part is used (time of day is ignored), so the
/// value never jumps across new-year boundaries or leap years the way a
/// day-of-year would. Both partners resolving the same local calendar day land
/// on the same value.
int _daysSinceEpoch(DateTime local) {
  // Normalize to a date-only UTC instant to avoid DST/offset wobble.
  final dateOnly = DateTime.utc(local.year, local.month, local.day);
  final epoch = DateTime.utc(2020, 1, 1);
  return dateOnly.difference(epoch).inDays;
}

/// Builds a deterministic permutation of `[0..n-1]` seeded by [seed].
///
/// Uses a Fisher–Yates shuffle driven by a tiny LCG so the result is identical
/// for the same (n, seed) on any device — giving each couple its own stable
/// question order with no repeats within one cycle of length n.
List<int> _permutation(int n, int seed) {
  final order = List<int>.generate(n, (i) => i);
  // LCG constants (Numerical Recipes); keep state in 32-bit space.
  const int mask = 0xFFFFFFFF;
  int state = (seed ^ 0x9E3779B9) & mask;
  if (state == 0) {
    state = 0x1; // avoid a stuck-at-zero LCG
  }
  for (int i = n - 1; i > 0; i--) {
    state = (state * 1664525 + 1013904223) & mask;
    final j = state % (i + 1);
    final tmp = order[i];
    order[i] = order[j];
    order[j] = tmp;
  }
  return order;
}

/// Returns the shared question entry for [local] (device-local date) and
/// [coupleId].
///
/// Algorithm: each couple gets a deterministic permutation of all question
/// indices (seeded by a stable hash of [coupleId]); the day picks a slot in
/// that permutation via `daysSinceEpoch % bankLength`. Properties:
///   • Same couple + same local day ⇒ same question (both partners agree).
///   • No question repeats within one full cycle (== bank length) of days.
///   • Different couples get different orderings.
///
/// ⚠️ **Changing the bank LENGTH reshuffles everything** (verified 2026-08-09 — an
/// earlier note here claimed the opposite). Both the Fisher–Yates permutation and
/// `daysSinceEpoch % n` depend on `n`, so adding even one question gives every
/// couple a brand-new order: today's question changes mid-cycle and the no-repeat
/// guarantee breaks across the boundary (simulated: growing 229 → 235 brought a
/// question from the previous 30 days back within the next 30). Two devices on
/// different app versions therefore see DIFFERENT questions on the same day, and
/// the journal marker keeps whichever text the SECOND answerer's build produced.
/// This is accepted debt (see `project/features/daily-question/dev.md` §Trade-off)
/// — mitigated in practice by the force-update floor. **Prefer editing existing
/// entries over appending**; a real fix means pinning the cycle length or storing
/// a per-couple offset.
///
/// An empty or null [coupleId] falls back to seed 0 (still valid, never throws).
/// Robust against an empty bank.
Map<String, String> questionForCouple(
  DateTime local,
  String coupleId,
  String langCode,
) {
  final n = dailyQuestions.length;
  if (n == 0) {
    return const {'vi': '', 'en': ''};
  }
  final id = coupleId.trim();
  final seed = id.isEmpty ? 0 : _fnv1a(id);
  final perm = _permutation(n, seed);
  final day = _daysSinceEpoch(local);
  // Positive modulo (daysSinceEpoch can be negative for pre-2020 dates).
  final slot = ((day % n) + n) % n;
  final index = perm[slot];
  return dailyQuestions[index];
}

/// Convenience: the localized question text for [local] and [coupleId] in
/// [langCode] ('vi'/'en'; anything else falls back to English).
String questionTextForCouple(
  DateTime local,
  String coupleId,
  String langCode,
) {
  final entry = questionForCouple(local, coupleId, langCode);
  final code = langCode.trim().toLowerCase();
  if (code.startsWith('vi')) {
    return entry['vi'] ?? entry['en'] ?? '';
  }
  return entry['en'] ?? entry['vi'] ?? '';
}

/// Legacy global (couple-agnostic) selection, kept for compatibility.
///
/// Returns the shared question for [local] (the device-local date). Selection is
/// `dayOfYear % length`. Prefer [questionForCouple] for per-couple variety.
@Deprecated('Use questionForCouple for per-couple, no-repeat selection')
Map<String, String> questionForDate(DateTime local, String langCode) {
  if (dailyQuestions.isEmpty) {
    return const {'vi': '', 'en': ''};
  }
  final dayOfYear =
      local.difference(DateTime(local.year, 1, 1)).inDays; // 0-based
  final index = dayOfYear % dailyQuestions.length;
  return dailyQuestions[index];
}

/// Legacy convenience text accessor. Prefer [questionTextForCouple].
@Deprecated('Use questionTextForCouple for per-couple, no-repeat selection')
String questionTextForDate(DateTime local, String langCode) {
  // ignore: deprecated_member_use_from_same_package
  final entry = questionForDate(local, langCode);
  final code = langCode.trim().toLowerCase();
  if (code.startsWith('vi')) {
    return entry['vi'] ?? entry['en'] ?? '';
  }
  return entry['en'] ?? entry['vi'] ?? '';
}
