import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// "Journey trail" (Profile redesign 2026-06-14, Concept B) — a horizontal
/// stepper of the couple's curated love-milestones. Passed stations are filled
/// rose with a check; the next one pulses-free as a rose ring with a "N days to
/// go" caption + a thin progress bar; far stations sit dim. Replaces the old
/// 4-stat grid (which showed the SAME day-count in four units).
///
/// Self-contained: give it [totalDays] and it derives everything (the
/// signature day number itself lives on the hero card, so it isn't repeated).
class MilestoneTrail extends StatelessWidget {
  const MilestoneTrail({super.key, required this.totalDays});

  final int totalDays;

  /// Curated, emotionally-meaningful milestones (ascending). 520 ≈ "anh yêu
  /// em", 1314 ≈ "yêu trọn đời"; the rest are round/anniversary marks.
  static const List<int> _stations = [100, 365, 520, 1000, 1314, 1825, 3650];

  /// Short label under a dot: anniversaries read as "N năm", the rest as the
  /// raw day count.
  String _label(int days, AppLocalizations l10n) {
    if (days % 365 == 0) {
      final years = days ~/ 365;
      return years == 1
          ? l10n.milestoneYearsOne(years)
          : l10n.milestoneYearsMany(years);
    }
    return '$days';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Index of the first not-yet-reached station (the "next" goal). -1 when
    // every curated milestone is already behind them.
    final nextIndex = _stations.indexWhere((d) => d > totalDays);
    final allDone = nextIndex < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _stations.length; i++) ...[
                if (i > 0)
                  _Connector(
                    // The connector leading INTO station i is "lit" once the
                    // PREVIOUS station is reached.
                    active: totalDays >= _stations[i - 1],
                  ),
                _Station(
                  label: _label(_stations[i], l10n),
                  reached: totalDays >= _stations[i],
                  isNext: !allDone && i == nextIndex,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (allDone)
          _AllDoneCaption(l10n: l10n)
        else
          _NextCaption(
            daysLeft: _stations[nextIndex] - totalDays,
            label: _label(_stations[nextIndex], l10n),
            progress: _segmentProgress(nextIndex),
            l10n: l10n,
          ),
      ],
    );
  }

  /// Fraction [0..1] through the current segment (previous reached station →
  /// next station). Drives the thin progress bar.
  double _segmentProgress(int nextIndex) {
    final from = nextIndex == 0 ? 0 : _stations[nextIndex - 1];
    final to = _stations[nextIndex];
    final span = (to - from).clamp(1, 1 << 31);
    return ((totalDays - from) / span).clamp(0.0, 1.0);
  }
}

class _Station extends StatelessWidget {
  const _Station({
    required this.label,
    required this.reached,
    required this.isNext,
  });

  final String label;
  final bool reached;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final Color labelColor;
    if (reached) {
      labelColor = AppColors.accentLoveDeep;
    } else if (isNext) {
      labelColor = AppColors.accentLove;
    } else {
      labelColor = AppColors.textTertiary;
    }

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          _dot(),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: (reached || isNext) ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    if (reached) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.accentLove,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentLove.withValues(alpha: 0.32),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, size: 18, color: AppColors.white),
      );
    }
    if (isNext) {
      // The goal: a hollow rose ring with a flag, so it reads as "you're
      // heading here next".
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accentLove, width: 3),
        ),
        child: const Icon(IconsaxPlusBold.flag, size: 15, color: AppColors.accentLove),
      );
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 34,
      alignment: Alignment.center,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentLove
              : AppColors.textTertiary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _NextCaption extends StatelessWidget {
  const _NextCaption({
    required this.daysLeft,
    required this.label,
    required this.progress,
    required this.l10n,
  });

  final int daysLeft;
  final String label;
  final double progress;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(IconsaxPlusBold.flag, size: 14, color: AppColors.accentLove),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.milestoneTrailNext(daysLeft, label),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.textTertiary.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentLove),
          ),
        ),
      ],
    );
  }
}

class _AllDoneCaption extends StatelessWidget {
  const _AllDoneCaption({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(IconsaxPlusLinear.magic_star, size: 14, color: AppColors.accentLove),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.milestoneTrailAllDone,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
