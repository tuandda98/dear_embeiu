import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../app/app_routes.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/counter_card.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/glass_card.dart';
import '../widgets/icon_badge.dart';
import '../widgets/language_toggle_button.dart';

/// Guest "try without signing in" love-day counter (Apple 5.1.1 fix).
///
/// Pure local: reads/writes the anniversary date from a Hive box
/// (`guest_settings`, key `anniversary` storing millisecondsSinceEpoch).
/// No Provider, no Firestore, no Auth — guest never touches the backend.
class GuestCounterScreen extends StatefulWidget {
  const GuestCounterScreen({super.key});

  @override
  State<GuestCounterScreen> createState() => _GuestCounterScreenState();
}

class _GuestCounterScreenState extends State<GuestCounterScreen> {
  static const String _boxName = 'guest_settings';
  static const String _anniversaryKey = 'anniversary';

  DateTime? _anniversaryDate;

  @override
  void initState() {
    super.initState();
    _loadAnniversary();
  }

  Future<void> _loadAnniversary() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    final millis = box.get(_anniversaryKey);
    if (millis is int && mounted) {
      setState(() {
        _anniversaryDate = DateTime.fromMillisecondsSinceEpoch(millis);
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _anniversaryDate ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
      locale: Localizations.localeOf(context),
    );

    if (picked == null || !mounted) {
      return;
    }

    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    await box.put(_anniversaryKey, picked.millisecondsSinceEpoch);

    if (!mounted) {
      return;
    }
    setState(() => _anniversaryDate = picked);
  }

  String _formatDate(DateTime date) {
    return DateFormat(context.l10n.fullDateFormat).format(date);
  }

  int _getTotalDays(DateTime anniversaryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      anniversaryDate.year,
      anniversaryDate.month,
      anniversaryDate.day,
    );
    return today.difference(start).inDays;
  }

  DateTime _getNextAnniversary(DateTime anniversaryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, anniversaryDate.month, anniversaryDate.day);

    if (!next.isAfter(today)) {
      next = DateTime(now.year + 1, anniversaryDate.month, anniversaryDate.day);
    }

    return next;
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
  }

  int _getNextMilestone(int totalDays) {
    const milestones = [
      30,
      50,
      100,
      180,
      365,
      500,
      730,
      1000,
      1500,
      2000,
      3000,
    ];
    for (final milestone in milestones) {
      if (totalDays < milestone) {
        return milestone;
      }
    }
    return ((totalDays ~/ 500) + 1) * 500;
  }

  String _milestoneLabel(int days, AppLocalizations l10n) {
    if (days % 365 == 0) {
      final count = days ~/ 365;
      return count == 1
          ? l10n.milestoneYearsOne(count)
          : l10n.milestoneYearsMany(count);
    }
    if (days < 365 && days % 30 == 0) {
      final count = days ~/ 30;
      return count == 1
          ? l10n.milestoneMonthsOne(count)
          : l10n.milestoneMonthsMany(count);
    }
    return l10n.milestoneDaysLabel(days);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageToggleButton(),
          ),
        ],
      ),
      body: Container(
        // `extendBodyBehindAppBar: true` gives the body loose height
        // constraints, so a shrink-wrapping child (the scroll view) would only
        // be as tall as its content — leaving the gradient short and exposing
        // the black Scaffold background below. Force the gradient to fill the
        // full available height.
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(l10n),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: _anniversaryDate == null
                          ? _buildEmptyCard(l10n)
                          : _buildDateContent(l10n, _anniversaryDate!),
                    ),
                    const SizedBox(height: 20),
                    _buildCtaCard(l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header-sync vòng 5: boxed eyebrow chip, light-surface navy-ink
        // recolor of the original (user request 2026-06-11).
        EyebrowChip(label: l10n.guestModeBadge, icon: LucideIcons.sparkles),
        const SizedBox(height: 14),
        Text(l10n.guestCounterTitle, style: AppTheme.pageTitleStyle()),
        const SizedBox(height: 10),
        Text(
          l10n.guestCounterSubtitle,
          style: AppTheme.pageSubtitleStyle(),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(AppLocalizations l10n) {
    return GlassCard(
      key: const ValueKey('guest-empty'),
      borderRadius: AppTheme.cardRadius,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.22),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.guestEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textOnGradient,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.guestEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _pickDate,
              icon: const Icon(LucideIcons.calendar, size: 18),
              label: Text(l10n.guestPickDate),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateContent(AppLocalizations l10n, DateTime date) {
    final totalDays = _getTotalDays(date);
    final nextAnniversary = _getNextAnniversary(date);
    final daysUntilAnniversary = _daysUntil(nextAnniversary);
    final nextMilestone = _getNextMilestone(totalDays);
    final progressToMilestone = (totalDays / nextMilestone).clamp(0.0, 1.0);

    return Column(
      key: const ValueKey('guest-counter'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CounterCard(
          // Days-only hero + live clock — matches the Home card (2026-06-10).
          totalDays: totalDays,
          liveSince: date,
          subtitle: l10n.guestCounterStartFrom(_formatDate(date)),
          footer: daysUntilAnniversary == 0
              ? l10n.todayIsAnniversary
              : l10n.daysUntilNextAnniversary(daysUntilAnniversary),
        ),
        const SizedBox(height: 20),
        _buildMilestoneSection(
          totalDays: totalDays,
          nextMilestone: nextMilestone,
          progress: progressToMilestone,
          l10n: l10n,
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(LucideIcons.repeat, size: 18),
          label: Text(l10n.guestChangeDate),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentRose,
            side: BorderSide(
              color: AppColors.accentRose.withValues(alpha: 0.45),
              width: 1.2,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneSection({
    required int totalDays,
    required int nextMilestone,
    required double progress,
    required AppLocalizations l10n,
  }) {
    final daysLeft = nextMilestone - totalDays;

    return ContentCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // accentGold on white fails contrast (~1.8:1) — rose tint (C5).
              const IconBadge(LucideIcons.award),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nextMilestonePrefix(
                        _milestoneLabel(nextMilestone, l10n),
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysLeft <= 0
                          ? l10n.milestoneReached
                          : l10n.onlyDaysUntilMilestone(daysLeft),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentRose,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.daysCountLabel(totalDays),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.percentThere((progress * 100).toStringAsFixed(0)),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCtaCard(AppLocalizations l10n) {
    return GlassCard(
      borderRadius: AppTheme.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Dark ink on glass (C5): white 13px text on the blush glass
              // failed contrast (S1) — switch to textPrimary/textSecondary.
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.accentRose,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.guestCtaTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.guestCtaBody,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.login),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentRose,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(l10n.guestCtaSignIn),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.register),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  l10n.guestCtaRegister,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
