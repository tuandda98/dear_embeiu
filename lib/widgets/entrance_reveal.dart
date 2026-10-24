import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_motion.dart';

/// B9 — Shared once-only entrance reveal (design-unify, 2026-06-11).
///
/// Canonical version of the `_OnceEntrance` pattern copied across gallery /
/// settings / milestone / custom-reminders: plays the shared fade + slideY
/// 0.08 entrance ONCE the first time it mounts, then renders its child
/// statically — so rebuilds and scroll-recycling never re-animate.
///
/// Tokens (A8): duration [AppMotion.entrance], curve [AppMotion.curve], delay
/// `stagger * order` (~50ms/item; only stagger the first ~6 list items).
/// Reduce Motion (WCAG 2.3.3): when the OS setting is on the child is
/// returned directly — no choreography at all.
class EntranceReveal extends StatefulWidget {
  const EntranceReveal({super.key, required this.order, required this.child});

  /// Stagger slot (0-based) — each step delays the reveal by
  /// [AppMotion.stagger].
  final int order;
  final Widget child;

  @override
  State<EntranceReveal> createState() => _EntranceRevealState();
}

class _EntranceRevealState extends State<EntranceReveal> {
  bool _played = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      AppMotion.entrance + AppMotion.stagger * widget.order,
      () {
        if (mounted) {
          setState(() => _played = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_played || AppMotion.reduceMotion(context)) {
      return widget.child;
    }
    return widget.child
        .animate()
        .fadeIn(duration: AppMotion.entrance, curve: AppMotion.curve)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppMotion.entrance,
          curve: AppMotion.curve,
          delay: AppMotion.stagger * widget.order,
        );
  }
}
