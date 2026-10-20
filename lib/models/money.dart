import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/money_input.dart';

/// Sổ tiền (feature expenses, overview D1/D6). Two books, one schema:
/// - own book    `users/{uid}/money*`       — only the owner reads/writes;
/// - shared book `couples/{coupleId}/money*` — every doc pins `memberUids`
///   (the couple's `memberIds` when it was written), and only those two read
///   it, so a partner who joins later never sees the previous couple's money.
///
/// Field limits below are the same numbers `firestore.rules` enforces. Money
/// is an `int` of đồng; `amount` is always positive and direction lives in
/// `outWalletId` / `inWalletId`.
enum MoneyBookKind { own, shared }

const String kMoneyWallets = 'moneyWallets';
const String kMoneyTx = 'moneyTx';
const String kMoneyBudgets = 'moneyBudgets';
const String kMoneyMeta = 'moneyMeta';
const String kMoneyMetaDoc = 'main';

/// `payer` of a shared entry paid from a shared wallet (nobody owes anyone).
const String kMoneyPayerWallet = 'wallet';

const int kMoneyNameMax = 30;
const int kMoneyNoteMax = 200;
const int kMoneyIdMax = 40;
const int kMoneyEmojiMax = 8;
const int kMoneyColorMax = 12;
const int kMoneyCategoryNameMax = 24;
const int kMoneyCustomCategoriesMax = 80;
const int kMoneyHiddenCategoriesMax = 120;

final RegExp kMoneyDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

enum MoneyWalletType { cash, bank, ewallet, credit, goal }

enum MoneyTxType { expense, income, transfer, adjust, contribution, settle }

/// How a shared expense is split (D12). [none]: not an expense the two
/// share (contribution, transfer, paid from the shared wallet…).
enum MoneySplitMode {
  equal('equal'),
  treat('treat'),
  forPartner('for_partner'),
  custom('custom'),
  none('none');

  const MoneySplitMode(this.wire);
  final String wire;

  static MoneySplitMode? fromWire(String? raw) {
    for (final m in values) {
      if (m.wire == raw) return m;
    }
    return null;
  }
}

T? _enumByName<T extends Enum>(List<T> values, Object? raw) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return null;
}

DateTime? _time(Object? raw) => raw is Timestamp ? raw.toDate() : null;

int _int(Object? raw, [int fallback = 0]) =>
    raw is num ? raw.toInt() : fallback;

String _str(Object? raw) => raw is String ? raw : '';

List<String> _strings(Object? raw) => raw is List
    ? [
        for (final v in raw)
          if (v is String) v,
      ]
    : const <String>[];

