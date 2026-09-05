import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/eyebrow_chip.dart';

/// O4 — First-launch intro (feature onboarding, 2026-09-05).
///
/// Three swipeable slides shown ONCE, before the guest landing, to a user who
/// has never opened the app: what the app counts, what the two of you do daily,
/// and — the one thing every couple app has to say up front — that it only
/// works when BOTH people install it and pair with an invite code.
///
/// Deliberately self-contained: no Provider, no Firestore, no route of its own.
/// [SessionRouteScreen] renders it in place of the guest push when
/// [hasSeen] is false, and calls [markSeen] via [onDone] before continuing the
/// normal guest flow — so the resolver's routing (force-update gate, auth,
/// couple watchers) is untouched.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onDone});

  /// Called when the user finishes (or skips) the intro. The caller is
  /// responsible for continuing to the guest route.
  final VoidCallback onDone;

  static const String _boxName = 'app_settings';
  static const String _seenKey = 'onboarding_seen_v1';

  /// Whether the intro was already shown on this device. Fail-soft: on any
  /// storage error we report `true`, i.e. we'd rather skip the intro than block
  /// a launch with it.
  static Future<bool> hasSeen() async {
    try {
      // `app_settings` is opened as Box<String> in main() (LocaleProvider) —
      // an untyped Hive.box() on an already-open typed box THROWS, which would
      // make this fail-soft `true` forever and the intro never show.
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box<String>(_boxName)
          : await Hive.openBox<String>(_boxName);
      return box.get(_seenKey) == 'true';
    } catch (_) {
      return true;
    }
  }

  /// Persists the "already seen" flag. Fail-soft (a write error only means the
  /// intro may show again next launch).
  static Future<void> markSeen() async {
    try {
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box<String>(_boxName)
          : await Hive.openBox<String>(_boxName);
      await box.put(_seenKey, 'true');
    } catch (_) {
      // Ignore — never block the launch on a preference write.
    }
  }

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const int _slideCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _slideCount - 1) {
      widget.onDone();
      return;
    }

    if (AppMotion.reduceMotion(context)) {
      _controller.jumpToPage(_index + 1);
    } else {
      _controller.nextPage(
        duration: AppMotion.slow,
        curve: AppMotion.curve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLast = _index == _slideCount - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
        child: SafeArea(
          child: Column(
            children: [
              // Fixed-height top bar so the pages never shift when Skip hides
              // on the last slide.
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: isLast ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: isLast,
                      child: TextButton(
                        onPressed: widget.onDone,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary.withValues(
                            alpha: 0.70,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          l10n.introSkip,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  children: [
                    _IntroSlide(
                      badge: l10n.introSlide1Badge,
                      badgeIcon: IconsaxPlusLinear.calendar_1,
                      title: l10n.introSlide1Title,
                      body: l10n.introSlide1Body,
                      illustration: const _CounterIllustration(),
                    ),
                    _IntroSlide(
                      badge: l10n.introSlide2Badge,
                      badgeIcon: IconsaxPlusLinear.gallery,
                      title: l10n.introSlide2Title,
                      body: l10n.introSlide2Body,
                      illustration: const _MemoriesIllustration(),
                    ),
                    _IntroSlide(
                      badge: l10n.introSlide3Badge,
                      badgeIcon: IconsaxPlusLinear.profile_2user,
                      title: l10n.introSlide3Title,
                      body: l10n.introSlide3Body,
                      illustration: const _TwoPhonesIllustration(),
                      footer: const _StoreChips(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _Dots(count: _slideCount, index: _index),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentLove,
                      foregroundColor: AppColors.white,
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                      ),
                    ),
                    child: Text(isLast ? l10n.introStart : l10n.introNext),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One slide: soft illustration → eyebrow chip → title → body (+ optional
/// footer). Entrance is the shared staggered reveal, which no-ops under
/// Reduce Motion.
class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.badge,
    required this.badgeIcon,
    required this.title,
    required this.body,
    required this.illustration,
    this.footer,
  });

  final String badge;
  final IconData badgeIcon;
  final String title;
  final String body;
  final Widget illustration;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EntranceReveal(order: 0, child: illustration),
          const SizedBox(height: 32),
          EntranceReveal(
            order: 1,
            child: EyebrowChip(label: badge, icon: badgeIcon),
          ),
          const SizedBox(height: 14),
          EntranceReveal(
            order: 2,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.pageTitleStyle(),
            ),
          ),
          const SizedBox(height: 12),
          EntranceReveal(
            order: 3,
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: AppTheme.pageSubtitleStyle(alpha: 0.72),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 20),
            EntranceReveal(order: 4, child: footer!),
          ],
        ],
      ),
    );
  }
}

