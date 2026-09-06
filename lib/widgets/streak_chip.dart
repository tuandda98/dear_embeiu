import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/streak_provider.dart';
import '../screens/love_tree_screen.dart';
import '../services/love_tree_service.dart';
import '../theme/app_colors.dart';
import 'shimmer_skeleton.dart';

/// Maps a [StreakState] + day count to its flame intensity (design §4): icon
/// color + glow alpha grow with the streak length so it "lights up" over time.
/// Shared between [StreakChip] and [StreakSheet] so the two never drift.
class StreakVisuals {
  const StreakVisuals._();

  /// Flame icon color by streak length (design §4).
  static Color flameColor(int streak) {
    if (streak <= 0) {
      return AppColors.textTertiary;
    }
    if (streak < 7) {
      return AppColors.accentCoral;
    }
    if (streak < 30) {
      return AppColors.accentRose;
    }
    return AppColors.accentLoveDeep;
  }

  /// Whether the flame should be filled (any active streak) vs outline (none).
  static bool isFilled(int streak) => streak > 0;
}

/// The streak chip shown inside the CounterCard hero (feature streak). Reads
/// [StreakProvider]; hidden while waiting for a partner or on a read error
/// (fail-soft). Tapping now pushes the [LoveTreeScreen] (feature love-tree, PO
/// 2026-06-14) — the streak sheet's auto-celebration still fires for streak
/// milestones, but the chip itself is the doorway to the Love Tree. While the
/// couple has unseen blooms the chip wears a glow dot + 🌸 to lure them in.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StreakProvider>();

    // Loading the first marker page → shimmer pill placeholder (design table).
    if (provider.isLoading && provider.state == StreakState.hidden) {
      return const ShimmerSkeleton(width: 160, height: 32, borderRadius: 999);
    }

    // Hidden (waiting for partner) or error → render nothing (fail-soft).
    if (!provider.isVisible) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final text = _chipText(provider, l10n);

    // Love Tree entry (feature love-tree): tapping the chip now opens the tree.
    // Show a small glow dot + swap ✨→🌸 while the couple has unseen blooms, to
    // lure the user in. flowerCount derives from the same three monotonic
    // signals the tree uses, via the shared LoveTreeService.
    final hasUnseenBlooms = _hasUnseenBlooms(context, provider);

    final chip = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        splashColor: AppColors.white.withValues(alpha: 0.15),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const LoveTreeScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(hasUnseenBlooms ? '🌸' : '✨',
                      style: const TextStyle(fontSize: 13, height: 1))
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .fade(
                    begin: 0.35,
                    end: 1.0,
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                  )
                  .scale(
                    begin: const Offset(0.78, 0.78),
                    end: const Offset(1.15, 1.15),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );

    if (!hasUnseenBlooms) {
      return chip;
    }

    // Glow dot anchored top-right (Stack overflows the pill slightly — clip off).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        chip,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentLoveDeep,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentLoveDeep.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Whether the couple has crossed more milestones than were last seen on the
  /// Love Tree screen → render the "come look" badge. Cheap & fail-soft: any
  /// missing data (no couple, read error) yields false.
  bool _hasUnseenBlooms(BuildContext context, StreakProvider provider) {
    if (provider.hasError) {
      return false;
    }
    final couple = context.watch<CoupleProvider>().couple;
    if (couple == null || couple.isWaitingForPartner) {
      return false;
    }
    final photo = context.watch<PhotoProvider>();
    final flowers = LoveTreeService.flowerCount(
      days: LoveTreeService.daysTogether(couple.anniversaryDate),
      longestStreak: provider.longestStreak,
      photoCount: photo.photoCount,
    );
    final lastSeen = LoveTreeService.readLastSeen(couple.id);
    return flowers > lastSeen;
  }

  String _chipText(StreakProvider provider, AppLocalizations l10n) {
    switch (provider.state) {
      case StreakState.activeToday:
        return l10n.streakChipActiveToday(provider.currentStreak);
      case StreakState.inProgress:
        return l10n.streakChipInProgress(provider.currentStreak);
      case StreakState.atRisk:
        return l10n.streakChipAtRisk(provider.currentStreak);
      case StreakState.noStreak:
        return provider.everHadStreak
            ? l10n.streakChipRestart
            : l10n.streakChipNoStreak;
      case StreakState.hidden:
        return '';
    }
  }

}
