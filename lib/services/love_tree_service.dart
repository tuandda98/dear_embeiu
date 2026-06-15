import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';

/// Pure milestone math + the "seen" marker for the Love Tree feature
/// (feature love-tree, 2026-06-14).
///
/// "Flowers = milestones crossed" derived from three MONOTONIC signals so a
/// bloomed flower never falls off (PO scope): days-together, the LONGEST streak
/// (never `currentStreak`, which resets), and the photo count. Everything here
/// is a pure function of those three ints — no backend, no provider — so both
/// [LoveTreeScreen] and the [StreakChip] entry badge compute the exact same
/// flower count and read/write the same Hive `lastSeen` marker.
enum FlowerKind { days, streak, photos }

/// One milestone = one flower. [index] is its STABLE slot (sorted days → streak
/// → photos, ascending within each) so the deterministic bloom layout never
/// shuffles existing flowers when newer ones unlock.
@immutable
class LoveTreeMilestone {
  const LoveTreeMilestone({
    required this.kind,
    required this.value,
    required this.index,
    required this.reached,
  });

  final FlowerKind kind;

  /// The threshold (e.g. 100 days, 7-day streak, 25 photos).
  final int value;

  /// Stable bloom slot — assigned over the FULL milestone list (reached or not)
  /// so a flower's position depends only on its rank, never on how many are
  /// currently open.
  final int index;

  final bool reached;
}

/// Tree growth stage, derived from the flower count alone (PO thresholds).
enum LoveTreeStage { seed, sprout, young, green, bloom }

class LoveTreeService {
  const LoveTreeService._();

  // Milestone thresholds per source (PO scope §2). Ascending — keep sorted.
  static const List<int> dayMilestones = [30, 100, 200, 365, 520, 730, 1000, 1314];
  static const List<int> streakMilestones = [3, 7, 30, 100, 365];
  static const List<int> photoMilestones = [1, 10, 25, 50, 100];

  /// Box + key for the per-couple "last seen flower count" (Hive `app_settings`,
  /// stored as a String to match the box's value type).
  static const String _boxName = 'app_settings';
  static String seenKey(String coupleId) => 'love_tree_seen_$coupleId';

  /// Days the couple has been together (date-only, clamped ≥0). Mirrors the
  /// counter's `inDays` semantics.
  static int daysTogether(DateTime anniversary) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start =
        DateTime(anniversary.year, anniversary.month, anniversary.day);
    final diff = today.difference(start).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Builds the FULL milestone list (reached + not), each with its stable
  /// [LoveTreeMilestone.index]. Order is days → streak → photos, ascending —
  /// this fixed order is what keeps flower positions deterministic.
  static List<LoveTreeMilestone> buildMilestones({
    required int days,
    required int longestStreak,
    required int photoCount,
  }) {
    final list = <LoveTreeMilestone>[];
    var i = 0;
    void add(FlowerKind kind, List<int> thresholds, int progress) {
      for (final v in thresholds) {
        list.add(LoveTreeMilestone(
          kind: kind,
          value: v,
          index: i++,
          reached: progress >= v,
        ));
      }
    }

    add(FlowerKind.days, dayMilestones, days);
    add(FlowerKind.streak, streakMilestones, longestStreak);
    add(FlowerKind.photos, photoMilestones, photoCount);
    return list;
  }

  /// Number of milestones crossed across all three sources = number of flowers.
  static int flowerCount({
    required int days,
    required int longestStreak,
    required int photoCount,
  }) {
    return buildMilestones(
      days: days,
      longestStreak: longestStreak,
      photoCount: photoCount,
    ).where((m) => m.reached).length;
  }

  /// Stage from flower count (PO thresholds): 0→seed, 1-2→sprout, 3-5→young,
  /// 6-9→green, 10+→bloom.
  static LoveTreeStage stageForFlowers(int flowers) {
    if (flowers <= 0) return LoveTreeStage.seed;
    if (flowers <= 2) return LoveTreeStage.sprout;
    if (flowers <= 5) return LoveTreeStage.young;
    if (flowers <= 9) return LoveTreeStage.green;
    return LoveTreeStage.bloom;
  }

  /// Reads the per-couple last-seen flower count (0 when absent/unparsable).
  /// Synchronous — the box is opened at startup; falls back to 0 on any error.
  static int readLastSeen(String coupleId) {
    try {
      final box = Hive.box<String>(_boxName);
      return int.tryParse(box.get(seenKey(coupleId)) ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Persists [flowers] as the last-seen count for [coupleId] (best-effort).
  static Future<void> writeLastSeen(String coupleId, int flowers) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(seenKey(coupleId), '$flowers');
    } catch (_) {
      // Best-effort — the in-session state already drove the bloom animation.
    }
  }

  // ── Per-kind visual tokens (design §3.2 / §8) ──────────────────────────────

  /// The nucleus icon for a flower kind. Heart uses Material's filled
  /// `IconsaxPlusBold.heart` (Lucide has no filled heart — app convention).
  static IconData nucleusIcon(FlowerKind kind) {
    switch (kind) {
      case FlowerKind.days:
        return IconsaxPlusBold.heart;
      case FlowerKind.streak:
        return IconsaxPlusLinear.flash;
      case FlowerKind.photos:
        return IconsaxPlusLinear.gallery;
    }
  }

  /// The nucleus disc fill colour (the secondary gradient stop is only used by
  /// the streak kind; others paint flat with [nucleusColor]).
  static Color nucleusColor(FlowerKind kind) {
    switch (kind) {
      case FlowerKind.days:
        return AppColors.accentLove; // #FF4D6D
      case FlowerKind.streak:
        return AppColors.accentLoveDeep; // gradient end #E63956
      case FlowerKind.photos:
        return AppColors.accentLavender; // #A78BFA
    }
  }

  /// Petal edge colour per kind (radial gradient runs from a soft pink centre
  /// out to this edge → each kind reads as a slightly different hue).
  static Color petalEdge(FlowerKind kind) {
    switch (kind) {
      case FlowerKind.days:
        return AppColors.sunset2; // #FF8FA3 coral
      case FlowerKind.streak:
        return AppColors.sunset3; // #FFB6C1
      case FlowerKind.photos:
        return AppColors.dawn3; // #C8A8E9 lavender-light
    }
  }
}
