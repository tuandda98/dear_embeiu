import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/journal_day.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/streak_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_app_bar.dart';
import 'setup_screen.dart';

/// The "Question journal" screen (feature couple-journal, Phần 1).
///
/// Lists revealed daily-question days (both members answered) newest-first on
/// the dawn-blush gradient (design-unify C9 — one background for every
/// screen), each as a solid white day-card with the question and two labelled
/// answer blocks. Loads once + "Show more" paging (no stream).
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final couple = context.read<CoupleProvider>().couple;
    final myUid = context.read<AuthProvider>().currentUser?.id ?? '';

    return ChangeNotifierProvider<JournalProvider>(
      create: (_) => JournalProvider(
        coupleId: couple?.id ?? '',
        myUid: myUid,
      )..load(),
      child: _JournalView(couple: couple),
    );
  }
}

class _JournalView extends StatelessWidget {
  const _JournalView({required this.couple});

  final Couple? couple;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Header vòng 5c (2026-06-11): the bar keeps only the back squircle —
        // the landing-style large header (EyebrowChip + pageTitle + subtitle)
        // lives in the body and scrolls with the content, like Settings.
        appBar: subScreenAppBar(context),
        body: SafeArea(
          top: false,
          child: Consumer<JournalProvider>(
            builder: (context, provider, _) => _buildBody(context, provider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JournalProvider provider) {
    switch (provider.status) {
      case JournalStatus.initial:
      case JournalStatus.loading:
        return const _JournalLoading();
      case JournalStatus.error:
        return _withFixedHeader(_JournalError(onRetry: provider.load));
      case JournalStatus.ready:
        if (provider.isEmpty) {
          return _withFixedHeader(_JournalEmpty(couple: couple));
        }
        return _JournalList(couple: couple, provider: provider);
    }
  }

  /// Centered states (error / empty) keep the large header pinned at the top —
  /// nothing scrolls there, so fixed vs scrolling makes no visual difference.
  Widget _withFixedHeader(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _JournalHeader(),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Landing-style page header (vòng 5c): chip + large title + subtitle, plus
/// the streak summary line that always travelled with the journal header.
class _JournalHeader extends StatelessWidget {
  const _JournalHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EyebrowChip(label: l10n.journalBadge, icon: LucideIcons.bookOpen),
        const SizedBox(height: 14),
        Text(l10n.journalScreenTitle, style: AppTheme.pageTitleStyle()),
        const SizedBox(height: 8),
        Text(l10n.journalHeaderSubtitle, style: AppTheme.pageSubtitleStyle()),
        const SizedBox(height: 20),
        // Streak summary (feature streak) — read-only single line, the only
        // place "longest" is shown. Hidden while waiting for a partner / on
        // error (fail-soft).
        const _JournalStreakSummary(),
      ],
    );
  }
}

// ── List (success) ──────────────────────────────────────────────────────────

class _JournalList extends StatelessWidget {
  const _JournalList({required this.couple, required this.provider});

  final Couple? couple;
  final JournalProvider provider;

  @override
  Widget build(BuildContext context) {
    final days = provider.days;
    // +1 leading slot for the scrolling page header, +1 trailing slot for the
    // "Show more" button (only when more remains).
    final showMore = provider.hasMore;
    final itemCount = 1 + days.length + (showMore ? 1 : 0);

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      itemCount: itemCount,
      separatorBuilder: (_, index) {
        // The header carries its own bottom spacing (vòng 5c).
        if (index == 0) {
          return const SizedBox.shrink();
        }
        // No gap before the "Show more" button (it carries its own top margin).
        if (showMore && index == days.length) {
          return const SizedBox.shrink();
        }
        return const SizedBox(height: 14);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _JournalHeader();
        }
        if (showMore && index == days.length + 1) {
          return _LoadMoreButton(
            isLoading: provider.isLoadingMore,
            onTap: provider.loadMore,
          );
        }

        final dayIndex = index - 1;
        final card = _JournalDayCard(day: days[dayIndex], couple: couple);
        // Staggered entrance for the first six cards only (like the gallery
        // feed); deeper cards revealed by scrolling appear plainly. B9 plays
        // once and honours Reduce Motion.
        if (dayIndex < 6) {
          return EntranceReveal(order: dayIndex, child: card);
        }
        return card;
      },
    );
  }
}

class _JournalDayCard extends StatelessWidget {
  const _JournalDayCard({required this.day, required this.couple});

  final JournalDay day;
  final Couple? couple;

  /// Resolves the partner's display name from the couple. The couple creator is
  /// person1; everyone else maps to person2.
  String _partnerName(AppLocalizations l10n) {
    final c = couple;
    if (c == null) {
      return l10n.posterNameFallback;
    }
    final name = day.partnerUid == c.createdByUserId
        ? c.person1Name
        : c.person2Name;
    return name.trim().isNotEmpty ? name.trim() : l10n.posterNameFallback;
  }

