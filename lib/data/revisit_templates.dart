/// Copy templates for the "NHÌN LẠI" (revisit) question source — feature
/// `endless-questions`, 2026-09-05.
///
/// A revisit question quotes a question the couple ALREADY answered together on
/// an older day (30 / 100 / 365 days ago, or the same day last month) and asks
/// them to look at it again. Only the OLD QUESTION is quoted — never the old
/// answers, because the shared question text is visible to both partners before
/// they answer today (leaking an answer would spoil the reveal).
///
/// Strings are split into prefix/suffix so the old question is concatenated
/// MANUALLY: no ICU braces `{}` anywhere, so the text is safe to render
/// verbatim and safe to store in the day marker.
///
/// Voice: "chúng mình" / "người ấy" / "bạn" (never "hai đứa").
library;

/// One revisit copy variant (both languages, split around the quoted question).
class RevisitTemplate {
  const RevisitTemplate({
    required this.viPrefix,
    required this.viSuffix,
    required this.enPrefix,
    required this.enSuffix,
  });

  final String viPrefix;
  final String viSuffix;
  final String enPrefix;
  final String enSuffix;

  String renderVi(String oldQuestion) => '$viPrefix$oldQuestion$viSuffix';

  String renderEn(String oldQuestion) => '$enPrefix$oldQuestion$enSuffix';
}

/// Bucket keys, in the order the source prefers them (farthest look-back first
/// — a one-year callback lands harder than a one-month one).
const List<String> revisitBucketPriority = <String>[
  revisitBucketYear,
  revisitBucketHundred,
  revisitBucketThirty,
  revisitBucketMonth,
];

const String revisitBucketYear = 'd365';
const String revisitBucketHundred = 'd100';
const String revisitBucketThirty = 'd30';
const String revisitBucketMonth = 'month';

