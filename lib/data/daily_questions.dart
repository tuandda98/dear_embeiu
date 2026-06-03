/// Curated bank of "daily questions" for couples (feature #5).
///
/// One shared question per calendar day for both partners. The question is
/// picked deterministically from the local day-of-year so both members — who
/// resolve their own local date — land on the same prompt on the same day.
///
/// Each entry has a `vi` and `en` variant. Keep copy warm, light, and
/// couple-friendly; avoid ICU braces `{}` or other markup so the strings are
/// safe to render verbatim.
library;

const List<Map<String, String>> dailyQuestions = [
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
    'vi': 'Kỷ niệm nào của hai bạn khiến bạn mỉm cười mỗi khi nhớ lại?',
    'en': 'Which memory of the two of you makes you smile every time?',
  },
  {
    'vi': 'Nếu mô tả người ấy bằng một từ, bạn sẽ chọn từ gì?',
    'en': 'If you described your partner in one word, what would it be?',
  },
  {
    'vi': 'Bạn mong hai đứa cùng nhau làm gì trong năm nay?',
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
    'vi': 'Nếu hai bạn có một ngày nghỉ trọn vẹn, bạn muốn làm gì?',
    'en': 'If the two of you had a whole day off, what would you do?',
  },
  {
    'vi': 'Điều gì ở mối quan hệ này khiến bạn tự hào?',
    'en': 'What about this relationship makes you proud?',
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
    'vi': 'Nếu viết một cuốn sách về hai bạn, tựa đề sẽ là gì?',
    'en': 'If you wrote a book about the two of you, what would the title be?',
  },
  {
    'vi': 'Điều gì khiến bạn tin rằng hai bạn hợp nhau?',
    'en': 'What makes you believe the two of you are a good match?',
  },
  {
    'vi': 'Bạn muốn giữ truyền thống nhỏ nào của riêng hai đứa?',
    'en': 'What little tradition would you like just the two of you to keep?',
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
    'vi': 'Bạn thấy hai đứa giống nhau ở điểm nào nhất?',
    'en': 'In what way do you think the two of you are most alike?',
  },
  {
    'vi': 'Người ấy khiến bạn cảm thấy can đảm hơn ở điều gì?',
    'en': 'In what way does your partner make you feel braver?',
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
    'vi': 'Nếu hai bạn nuôi một thú cưng, bạn muốn đặt tên là gì?',
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
    'vi': 'Điều gì khiến bạn cảm thấy được người ấy thấu hiểu?',
    'en': 'What makes you feel understood by your partner?',
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
    'vi': 'Nếu hai bạn có một ngày hoàn toàn tự do, bạn ước làm gì?',
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
    'vi': 'Bạn mong hai đứa luôn giữ được điều gì dù thời gian trôi qua?',
    'en': 'What do you hope the two of you always keep, no matter the time?',
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
];

/// Returns the shared question for [local] (the device-local date) in the given
/// [langCode] ('vi'/'en', anything else falls back to English).
///
/// Selection is `dayOfYear % length`, so both partners resolving the same local
/// day land on the same prompt. Robust against an empty bank.
Map<String, String> questionForDate(DateTime local, String langCode) {
  if (dailyQuestions.isEmpty) {
    return const {'vi': '', 'en': ''};
  }
  final dayOfYear =
      local.difference(DateTime(local.year, 1, 1)).inDays; // 0-based
  final index = dayOfYear % dailyQuestions.length;
  return dailyQuestions[index];
}

/// Convenience: the localized question text for [local] in [langCode].
String questionTextForDate(DateTime local, String langCode) {
  final entry = questionForDate(local, langCode);
  final code = langCode.trim().toLowerCase();
  if (code.startsWith('vi')) {
    return entry['vi'] ?? entry['en'] ?? '';
  }
  return entry['en'] ?? entry['vi'] ?? '';
}
