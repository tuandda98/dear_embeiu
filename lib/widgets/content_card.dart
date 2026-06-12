import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// B4 — Solid white content card (design-unify, 2026-06-11).
///
/// Extracted from the TodayRitualCard surface (`today_ritual_card.dart`) —
/// THE reading surface for content-heavy blocks across the app (ritual card,
/// profile/settings section cards, journal/history cards, notification tiles,
/// forms).
///
/// Tokens/rules (A1/A3/A5):
/// - Fill: solid `#FFFFFF` ([AppColors.cardSurface]) — NOT translucent white
///   .72–.94 (that belongs to row tiles, r22) and NOT glass (B11 reserves
///   [GlassCard] for auth/setup/guest forms, the bottom nav and photo
///   overlays).
/// - Radius 24, padding 20, shadow `black .06, blur 16, offset(0,10)` — the
///   single standard for white content cards.
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
