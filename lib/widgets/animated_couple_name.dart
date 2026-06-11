import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

class AnimatedHeartIcon extends StatefulWidget {
  const AnimatedHeartIcon({
    super.key,
    this.color = AppColors.accentRose,
    this.size = 18,
  });

  final Color color;
  final double size;

  @override
  State<AnimatedHeartIcon> createState() => _AnimatedHeartIconState();
}

class _AnimatedHeartIconState extends State<AnimatedHeartIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.16).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce Motion: park the heart at full size instead of pulsing forever.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    } else if (!reduce && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        Icons.favorite_rounded,
        size: widget.size,
        color: widget.color,
      ),
    );
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
        ),
        Text(second, style: style),
      ],
    );
  }
}

