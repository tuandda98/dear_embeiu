import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft fade under the status bar for edge-to-edge scrolling screens
/// (2026-10-13): content slides under the clock/battery, and this keeps the
/// status-bar text readable. Pointer-transparent; place it in a Stack over the
/// scroll view. [color] = the screen's top background (dawnBlush starts at
/// dawn1).
class StatusBarScrim extends StatelessWidget {
  const StatusBarScrim({super.key, this.color = AppColors.dawn1});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    if (top <= 0) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: top + 12,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
