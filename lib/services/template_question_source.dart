import '../data/daily_questions.dart' show stableQuestionHash, deterministicPermutation;
import '../data/question_templates.dart';
import 'question_source.dart';

/// Time- and context-aware question source (feature endless-questions).
///
/// Picks a template from `data/question_templates.dart`: the engine either asks
/// for a specific group (weekday schedule / calendar override) via
/// [proposeGroup], or lets the source choose one itself via [propose].
///
/// Deterministic: the variant is chosen from a (coupleId + dateKey + group)
/// seeded permutation, so both phones agree even before the day marker exists.
/// Keys already in `recentTemplateKeys` are skipped (all-used ⇒ fresh cycle).
class TemplateQuestionSource implements QuestionSource {
  const TemplateQuestionSource();

  @override
  String get key => 'template';

  /// Anniversary milestones (in days together) worth a heads-up question.
  static const List<int> milestoneDays = <int>[100, 365, 520, 1000, 1314];

  /// Streak lengths worth celebrating in the question itself.
  static const List<int> streakMilestones = <int>[7, 30, 50, 100, 200, 365];

  /// How many days before/after a milestone the hook may fire.
  static const int milestoneWindowDays = 3;

  @override
  Future<QuestionCandidate?> propose(QuestionContext ctx) async {
    try {
      for (final group in groupsFor(ctx)) {
        final candidate = _pick(ctx, group);
        if (candidate != null) {
          return candidate;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Proposes from ONE specific [group] (used by the engine's weekday schedule
  /// and calendar overrides). Returns null when the group has no usable copy
  /// for this context — the engine then falls through to the next source.
  Future<QuestionCandidate?> proposeGroup(
    QuestionContext ctx,
    String group,
  ) async {
    try {
      return _pick(ctx, group);
    } catch (_) {
      return null;
    }
  }

  // ── Group selection ──────────────────────────────────────────────────────

  /// Context-driven groups, most specific first. The engine reuses this for its
  /// calendar overrides ([overrideGroupsFor]) so both paths stay in sync.
  static List<String> groupsFor(QuestionContext ctx) => <String>[
        ...overrideGroupsFor(ctx),
        weekdayGroupFor(ctx.date) ?? kTplGroupFeeling,
        kTplGroupFeeling,
      ];

  /// Calendar/context hooks that OVERRIDE the plain weekday rotation, ordered
  /// by precedence: fixed holidays → anniversary milestone → month edges →
  /// streak milestone → photo-less weekend → partner's mood.
  static List<String> overrideGroupsFor(QuestionContext ctx) {
    final date = ctx.date;
    final groups = <String>[];

    // Fixed dates.
    if (date.month == 1 && date.day == 1) {
      groups.add(kTplGroupNewYear);
    }
    if (date.month == 2 && date.day == 14) {
      groups.add(kTplGroupValentine);
    }
    if (date.month == 3 && date.day == 8) {
      groups.add(kTplGroupWomensDay);
    }
    if (date.month == 10 && date.day == 20) {
      groups.add(kTplGroupVnWomen);
    }
    if (date.month == 12 && (date.day == 24 || date.day == 25)) {
      groups.add(kTplGroupChristmas);
    }

    // Anniversary milestone within +/- 3 days.
    if (nearestMilestoneOffset(ctx.anniversaryDate, date) != null) {
      groups.add(kTplGroupMilestoneNear);
    }

    // Month edges (a 1st that is also New Year already added new_year first).
    if (date.day == 1) {
      groups.add(kTplGroupMonthStart);
    }
    if (_isLastDayOfMonth(date)) {
      groups.add(kTplGroupMonthEnd);
    }

    if (streakMilestones.contains(ctx.currentStreak)) {
      groups.add(kTplGroupStreakMilestone);
    }

    final isWeekend = date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
    if (isWeekend && ctx.photosThisWeek == 0) {
      groups.add(kTplGroupNoPhotosWeekend);
    }

    final mood = ctx.partnerMoodToday?.trim();
    if (mood != null && kMoodWordVi.containsKey(mood)) {
      groups.add(kTplGroupMoodPartner);
    }

    return groups;
  }

  /// The template group of the plain weekday rotation, or null on days the
  /// schedule hands to another source (Tue/Thu/Sat → bank, Fri → revisit).
  static String? weekdayGroupFor(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return kTplGroupWeekStart;
      case DateTime.wednesday:
        return kTplGroupFeeling;
      case DateTime.sunday:
        return kTplGroupWeekRecap;
      default:
        return null;
    }
  }

  /// `milestone - daysTogether` when a milestone falls within
  /// [milestoneWindowDays] of [date], else null. Negative ⇒ just passed.
  /// Milestones = the curated list plus every whole year (365 * n).
  static ({int milestone, int offset})? nearestMilestoneOffset(
    DateTime anniversary,
    DateTime date,
  ) {
    final from = DateTime(anniversary.year, anniversary.month, anniversary.day);
    final today = DateTime(date.year, date.month, date.day);
    final daysTogether = today.difference(from).inDays;
    if (daysTogether < 0) {
      return null;
    }

    final candidates = <int>{
      ...milestoneDays,
      // Yearly marks around today (previous, current and next year mark).
      for (int y = 1; y <= (daysTogether ~/ 365) + 2; y++) 365 * y,
    };

    ({int milestone, int offset})? best;
    for (final milestone in candidates) {
      final offset = milestone - daysTogether;
      if (offset.abs() > milestoneWindowDays) {
        continue;
      }
      if (best == null || offset.abs() < best.offset.abs()) {
        best = (milestone: milestone, offset: offset);
      }
    }
    return best;
  }

  static bool _isLastDayOfMonth(DateTime date) {
    final nextMonth = date.month == 12
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1)).day;
    return date.day == lastDay;
  }

  // ── Picking ──────────────────────────────────────────────────────────────

  QuestionCandidate? _pick(QuestionContext ctx, String group) {
    final milestone = nearestMilestoneOffset(ctx.anniversaryDate, ctx.date);
    final moodKey = ctx.partnerMoodToday?.trim();
    final moodVi = moodKey == null ? null : kMoodWordVi[moodKey];
    final moodEn = moodKey == null ? null : kMoodWordEn[moodKey];

    // Only templates whose placeholders we can actually fill for this context.
    final usable = templatesForGroup(group).where((t) {
      if (t.needsMood && (moodVi == null || moodEn == null)) {
        return false;
      }
      if (t.needsMilestone && milestone == null) {
        return false;
      }
      // "còn N ngày" only makes sense strictly BEFORE the milestone.
      if (t.needsDays && (milestone == null || milestone.offset < 1)) {
        return false;
      }
      if (t.needsStreak && ctx.currentStreak <= 0) {
        return false;
      }
      return true;
    }).toList();

    if (usable.isEmpty) {
      return null;
    }

    final seed = stableQuestionHash('${ctx.coupleId}|${ctx.dateKey}|$group');
    final perm = deterministicPermutation(usable.length, seed);
    final recent = ctx.recentTemplateKeys.toSet();

    QuestionTemplate chosen = usable[perm.first];
    for (final index in perm) {
      if (!recent.contains(usable[index].key)) {
        chosen = usable[index];
        break;
      }
    }

    final vi = _fill(
      chosen.vi,
      milestone: milestone,
      mood: moodVi,
      streak: ctx.currentStreak,
    );
    final en = _fill(
      chosen.en,
      milestone: milestone,
      mood: moodEn,
      streak: ctx.currentStreak,
    );
    if (vi.isEmpty || en.isEmpty) {
      return null;
    }

    return QuestionCandidate(
      source: 'template',
      questionVi: vi,
      questionEn: en,
      templateKey: chosen.key,
    );
  }

  /// Substitutes the `%token%` placeholders by plain concatenation (no ICU).
  static String _fill(
    String text, {
    ({int milestone, int offset})? milestone,
    String? mood,
    required int streak,
  }) {
    var out = text;
    if (milestone != null) {
      out = out
          .replaceAll(kTplDays, milestone.offset.abs().toString())
          .replaceAll(kTplMilestone, milestone.milestone.toString());
      // EN plural: "1 days" → "1 day" (the day right before every milestone).
      out = out.replaceAll(RegExp(r'\b1 days\b'), '1 day');
    }
    if (mood != null) {
      out = out.replaceAll(kTplMood, mood);
    }
    out = out.replaceAll(kTplStreak, streak.toString());
    // Defensive: never render a leftover token.
    if (out.contains('%')) {
      return '';
    }
    return out;
  }
}