/// ≥ 6 variants per bucket so a couple can hit the same distance many times
/// without seeing the same wrapper twice in a row.
const Map<String, List<RevisitTemplate>> revisitTemplates =
    <String, List<RevisitTemplate>>{
  revisitBucketYear: <RevisitTemplate>[
    RevisitTemplate(
      viPrefix: 'Đúng một năm trước, câu hỏi của chúng mình là "',
      viSuffix: '". Một năm qua điều đó thay đổi thế nào?',
      enPrefix: 'Exactly a year ago our question was "',
      enSuffix: '". How has that changed over the past year?',
    ),
    RevisitTemplate(
      viPrefix: 'Một năm trước chúng mình cùng trả lời: "',
      viSuffix: '". Hôm nay bạn sẽ trả lời khác đi ở chỗ nào?',
      enPrefix: 'A year ago we both answered: "',
      enSuffix: '". Where would your answer be different today?',
    ),
    RevisitTemplate(
      viPrefix: 'Tròn một năm kể từ câu hỏi "',
      viSuffix: '". Điều gì trong bạn vẫn còn nguyên vẹn?',
      enPrefix: 'A full year since the question "',
      enSuffix: '". What inside you has stayed exactly the same?',
    ),
    RevisitTemplate(
      viPrefix: 'Ngày này năm ngoái, chúng mình đã trả lời "',
      viSuffix: '". Bạn tự hào nhất điều gì của một năm qua?',
      enPrefix: 'On this day last year we answered "',
      enSuffix: '". What are you proudest of from this past year?',
    ),
    RevisitTemplate(
      viPrefix: 'Một năm trước, câu hỏi này từng ở đây: "',
      viSuffix: '". Chúng mình đã đi được bao xa rồi?',
      enPrefix: 'A year ago this question was right here: "',
      enSuffix: '". How far have we come since then?',
    ),
    RevisitTemplate(
      viPrefix: 'Nhìn lại một năm: "',
      viSuffix: '". Nếu trả lời lại hôm nay, bạn muốn viết gì cho người ấy?',
      enPrefix: 'Looking back one year: "',
      enSuffix: '". Answering it again today, what would you write for your partner?',
    ),
  ],
  revisitBucketHundred: <RevisitTemplate>[
    RevisitTemplate(
      viPrefix: '100 ngày trước chúng mình cùng trả lời: "',
      viSuffix: '". Sau 100 ngày, câu trả lời của bạn đổi khác thế nào?',
      enPrefix: 'A hundred days ago we both answered: "',
      enSuffix: '". After a hundred days, how has your answer changed?',
    ),
    RevisitTemplate(
      viPrefix: 'Tròn 100 ngày kể từ câu hỏi "',
      viSuffix: '". Hôm nay bạn trả lời sao?',
      enPrefix: 'It has been a hundred days since the question "',
      enSuffix: '". How would you answer it today?',
    ),
    RevisitTemplate(
      viPrefix: 'Chúng mình từng trả lời "',
      viSuffix: '" cách đây 100 ngày. Điều gì bây giờ bạn thấy rõ hơn?',
      enPrefix: 'We answered "',
      enSuffix: '" a hundred days ago. What do you see more clearly now?',
    ),
    RevisitTemplate(
      viPrefix: '100 ngày trước, câu hỏi của chúng mình là "',
      viSuffix: '". Bạn muốn nói gì với chính mình hồi đó?',
      enPrefix: 'A hundred days ago our question was "',
      enSuffix: '". What would you tell your past self?',
    ),
    RevisitTemplate(
      viPrefix: 'Nhìn lại 100 ngày: "',
      viSuffix: '". Điều gì giữa chúng mình đã lớn lên từ đó?',
      enPrefix: 'Looking back a hundred days: "',
      enSuffix: '". What has grown between us since then?',
    ),
    RevisitTemplate(
      viPrefix: 'Cách đây 100 ngày chúng mình đã cùng trả lời "',
      viSuffix: '". Câu trả lời cũ còn đúng với bạn chứ?',
      enPrefix: 'A hundred days back we both answered "',
      enSuffix: '". Does that old answer still fit you?',
    ),
  ],
  revisitBucketThirty: <RevisitTemplate>[
    RevisitTemplate(
      viPrefix: '30 ngày trước chúng mình cùng trả lời: "',
      viSuffix: '". Giờ nhìn lại, câu trả lời của bạn còn đúng không, '
          'hay đã có gì đổi khác?',
      enPrefix: 'Thirty days ago we both answered: "',
      enSuffix: '". Looking back now, does your answer still hold, '
          'or has something changed?',
    ),
    RevisitTemplate(
      viPrefix: 'Cách đây 30 ngày chúng mình được hỏi: "',
      viSuffix: '". Nếu trả lời lại hôm nay, bạn sẽ viết gì?',
      enPrefix: 'Thirty days ago we were asked: "',
      enSuffix: '". If you answered it again today, what would you write?',
    ),
    RevisitTemplate(
      viPrefix: '30 ngày trước, câu hỏi của chúng mình là "',
      viSuffix: '". Điều gì trong câu trả lời của bạn vẫn nguyên vẹn?',
      enPrefix: 'Thirty days back, our question was "',
      enSuffix: '". What part of your answer is still exactly the same?',
    ),
    RevisitTemplate(
      viPrefix: 'Nhìn lại 30 ngày: chúng mình từng trả lời "',
      viSuffix: '". Hôm nay bạn muốn nói thêm điều gì?',
      enPrefix: 'Looking back thirty days: we once answered "',
      enSuffix: '". What would you add to it today?',
    ),
    RevisitTemplate(
      viPrefix: '30 ngày vừa rồi bắt đầu bằng câu hỏi này: "',
      viSuffix: '". Từ đó tới giờ, điều gì giữa chúng mình đã khác đi?',
      enPrefix: 'The last thirty days started with this question: "',
      enSuffix: '". Since then, what has shifted between us?',
    ),
    RevisitTemplate(
      viPrefix: '30 ngày trước bạn từng trả lời câu này: "',
      viSuffix: '". Bạn có bất ngờ với chính mình của hồi đó không?',
      enPrefix: 'Thirty days ago you answered this one: "',
      enSuffix: '". Does your past self surprise you at all?',
    ),
  ],
  revisitBucketMonth: <RevisitTemplate>[
    RevisitTemplate(
      viPrefix: 'Ngày này tháng trước chúng mình trả lời: "',
      viSuffix: '". Một tháng qua có gì đổi khác không?',
      enPrefix: 'On this day last month we answered: "',
      enSuffix: '". Has anything changed in the past month?',
    ),
    RevisitTemplate(
      viPrefix: 'Tháng trước, đúng ngày này, câu hỏi là "',
      viSuffix: '". Bạn trả lời lại thế nào?',
      enPrefix: 'Last month, on this very day, the question was "',
      enSuffix: '". How would you answer it now?',
    ),
    RevisitTemplate(
      viPrefix: 'Chúng mình từng trả lời "',
      viSuffix: '" vào ngày này tháng trước. Điều gì bạn muốn giữ lại?',
      enPrefix: 'We answered "',
      enSuffix: '" on this day last month. What would you like to keep?',
    ),
    RevisitTemplate(
      viPrefix: 'Một tháng trôi qua kể từ câu hỏi "',
      viSuffix: '". Hôm nay bạn thấy thế nào?',
      enPrefix: 'A month has passed since the question "',
      enSuffix: '". How do you feel about it today?',
    ),
    RevisitTemplate(
      viPrefix: 'Ngày này tháng trước, chúng mình cùng nghĩ về "',
      viSuffix: '". Giờ bạn nghĩ khác đi ở chỗ nào?',
      enPrefix: 'On this day last month we both thought about "',
      enSuffix: '". Where do you think differently now?',
    ),
    RevisitTemplate(
      viPrefix: 'Tháng trước chúng mình đã trả lời "',
      viSuffix: '". Bạn muốn nói thêm gì với người ấy?',
      enPrefix: 'Last month we answered "',
      enSuffix: '". What else would you like to say to your partner?',
    ),
  ],
};