/// Shared soft halo behind every illustration — two stacked translucent discs
/// so the icons feel embedded in the dawn gradient instead of pasted on it.
class _Halo extends StatelessWidget {
  const _Halo({required this.child, this.size = 176});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.28),
            ),
          ),
          Container(
            width: size * 0.74,
            height: size * 0.74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.55),
              boxShadow: [AppColors.softCardShadow(opacity: 0.18)],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Slide 1 — day counter, milestones, love tree.
class _CounterIllustration extends StatelessWidget {
  const _CounterIllustration();

  @override
  Widget build(BuildContext context) {
    return _Halo(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            IconsaxPlusBold.heart,
            size: 56,
            color: AppColors.accentLove,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _MiniGlyph(icon: IconsaxPlusLinear.medal_star),
              SizedBox(width: 10),
              _MiniGlyph(icon: IconsaxPlusLinear.tree),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slide 2 — shared gallery, daily question, streak, chat.
class _MemoriesIllustration extends StatelessWidget {
  const _MemoriesIllustration();

  @override
  Widget build(BuildContext context) {
    return _Halo(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            IconsaxPlusBold.gallery,
            size: 52,
            color: AppColors.accentLavenderDeep,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _MiniGlyph(icon: IconsaxPlusLinear.message_question),
              SizedBox(width: 10),
              _MiniGlyph(icon: IconsaxPlusLinear.flash_1),
              SizedBox(width: 10),
              _MiniGlyph(icon: IconsaxPlusLinear.messages_2),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slide 3 — "it takes two": two phone frames with a heart bridging them.
class _TwoPhonesIllustration extends StatelessWidget {
  const _TwoPhonesIllustration();

  @override
  Widget build(BuildContext context) {
    return _Halo(
      size: 196,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _PhoneFrame(icon: IconsaxPlusLinear.user),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentLove,
              boxShadow: [AppColors.softCardShadow(opacity: 0.30)],
            ),
            child: const Icon(
              IconsaxPlusBold.heart,
              size: 20,
              color: AppColors.white,
            ),
          ),
          const _PhoneFrame(icon: IconsaxPlusLinear.user),
        ],
      ),
    );
  }
}

/// A small rounded "phone" — pure decoration (no asset), matching the card
/// radius family so it reads as an app screen.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.10),
        ),
        boxShadow: [AppColors.softCardShadow(opacity: 0.16)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textPrimary.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 8),
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.dawn2,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.dawn2.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGlyph extends StatelessWidget {
  const _MiniGlyph({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.85),
      ),
      child: Icon(
        icon,
        size: 15,
        color: AppColors.textPrimary.withValues(alpha: 0.62),
      ),
    );
  }
}

/// Illustrative store chips on the last slide (no links — the partner just
/// needs to know the app exists on both platforms).
class _StoreChips extends StatelessWidget {
  const _StoreChips();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _StoreChip(icon: IconsaxPlusLinear.mobile, label: 'App Store'),
        SizedBox(width: 10),
        _StoreChip(icon: IconsaxPlusLinear.play, label: 'Google Play'),
      ],
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentLoveDeep),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.accentLove
                : AppColors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
