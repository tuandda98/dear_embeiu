import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';

import '../l10n/l10n.dart';
import '../screens/feedback_screen.dart';
import '../services/analytics_service.dart';
import '../services/rating_prompt_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'invite_qr_sheet.dart';

/// Thẻ hỏi 1–5 sao (feature `feedback`, D1). 4–5 sao → hộp đánh giá của store;
/// 1–3 sao → [FeedbackScreen] điền sẵn số sao.
class RatingSheet extends StatefulWidget {
  const RatingSheet({super.key, required this.source});

  /// `settings` · `reveal` · `photo` — chỉ để analytics.
  final String source;

  static const String _appStoreId = '6775165592';

  static Future<void> show(BuildContext context, {required String source}) {
    AnalyticsService.instance.logRatePromptShown(source: source);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: 'RatingSheet'),
      builder: (_) => RatingSheet(source: source),
    );
  }

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int _stars = 0;
  int _pulse = 0;

  void _pick(int n) {
    HapticFeedback.selectionClick();
    setState(() {
      _stars = n;
      _pulse = n;
    });
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _pulse = 0);
    });
  }

  Future<void> _confirm() async {
    if (_stars == 0) return;
    final stars = _stars;
    final navigator = Navigator.of(context);
    final source = widget.source;
    AnalyticsService.instance.logRateStars(stars);
    navigator.pop();
    if (stars <= 3) {
      navigator.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'Feedback'),
          builder: (_) => FeedbackScreen(lowRating: stars, source: source),
        ),
      );
      return;
    }
    await RatingPromptService.markRatedHigh();
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: RatingSheet._appStoreId);
      }
    } catch (_) {
      try {
        await InAppReview.instance.openStoreListing(
          appStoreId: RatingSheet._appStoreId,
        );
      } catch (_) {}
    }
  }

  String _label(int stars) {
    final l = context.l10n;
    switch (stars) {
      case 1:
        return l.rateAppStar1;
      case 2:
        return l.rateAppStar2;
      case 3:
        return l.rateAppStar3;
      case 4:
        return l.rateAppStar4;
      case 5:
        return l.rateAppStar5;
    }
    return '';
  }

  String _cta() {
    final l = context.l10n;
    if (_stars == 0) return l.rateAppCtaDefault;
    if (_stars <= 3) return l.rateAppCtaLow;
    return Platform.isIOS ? l.rateAppCtaIos : l.rateAppCtaAndroid;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduce = AppMotion.reduceMotion(context);
    final fade = reduce
        ? const Duration(milliseconds: 80)
        : const Duration(milliseconds: 200);

    return InviteSheetFrame(
      children: [
        const SizedBox(height: 18),
        Text(
          l10n.rateAppTitle,
          textAlign: TextAlign.center,
          style: AppTheme.displaySerif(size: 20, letterSpacing: 0, height: 1.25),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.rateAppSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          container: true,
          label: l10n.rateAppStarsGroupSemantics,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++) ...[
                if (i > 1) const SizedBox(width: 8),
                _Star(
                  selected: i <= _stars,
                  pulsing: !reduce && _pulse == i,
                  semanticsLabel: l10n.rateAppStarSemantics(i),
                  isChosen: i == _stars,
                  onTap: () => _pick(i),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 20,
          child: Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: fade,
              child: Text(
                _label(_stars),
                key: ValueKey<int>(_stars),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _stars == 0 ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              disabledBackgroundColor: AppColors.textPrimary.withValues(
                alpha: 0.28,
              ),
              foregroundColor: AppColors.white,
              disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: AnimatedSwitcher(
              duration: fade,
              child: Text(
                _cta(),
                key: ValueKey<String>(_cta()),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.rateAppLater,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.selected,
    required this.pulsing,
    required this.semanticsLabel,
    required this.isChosen,
    required this.onTap,
  });

  final bool selected;
  final bool pulsing;
  final String semanticsLabel;
  final bool isChosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isChosen,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedScale(
              scale: pulsing ? 1.18 : 1,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: Icon(
                selected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 36,
                color: selected ? AppColors.accentLove : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
