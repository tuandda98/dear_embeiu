import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/answer_reaction.dart';
import '../providers/answer_reaction_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// The reaction strip shown under one daily-question answer (Home ritual card +
/// Journal).
///
/// Two shapes, chosen by [canReact]:
/// - **partner's answer** (`canReact: true`) — a tappable heart that thaws ❤️,
///   toggles it off on a second tap, and opens the six-emoji picker on
///   long-press. Mirrors the photo [ReactionBar] gesture vocabulary so the two
///   reaction surfaces feel like one thing.
/// - **your own answer** (`canReact: false`) — read-only: shows the partner's
///   reaction if they left one, and renders nothing at all otherwise (an empty
///   affordance on your own answer would just look broken — you cannot react to
///   yourself, by product decision and by rules).
///
/// Renders nothing when the provider isn't streaming (local fallback / guest).
class AnswerReactionRow extends StatefulWidget {
  const AnswerReactionRow({
    super.key,
    required this.date,
    required this.answerAuthorUid,
    required this.myUid,
    this.padding = const EdgeInsets.only(top: 8),
  });

  /// The day this answer belongs to, `YYYY-MM-DD`.
  final String date;

  /// Whose answer this row sits under.
  final String answerAuthorUid;

  final String myUid;
  final EdgeInsetsGeometry padding;

  /// You react to your partner's answer, never your own.
  bool get canReact => answerAuthorUid != myUid;

  @override
  State<AnswerReactionRow> createState() => _AnswerReactionRowState();
}

class _AnswerReactionRowState extends State<AnswerReactionRow> {
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

  AnswerReactionProvider get _provider =>
      context.read<AnswerReactionProvider>();

  Future<void> _onTapHeart() async {
    final provider = _provider;
    final mine = provider.myReaction(widget.date, widget.answerAuthorUid);
    if (mine == kDefaultReactionEmoji) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
    await provider.toggleHeart(widget.date, widget.answerAuthorUid);
  }

  void _onLongPressHeart() {
    HapticFeedback.mediumImpact();
    _showPicker();
  }

  Future<void> _pick(String emoji) async {
    _removePicker();
    HapticFeedback.selectionClick();
    final provider = _provider;
    final mine = provider.myReaction(widget.date, widget.answerAuthorUid);
    if (mine == emoji) {
      await provider.remove(widget.date, widget.answerAuthorUid);
    } else {
      await provider.setReaction(widget.date, widget.answerAuthorUid, emoji);
    }
  }

  void _showPicker() {
    _removePicker();
    final overlay = Overlay.of(context);
    final box = _heartKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.of(context).size;

    // Keep the 6-emoji strip on screen when the answer sits near the right edge.
    const stripWidth = 268.0;
    final left = origin.dx.clamp(12.0, screen.width - stripWidth - 12.0);
    final top = origin.dy - 58;

    final mine = _provider.myReaction(widget.date, widget.answerAuthorUid);

    _pickerEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removePicker,
            ),
          ),
          Positioned(
            left: left,
            top: top < 12 ? origin.dy + 44 : top,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: stripWidth,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentLove.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final emoji in kReactionEmojis)
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => _pick(emoji),
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          curve: AppMotion.curve,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: emoji == mine
                                ? AppColors.accentLove.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_pickerEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<AnswerReactionProvider>();

    if (!provider.isReady) {
      return const SizedBox.shrink();
    }

    final mine = provider.myReaction(widget.date, widget.answerAuthorUid);
    final partner =
        provider.partnerReaction(widget.date, widget.answerAuthorUid);
    final failed = provider.hasError(widget.date, widget.answerAuthorUid);

    if (!widget.canReact) {
      // My own answer: only ever a read-only echo of what my partner left.
      if (partner == null) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: widget.padding,
        child: Row(
          children: [
            _EmojiPill(emoji: partner.emoji, highlighted: true),
          ],
        ),
      );
    }

    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: mine == null
                ? l10n.answerReactionAddTooltip
                : l10n.answerReactionRemoveTooltip,
            child: InkWell(
              key: _heartKey,
              borderRadius: BorderRadius.circular(999),
              onTap: _onTapHeart,
              onLongPress: _onLongPressHeart,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: mine == null
                      ? AppColors.accentLove.withValues(alpha: 0.06)
                      : AppColors.accentLove.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: mine == null
                    ? Icon(
                        IconsaxPlusLinear.heart,
                        size: 18,
                        color: AppColors.accentLove.withValues(alpha: 0.75),
                      )
                    : Text(mine, style: const TextStyle(fontSize: 17)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: failed
                ? Text(
                    l10n.answerReactionErrorRetry,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accentLoveDeep,
                    ),
                  )
                : mine == null
                    ? Text(
                        l10n.answerReactionHint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// A small emoji chip — the partner's reaction echoed on your own answer.
class _EmojiPill extends StatelessWidget {
  const _EmojiPill({required this.emoji, this.highlighted = false});

  final String emoji;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accentLove.withValues(alpha: 0.12)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 17)),
    );
  }
}
