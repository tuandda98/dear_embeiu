import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/mood.dart';

/// Animated face for a mood (feature mood — animated icons, 2026-06-19).
///
/// Renders the mood's Noto Animated Emoji Lottie (CC BY 4.0) at [size]. Falls
/// back to the static [MoodOption.emoji] glyph when the asset is missing or
/// fails to load — so an unknown/newer mood key never crashes (mirrors
/// `LoveLottie`'s safety policy).
///
/// Animation is suppressed (static first frame) when [animate] is false or when
/// the OS "reduce motion" accessibility flag is on. Callers animate only the
/// faces that matter (e.g. the picker plays just the selected one) to keep many
/// simultaneous faces light.
class MoodGlyph extends StatelessWidget {
  const MoodGlyph({
    super.key,
    required this.option,
    required this.size,
    this.animate = true,
  });

  final MoodOption option;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final play = animate && !reduceMotion;
    return Lottie.asset(
      option.lottie,
      width: size,
      height: size,
      repeat: play,
      animate: play,
      fit: BoxFit.contain,
      // Missing/broken asset → static emoji, never break the layout.
      errorBuilder: (context, error, stackTrace) => Text(
        option.emoji,
        style: TextStyle(fontSize: size * 0.82, height: 1),
      ),
    );
  }
}
