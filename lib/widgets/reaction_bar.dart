import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/photo.dart';
import '../models/photo_reaction.dart';
import '../providers/reaction_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Resolves the display name for a reaction's author from the couple. person1 is
/// the couple creator (`createdByUserId`); the other member is person2. Falls
/// back to the partner-name placeholder when the couple is missing.
String _reactorName(Couple? couple, String authorUserId) {
  if (couple == null) {
    return '';
  }
  if (authorUserId == couple.createdByUserId) {
    return couple.person1Name.trim();
  }
  return couple.person2Name.trim();
}

/// The reaction surface shown under a photo (feed card + fullscreen preview).
///
/// Renders the heart button (3 states), the partner/you chips, and wires the
/// long-press emoji picker. The double-tap-to-react gesture lives on the photo
/// itself (see [HeartBurstOverlay]); this bar handles the tap/long-press paths.
///
/// Set [onDark] for the fullscreen variant (light text on dark panel).
class ReactionBar extends StatefulWidget {
  const ReactionBar({
    super.key,
    required this.photo,
    required this.couple,
    required this.myUid,
    this.onDark = false,
    this.padding = const EdgeInsets.fromLTRB(18, 0, 18, 16),
  });

  final Photo photo;
  final Couple? couple;
  final String myUid;
  final bool onDark;
  final EdgeInsetsGeometry padding;

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  final GlobalKey _heartKey = GlobalKey();
  OverlayEntry? _pickerEntry;

  @override
  void dispose() {
    _removePicker();
    super.dispose();
  }

  void _removePicker() {
    _pickerEntry?.remove();
    _pickerEntry = null;
  }

  Future<void> _onTapHeart() async {
    final provider = context.read<ReactionProvider>();
    final current = provider.myReaction(widget.photo.id, widget.myUid);
    if (current == kDefaultReactionEmoji) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
    await provider.toggleHeart(widget.photo.id);
    _showErrorIfNeeded(provider);
  }

  void _onLongPressHeart() {
    HapticFeedback.mediumImpact();
    _openPicker();
  }

  void _openPicker() {
    _removePicker();
    final box = _heartKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return;
    }

    final heartTopLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final heartSize = box.size;
    final selected =
        context.read<ReactionProvider>().myReaction(widget.photo.id, widget.myUid);

