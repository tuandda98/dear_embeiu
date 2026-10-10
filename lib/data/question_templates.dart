/// Time- and context-aware question templates (feature endless-questions).
///
/// Data = a **time frame** (today / the past few days / this week / last
/// weekend / this month / since the start of the year) crossed with a **theme**
/// (how you feel · what made you smile · what drained you · what you're
/// grateful for in your partner · a small moment together · something to do
/// together soon · something you learned about each other · what you'd love to
/// hear · what you're proud of · a small habit to build together), with 2–3
/// phrasings per combination.
///
/// Rules for every entry (enforced by `test/question_engine_test.dart`):
///   • BOTH `vi` and `en`, warm and light, ≤ 200 characters.
///   • Voice: "chúng mình" / "người ấy" / "bạn" — never "hai đứa".
///   • No ICU braces `{}` and no `<>` markup: the text is rendered verbatim.
///   • Dynamic numbers/words use the `%token%` placeholders below and are
///     substituted by `TemplateQuestionSource` with plain string concatenation.
///
/// `key` = `group:topic:variant` and is persisted (`questionState/main
/// .recentTemplateKeys` + the day marker) — treat keys as STABLE ids: add new
/// entries freely, but do not rename or reuse an existing key for other copy.
library;

/// Placeholder tokens replaced at proposal time.
const String kTplDays = '%days%'; // days remaining until a milestone
const String kTplMilestone = '%milestone%'; // the milestone itself, in days
const String kTplMood = '%mood%'; // mood word of whoever set it, localized
const String kTplStreak = '%streak%'; // current streak length, in days

/// One template. Immutable data only — no logic lives here.
class QuestionTemplate {
  const QuestionTemplate({
    required this.group,
    required this.topic,
    required this.variant,
    required this.vi,
    required this.en,
  });

  /// Scheduling bucket, e.g. `week_start`, `feeling`, `valentine`.
  final String group;

  /// Theme inside the group, e.g. `week_hope`.
  final String topic;

  /// Phrasing index inside the topic (1-based).
  final int variant;

  final String vi;
  final String en;

  /// Stable id persisted on the marker + in `recentTemplateKeys`.
  String get key => '$group:$topic:$variant';

  /// True when the copy needs a runtime value substituted.
  bool get needsDays => vi.contains(kTplDays) || en.contains(kTplDays);
  bool get needsMilestone =>
      vi.contains(kTplMilestone) || en.contains(kTplMilestone);
  bool get needsMood => vi.contains(kTplMood) || en.contains(kTplMood);
  bool get needsStreak => vi.contains(kTplStreak) || en.contains(kTplStreak);
}

// ── Group ids (also the values accepted by `proposeGroup`) ─────────────────
const String kTplGroupWeekStart = 'week_start';
const String kTplGroupFeeling = 'feeling';
const String kTplGroupWeekRecap = 'week_recap';
const String kTplGroupMonthStart = 'month_start';
const String kTplGroupMonthEnd = 'month_end';
const String kTplGroupNewYear = 'new_year';
const String kTplGroupValentine = 'valentine';
const String kTplGroupWomensDay = 'womens_day_8_3';
const String kTplGroupVnWomen = 'vn_women_20_10';
const String kTplGroupChristmas = 'christmas';
const String kTplGroupMilestoneNear = 'milestone_near';
const String kTplGroupMoodPartner = 'mood_partner';
const String kTplGroupNoPhotosWeekend = 'no_photos_weekend';
const String kTplGroupStreakMilestone = 'streak_milestone';

/// Localized mood words for [kTplMood] — mirrors `kMoodOptions` keys in
/// `models/mood.dart`. Kept here (not in the ARB) because the sentence is
/// stored in BOTH languages on the marker, so it can't depend on the reader's
/// device language. Same reason the words must not point at a reader ("nhớ
/// bạn"): both partners read the one sentence.
const Map<String, String> kMoodWordVi = <String, String>{
  'happy': 'vui',
  'loved': 'hạnh phúc',
  'missing': 'nhớ nửa kia',
  'calm': 'bình yên',
  'meh': 'bình thường',
  'tired': 'mệt',
  'sad': 'buồn',
  'stressed': 'căng thẳng',
};

