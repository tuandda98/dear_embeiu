import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// B1 — Standard full-screen gradient background (design-unify, 2026-06-11).
///
/// Tokens/rules:
/// - EVERY screen sits on [AppColors.dawnBlush] (the gradient Home wraps all
///   three tabs in — `home_screen.dart`). `dreamyMint` is demoted to a
///   decorative accent only; `sunsetRomance` is reserved for the hero
///   CounterCard.
/// - Wrap the screen's `Scaffold` (give it `backgroundColor:
///   Colors.transparent`) so the gradient paints edge-to-edge behind app bars
///   and lists.
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({
    super.key,
    this.gradient = AppColors.dawnBlush,
    required this.child,
  });

  /// Background gradient. Defaults to the app-wide dawnBlush.
  final Gradient gradient;

  /// Usually a transparent [Scaffold].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