    _pickerEntry = OverlayEntry(
      builder: (overlayContext) {
        return _ReactionPickerPill(
          anchorTopLeft: heartTopLeft,
          anchorSize: heartSize,
          overlaySize: overlay.size,
          selectedEmoji: selected,
          onPick: (emoji) async {
            _removePicker();
            final provider = context.read<ReactionProvider>();
            HapticFeedback.lightImpact();
            await provider.setReaction(widget.photo.id, emoji);
            _showErrorIfNeeded(provider);
          },
          onDismiss: _removePicker,
        );
      },
    );
    Overlay.of(context).insert(_pickerEntry!);
  }

  void _showErrorIfNeeded(ReactionProvider provider) {
    if (!mounted || !provider.hasError(widget.photo.id)) {
      return;
    }
    provider.clearError(widget.photo.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        content: Text(context.l10n.reactionErrorRetry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReactionProvider>();
    final reactions = provider.reactionsFor(widget.photo.id);
    final myEmoji = provider.myReaction(widget.photo.id, widget.myUid);
    final partner = provider.partnerReaction(widget.photo.id, widget.myUid);

    final hintColor = widget.onDark
        ? AppColors.white.withValues(alpha: 0.6)
        : AppColors.textTertiary;

    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          _HeartButton(
            key: _heartKey,
            emoji: myEmoji,
            onDark: widget.onDark,
            onTap: _onTapHeart,
            onLongPress: _onLongPressHeart,
            tooltip: myEmoji == null
                ? context.l10n.reactionAddTooltip
                : context.l10n.reactionRemoveTooltip,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: reactions.isEmpty
                ? Text(
                    context.l10n.reactionHint,
                    style: TextStyle(
                      color: hintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (partner != null)
                        ReactionChip(
                          emoji: partner.emoji,
                          label: _reactorName(widget.couple, partner.authorUserId)
                                  .isNotEmpty
                              ? _reactorName(
                                  widget.couple, partner.authorUserId)
                              : context.l10n.reactionYouLabel,
                          isMine: false,
                          onDark: widget.onDark,
                        ),
                      if (myEmoji != null)
                        ReactionChip(
                          emoji: myEmoji,
                          label: context.l10n.reactionYouLabel,
                          isMine: true,
                          onDark: widget.onDark,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// The circular heart button with three states: outline (no reaction), filled
/// ❤️ (default reaction), or an emoji chip (any other reaction).
class _HeartButton extends StatefulWidget {
  const _HeartButton({
    super.key,
    required this.emoji,
    required this.onDark,
    required this.onTap,
    required this.onLongPress,
    required this.tooltip,
  });

  final String? emoji;
  final bool onDark;
  final Future<void> Function() onTap;
  final VoidCallback onLongPress;
  final String tooltip;

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    // The TweenSequence itself produces the "pop" (1.0→1.25→1.0), so the driving
    // curve must stay within [0,1]. An overshoot curve (e.g. Curves.easeOutBack)
    // feeds t>1.0 into TweenSequence.transform, which asserts `t >= 0.0 &&
    // t <= 1.0` → on a reaction tap it threw during layout and snowballed into a
    // per-frame semantics-error storm. Use the bounded house curve instead.
    _pop = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _popController, curve: AppMotion.curve),
    );
  }

  @override
  void didUpdateWidget(covariant _HeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pop whenever the user's reaction changes to a non-null value.
    if (widget.emoji != oldWidget.emoji && widget.emoji != null) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.emoji;
    final isHeart = emoji == kDefaultReactionEmoji;
    final isOtherEmoji = emoji != null && !isHeart;

    final Color bg;
    if (widget.onDark) {
      bg = AppColors.white.withValues(alpha: 0.14);
    } else if (isOtherEmoji) {
      bg = AppColors.accentRose.withValues(alpha: 0.12);
    } else {
      bg = Colors.transparent;
    }

    Widget content;
    if (isOtherEmoji) {
      content = Text(emoji, style: const TextStyle(fontSize: 20, height: 1));
    } else if (isHeart) {
      content = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentLove.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(IconsaxPlusBold.heart, size: 22, color: AppColors.accentLove),
      );
    } else {
      content = Icon(
        IconsaxPlusLinear.heart,
        size: 22,
        color: widget.onDark
            ? AppColors.white.withValues(alpha: 0.85)
            : AppColors.accentRose.withValues(alpha: 0.85),
      );
    }

    return Tooltip(
      message: widget.tooltip,
      // Long-press is our "open picker" gesture, so don't let the tooltip also
      // pop on long-press (would double up). Tap-and-hold opens the picker; the
      // tooltip stays available for hover/a11y only.
      triggerMode: TooltipTriggerMode.manual,
      child: ScaleTransition(
        scale: _pop,
        child: Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => widget.onTap(),
            onLongPress: widget.onLongPress,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small pill showing who reacted with which emoji (partner or "You").
class ReactionChip extends StatelessWidget {
  const ReactionChip({
    super.key,
    required this.emoji,
    required this.label,
    required this.isMine,
    this.onDark = false,
  });

  final String emoji;
  final String label;
  final bool isMine;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    if (onDark) {
      bg = AppColors.white.withValues(alpha: isMine ? 0.20 : 0.14);
      textColor = AppColors.white.withValues(alpha: isMine ? 1.0 : 0.9);
    } else if (isMine) {
      bg = AppColors.accentLove.withValues(alpha: 0.10);
      textColor = AppColors.accentLoveDeep;
    } else {
      bg = AppColors.surfaceLight;
      textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16, height: 1)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating glass pill of all six emoji, anchored just above the heart button.
class _ReactionPickerPill extends StatefulWidget {
  const _ReactionPickerPill({
    required this.anchorTopLeft,
    required this.anchorSize,
    required this.overlaySize,
    required this.selectedEmoji,
    required this.onPick,
    required this.onDismiss,
  });

  final Offset anchorTopLeft;
  final Size anchorSize;
  final Size overlaySize;
  final String? selectedEmoji;
  final ValueChanged<String> onPick;
  final VoidCallback onDismiss;

  @override
  State<_ReactionPickerPill> createState() => _ReactionPickerPillState();
}

class _ReactionPickerPillState extends State<_ReactionPickerPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  // Pill geometry — keep in sync with the rendered content below.
  static const double _emojiSize = 26;
  static const double _hitTarget = 44;
  static const double _padH = 12;
  static const double _padV = 8;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    )..forward();
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: AppMotion.curve));
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pillWidth =
        kReactionEmojis.length * _hitTarget + (_padH * 2) - (_hitTarget - _emojiSize);
    final pillHeight = _hitTarget + (_padV * 2);

    // Anchor the pill bottom-center to the heart's top-center, clamped on-screen.
    final anchorCenterX = widget.anchorTopLeft.dx + widget.anchorSize.width / 2;
    double left = anchorCenterX - pillWidth / 2;
    left = left.clamp(8.0, math.max(8.0, widget.overlaySize.width - pillWidth - 8));
    final top = widget.anchorTopLeft.dy - pillHeight - 8;

    return Stack(
      children: [
        // Tap-outside scrim to dismiss.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
          ),
        ),
        Positioned(
          left: left,
          top: top < 8 ? widget.anchorTopLeft.dy + widget.anchorSize.height + 8 : top,
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _padH,
                      vertical: _padV,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final emoji in kReactionEmojis)
                          _PickerEmoji(
                            emoji: emoji,
                            isSelected: emoji == widget.selectedEmoji,
                            onTap: () => widget.onPick(emoji),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerEmoji extends StatelessWidget {
  const _PickerEmoji({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: isSelected
            ? BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentRose.withValues(alpha: 0.14),
                border: Border.all(color: AppColors.accentLove, width: 1.4),
              )
            : null,
        child: Text(emoji, style: const TextStyle(fontSize: 26, height: 1)),
      ),
    );
  }
}

/// A one-shot heart-burst played over the photo on double-tap: a large heart
/// pops in and fades out while a handful of small hearts drift upward.
///
/// Wrap the photo in a [Stack] and insert a [HeartBurstOverlay] keyed by a
/// trigger counter; bump the counter to replay. Purely decorative — it ignores
/// pointers so it never blocks the gesture underneath.
class HeartBurstOverlay extends StatefulWidget {
  const HeartBurstOverlay({super.key, required this.trigger});

  /// Increment to fire a new burst. 0 = idle (nothing shown).
  final int trigger;

  @override
  State<HeartBurstOverlay> createState() => _HeartBurstOverlayState();
}

class _HeartBurstOverlayState extends State<HeartBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = <_Particle>[];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.trigger > 0) {
      _fire();
    }
  }

  @override
  void didUpdateWidget(covariant HeartBurstOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _fire();
    }
  }

  void _fire() {
    _particles
      ..clear()
      ..addAll(List.generate(6, (_) {
        return _Particle(
          dx: (_random.nextDouble() - 0.5) * 120,
          rise: 80 + _random.nextDouble() * 70,
          size: 14 + _random.nextDouble() * 8,
          delay: _random.nextDouble() * 0.2,
        );
      }));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          if (t == 0 || t == 1) {
            return const SizedBox.shrink();
          }

          // Big central heart: scale 0 → 1.15 → 1, fade out near the end.
          final bigScale = t < 0.4 ? (t / 0.4) * 1.15 : 1.15 - (t - 0.4) * 0.25;
          final bigOpacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);

          return Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: bigOpacity,
                  child: Transform.scale(
                    scale: bigScale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.white.withValues(alpha: 0.5),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: const Icon(
                        IconsaxPlusBold.heart,
                        size: 88,
                        color: AppColors.accentLove,
                      ),
                    ),
                  ),
                ),
                for (final p in _particles) _buildParticle(p, t),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(_Particle p, double t) {
    final localT = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
    if (localT <= 0) {
      return const SizedBox.shrink();
    }
    final opacity = (1 - localT).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(p.dx * localT, -p.rise * localT),
      child: Opacity(
        opacity: opacity,
        child: Icon(IconsaxPlusBold.heart, size: p.size, color: AppColors.accentLove),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.dx,
    required this.rise,
    required this.size,
    required this.delay,
  });

  final double dx;
  final double rise;
  final double size;
  final double delay;
}

/// Compact read-only reaction badge for the Home "Recent memories" cards.
///
/// Shows the most prominent emoji (❤️ wins, else the partner's) and the count
/// when both members reacted. Hidden entirely when there are no reactions.
/// Read-only by design (D4) — never reacts.
class ReactionCountBadge extends StatelessWidget {
  const ReactionCountBadge({super.key, required this.reactions});

  final List<PhotoReaction> reactions;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Prominent emoji: prefer ❤️, else the first reaction's emoji.
    final heart = reactions.firstWhere(
      (r) => r.emoji == kDefaultReactionEmoji,
      orElse: () => reactions.first,
    );
    final count = reactions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(heart.emoji, style: const TextStyle(fontSize: 12, height: 1)),
          if (count >= 2) ...[
            const SizedBox(width: 3),
            const Text(
              '2',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
