import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/revisit_templates.dart';
import 'firebase_bootstrap_service.dart';
import 'question_source.dart';

/// "NHÌN LẠI" — a [QuestionSource] that builds today's question out of the
/// couple's OWN history instead of a bank/AI (feature `endless-questions`,
/// 2026-09-05).
///
/// It looks for a day the couple already finished together (`bothAnswered`) a
/// meaningful distance back — 365 / 100 / 30 days (±2) or the same day last
/// month — and asks them to look at that question again. Rule-based only: no
/// network beyond Firestore, no AI.
///
/// Privacy rule: the shared question quotes ONLY the old QUESTION, never an old
/// answer. Both partners see the marker text before answering today, so quoting
/// a partner's answer would leak it. Each member's own old answer is surfaced
/// separately through [QuestionCandidate.hintVi]/[QuestionCandidate.hintEn],
/// which the engine does NOT persist on the marker.
///
/// Fail-soft by contract: every error, timeout (5s) or missing precondition
/// returns null so the engine falls through to the next source.
class RevisitQuestionSource implements QuestionSource {
  RevisitQuestionSource({FirebaseFirestore? firestore}) : _firestore = firestore;

  /// Injectable for tests; falls back to the default app instance.
  final FirebaseFirestore? _firestore;

  /// How many marker docs to scan (newest first) — ~5 months of daily play, and
  /// enough to reach a one-year callback for couples with gaps.
  static const int _markerScanLimit = 150;

  static const Duration _budget = Duration(seconds: 5);

  @override
  String get key => 'revisit';

  bool get _isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<QuestionCandidate?> propose(QuestionContext ctx) async {
    if (!_isUsingFirebase ||
        ctx.coupleId.trim().isEmpty ||
        ctx.myUid.trim().isEmpty ||
        ctx.partnerUid.trim().isEmpty) {
      return null;
    }

    try {
      return await Future<QuestionCandidate?>(() => _propose(ctx))
          .timeout(_budget);
    } catch (_) {
      // Never throw: the engine must be able to fall through to another source.
      return null;
    }
  }

  Future<QuestionCandidate?> _propose(QuestionContext ctx) async {
    final markers = _db
        .collection('couples')
        .doc(ctx.coupleId)
        .collection('dailyAnswers');

    final snapshot = await markers
        .orderBy('date', descending: true)
        .limit(_markerScanLimit)
        .get();

    // Client-side filter: only fully revealed days that actually carry a
    // question snapshot are quotable.
    final questionsByDate = <String, _OldQuestion>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['bothAnswered'] != true) {
        continue;
      }
      final vi = (data['questionVi'] as String? ?? '').trim();
      if (vi.isEmpty) {
        continue;
      }
      final en = (data['questionEn'] as String? ?? '').trim();
      final dateKey = (data['date'] as String?)?.trim().isNotEmpty == true
          ? (data['date'] as String).trim()
          : doc.id;
      questionsByDate[dateKey] = _OldQuestion(vi: vi, en: en.isEmpty ? vi : en);
    }
    if (questionsByDate.isEmpty) {
      return null;
    }

    final seedKey = '${ctx.coupleId}|${ctx.dateKey}';
    final pick = pickRevisitDate(
      today: ctx.date,
      availableDateKeys: questionsByDate.keys,
      excludedDateKeys: ctx.recentRevisitDates.toSet(),
      seedKey: seedKey,
    );
    if (pick == null) {
      return null;
    }

    final old = questionsByDate[pick.dateKey]!;
    final text = renderRevisitQuestion(
      bucket: pick.bucket,
      oldQuestionVi: old.vi,
      oldQuestionEn: old.en,
      seedKey: seedKey,
    );

    // Per-user hint: only MY own old answer, never the partner's.
    RevisitHints? hints;
    try {
      final mine = await markers
          .doc(pick.dateKey)
          .collection('responses')
          .doc(ctx.myUid)
          .get();
      hints = buildRevisitHints(mine.data()?['text'] as String?);
    } catch (_) {
      hints = null;
    }

    return QuestionCandidate(
      source: key,
      questionVi: text.vi,
      questionEn: text.en,
      refDate: pick.dateKey,
      hintVi: hints?.vi,
      hintEn: hints?.en,
    );
  }
}