  /// Eyebrow date: full weekday + date, localized (decision D3), uppercased.
  String _dateLabel(BuildContext context) {
    final parsed = day.parsedDate;
    if (parsed == null) {
      return day.date.toUpperCase();
    }
    final langCode = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMMEEEEd(langCode).format(parsed).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final langCode = Localizations.localeOf(context).languageCode;
    final question = day.questionFor(langCode);

    // B4 surface: solid white r24 + the standard black .06 content shadow
    // (design-unify C9 — was r28 with a rose-tinted shadow).
    return ContentCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _dateLabel(context),
                  style: const TextStyle(
                    color: AppColors.accentLove,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('💞', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: AppTheme.displaySerif(
              size: 18,
              weight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.25,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          _AnswerBlock(
            label: l10n.journalYourAnswerLabel,
            text: day.myAnswer,
            background: AppColors.surfaceLight,
            labelColor: AppColors.accentLoveDeep,
          ),
          const SizedBox(height: 10),
          _AnswerBlock(
            label: l10n.journalPartnerAnswerLabel(_partnerName(l10n)),
            text: day.partnerAnswer,
            background: AppColors.accentLavender.withValues(alpha: 0.10),
            labelColor: AppColors.accentLavenderDeep,
          ),
        ],
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({
    required this.label,
    required this.text,
    required this.background,
    required this.labelColor,
  });

  final String label;
  final String text;
  final Color background;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: isLoading
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap();
                  },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.accentLove, width: 1.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.accentLove),
                      ),
                    )
                  else
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.accentLove,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.journalLoadMore,
                    style: const TextStyle(
                      color: AppColors.accentLove,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

// ── Loading ─────────────────────────────────────────────────────────────────

class _JournalLoading extends StatelessWidget {
  const _JournalLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      // +1 leading slot for the page header (vòng 5c).
      itemCount: 4,
      separatorBuilder: (_, index) =>
          index == 0 ? const SizedBox.shrink() : const SizedBox(height: 14),
      itemBuilder: (_, index) => index == 0
          ? const _JournalHeader()
          : Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerSkeleton(width: 120, height: 12, borderRadius: 6),
            SizedBox(height: 14),
            ShimmerSkeleton(height: 18, borderRadius: 8),
            SizedBox(height: 16),
            ShimmerSkeleton(height: 48, borderRadius: 16),
            SizedBox(height: 10),
            ShimmerSkeleton(height: 48, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

// ── Empty ───────────────────────────────────────────────────────────────────

class _JournalEmpty extends StatelessWidget {
  const _JournalEmpty({required this.couple});

  final Couple? couple;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final noPartner = couple?.isWaitingForPartner ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.bookOpen,
                size: 38,
                color: AppColors.accentLove,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.journalEmptyTitle,
              textAlign: TextAlign.center,
              style: AppTheme.displaySerif(
                size: 20,
                weight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              noPartner ? l10n.journalEmptyNoPartnerBody : l10n.journalEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (noPartner) {
                    // Send the user to the setup/invite flow.
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SetupScreen(),
                      ),
                    );
                  } else {
                    // Back to Home so they can answer today's question.
                    Navigator.of(context).maybePop();
                  }
                },
                child: Text(
                  noPartner
                      ? l10n.journalEmptyNoPartnerCta
                      : l10n.journalEmptyCta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Streak summary (header line) ─────────────────────────────────────────────

class _JournalStreakSummary extends StatelessWidget {
  const _JournalStreakSummary();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final streak = context.watch<StreakProvider>();

    // Hidden (no partner) or error → render nothing (fail-soft); the header's
    // own 20px gap already separates it from the content.
    if (!streak.isVisible) {
      return const SizedBox.shrink();
    }

    // Show the numbers once a streak/record exists; otherwise an inviting line.
    final hasNumbers = streak.currentStreak > 0 || streak.longestStreak > 0;
    final text = hasNumbers
        ? l10n.streakJournalSummary(streak.currentStreak, streak.longestStreak)
        : l10n.streakJournalSummaryNone;

    return Padding(
      // Sits inside the (already 20px-padded) page header (vòng 5c).
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(
            LucideIcons.flame,
            size: 14,
            color: hasNumbers ? AppColors.accentRose : AppColors.textTertiary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error ───────────────────────────────────────────────────────────────────

class _JournalError extends StatelessWidget {
  const _JournalError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.cloudOff,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.journalErrorTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onRetry();
              },
              child: Text(
                l10n.journalRetry,
                style: const TextStyle(
                  color: AppColors.accentLove,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
