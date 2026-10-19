/// "Chọn giúp chúng mình" (feature decision-wheel, 2026-10-19).
///
/// One committed pick lives at `couples/{coupleId}/decisions/{id}`:
/// `{date}_eat` / `{date}_go` (one per day per mode — spinning again
/// overwrites it, `spins` + 1) or an auto id for a custom question. Spinning
/// itself is local and free; only "Chốt" writes (overview D2/D3).
enum DecisionKind { eat, go, custom }

DecisionKind? decisionKindFromString(String? raw) {
  switch ((raw ?? '').trim()) {
    case 'eat':
      return DecisionKind.eat;
    case 'go':
      return DecisionKind.go;
    case 'custom':
      return DecisionKind.custom;
    default:
      return null;
  }
}

/// Limits shared with `firestore.rules` (D3).
const int kDecisionResultMax = 40;
const int kDecisionQuestionMax = 60;
const int kDecisionOptionMax = 40;
const int kDecisionOptionsMin = 2;
const int kDecisionOptionsMaxCount = 12;
const int kDecisionOptionsTotalMax = 480;

/// Client-side cap on custom picks per day (rules don't count docs — D5).
const int kDecisionCustomDailyCap = 10;

/// Filter chips (stored in `filter`). Eat: tuy · nha · ngoai · nhanh. Go:
/// tuy · nha · ngoai · free. Custom: ''.
const String kDecisionFilterAny = 'tuy';

/// Doc id for the one-per-day modes. Custom picks use an auto id.
String decisionDocId(DecisionKind kind, String dateKey) {
  assert(kind != DecisionKind.custom);
  return '${dateKey}_${kind.name}';
}

/// Trim, collapse inner whitespace, lower-case — how two names are compared
/// ("Bún  chả" == "bún chả"), for the 7/14-day exclusion and the top 5 (D4/D9).
String normalizeDecisionName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// One row of the dish / activity bank (generated from the PO's tables by
/// `scripts/gen-decision-banks.py`). [tags] holds every column value:
/// dishes `sang|trua|toi` · `nha|ngoai` · `nhanh|vua|cau_ky`; activities
/// `nha|ngoai` · `free|re|ton` · `ngay|toi|cuoi_tuan`.
class DecisionBankItem {
  const DecisionBankItem(this.id, this.vi, this.en, this.emoji, this.tags);

  final String id;
  final String vi;
  final String en;
  final String emoji;
  final Set<String> tags;

  bool has(String tag) => tags.contains(tag);
}

class Decision {
  const Decision({
    required this.id,
    required this.kind,
    required this.date,
    required this.result,
    this.question = '',
    this.options = const <String>[],
    this.filter = '',
    this.resultId = '',
    this.spins = 1,
    this.byUserId = '',
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DecisionKind kind;
  final String date;
  final String question;
  final List<String> options;
  final String filter;
  final String result;
  final String resultId;
  final int spins;
  final String byUserId;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// When the current pick was made (a re-spin moves it).
  DateTime? get pickedAt => updatedAt ?? createdAt;

  /// Typed in by hand (no bank id) — such picks join the pool (×2, D4).
  bool get isManual => kind != DecisionKind.custom && resultId.isEmpty;

  /// null when the doc is malformed (unknown kind / empty result) — skipped.
  static Decision? fromDoc(String id, Map<String, dynamic> data) {
    final kind = decisionKindFromString(data['kind'] as String?);
    final result = (data['result'] as String?)?.trim() ?? '';
    if (kind == null || result.isEmpty) {
      return null;
    }
    final rawOptions = data['options'];
    return Decision(
      id: id,
      kind: kind,
      date: (data['date'] as String?)?.trim() ?? '',
      question: (data['question'] as String?)?.trim() ?? '',
      options: rawOptions is List
          ? rawOptions.whereType<String>().toList(growable: false)
          : const <String>[],
      filter: (data['filter'] as String?)?.trim() ?? '',
      result: result,
      resultId: (data['resultId'] as String?)?.trim() ?? '',
      spins: (data['spins'] as num?)?.toInt() ?? 1,
      byUserId: (data['byUserId'] as String?)?.trim() ?? '',
      createdBy: (data['createdBy'] as String?)?.trim() ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Decision copyWith({
    String? result,
    String? resultId,
    int? spins,
    String? byUserId,
    DateTime? updatedAt,
  }) {
    return Decision(
      id: id,
      kind: kind,
      date: date,
      question: question,
      options: options,
      filter: filter,
      result: result ?? this.result,
      resultId: resultId ?? this.resultId,
      spins: spins ?? this.spins,
      byUserId: byUserId ?? this.byUserId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Firestore Timestamp duck-typed via toDate() (keeps cloud_firestore out of
  // the model layer — same trick as AppNotification).
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      final dynamic d = (value as dynamic).toDate();
      return d is DateTime ? d : null;
    } catch (_) {
      return null;
    }
  }
}
