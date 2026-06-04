import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/streak_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'streak_chip.dart';

/// Bottom sheet that explains/celebrates the couple streak (feature streak,
/// design §3/§6). Opened by tapping the chip, OR auto-shown in "milestone" mode
/// when a reveal pushes the streak onto a milestone (3/7/30/100/365).
class StreakSheet extends StatelessWidget {
  const StreakSheet._({this.celebrateMilestone});

  /// When non-null, the sheet opens in celebration mode for this milestone
  /// (count-up number + confetti + haptic). Otherwise it's the normal explainer.
  final int? celebrateMilestone;

  /// Opens the normal explainer sheet (tap on chip).
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<StreakProvider>.value(
        value: context.read<StreakProvider>(),
        child: const StreakSheet._(),
      ),
    );
  }

  /// Opens the milestone celebration sheet for [milestone].
  static Future<void> showMilestone(BuildContext context, int milestone) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<StreakProvider>.value(
        value: context.read<StreakProvider>(),
        child: StreakSheet._(celebrateMilestone: milestone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _StreakSheetBody(celebrateMilestone: celebrateMilestone);
  }
}

class _StreakSheetBody extends StatefulWidget {
  const _StreakSheetBody({this.celebrateMilestone});

  final int? celebrateMilestone;

  @override
  State<_StreakSheetBody> createState() => _StreakSheetBodyState();
}

class _StreakSheetBodyState extends State<_StreakSheetBody>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 600));

  // Count-up controller for the milestone celebration number.
  AnimationController? _countUp;
  Animation<double>? _countUpAnim;

  bool get _isMilestone => widget.celebrateMilestone != null;

  @override
  void initState() {
    super.initState();
    if (_isMilestone) {
      final target = widget.celebrateMilestone!;
      // Count up from a few below the milestone to the milestone itself.
      final from = (target - 3).clamp(0, target).toDouble();
      _countUp = AnimationController(
        vsync: this,
        duration: AppMotion.slow, // 320ms
      );
      _countUpAnim = Tween<double>(begin: from, end: target.toDouble()).animate(
        CurvedAnimation(parent: _countUp!, curve: Curves.easeOutCubic),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        HapticFeedback.mediumImpact();
        _confetti.play();
        _countUp!.forward();
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _countUp?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<StreakProvider>();
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    const SizedBox(height: 18),
                    _buildIcon(provider),
                    const SizedBox(height: 12),
                    _buildBigNumber(provider),
                    const SizedBox(height: 6),
                    Text(
                      l10n.streakSheetUnit,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTitleBody(provider, l10n),
                    _buildProgress(provider, l10n),
                    _buildCta(provider, l10n),
                  ],
                ),
              ),
            ),
          ),
          // Sheet-local celebration confetti (only the milestone path plays it).
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 14,
            maxBlastForce: 14,
            minBlastForce: 6,
            emissionFrequency: 0.0,
            gravity: 0.25,
            shouldLoop: false,
            colors: const [
              AppColors.accentRose,
              AppColors.accentLavender,
              AppColors.accentCoral,
              AppColors.white,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(StreakProvider provider) {
    final color = StreakVisuals.flameColor(provider.currentStreak);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        boxShadow: provider.currentStreak > 0
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: Icon(LucideIcons.flame, size: 36, color: color),
    );
  }

  Widget _buildBigNumber(StreakProvider provider) {
    // Milestone mode animates the count-up; otherwise show the current streak.
    if (_isMilestone && _countUpAnim != null) {
      return AnimatedBuilder(
        animation: _countUpAnim!,
        builder: (context, _) => _shadedNumber(_countUpAnim!.value.round()),
      );
    }
    return _shadedNumber(provider.currentStreak);
  }

  /// The large serif number painted with the Sunset Romance gradient.
  Widget _shadedNumber(int value) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.sunsetRomance.createShader(bounds),
      child: Text(
        '$value',
        style: AppTheme.displaySerif(
          size: 56,
          weight: FontWeight.w600,
          color: AppColors.white, // masked by the shader
        ),
      ),
    );
  }

  Widget _buildTitleBody(StreakProvider provider, AppLocalizations l10n) {
    final (String title, String body) = _titleBodyFor(provider, l10n);
    return Column(
      children: [
        Text(
          title,
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
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        // Restart state: surface the record gently as motivation, not blame.
        if (provider.state == StreakState.noStreak &&
            provider.everHadStreak &&
            provider.longestStreak > 0) ...[
          const SizedBox(height: 10),
          Text(
            l10n.streakSheetRecord(provider.longestStreak),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accentLoveDeep,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  (String, String) _titleBodyFor(
    StreakProvider provider,
    AppLocalizations l10n,
  ) {
    // Milestone celebration copy takes precedence (design §9.4).
    final milestone = widget.celebrateMilestone;
    if (milestone != null) {
      switch (milestone) {
        case 3:
          return (l10n.streakMilestone3Title, l10n.streakMilestone3Body);
        case 7:
          return (l10n.streakMilestone7Title, l10n.streakMilestone7Body);
        case 30:
          return (l10n.streakMilestone30Title, l10n.streakMilestone30Body);
        case 100:
          return (l10n.streakMilestone100Title, l10n.streakMilestone100Body);
        case 365:
          return (l10n.streakMilestone365Title, l10n.streakMilestone365Body);
      }
    }

    switch (provider.state) {
      case StreakState.activeToday:
        return (l10n.streakSheetActiveTitle, l10n.streakSheetActiveBody);
      case StreakState.inProgress:
        return (
          l10n.streakSheetInProgressTitle,
          l10n.streakSheetInProgressBody(provider.currentStreak),
        );
      case StreakState.atRisk:
        return (
          l10n.streakSheetAtRiskTitle,
          l10n.streakSheetAtRiskBody(provider.currentStreak),
        );
      case StreakState.noStreak:
        if (provider.everHadStreak) {
          return (
            l10n.streakSheetNoStreakTitle,
            l10n.streakSheetRestartBody,
          );
        }
        return (
          l10n.streakSheetNoStreakTitle,
          l10n.streakSheetNoStreakBody,
        );
      case StreakState.hidden:
        return ('', '');
    }
  }

  /// Progress bar toward the next milestone (design §7). Hidden when there's no
  /// next milestone (past 365) or no streak yet.
  Widget _buildProgress(StreakProvider provider, AppLocalizations l10n) {
    final next = provider.nextMilestone;
    final daysLeft = provider.daysToNextMilestone;
    if (next == null || daysLeft == null || provider.currentStreak <= 0) {
      return const SizedBox(height: 4);
    }
    final progress = (provider.currentStreak / next).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentRose),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.streakNextMilestone(daysLeft, next),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// "Answer now" CTA — only when today still needs answering. Pops the sheet
  /// (v1): the Daily Question card sits right below the hero on Home.
  Widget _buildCta(StreakProvider provider, AppLocalizations l10n) {
    if (!provider.needsActionToday) {
      return const SizedBox.shrink();
    }
    final label = provider.state == StreakState.atRisk
        ? l10n.streakCtaKeepGoing
        : l10n.streakCtaAnswerNow;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).maybePop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label),
              const SizedBox(width: 8),
              const Icon(LucideIcons.arrowRight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