// ── Pure helpers (unit-tested without Firestore) ─────────────────────────────

/// A look-back window the source is willing to revisit.
class RevisitTarget {
  const RevisitTarget({
    required this.bucket,
    required this.date,
    required this.toleranceDays,
  });

  /// One of [revisitBucketPriority].
  final String bucket;

  /// The ideal day to revisit (UTC-normalized, date-only).
  final DateTime date;

  /// How many days away from [date] still counts as a hit.
  final int toleranceDays;
}

/// The day the source decided to revisit.
class RevisitPick {
  const RevisitPick({required this.bucket, required this.dateKey});

  final String bucket;

  /// 'YYYY-MM-DD' of the old day.
  final String dateKey;
}

/// Rendered question text, both languages.
class RevisitQuestionText {
  const RevisitQuestionText({required this.vi, required this.en});

  final String vi;
  final String en;
}

/// Per-user hint text, both languages.
class RevisitHints {
  const RevisitHints({required this.vi, required this.en});

  final String vi;
  final String en;
}

class _OldQuestion {
  const _OldQuestion({required this.vi, required this.en});

  final String vi;
  final String en;
}

/// Max characters of the quoted OLD question (ellipsis included).
const int kRevisitQuoteMaxChars = 90;

/// Max characters of the quoted OLD answer inside a hint (ellipsis included).
const int kRevisitHintMaxChars = 80;

/// Hard cap for the rendered question (matches the daily-answer text budget).
const int kRevisitQuestionMaxChars = 280;

/// Days that must have passed before a day can be revisited — the last week is
/// still fresh in mind, quoting it feels like a repeat rather than a callback.
const int kRevisitMinAgeDays = 8;

/// The look-back windows for [today], in priority order (farthest first).
List<RevisitTarget> revisitTargetsFor(DateTime today) {
  final base = _utcDate(today);
  return <RevisitTarget>[
    RevisitTarget(
      bucket: revisitBucketYear,
      date: base.subtract(const Duration(days: 365)),
      toleranceDays: 2,
    ),
    RevisitTarget(
      bucket: revisitBucketHundred,
      date: base.subtract(const Duration(days: 100)),
      toleranceDays: 2,
    ),
    RevisitTarget(
      bucket: revisitBucketThirty,
      date: base.subtract(const Duration(days: 30)),
      toleranceDays: 2,
    ),
    RevisitTarget(
      bucket: revisitBucketMonth,
      // Same day-of-month one month back, clamped to the end of short months
      // (31 Mar → 28/29 Feb, 31 May → 30 Apr).
      date: monthsAgo(base, 1),
      toleranceDays: 0,
    ),
  ];
}

/// [date] shifted back by [months] calendar months, clamping the day-of-month to
/// the last valid day of the target month. Date-only, UTC-normalized.
DateTime monthsAgo(DateTime date, int months) {
  final base = _utcDate(date);
  var year = base.year;
  var month = base.month - months;
  while (month <= 0) {
    month += 12;
    year -= 1;
  }
  while (month > 12) {
    month -= 12;
    year += 1;
  }
  // Day 0 of the following month == last day of this month.
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, base.day < lastDay ? base.day : lastDay);
}

