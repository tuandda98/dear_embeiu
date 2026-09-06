import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Tủ kỷ lục" — a bottom sheet that gathers the couple's notable records in one
/// place (Profile redesign 2026-06-18). Opened by tapping the "Kỷ lục" badge.
///
/// All values are passed in (computed by the achievements grid that already has
/// them) so the sheet stays a pure presenter with no provider wiring.
class RecordsSheet extends StatelessWidget {
  const RecordsSheet._({
    required this.longestStreak,
    required this.daysTogether,
    required this.photoCount,
    required this.journalCount,
    required this.milestonesReached,
    required this.milestonesTotal,
  });

  final int longestStreak;
  final int daysTogether;
  final int photoCount;
  final int journalCount;
  final int milestonesReached;
  final int milestonesTotal;

  static Future<void> show(
    BuildContext context, {
    required int longestStreak,
    required int daysTogether,
    required int photoCount,
    required int journalCount,
    required int milestonesReached,
    required int milestonesTotal,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordsSheet._(
        longestStreak: longestStreak,
        daysTogether: daysTogether,
        photoCount: photoCount,
        journalCount: journalCount,
        milestonesReached: milestonesReached,
        milestonesTotal: milestonesTotal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nf = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );

    final rows = <_RecordRow>[
      _RecordRow(
        icon: IconsaxPlusBold.flash,
        tint: AppColors.accentLove,
        label: l10n.profileRecordLongestStreak,
        value: l10n.daysCountLabel(longestStreak),
      ),
      _RecordRow(
        icon: IconsaxPlusBold.heart,
        tint: AppColors.accentLove,
        label: l10n.profileRecordDaysTogether,
        value: l10n.daysCountLabel(daysTogether),
      ),
      _RecordRow(
        icon: IconsaxPlusBold.gallery,
        tint: AppColors.accentCoral,
        label: l10n.profileRecordTotalMemories,
        value: nf.format(photoCount),
      ),
      _RecordRow(
        icon: IconsaxPlusBold.book_1,
        tint: AppColors.accentLavender,
        label: l10n.profileRecordJournalEntries,
        value: l10n.profileJournalCountLabel(nf.format(journalCount)),
      ),
      _RecordRow(
        icon: IconsaxPlusBold.magic_star,
        tint: AppColors.accentCoral,
        label: l10n.profileRecordStreakMilestones,
        value: '${nf.format(milestonesReached)}/${nf.format(milestonesTotal)}',
      ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentLove.withValues(alpha: 0.12),
                  ),
                  child: const Icon(IconsaxPlusBold.cup,
                      size: 32, color: AppColors.accentLove),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.profileRecordsTitle,
                textAlign: TextAlign.center,
                style: AppTheme.displaySerif(
                  size: 20,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _buildRow(rows[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(_RecordRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: row.tint.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: row.tint.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(row.icon, color: row.tint, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            row.value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow {
  const _RecordRow({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;
}
