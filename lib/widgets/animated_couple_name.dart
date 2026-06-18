import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

class AnimatedHeartIcon extends StatefulWidget {
  const AnimatedHeartIcon({
    super.key,
    this.color = AppColors.accentRose,
    this.size = 18,
    this.pulse = false,
  });

  final Color color;
  final double size;

  /// Breathe (scale-pulse) forever vs. sit still. Only HERO lockups opt in
  /// (Home counter, Profile header) where the heart is a single focal point.
  /// Inline name rows (gallery feed, composer, cards) keep it STATIC — a list
  /// of cards must not become a field of throbbing hearts (user 2026-06-18).
  final bool pulse;

  @override
  State<AnimatedHeartIcon> createState() => _AnimatedHeartIconState();
}

class _AnimatedHeartIconState extends State<AnimatedHeartIcon>
    with SingleTickerProviderStateMixin {
  // Null when the heart is static — no controller is created so a feed of
  // many hearts costs no tickers.
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 820),
      )..repeat(reverse: true);
      _controller = c;
      _scaleAnimation = Tween<double>(begin: 0.9, end: 1.16).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = _controller;
    if (c == null) return; // static heart — nothing to pause.
    // Reduce Motion: park the heart at full size instead of pulsing forever.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce && c.isAnimating) {
      c.stop();
      c.value = 1;
    } else if (!reduce && !c.isAnimating) {
      c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optically centre on the text midline: the bold-heart glyph carries its
    // mass slightly high in its square box, so nudge it down a hair (visual
    // only — Transform doesn't change the layout box, keeping Wrap centring
    // stable). Keeps "name ♥ name" reading as one tidy line.
    final heart = Transform.translate(
      offset: Offset(0, widget.size * 0.06),
      child: Icon(
        IconsaxPlusBold.heart,
        size: widget.size,
        color: widget.color,
      ),
    );
    final scale = _scaleAnimation;
    if (scale == null) return heart;
    return ScaleTransition(scale: scale, child: heart);
  }
}

class AnimatedCoupleName extends StatelessWidget {
  const AnimatedCoupleName({
    super.key,
    required this.person1Name,
    required this.person2Name,
    this.creatorUserId,
    this.textStyle,
    this.heartColor,
    this.heartSize = 18,
    this.spacing = 8,
    this.runSpacing = 4,
    this.alignment = WrapAlignment.start,
    this.pulseHeart = false,
  });

  /// person1 is always the couple creator; person2 is the partner who joined.
  final String person1Name;
  final String person2Name;

  /// The couple creator's uid (`couple.createdByUserId`). When provided, the
  /// name belonging to the CURRENT signed-in user is shown first ("me ♥ you"),
  /// regardless of who created the couple. Omit it (e.g. raw/anonymous display)
  /// to keep the fixed person1 ♥ person2 order.
  final String? creatorUserId;
  final TextStyle? textStyle;
  final Color? heartColor;
  final double heartSize;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  /// Forwarded to the heart: only HERO contexts pulse (see [AnimatedHeartIcon.pulse]).
  final bool pulseHeart;

  @override
  Widget build(BuildContext context) {
    // Put the viewer's own name first when we can tell who they are. person1 is
    // the creator; if the signed-in uid is NOT the creator, they're person2, so
    // swap. Falls back to the original order when the creator/viewer is unknown.
    var first = person1Name.trim();
    var second = person2Name.trim();
    final creator = creatorUserId?.trim();
    if (creator != null && creator.isNotEmpty) {
      final myUid = context.read<AuthProvider>().currentUser?.id;
      if (myUid != null && myUid != creator) {
        final tmp = first;
        first = second;
        second = tmp;
      }
    }
    final style = textStyle ?? const TextStyle();

    if (first.isEmpty && second.isEmpty) {
      return Text(context.l10n.youTwoLabel, style: style);
    }

    if (first.isEmpty) {
      return Text(second, style: style);
    }

    if (second.isEmpty) {
      return Text(first, style: style);
    }

    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        Text(first, style: style),
        AnimatedHeartIcon(
          size: heartSize,
          color: heartColor ?? style.color ?? AppColors.accentRose,
          pulse: pulseHeart,
        ),
        Text(second, style: style),
      ],
    );
  }
}

