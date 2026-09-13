import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../l10n/l10n.dart';
import '../models/rps_game.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Localized label for a hand (Búa / Bao / Kéo / Bỏ lượt).
String rpsChoiceLabel(AppLocalizations l10n, RpsChoice choice) {
  switch (choice) {
    case RpsChoice.rock:
      return l10n.rpsChoiceRock;
    case RpsChoice.paper:
      return l10n.rpsChoicePaper;
    case RpsChoice.scissors:
      return l10n.rpsChoiceScissors;
    case RpsChoice.none:
      return l10n.rpsChoiceNone;
  }
}

/// Emoji glyph for a hand as the UI renders it. [RpsChoice.none] shows the
/// hourglass (design §4.3d "⏳ Bỏ lượt") — the model's own `emoji` is the
/// stopwatch, which reads as "timer", not "missed".
String rpsChoiceGlyph(RpsChoice choice) =>
    choice == RpsChoice.none ? '⏳' : choice.emoji;

/// Visual state of one hand button (design.md §5.3).
enum RpsChoiceTileState {
  /// Tappable, white card.
  idle,

  /// The hand I locked in — sunsetRomance fill + check badge.
  selected,

  /// The two hands I didn't pick — faded, not tappable.
  dimmed,

  /// Not `playing` yet / clock ran out — half-faded, no ripple.
  disabled,
}

/// One of the three hand buttons on the game screen (feature rps-game):
/// emoji 44 + label 14 w700 on a white r24 card, ≥96pt tall, with a pressed
/// scale, the selected gradient fill and the dimmed/disabled fades all
/// animated over [AppMotion.base] so a pick feels like a physical lock-in.
///
/// Width is decided by the parent (a `Row` of three `Expanded`s); [compact]
/// shrinks the emoji/height for ≤360pt screens (design: 96×112, emoji 40).
class RpsChoiceTile extends StatefulWidget {
  const RpsChoiceTile({
    super.key,
    required this.choice,
    required this.state,
    required this.onTap,
    this.compact = false,
  });

  final RpsChoice choice;
  final RpsChoiceTileState state;

  /// Called on tap while [state] is [RpsChoiceTileState.idle].
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<RpsChoiceTile> createState() => _RpsChoiceTileState();
}

class _RpsChoiceTileState extends State<RpsChoiceTile> {
  bool _pressed = false;

  bool get _tappable =>
      widget.state == RpsChoiceTileState.idle && widget.onTap != null;

  void _handleTap() {
    if (!_tappable) {
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = rpsChoiceLabel(l10n, widget.choice);
    final selected = widget.state == RpsChoiceTileState.selected;
    final double opacity;
    switch (widget.state) {
      case RpsChoiceTileState.idle:
      case RpsChoiceTileState.selected:
        opacity = 1;
      case RpsChoiceTileState.dimmed:
        opacity = 0.38;
      case RpsChoiceTileState.disabled:
        opacity = 0.5;
    }
    final height = widget.compact ? 112.0 : 120.0;
    final emojiSize = widget.compact ? 40.0 : 44.0;
    final br = BorderRadius.circular(24);

    // Reduce Motion: fills/fades snap instead of tweening (the pressed scale
    // is a 100ms tap echo, harmless either way).
    final duration = AppMotion.reduceMotion(context)
        ? Duration.zero
        : AppMotion.base;

    final card = AnimatedContainer(
      duration: duration,
      curve: AppMotion.curve,
      height: height,
      decoration: BoxDecoration(
        color: selected ? null : AppColors.cardSurface,
        gradient: selected ? AppColors.sunsetRomance : null,
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.accentRose.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: Offset(0, selected ? 8 : 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: br,
                onTap: _tappable ? _handleTap : null,
                onHighlightChanged: (v) {
                  if (_tappable) {
                    setState(() => _pressed = v);
                  }
                },
                splashColor: selected
                    ? AppColors.white.withValues(alpha: 0.12)
                    : AppColors.accentRose.withValues(alpha: 0.08),
                highlightColor: selected
                    ? Colors.transparent
                    : AppColors.accentLove.withValues(alpha: 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.choice.emoji,
                      style: TextStyle(fontSize: emojiSize, height: 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Check badge — top-right, riding just outside the card corner.
          Positioned(
            top: -6,
            right: -6,
            child: AnimatedScale(
              duration: duration,
              curve: AppMotion.curve,
              scale: selected ? 1 : 0,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconsaxPlusBold.tick_circle,
                  size: 18,
                  color: AppColors.accentLoveDeep,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      enabled: _tappable,
      label: l10n.rpsChoiceSemantics(label),
      child: ExcludeSemantics(
        child: IgnorePointer(
          ignoring: !_tappable,
          child: AnimatedOpacity(
            duration: duration,
            curve: AppMotion.curve,
            opacity: opacity,
            child: AnimatedScale(
              duration: _pressed
                  ? const Duration(milliseconds: 100)
                  : AppMotion.fast,
              curve: AppMotion.curve,
              scale: _pressed ? 0.96 : 1,
              child: card,
            ),
          ),
        ),
      ),
    );
  }
}