/// Picks the old day to revisit, or null when nothing qualifies.
///
/// Walks [revisitTargetsFor] in priority order; within one window every eligible
/// day is equally good, so the choice is deterministic on
/// FNV-1a([seedKey]) — both partners' devices land on the same day without any
/// coordination.
RevisitPick? pickRevisitDate({
  required DateTime today,
  required Iterable<String> availableDateKeys,
  required String seedKey,
  Set<String> excludedDateKeys = const <String>{},
}) {
  final base = _utcDate(today);

  // Parse once, drop malformed / too-fresh / already-revisited days.
  final eligible = <String, DateTime>{};
  for (final rawKey in availableDateKeys) {
    final key = rawKey.trim();
    if (key.isEmpty || excludedDateKeys.contains(key)) {
      continue;
    }
    final parsed = DateTime.tryParse(key);
    if (parsed == null) {
      continue;
    }
    final date = _utcDate(parsed);
    if (base.difference(date).inDays < kRevisitMinAgeDays) {
      continue;
    }
    eligible[key] = date;
  }
  if (eligible.isEmpty) {
    return null;
  }

  for (final target in revisitTargetsFor(base)) {
    final matches = <String>[];
    eligible.forEach((key, date) {
      final gap = date.difference(target.date).inDays.abs();
      if (gap <= target.toleranceDays) {
        matches.add(key);
      }
    });
    if (matches.isEmpty) {
      continue;
    }
    matches.sort();
    final index = fnv1a32('$seedKey|${target.bucket}') % matches.length;
    final chosen = matches[index];
    // A calendar month back is always 28–31 days, i.e. it always falls inside
    // the 30 ±2 window too. Same DATE either way, so keep the priority order
    // from the spec but label an exact month anniversary with the 'month'
    // bucket — its copy ("ngày này tháng trước") reads truer than "30 ngày".
    final bucket = target.bucket == revisitBucketThirty &&
            chosen == _dateKeyOf(monthsAgo(base, 1))
        ? revisitBucketMonth
        : target.bucket;
    return RevisitPick(bucket: bucket, dateKey: chosen);
  }
  return null;
}

/// Renders the revisit question for [bucket], quoting [oldQuestionVi] /
/// [oldQuestionEn]. Deterministic on FNV-1a([seedKey]); the result never exceeds
/// [kRevisitQuestionMaxChars] and never contains ICU braces.
RevisitQuestionText renderRevisitQuestion({
  required String bucket,
  required String oldQuestionVi,
  required String oldQuestionEn,
  required String seedKey,
}) {
  final variants =
      revisitTemplates[bucket] ?? revisitTemplates[revisitBucketThirty]!;
  final template = variants[fnv1a32('$seedKey#$bucket') % variants.length];

  final vi = oldQuestionVi.trim();
  final en = oldQuestionEn.trim().isEmpty ? vi : oldQuestionEn.trim();

  return RevisitQuestionText(
    vi: _fit((quote) => template.renderVi(quote), vi),
    en: _fit((quote) => template.renderEn(quote), en),
  );
}

/// The per-user hint ("what YOU wrote back then"), or null when there is no own
/// answer to quote.
RevisitHints? buildRevisitHints(String? myOldAnswer) {
  final quote = truncateForQuote(myOldAnswer ?? '', kRevisitHintMaxChars);
  if (quote.isEmpty) {
    return null;
  }
  return RevisitHints(
    vi: 'Hồi đó bạn viết: "$quote"',
    en: 'Back then you wrote: "$quote"',
  );
}

/// Collapses whitespace and cuts [text] down to [maxChars] characters,
/// ellipsis included. Returns '' for blank input.
String truncateForQuote(String text, int maxChars) {
  final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.isEmpty || maxChars <= 0) {
    return '';
  }
  final runes = clean.runes.toList();
  if (runes.length <= maxChars) {
    return clean;
  }
  final head = String.fromCharCodes(runes.take(maxChars - 1)).trimRight();
  return '$head…';
}

/// FNV-1a 32-bit — small, stable across platforms and Dart versions (unlike
/// [Object.hashCode]), which is what makes both devices agree.
int fnv1a32(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Renders with progressively shorter quotes until the whole line fits the
/// [kRevisitQuestionMaxChars] budget.
String _fit(String Function(String quote) render, String source) {
  for (final max in const <int>[kRevisitQuoteMaxChars, 70, 50, 30]) {
    final candidate = render(truncateForQuote(source, max));
    if (candidate.runes.length <= kRevisitQuestionMaxChars) {
      return candidate;
    }
  }
  return truncateForQuote(
    render(truncateForQuote(source, 30)),
    kRevisitQuestionMaxChars,
  );
}

DateTime _utcDate(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

String _dateKeyOf(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
