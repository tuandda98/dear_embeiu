import 'package:flutter/animation.dart';

/// Shared motion tokens for the "Sunset Romance" UI revamp.
///
/// Reuse these so animations feel consistent across the app instead of
/// scattering magic-number durations. New animations should pick one of
/// [fast] / [base] / [slow] and use [curve] unless there is a reason not to.
class AppMotion {
  const AppMotion._();

  /// Quick feedback (taps, small toggles).
  static const Duration fast = Duration(milliseconds: 200);

  /// Default for most transitions / reveals.
  static const Duration base = Duration(milliseconds: 280);

  /// Larger, more deliberate movements (sliding pills, page-level reveals).
  static const Duration slow = Duration(milliseconds: 320);

  /// House easing curve for the revamp.
  static const Curve curve = Curves.easeOutCubic;

  /// Staggered entrance reveal (fade + 8px slide-up). Shared so list/section
  /// reveals feel consistent. Each element should add a [stagger] delay
  /// increasing by ~50ms per item.
  static const Duration entrance = Duration(milliseconds: 360);

  /// Per-item delay step for a staggered entrance.
  static const Duration stagger = Duration(milliseconds: 50);
}
