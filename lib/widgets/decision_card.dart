import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/decision.dart';
import '../providers/decision_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'content_card.dart';
import 'decision_parts.dart';
import 'icon_badge.dart';
import 'ink_tile.dart';
import 'shimmer_skeleton.dart';
import 'today_constellation.dart' show MidnightBuilder;

/// Home card "Phân vân gì không?" (feature decision-wheel; compact layout of
/// Home D, 2026-10-29): today's picks as tinted rows (tap → result sheet), then
/// three equal buttons Ăn gì? · Đi đâu? · Khác. Shown for active AND waiting
/// couples. Redraws at midnight.
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
    final eat = provider.todayEat;
    final go = provider.todayGo;
    final picks = <Widget>[
      if (eat != null) _PickRow(kind: DecisionKind.eat, decision: eat),
      if (go != null) _PickRow(kind: DecisionKind.go, decision: go),
      if (customs.isNotEmpty)
        _PickRow(
          kind: DecisionKind.custom,
          decision: customs.first,
          moreCount: customs.length - 1,
        ),
    ];

    return ContentCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          // Today's picks; a placeholder row while the day is loading.
          if (picks.isEmpty && loading) ...[
            const SizedBox(height: 12),
            const ShimmerSkeleton(height: 64, borderRadius: 16),
          ],
          for (final pick in picks) ...[const SizedBox(height: 12), pick],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SpinButton(
                  kind: DecisionKind.eat,
                  decision: eat,
                  loading: loading,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SpinButton(
                  kind: DecisionKind.go,
                  decision: go,
                  loading: loading,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _SpinButton(kind: DecisionKind.custom, loading: false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of today's picks on a tinted row: label (HÔM NAY ĂN / question) ·
/// result · who and when, chevron → result sheet.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.kind,
    required this.decision,
    this.moreCount = 0,
  });

  final DecisionKind kind;
  final Decision decision;
  final int moreCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = decision;
    final english = decisionIsEnglish(context);
    var meta = decisionMeta(context, d);
    if (d.spins > 1) meta += ' · ${l10n.decisionSpinsBadge(d.spins)}';
    if (kind == DecisionKind.custom && moreCount > 0) {
      meta += ' · ${l10n.decisionCustomMore(moreCount)}';
    }
    final title = switch (kind) {
      DecisionKind.eat => l10n.decisionRowEatTitle,
      DecisionKind.go => l10n.decisionRowGoTitle,
      DecisionKind.custom => l10n.decisionRowCustomTitle,
    };
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
    return Semantics(
      button: true,
      label: '$title. $name, $meta',
      hint: l10n.decisionRowHintView,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkTile(
          borderRadius: 16,
          onTap: () {
            HapticFeedback.selectionClick();
            AnalyticsService.instance.logHomeEntryTap('decide_pick');
            showDecisionResultSheet(context, d);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.base,
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previous, ?current],
                    ),
                    child: Column(
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
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ăn gì? · Đi đâu? · Khác: rose-tint pill, ≥44 tall (grows with large
/// text). Eat/go open today's pick if there is one, else the wheel spinning
/// at once; Khác always opens the wheel to type a new question (D20).
class _SpinButton extends StatelessWidget {
  const _SpinButton({required this.kind, required this.loading, this.decision});

  final DecisionKind kind;
  final Decision? decision;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final custom = kind == DecisionKind.custom;
    final label = switch (kind) {
      DecisionKind.eat => l10n.decisionRowEatTitle,
      DecisionKind.go => l10n.decisionRowGoTitle,
      DecisionKind.custom => l10n.decisionChipCustom,
    };
    final d = decision;
    void onTap() {
      HapticFeedback.selectionClick();
      AnalyticsService.instance.logHomeEntryTap('decide_${kind.name}');
      if (d != null) {
        showDecisionResultSheet(context, d);
      } else {
        // Not while the day is loading: a spin would race today's pick.
        openDecisionWheel(context, kind: kind, autoSpin: !custom && !loading);
      }
    }

    return Semantics(
      button: true,
      label: custom ? l10n.decisionRowCustomTitle : label,
      hint: d == null ? l10n.decisionRowHintSpin : l10n.decisionRowHintView,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accentRose.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: InkTile(
          borderRadius: 999,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    custom ? IconsaxPlusLinear.edit_2 : decisionKindIcon(kind),
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
