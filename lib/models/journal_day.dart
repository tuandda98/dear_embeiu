/// One revealed day in the couple journal (feature couple-journal).
///
/// Aggregates a `couples/{coupleId}/dailyAnswers/{date}` marker doc with its two
/// `responses` (both members answered → revealed). The question text is read
/// straight from the marker (`questionVi`/`questionEn`) — it is the text shown
/// the day it was answered, NOT re-derived from the bank (the bank may have
/// shifted since; see PO decision A).
class JournalDay {
  /// 'YYYY-MM-DD' day bucket (the marker doc id).
  final String date;

  /// Question text snapshot for the day, per language.
  final String questionVi;
  final String questionEn;

  /// The current user's answer text (author == [myUid]).
  final String myAnswer;

  /// The partner's answer text (author != [myUid]).
  final String partnerAnswer;

  /// Partner author uid (used to resolve the partner display name).
  final String partnerUid;

  const JournalDay({
    required this.date,
    required this.questionVi,
    required this.questionEn,
    required this.myAnswer,
    required this.partnerAnswer,
    required this.partnerUid,
  });

  /// The localized question text for [langCode] ('vi'/'en'; anything else falls
  /// back to English, then to whatever is available).
  String questionFor(String langCode) {
    final code = langCode.trim().toLowerCase();
    if (code.startsWith('vi')) {
      return questionVi.isNotEmpty ? questionVi : questionEn;
    }
    return questionEn.isNotEmpty ? questionEn : questionVi;
  }

  /// Parses the [date] key into a [DateTime] (date-only). Returns null if the
  /// key is malformed.
  DateTime? get parsedDate => DateTime.tryParse(date);
}
