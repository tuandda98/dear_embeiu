import 'dart:math';

import '../data/activity_bank.dart';
import '../data/dish_bank.dart';
import '../models/decision.dart';

/// One thing the spinner can land on. [name] is what gets stored as `result`:
/// the bank name in the spinner's language (raw — activity names stay lower
/// case in English, the push builds "let's {result}" from them), or the text
/// someone typed. [item] is null for typed-in picks and custom options.
class DecisionCandidate {
  const DecisionCandidate({required this.name, this.resultId = '', this.item});

  final String name;
  final String resultId;
  final DecisionBankItem? item;
}

/// Pure pick logic for the wheel (overview D4). No Flutter, no Firestore —
/// everything time-dependent comes in through `now`, so it is unit-tested.
///
/// - **eat:** dish bank + dishes typed in by hand in the last 90 days (×2);
///   drops what was picked in the last 7 days; before 10:00 breakfast dishes
///   ×2, from 14:00 dinner dishes ×2.
/// - **go:** activity bank + typed-in plans (×2); drops the last 14 days;
///   weekends or after 17:00 `cuoi_tuan`/`toi` ×2, weekday daytime
///   `cuoi_tuan` ×0.5.
/// - **custom:** exactly the typed options, uniform.
///
/// Within one session (this object) eat/go never repeat a pick until the pool
/// runs out. Custom deliberately does NOT: with two options that rule would
/// turn "Ai rửa bát?" into a strict A, B, A, B alternation — not random.
class DecisionSuggester {
  DecisionSuggester({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, Set<String>> _seen = <String, Set<String>>{};

  static const int eatExcludeDays = 7;
  static const int goExcludeDays = 14;
  static const int manualDays = 90;

  static List<DecisionBankItem> bankFor(DecisionKind kind) =>
      kind == DecisionKind.eat ? kDishBank : kActivityBank;

  static DecisionBankItem? bankItem(DecisionKind kind, String id) {
    if (id.isEmpty || kind == DecisionKind.custom) {
      return null;
    }
    for (final item in bankFor(kind)) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  /// 'YYYY-MM-DD' of the local day [daysBack] before [now] (string-comparable).
  static String dayKey(DateTime now, int daysBack) {
    final d = DateTime(now.year, now.month, now.day - daysBack);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static bool _passesFilter(DecisionBankItem item, String filter) {
    if (filter.isEmpty || filter == kDecisionFilterAny) {
      return true;
    }
    return item.has(filter);
  }

  static double _weight(
    DecisionKind kind,
    DecisionBankItem item,
    DateTime now,
  ) {
    var w = 1.0;
    if (kind == DecisionKind.eat) {
      if (now.hour < 10 && item.has('sang')) w *= 2;
      if (now.hour >= 14 && item.has('toi')) w *= 2;
    } else {
      final weekend =
          now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
      if (weekend || now.hour >= 17) {
        if (item.has('cuoi_tuan') || item.has('toi')) w *= 2;
      } else if (item.has('cuoi_tuan')) {
        w *= 0.5;
      }
    }
    return w;
  }

  /// The weighted pool for eat/go after filtering + recency exclusion.
  static List<(DecisionCandidate, double)> pool({
    required DecisionKind kind,
    required String filter,
    required DateTime now,
    required Iterable<Decision> history,
    required bool english,
  }) {
    assert(kind != DecisionKind.custom);
    final excludeFrom = dayKey(
      now,
      (kind == DecisionKind.eat ? eatExcludeDays : goExcludeDays) - 1,
    );
    final manualFrom = dayKey(now, manualDays - 1);
    final recentIds = <String>{};
    final recentNames = <String>{};
    final ofKind = history.where((d) => d.kind == kind).toList();
    for (final d in ofKind) {
      if (d.date.compareTo(excludeFrom) >= 0) {
        if (d.resultId.isNotEmpty) recentIds.add(d.resultId);
        recentNames.add(normalizeDecisionName(d.result));
      }
    }

    final out = <(DecisionCandidate, double)>[];
    final bankNames = <String>{};
    for (final item in bankFor(kind)) {
      final vi = normalizeDecisionName(item.vi);
      final en = normalizeDecisionName(item.en);
      bankNames
        ..add(vi)
        ..add(en);
      if (!_passesFilter(item, filter) ||
          recentIds.contains(item.id) ||
          recentNames.contains(vi) ||
          recentNames.contains(en)) {
        continue;
      }
      out.add((
        DecisionCandidate(
          name: english ? item.en : item.vi,
          resultId: item.id,
          item: item,
        ),
        _weight(kind, item, now),
      ));
    }

    // Typed-in picks of the last 90 days, once each, ×2. Tagless, so they only
    // join the chip they were committed under (or "Tuỳ").
    final manualSeen = <String>{};
    for (final d in ofKind) {
      if (!d.isManual || d.date.compareTo(manualFrom) < 0) continue;
      final key = normalizeDecisionName(d.result);
      if (key.isEmpty ||
          bankNames.contains(key) ||
          recentNames.contains(key) ||
          !manualSeen.add(key)) {
        continue;
      }
      if (filter != kDecisionFilterAny &&
          filter.isNotEmpty &&
          d.filter != filter) {
        continue;
      }
      out.add((DecisionCandidate(name: d.result), 2.0));
    }
    return out;
  }

  /// Next pick for eat/go (null = nothing matches this filter), or a uniform
  /// pick among [options] for custom (null when fewer than 2).
  DecisionCandidate? next({
    required DecisionKind kind,
    String filter = kDecisionFilterAny,
    DateTime? now,
    Iterable<Decision> history = const <Decision>[],
    bool english = false,
    List<String> options = const <String>[],
  }) {
    if (kind == DecisionKind.custom) {
      if (options.length < kDecisionOptionsMin) return null;
      return DecisionCandidate(name: options[_random.nextInt(options.length)]);
    }
    final all = pool(
      kind: kind,
      filter: filter,
      now: now ?? DateTime.now(),
      history: history,
      english: english,
    );
    if (all.isEmpty) return null;
    final seen = _seen.putIfAbsent('${kind.name}|$filter', () => <String>{});
    var fresh = all
        .where((e) => !seen.contains(normalizeDecisionName(e.$1.name)))
        .toList();
    if (fresh.isEmpty) {
      seen.clear();
      fresh = all;
    }
    final picked = _weighted(fresh);
    seen.add(normalizeDecisionName(picked.name));
    return picked;
  }

  /// [count] random entries to scroll past before the result (repeats allowed
  /// — a 2-option custom reel just alternates). Pure decoration.
  List<String> reelFiller(List<String> names, int count) {
    if (names.isEmpty) return const <String>[];
    return List<String>.generate(
      count,
      (_) => names[_random.nextInt(names.length)],
    );
  }

  DecisionCandidate _weighted(List<(DecisionCandidate, double)> entries) {
    final total = entries.fold<double>(0, (sum, e) => sum + e.$2);
    var r = _random.nextDouble() * total;
    for (final e in entries) {
      r -= e.$2;
      if (r < 0) return e.$1;
    }
    return entries.last.$1;
  }
}

String _capitalizeFirst(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// The name to SHOW: a bank pick in the viewer's language (English activity
/// names get a capital — design §10), anything else as stored. Pure — used by
/// the widgets and by the background push handler (widget-today B3).
String decisionDisplayName(
  DecisionKind kind,
  String result,
  String resultId, {
  required bool english,
}) {
  final item = DecisionSuggester.bankItem(kind, resultId);
  if (item == null) {
    return result;
  }
  return english ? _capitalizeFirst(item.en) : item.vi;
}

/// Why a custom option list can't be committed yet (null = OK). Mirrors the
/// rules: 2..12 options, each 1..40 UTF-16 units, ≤480 in total, no duplicate.
enum CustomOptionsIssue { tooFew, tooMany, tooLong, duplicate }

CustomOptionsIssue? validateCustomOptions(List<String> options) {
  if (options.length < kDecisionOptionsMin) return CustomOptionsIssue.tooFew;
  if (options.length > kDecisionOptionsMaxCount) {
    return CustomOptionsIssue.tooMany;
  }
  var total = 0;
  final seen = <String>{};
  for (final o in options) {
    if (o.trim().isEmpty || o.length > kDecisionOptionMax) {
      return CustomOptionsIssue.tooLong;
    }
    total += o.length;
    if (!seen.add(normalizeDecisionName(o))) {
      return CustomOptionsIssue.duplicate;
    }
  }
  return total > kDecisionOptionsTotalMax ? CustomOptionsIssue.tooLong : null;
}