class MoneyWallet {
  const MoneyWallet({
    required this.id,
    required this.name,
    required this.type,
    this.emoji = '',
    this.color = '',
    this.openingBalance = 0,
    this.includeInTotal = true,
    this.archived = false,
    this.order = 0,
    this.goalTarget,
    this.goalDeadline,
    this.goalReachedAt,
    this.memberUids = const <String>[],
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final MoneyWalletType type;
  final String emoji;
  final String color;
  final int openingBalance;
  final bool includeInTotal;
  final bool archived;
  final int order;
  final int? goalTarget;
  final String? goalDeadline;
  final DateTime? goalReachedAt;
  final List<String> memberUids;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isGoal => type == MoneyWalletType.goal;

  /// Counts in "Tổng tiền đang có": in use, not a goal, not switched off (D7).
  bool get countsInTotal => includeInTotal && !isGoal && !archived;

  static MoneyWallet? fromDoc(String id, Map<String, dynamic>? d) {
    if (d == null) return null;
    final type = _enumByName(MoneyWalletType.values, d['type']);
    if (type == null) return null;
    final target = d['goalTarget'];
    final deadline = d['goalDeadline'];
    return MoneyWallet(
      id: id,
      name: _str(d['name']),
      type: type,
      emoji: _str(d['emoji']),
      color: _str(d['color']),
      openingBalance: _int(d['openingBalance']),
      includeInTotal: d['includeInTotal'] != false,
      archived: d['archived'] == true,
      order: _int(d['order']),
      goalTarget: target is num ? target.toInt() : null,
      goalDeadline: deadline is String ? deadline : null,
      goalReachedAt: _time(d['goalReachedAt']),
      memberUids: _strings(d['memberUids']),
      createdBy: _str(d['createdBy']),
      createdAt: _time(d['createdAt']),
      updatedAt: _time(d['updatedAt']),
    );
  }

  /// Create payload (rules: `createdAt == request.time`).
  Map<String, dynamic> toCreateMap({required String uid}) => <String, dynamic>{
    'name': name.trim(),
    'type': type.name,
    'emoji': emoji,
    'color': color,
    'openingBalance': openingBalance,
    'includeInTotal': includeInTotal,
    'archived': archived,
    'order': order,
    if (isGoal && goalTarget != null) 'goalTarget': goalTarget,
    if (isGoal && goalDeadline != null) 'goalDeadline': goalDeadline,
    if (memberUids.isNotEmpty) 'memberUids': memberUids,
    'createdBy': uid,
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// Same limits as the rules — checked before writing so an offline write
  /// can't sit in the queue only to be rejected later.
  bool get isWellFormed =>
      name.trim().isNotEmpty &&
      name.trim().length <= kMoneyNameMax &&
      emoji.length <= kMoneyEmojiMax &&
      color.length <= kMoneyColorMax &&
      openingBalance >= kMoneyWalletMin &&
      openingBalance <= kMoneyWalletMax &&
      (goalTarget == null ||
          (isGoal && goalTarget! >= 1 && goalTarget! <= kMoneyWalletMax)) &&
      (goalDeadline == null ||
          (isGoal && kMoneyDatePattern.hasMatch(goalDeadline!)));
}

class MoneyTx {
  const MoneyTx({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.outWalletId = '',
    this.inWalletId = '',
    this.categoryId = '',
    this.note = '',
    this.linkId,
    this.recurringId,
    this.source,
    this.payer,
    this.splitMode,
    this.payerShare = 0,
    this.memberUids = const <String>[],
    this.createdBy = '',
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.editCount = 0,
    this.pending = false,
  });

  final String id;
  final MoneyTxType type;
  final int amount;

  /// 'YYYY-MM-DD', the day the money moved (chosen by the user).
  final String date;
  final String outWalletId;
  final String inWalletId;
  final String categoryId;
  final String note;

  /// Pairs this doc with one in the other book (D11). Immutable.
  final String? linkId;
  final String? recurringId;

  /// 'manual' | 'decision' | 'recurring'.
  final String? source;

  /// Shared book only: a member uid or [kMoneyPayerWallet].
  final String? payer;
  final MoneySplitMode? splitMode;

  /// Shared book only: the part the payer bears themselves.
  final int payerShare;
  final List<String> memberUids;
  final String createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final int editCount;

  /// Written on this phone, not yet confirmed by the server ("chờ mạng").
  final bool pending;

  String get month => date.length >= 7 ? date.substring(0, 7) : date;

  /// What this entry does to [walletId]'s balance.
  int deltaFor(String walletId) =>
      (inWalletId == walletId ? amount : 0) -
      (outWalletId == walletId ? amount : 0);

  static MoneyTx? fromDoc(
    String id,
    Map<String, dynamic>? d, {
    bool pending = false,
  }) {
    if (d == null) return null;
    final type = _enumByName(MoneyTxType.values, d['type']);
    final amount = d['amount'];
    final date = d['date'];
    if (type == null || amount is! num || date is! String) return null;
    final payer = d['payer'];
    final linkId = d['linkId'];
    final recurringId = d['recurringId'];
    final source = d['source'];
    final updatedBy = d['updatedBy'];
    return MoneyTx(
      id: id,
      type: type,
      amount: amount.toInt(),
      date: date,
      outWalletId: _str(d['outWalletId']),
      inWalletId: _str(d['inWalletId']),
      categoryId: _str(d['categoryId']),
      note: _str(d['note']),
      linkId: linkId is String ? linkId : null,
      recurringId: recurringId is String ? recurringId : null,
      source: source is String ? source : null,
      payer: payer is String ? payer : null,
      splitMode: MoneySplitMode.fromWire(d['splitMode'] as String?),
      payerShare: _int(d['payerShare']),
      memberUids: _strings(d['memberUids']),
      createdBy: _str(d['createdBy']),
      createdAt: _time(d['createdAt']),
      updatedBy: updatedBy is String ? updatedBy : null,
      updatedAt: _time(d['updatedAt']),
      editCount: _int(d['editCount']),
      pending: pending,
    );
  }

  MoneyTx copyWith({
    String? id,
    MoneyTxType? type,
    String? linkId,
    String? source,
    List<String>? memberUids,
    int? amount,
    String? date,
    String? outWalletId,
    String? inWalletId,
    String? categoryId,
    String? note,
    String? payer,
    MoneySplitMode? splitMode,
    int? payerShare,
  }) => MoneyTx(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    outWalletId: outWalletId ?? this.outWalletId,
    inWalletId: inWalletId ?? this.inWalletId,
    categoryId: categoryId ?? this.categoryId,
    note: note ?? this.note,
    linkId: linkId ?? this.linkId,
    recurringId: recurringId,
    source: source ?? this.source,
    payer: payer ?? this.payer,
    splitMode: splitMode ?? this.splitMode,
    payerShare: payerShare ?? this.payerShare,
    memberUids: memberUids ?? this.memberUids,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedBy: updatedBy,
    updatedAt: updatedAt,
    editCount: editCount,
    pending: pending,
  );

  bool get _isShared => memberUids.isNotEmpty;

  /// The fields a user can change (the rest is pinned at creation).
  Map<String, dynamic> editableFields() => <String, dynamic>{
    'amount': amount,
    'outWalletId': outWalletId,
    'inWalletId': inWalletId,
    'date': date,
    'categoryId': categoryId,
    'note': note.trim(),
    if (_isShared) 'payer': payer,
    if (_isShared) 'splitMode': (splitMode ?? MoneySplitMode.none).wire,
    if (_isShared) 'payerShare': payerShare,
  };

  Map<String, dynamic> toCreateMap({required String uid}) => <String, dynamic>{
    'type': type.name,
    ...editableFields(),
    if (linkId != null) 'linkId': linkId,
    if (recurringId != null) 'recurringId': recurringId,
    if (source != null) 'source': source,
    if (_isShared) 'memberUids': memberUids,
    'createdBy': uid,
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// Mirrors the rules' per-type shape (§5) for the book this doc lives in.
  bool get isWellFormed {
    if (amount < 1 || amount > kMoneyTxMax) return false;
    if (!kMoneyDatePattern.hasMatch(date)) return false;
    if (note.trim().length > kMoneyNoteMax) return false;
    if (outWalletId.length > kMoneyIdMax ||
        inWalletId.length > kMoneyIdMax ||
        categoryId.length > kMoneyIdMax ||
        (linkId?.length ?? 0) > kMoneyIdMax) {
      return false;
    }
    final shared = _isShared;
    final payerIsPerson = shared && payer != null && memberUids.contains(payer);
    if (shared) {
      if (memberUids.length != 2) return false;
      if (!payerIsPerson && payer != kMoneyPayerWallet) return false;
      if (payer == kMoneyPayerWallet && outWalletId.isEmpty) return false;
      // A person paid → out of their pocket, never a shared wallet as well
      // (the wallet would drop AND the couple balance count it).
      if (payerIsPerson && outWalletId.isNotEmpty) return false;
      if (payerShare < 0 || payerShare > amount) return false;
    } else if (payer != null || splitMode != null || payerShare != 0) {
      return false;
    }
    final hasOut = outWalletId.isNotEmpty, hasIn = inWalletId.isNotEmpty;
    switch (type) {
      case MoneyTxType.expense:
        return !hasIn && (hasOut || payerIsPerson);
      case MoneyTxType.income:
        return hasIn && !hasOut;
      case MoneyTxType.transfer:
        return hasIn && hasOut && inWalletId != outWalletId;
      case MoneyTxType.adjust:
        return hasIn != hasOut;
      case MoneyTxType.contribution:
        return shared
            ? (hasIn && !hasOut && payerIsPerson)
            : (hasOut && !hasIn);
      case MoneyTxType.settle:
        return shared && payerIsPerson && !hasIn && !hasOut && payerShare == 0;
    }
  }
}

class MoneyBudget {
  const MoneyBudget({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.alerted = const <String, int>{},
  });

  final String id;

  /// '' = the whole-book budget.
  final String categoryId;
  final int amount;

  /// Shared book: month → highest level (80 / 100) already pushed. CF-only.
  final Map<String, int> alerted;

  bool get isTotal => categoryId.isEmpty;

  /// Doc id of a budget: 'total' for the whole book, else the category id —
  /// fixed so two phones setting the same budget hit one doc (rules check).
  static String idFor(String categoryId) =>
      categoryId.isEmpty ? 'total' : categoryId;

  static MoneyBudget? fromDoc(String id, Map<String, dynamic>? d) {
    if (d == null || d['amount'] is! num) return null;
    final raw = d['alerted'];
    return MoneyBudget(
      id: id,
      categoryId: _str(d['categoryId']),
      amount: _int(d['amount']),
      alerted: raw is Map
          ? {
              for (final e in raw.entries)
                if (e.key is String && e.value is num)
                  e.key as String: (e.value as num).toInt(),
            }
          : const <String, int>{},
    );
  }
}

/// A category the user added to one book.
class MoneyCustomCategory {
  const MoneyCustomCategory({
    required this.id,
    required this.kind,
    required this.name,
    this.parentId = '',
    this.emoji = '',
  });

  final String id;

  /// [MoneyTxType.expense] or [MoneyTxType.income].
  final MoneyTxType kind;
  final String parentId;
  final String name;
  final String emoji;

  static MoneyCustomCategory? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'], name = raw['name'];
    final kind = raw['kind'] == 'income'
        ? MoneyTxType.income
        : raw['kind'] == 'expense'
        ? MoneyTxType.expense
        : null;
    if (id is! String || name is! String || kind == null) return null;
    return MoneyCustomCategory(
      id: id,
      kind: kind,
      name: name,
      parentId: _str(raw['parentId']),
      emoji: _str(raw['emoji']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'kind': kind.name,
    'parentId': parentId,
    'name': name,
    'emoji': emoji,
  };
}

/// `{book}/moneyMeta/main`: the book's own category tweaks.
class MoneyMeta {
  const MoneyMeta({
    this.customCategories = const <MoneyCustomCategory>[],
    this.overrides = const <String, ({String name, String emoji})>{},
    this.hiddenCategoryIds = const <String>{},
    this.defaultWalletId,
  });

  static const MoneyMeta empty = MoneyMeta();

  final List<MoneyCustomCategory> customCategories;

  /// Renamed / re-iconed default categories.
  final Map<String, ({String name, String emoji})> overrides;
  final Set<String> hiddenCategoryIds;
  final String? defaultWalletId;

  static MoneyMeta fromDoc(Map<String, dynamic>? d) {
    if (d == null) return empty;
    final rawOverrides = d['overrides'];
    final wallet = d['defaultWalletId'];
    return MoneyMeta(
      customCategories: [
        if (d['customCategories'] is List)
          for (final c in d['customCategories'] as List)
            ?MoneyCustomCategory.fromMap(c),
      ],
      overrides: {
        if (rawOverrides is Map)
          for (final e in rawOverrides.entries)
            if (e.key is String && e.value is Map)
              e.key as String: (
                name: _str((e.value as Map)['name']),
                emoji: _str((e.value as Map)['emoji']),
              ),
      },
      hiddenCategoryIds: _strings(d['hiddenCategoryIds']).toSet(),
      defaultWalletId: wallet is String && wallet.isNotEmpty ? wallet : null,
    );
  }
}
