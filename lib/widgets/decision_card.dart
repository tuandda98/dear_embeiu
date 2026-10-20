import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/decision.dart';
import '../providers/decision_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'content_card.dart';
import 'decision_parts.dart';
import 'icon_badge.dart';
import 'ink_tile.dart';
import 'shimmer_skeleton.dart';
import 'today_constellation.dart' show MidnightBuilder;

/// Home card "Phân vân gì không?" (feature decision-wheel, design A): three
/// rows — Ăn gì? · Đi đâu? · Phân vân khác — each showing today's pick or a
/// Spin pill. Shown for active AND waiting couples. Redraws at midnight.
class DecisionCard extends StatelessWidget {
  const DecisionCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Not const: MidnightBuilder's 0:00 setState must rebuild the body so it
    // runs refreshDay() for the new date (a const child would be skipped).
    return MidnightBuilder(builder: (context) => _DecisionCardBody());
  }
}

class _DecisionCardBody extends StatelessWidget {
  const _DecisionCardBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<DecisionProvider>();
    // After midnight (or a long sleep) re-subscribe to the new day.
    WidgetsBinding.instance.addPostFrameCallback((_) => provider.refreshDay());
    final loading = provider.isLoading;
    final customs = provider.todayCustoms;

    return ContentCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
            child: Row(
              children: [
                const IconBadge(
                  IconsaxPlusLinear.shuffle,
                  tint: AppColors.accentRose,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.decisionCardTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => openDecisionHistory(context),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: AppColors.textPrimary,
                    textStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(l10n.decisionHistoryLink),
                ),
              ],
            ),
          ),
          _DecisionRow(
            kind: DecisionKind.eat,
            decision: provider.todayEat,
            loading: loading,
          ),
          const _Hairline(),
          _DecisionRow(
            kind: DecisionKind.go,
            decision: provider.todayGo,
            loading: loading,
          ),
          const _Hairline(),
          _DecisionRow(
            kind: DecisionKind.custom,
            decision: customs.firstOrNull,
            moreCount: customs.length - 1,
            loading: loading,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.only(left: 72, right: 16),
    color: AppColors.surfaceLight,
  );
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({
    required this.kind,
    required this.decision,
    required this.loading,
    this.moreCount = 0,
  });

  final DecisionKind kind;
  final Decision? decision;
  final bool loading;
  final int moreCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = decision;
    final title = switch (kind) {
      DecisionKind.eat => l10n.decisionRowEatTitle,
      DecisionKind.go => l10n.decisionRowGoTitle,
      DecisionKind.custom => l10n.decisionRowCustomTitle,
    };

    final Widget middle;
    final String semantics;
    if (d == null) {
      final subtitle = kind == DecisionKind.custom
          ? l10n.decisionRowCustomEmpty
          : l10n.decisionRowEmpty;
      semantics = '$title. $subtitle';
      middle = Column(
        key: const ValueKey('empty'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          if (loading && kind != DecisionKind.custom)
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: ShimmerSkeleton(width: 120, height: 12, borderRadius: 6),
            )
          else
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      );
    } else {
      final english = decisionIsEnglish(context);
      var meta = decisionMeta(context, d);
      if (d.spins > 1) meta += ' · ${l10n.decisionSpinsBadge(d.spins)}';
      if (kind == DecisionKind.custom && moreCount > 0) {
        meta += ' · ${l10n.decisionCustomMore(moreCount)}';
      }
      final label = switch (kind) {
        DecisionKind.eat => l10n.decisionRowEatLabel,
        DecisionKind.go => l10n.decisionRowGoLabel,
        DecisionKind.custom => d.question,
      };
      final name = decisionDisplayName(
        kind,
        d.result,
        d.resultId,
        english: english,
      );
      semantics = '$title. $name, $meta';
      middle = Column(
        key: ValueKey('${d.id}|${d.result}|${d.spins}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: kind == DecisionKind.custom
                ? const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )
                : const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            decisionLine(d, english: english),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final Widget trailing;
    if (d != null) {
      trailing = const Icon(
        IconsaxPlusLinear.arrow_right_3,
        size: 18,
        color: AppColors.textTertiary,
      );
    } else if (loading && kind != DecisionKind.custom) {
      trailing = const SizedBox.shrink();
    } else {
      final custom = kind == DecisionKind.custom;
      trailing = Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.accentRose.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              custom ? IconsaxPlusLinear.edit_2 : IconsaxPlusLinear.shuffle,
              size: 16,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              custom ? l10n.decisionCustomCta : l10n.decisionSpinCta,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    void onTap() {
      HapticFeedback.selectionClick();
      if (d != null) {
        showDecisionResultSheet(context, d);
      } else {
        // "Nhập & quay" opens without spinning (nothing typed yet, D20).
        openDecisionWheel(
          context,
          kind: kind,
          autoSpin: kind != DecisionKind.custom,
        );
      }
    }

    return Semantics(
      button: true,
      label: semantics,
      hint: d == null ? l10n.decisionRowHintSpin : l10n.decisionRowHintView,
      excludeSemantics: true,
      child: InkTile(
        borderRadius: 16,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: d == null ? 64 : 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                IconBadge(
                  decisionKindIcon(kind),
                  tint: decisionKindTint(kind),
                  size: 40,
                  radius: 14,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.base,
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    ),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previous, ?current],
                    ),
                    child: middle,
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
