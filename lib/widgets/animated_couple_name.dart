import 'package:flutter/material.dart';

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
    this.textStyle,
    this.heartColor,
    this.heartSize = 18,
    this.spacing = 8,
    this.runSpacing = 4,
    this.alignment = WrapAlignment.start,
  });

  final String person1Name;
  final String person2Name;
  final TextStyle? textStyle;
  final Color? heartColor;
  final double heartSize;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final first = person1Name.trim();
    final second = person2Name.trim();
    final style = textStyle ?? const TextStyle();

    if (first.isEmpty && second.isEmpty) {
      return Text('Hai bạn', style: style);
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