const Map<String, String> kMoodWordEn = <String, String>{
  'happy': 'happy',
  'loved': 'loved',
  'missing': 'a little lonely',
  'calm': 'calm',
  'meh': 'somewhere in between',
  'tired': 'tired',
  'sad': 'sad',
  'stressed': 'stressed',
};

/// The full template catalogue.
const List<QuestionTemplate> questionTemplates = <QuestionTemplate>[
  // ── week_start (Monday — the week ahead) ─────────────────────────────────
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_hope',
    variant: 1,
    vi: 'Tuần mới bắt đầu rồi, điều bạn mong nhất ở tuần này là gì?',
    en: 'A new week begins. What do you hope for most in the days ahead?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_hope',
    variant: 2,
    vi: 'Nếu được chọn một chuyện tuần này chắc chắn suôn sẻ, bạn chọn chuyện gì?',
    en: 'If just one thing could go beautifully this week, what would you pick?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_hope',
    variant: 3,
    vi: 'Bạn muốn tuần này của chúng mình ra sao: bận rộn, nhẹ nhàng hay nhiều tiếng cười?',
    en: 'What colour should our week have: busy, gentle, or full of laughter?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_plan_together',
    variant: 1,
    vi: 'Tuần này chúng mình dành cho nhau một buổi tối nhé, bạn muốn làm gì cùng nhau?',
    en: 'Let us save one evening for each other this week. What should we do together?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_plan_together',
    variant: 2,
    vi: 'Có việc nhỏ nào tuần này bạn muốn chúng mình làm chung thay vì làm một mình?',
    en: 'Is there a small thing this week you would rather we do together than alone?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_support',
    variant: 1,
    vi: 'Tuần này có việc gì bạn hơi ngại phải đối mặt và muốn có người ấy ở bên?',
    en: 'Is anything this week a little daunting? Let your partner be there for it.',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_support',
    variant: 2,
    vi: 'Tuần này bạn cần người ấy giúp một tay ở chuyện gì?',
    en: 'What could your partner take off your shoulders this week?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_one_small_thing',
    variant: 1,
    vi: 'Điều nhỏ nào bạn muốn làm cho người ấy trong tuần này?',
    en: 'What is one small thing you want to do for your partner this week?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_one_small_thing',
    variant: 2,
    vi: 'Thói quen nhỏ nào của chúng mình bạn muốn giữ đều trong tuần này?',
    en: 'Which small habit of ours do you want to keep alive this week?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_worry',
    variant: 1,
    vi: 'Có chuyện gì tuần này đang làm bạn hơi lo không? Kể ra đây cho nhẹ lòng nhé.',
    en: 'Is something about this week weighing on you? Say it out loud here.',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_worry',
    variant: 2,
    vi: 'Tuần này bạn muốn bớt điều gì để thấy dễ thở hơn?',
    en: 'What would you like less of this week so it feels lighter?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_looking_forward',
    variant: 1,
    vi: 'Bạn đang háo hức chờ tới lúc nào nhất trong tuần này?',
    en: 'Which moment of this week are you looking forward to most?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekStart,
    topic: 'week_looking_forward',
    variant: 2,
    vi: 'Nếu cuối tuần này chúng mình được đi đâu đó, bạn muốn đi đâu?',
    en: 'If we could go somewhere this weekend, where would you want to go?',
  ),

  // ── feeling (midweek emotional check-in: today / the past few days) ──────
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'today_mood',
    variant: 1,
    vi: 'Thật lòng thì hôm nay bạn thấy thế nào? Một câu thôi cũng được.',
    en: 'How are you really feeling today? One honest sentence is enough.',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'today_mood',
    variant: 2,
    vi: 'Nếu tâm trạng hôm nay là thời tiết, trời của bạn đang nắng, mưa hay âm u?',
    en: 'If today had weather, what would your mood look like?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'today_mood',
    variant: 3,
    vi: 'Hôm nay bạn đang đầy pin hay sắp cạn pin? Vì sao vậy?',
    en: 'Are you running full or nearly empty today, and why?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'today_bright',
    variant: 1,
    vi: 'Điều nhỏ nào hôm nay làm bạn khẽ mỉm cười?',
    en: 'What small thing made you smile today?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'today_bright',
    variant: 2,
    vi: 'Hôm nay có chuyện gì vui mà bạn muốn kể cho người ấy nghe đầu tiên?',
    en: 'What good thing from today do you want to tell your partner first?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'recent_heavy',
    variant: 1,
    vi: 'Mấy ngày qua điều gì làm bạn thấy mệt nhất?',
    en: 'What has drained you most over the past few days?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'recent_heavy',
    variant: 2,
    vi: 'Mấy hôm nay có áp lực nào bạn đang gánh một mình không?',
    en: 'Is there any pressure you have been carrying alone these past days?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'recent_bright',
    variant: 1,
    vi: 'Mấy ngày qua, lúc nào bạn thấy nhẹ lòng nhất?',
    en: 'Which moment of the past few days felt the lightest?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'recent_bright',
    variant: 2,
    vi: 'Mấy hôm nay bạn thấy biết ơn điều gì nhất, dù là điều rất nhỏ?',
    en: 'What are you most grateful for these past days, however small?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'need_from_partner',
    variant: 1,
    vi: 'Lúc này bạn cần người ấy ở bên theo cách nào: lắng nghe, ôm một cái, hay để bạn yên một chút?',
    en: 'Right now, do you need your partner to listen, to hold you, or to give you space?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'need_from_partner',
    variant: 2,
    vi: 'Hôm nay người ấy làm gì thì bạn sẽ thấy dễ chịu hơn?',
    en: 'What from your partner would make today easier?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'want_to_hear',
    variant: 1,
    vi: 'Lúc này bạn muốn nghe người ấy nói câu gì nhất?',
    en: 'What is the one sentence you would love to hear from your partner right now?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'want_to_hear',
    variant: 2,
    vi: 'Có điều gì bạn muốn người ấy hiểu về mình mà bạn chưa kịp nói?',
    en: 'What do you wish your partner understood about you but you have not said yet?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'gratitude_partner',
    variant: 1,
    vi: 'Có điều gì ở người ấy làm bạn thấy biết ơn hôm nay?',
    en: 'What are you grateful for in your partner today?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'gratitude_partner',
    variant: 2,
    vi: 'Thói quen nhỏ nào của người ấy làm ngày của bạn dễ chịu hơn?',
    en: 'Which small habit of your partner makes your day softer?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'small_moment',
    variant: 1,
    vi: 'Gần đây có chuyện nhỏ nào của chúng mình mà bạn muốn giữ lại thật lâu?',
    en: 'Which small moment of ours lately would you like to keep for a long time?',
  ),
  QuestionTemplate(
    group: kTplGroupFeeling,
    topic: 'small_moment',
    variant: 2,
    vi: 'Lần gần nhất chúng mình cười với nhau là vì chuyện gì?',
    en: 'What was the last thing that made us laugh together?',
  ),

  // ── week_recap (Sunday — looking back) ───────────────────────────────────
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_best_moment',
    variant: 1,
    vi: 'Tuần vừa rồi khoảnh khắc nào bạn thích nhất?',
    en: 'What was your favourite moment of the week that just passed?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_best_moment',
    variant: 2,
    vi: 'Nếu chỉ được giữ lại một cảnh của tuần này, bạn giữ cảnh nào?',
    en: 'If you could keep just one scene from this week, which one would it be?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_hard_moment',
    variant: 1,
    vi: 'Tuần vừa rồi chuyện gì làm bạn thấy khó nhất? Bạn đã xoay xở thế nào?',
    en: 'What was hardest this week, and how did you get through it?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_hard_moment',
    variant: 2,
    vi: 'Có chuyện gì tuần này bạn muốn cho qua luôn, không mang sang tuần mới?',
    en: 'What from this week do you want to leave behind as the new week starts?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_grateful_partner',
    variant: 1,
    vi: 'Tuần này người ấy đã làm điều gì khiến bạn thấy được yêu thương?',
    en: 'What did your partner do this week that made you feel loved?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_grateful_partner',
    variant: 2,
    vi: 'Tuần này bạn muốn cảm ơn người ấy vì điều gì?',
    en: 'What would you like to thank your partner for this week?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_learned',
    variant: 1,
    vi: 'Tuần này bạn biết thêm điều gì về người ấy?',
    en: 'What did you learn about your partner this week?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_learned',
    variant: 2,
    vi: 'Qua tuần này, bạn nhận ra điều gì mới về chính mình?',
    en: 'What did you notice about yourself this week?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'weekend_together',
    variant: 1,
    vi: 'Cuối tuần này ở bên nhau, bạn thích nhất lúc nào?',
    en: 'What part of the weekend together did you enjoy the most?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'weekend_together',
    variant: 2,
    vi: 'Cuối tuần này chúng mình đã bỏ lỡ điều gì mà tuần sau nên làm bằng được?',
    en: 'What did we miss this weekend that we should not miss next time?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_proud_of_partner',
    variant: 1,
    vi: 'Người ấy đã làm bạn tự hào ở chuyện gì trong tuần này?',
    en: 'What made you proud of your partner this week?',
  ),
  QuestionTemplate(
    group: kTplGroupWeekRecap,
    topic: 'week_proud_of_partner',
    variant: 2,
    vi: 'Tuần này bạn thấy chúng mình làm tốt nhất chuyện gì?',
    en: 'What did we do best together this week?',
  ),

  // ── month_start / month_end ──────────────────────────────────────────────
  QuestionTemplate(
    group: kTplGroupMonthStart,
    topic: 'month_wish',
    variant: 1,
    vi: 'Sang tháng mới rồi, bạn mong tháng này chúng mình có thêm điều gì?',
    en: 'A new month. What do you hope it brings for the two of us?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthStart,
    topic: 'month_wish',
    variant: 2,
    vi: 'Tháng này bạn muốn sống chậm lại ở chuyện gì?',
    en: 'What would you like to slow down on this month?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthStart,
    topic: 'month_together_goal',
    variant: 1,
    vi: 'Tháng này chúng mình cùng thử một điều mới nhé. Bạn muốn thử gì?',
    en: 'Let us try something new together this month. What do you suggest?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthStart,
    topic: 'month_together_goal',
    variant: 2,
    vi: 'Có nơi nào bạn muốn chúng mình cùng đến trong tháng này không?',
    en: 'Is there a place you want us to visit together this month?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthStart,
    topic: 'month_habit',
    variant: 1,
    vi: 'Thói quen nhỏ nào bạn muốn chúng mình cùng tập trong tháng này?',
    en: 'Which small habit would you like us to build together this month?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthStart,
    topic: 'month_habit',
    variant: 2,
    vi: 'Tháng này bạn muốn dành thêm thời gian cho điều gì?',
    en: 'What do you want to give more time to this month?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthEnd,
    topic: 'month_best',
    variant: 1,
    vi: 'Tháng này bạn nhớ nhất kỷ niệm nào của chúng mình?',
    en: 'Which of our memories this month stayed with you the most?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthEnd,
    topic: 'month_best',
    variant: 2,
    vi: 'Nếu đặt tên cho tháng này của chúng mình, bạn đặt tên gì?',
    en: 'If you had to name this month of ours, what would you call it?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthEnd,
    topic: 'month_change',
    variant: 1,
    vi: 'Tháng này có điều gì ở chúng mình đã thay đổi theo hướng bạn thích?',
    en: 'What changed about us this month in a way you liked?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthEnd,
    topic: 'month_change',
    variant: 2,
    vi: 'Tháng sau bạn muốn chúng mình làm khác đi ở chuyện gì?',
    en: 'What would you like us to do differently next month?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthEnd,
    topic: 'month_thanks',
    variant: 1,
    vi: 'Cuối tháng rồi, bạn muốn cảm ơn người ấy vì điều gì?',
    en: 'As this month closes, what do you want to thank your partner for?',
  ),
  QuestionTemplate(
    group: kTplGroupMonthEnd,
    topic: 'month_thanks',
    variant: 2,
    vi: 'Tháng này bạn thấy người ấy đã cố gắng nhất ở chuyện gì?',
    en: 'Where did you see your partner try the hardest this month?',
  ),

  // ── Calendar hooks ───────────────────────────────────────────────────────
  QuestionTemplate(
    group: kTplGroupNewYear,
    topic: 'year_wish',
    variant: 1,
    vi: 'Năm mới rồi, bạn mong điều gì nhất cho chúng mình trong năm nay?',
    en: 'A new year. What do you wish for us most this year?',
  ),
  QuestionTemplate(
    group: kTplGroupNewYear,
    topic: 'year_wish',
    variant: 2,
    vi: 'Nếu năm nay chúng mình chỉ làm được một điều thật lớn cùng nhau, bạn chọn điều gì?',
    en: 'If we could do just one big thing together this year, what would you choose?',
  ),
  QuestionTemplate(
    group: kTplGroupNewYear,
    topic: 'year_grateful',
    variant: 1,
    vi: 'Nhìn lại năm vừa qua, bạn biết ơn người ấy nhất vì điều gì?',
    en: 'Looking back at the past year, what are you most grateful to your partner for?',
  ),
  QuestionTemplate(
    group: kTplGroupNewYear,
    topic: 'year_grateful',
    variant: 2,
    vi: 'Kỷ niệm nào của năm cũ bạn muốn mang theo sang năm mới?',
    en: 'Which memory from last year do you want to carry into this one?',
  ),
  QuestionTemplate(
    group: kTplGroupNewYear,
    topic: 'year_together',
    variant: 1,
    vi: 'Năm nay bạn muốn chúng mình cùng bắt đầu điều gì mới?',
    en: 'What new thing do you want us to start together this year?',
  ),
  QuestionTemplate(
    group: kTplGroupValentine,
    topic: 'love_meaning',
    variant: 1,
    vi: 'Với bạn, yêu nhau mỗi ngày nghĩa là gì?',
    en: 'What does loving each other every day mean to you?',
  ),
  QuestionTemplate(
    group: kTplGroupValentine,
    topic: 'love_meaning',
    variant: 2,
    vi: 'Điều gì ở tình cảm của chúng mình khiến bạn thấy an tâm nhất?',
    en: 'What about what we have makes you feel safest?',
  ),
  QuestionTemplate(
    group: kTplGroupValentine,
    topic: 'first_feeling',
    variant: 1,
    vi: 'Lần đầu bạn nhận ra mình thương người ấy là khi nào?',
    en: 'When did you first realize you were falling for your partner?',
  ),
  QuestionTemplate(
    group: kTplGroupValentine,
    topic: 'first_feeling',
    variant: 2,
    vi: 'Hồi mới quen, điều gì ở người ấy làm bạn nhớ mãi? Đến giờ vẫn vậy chứ?',
    en: 'What stayed with you from the early days, and does it still?',
  ),
  QuestionTemplate(
    group: kTplGroupValentine,
    topic: 'wish_for_us',
    variant: 1,
    vi: 'Hôm nay là Valentine, bạn muốn chúc chúng mình điều gì?',
    en: 'It is a day for love. What do you wish for the two of us?',
  ),
  QuestionTemplate(
    group: kTplGroupWomensDay,
    topic: 'admire',
    variant: 1,
    vi: 'Hôm nay 8 tháng 3, bạn ngưỡng mộ điều gì nhất ở người phụ nữ trong đời mình?',
    en: 'On this Women\'s Day, what do you admire most about the woman in your life?',
  ),
  QuestionTemplate(
    group: kTplGroupWomensDay,
    topic: 'admire',
    variant: 2,
    vi: 'Cử chỉ dịu dàng nào của người ấy làm bạn thấy được chăm sóc?',
    en: 'What about your partner\'s tenderness makes you feel looked after?',
  ),
  QuestionTemplate(
    group: kTplGroupWomensDay,
    topic: 'celebrate',
    variant: 1,
    vi: 'Hôm nay bạn muốn làm điều nhỏ gì để người ấy thấy mình đặc biệt với bạn?',
    en: 'What small thing could you do today to make your partner feel special?',
  ),
  QuestionTemplate(
    group: kTplGroupVnWomen,
    topic: 'thanks',
    variant: 1,
    vi: 'Hôm nay 20 tháng 10, có điều gì bạn muốn cảm ơn người ấy mà ngày thường hay quên nói?',
    en: 'Today is Vietnamese Women\'s Day. What do you want to thank your partner for that usually goes unsaid?',
  ),
  QuestionTemplate(
    group: kTplGroupVnWomen,
    topic: 'thanks',
    variant: 2,
    vi: 'Bạn có để ý người ấy đã âm thầm lo cho chúng mình những gì không?',
    en: 'What has your partner quietly taken care of for us that you noticed?',
  ),
  QuestionTemplate(
    group: kTplGroupVnWomen,
    topic: 'promise',
    variant: 1,
    vi: 'Hôm nay bạn muốn hứa với người ấy một điều nhỏ nào?',
    en: 'What small promise would you like to make your partner today?',
  ),
  QuestionTemplate(
    group: kTplGroupChristmas,
    topic: 'warmth',
    variant: 1,
    vi: 'Mùa Giáng sinh này, điều gì làm bạn thấy ấm lòng nhất khi nghĩ về chúng mình?',
    en: 'This Christmas, what warms you most when you think about us?',
  ),
  QuestionTemplate(
    group: kTplGroupChristmas,
    topic: 'warmth',
    variant: 2,
    vi: 'Nếu tối nay chỉ có hai người bên ly trà nóng, bạn muốn kể cho người ấy nghe chuyện gì?',
    en: 'If tonight were just the two of us and something warm to drink, what story would you tell?',
  ),
  QuestionTemplate(
    group: kTplGroupChristmas,
    topic: 'gift_wish',
    variant: 1,
    vi: 'Giáng sinh này bạn thật sự muốn người ấy tặng gì? Không nhất thiết phải là đồ vật đâu.',
    en: 'What Christmas gift do you truly want from your partner, even if it is not a thing?',
  ),
  QuestionTemplate(
    group: kTplGroupChristmas,
    topic: 'tradition',
    variant: 1,
    vi: 'Chúng mình tạo một truyền thống Giáng sinh riêng nhé. Bạn nghĩ nên là gì?',
    en: 'We should have a Christmas tradition of our own. What should it be?',
  ),

  // ── Context hooks (dynamic values) ───────────────────────────────────────
  QuestionTemplate(
    group: kTplGroupMilestoneNear,
    topic: 'count_down',
    variant: 1,
    vi: 'Còn $kTplDays ngày nữa là chúng mình tròn $kTplMilestone ngày yêu. Bạn muốn kỷ niệm ngày đó thế nào?',
    en: 'Only $kTplDays days until our $kTplMilestone days together. How do you want to mark it?',
  ),
  QuestionTemplate(
    group: kTplGroupMilestoneNear,
    topic: 'count_down',
    variant: 2,
    vi: 'Sắp tới mốc $kTplMilestone ngày yêu rồi, còn $kTplDays ngày thôi. Từ ngày đầu tới giờ, bạn nhớ nhất chuyện gì?',
    en: 'Our $kTplMilestone days mark is close, just $kTplDays days away. What do you remember most from the road here?',
  ),
  QuestionTemplate(
    group: kTplGroupMilestoneNear,
    topic: 'celebrate_plan',
    variant: 1,
    vi: 'Chỉ còn $kTplDays ngày nữa là tới mốc của chúng mình. Bạn muốn ăn mừng đơn giản hay làm gì đó thật khác?',
    en: 'Just $kTplDays days to go. Should we celebrate simply, or do something completely different?',
  ),
  QuestionTemplate(
    group: kTplGroupMilestoneNear,
    topic: 'look_back',
    variant: 1,
    vi: 'Gần $kTplMilestone ngày bên nhau rồi, bạn thấy chúng mình đã trưởng thành hơn ở điểm nào?',
    en: 'Nearly $kTplMilestone days together. What has grown the most between us?',
  ),
  // mood_partner: the mood is the OTHER phone's partner, but the sentence lands
  // on the shared marker and BOTH read it — so never "người ấy"/"your partner"
  // (the one who set the mood would read about themselves). "Một người trong
  // chúng mình" / "có người" read right from either side.
  QuestionTemplate(
    group: kTplGroupMoodPartner,
    topic: 'ease',
    variant: 1,
    vi: 'Hôm nay một người trong chúng mình thấy $kTplMood. Tối nay chúng mình làm gì cùng nhau thì hợp nhất?',
    en: 'One of us feels $kTplMood today. What would be the best thing to do together tonight?',
  ),
  QuestionTemplate(
    group: kTplGroupMoodPartner,
    topic: 'ease',
    variant: 2,
    vi: 'Hôm nay có người đang thấy $kTplMood đó. Những lúc như vậy, bạn muốn được nghe câu gì nhất?',
    en: 'One of us feels $kTplMood today. When you feel that way, what do you most want to hear?',
  ),
  QuestionTemplate(
    group: kTplGroupMoodPartner,
    topic: 'understand',
    variant: 1,
    vi: 'Hôm nay một người trong chúng mình thấy $kTplMood. Những ngày như vậy, điều gì làm bạn thấy dễ chịu nhất?',
    en: 'One of us feels $kTplMood today. On days like that, what makes you feel most at ease?',
  ),
  QuestionTemplate(
    group: kTplGroupMoodPartner,
    topic: 'accompany',
    variant: 1,
    vi: 'Hôm nay có người đang thấy $kTplMood đó. Bạn muốn chúng mình ở bên nhau theo cách nào?',
    en: 'One of us is feeling $kTplMood today. How would you like us to spend time together?',
  ),
  QuestionTemplate(
    group: kTplGroupNoPhotosWeekend,
    topic: 'capture',
    variant: 1,
    vi: 'Tuần này chúng mình chưa lưu tấm ảnh nào. Lúc nào trong tuần đáng giữ lại nhất?',
    en: 'We have not saved a single photo this week. Which moment deserves to be kept?',
  ),
  QuestionTemplate(
    group: kTplGroupNoPhotosWeekend,
    topic: 'moment_worth',
    variant: 1,
    vi: 'Nếu cuối tuần này chụp một tấm ảnh cho chúng mình, bạn muốn trong ảnh có gì?',
    en: 'If we took one photo this weekend, what would you want in it?',
  ),
  QuestionTemplate(
    group: kTplGroupNoPhotosWeekend,
    topic: 'plan_photo',
    variant: 1,
    vi: 'Cuối tuần này chúng mình đi đâu đó chụp ảnh nhé. Bạn chọn chỗ nào?',
    en: 'Let us go somewhere this weekend for a new photo. Where should it be?',
  ),
  QuestionTemplate(
    group: kTplGroupStreakMilestone,
    topic: 'streak_proud',
    variant: 1,
    vi: 'Chúng mình đã cùng trả lời $kTplStreak ngày liền rồi. Điều gì làm bạn muốn giữ thói quen này?',
    en: 'We have answered together $kTplStreak days in a row. What makes you want to keep this going?',
  ),
  QuestionTemplate(
    group: kTplGroupStreakMilestone,
    topic: 'streak_proud',
    variant: 2,
    vi: '$kTplStreak ngày liền chúng mình không bỏ lỡ ngày nào. Bạn thấy điều đó nói lên gì về chúng mình?',
    en: '$kTplStreak days without missing one. What do you think that says about us?',
  ),
  QuestionTemplate(
    group: kTplGroupStreakMilestone,
    topic: 'streak_ritual',
    variant: 1,
    vi: 'Sau $kTplStreak ngày, câu hỏi mỗi ngày đã thành thói quen của bạn chưa? Bạn muốn thêm gì vào đó?',
    en: 'After $kTplStreak days, has this become a ritual for you, and what would you add to it?',
  ),
];

/// All templates in [group] (empty when the group has no copy yet).
List<QuestionTemplate> templatesForGroup(String group) =>
    questionTemplates.where((t) => t.group == group).toList();
