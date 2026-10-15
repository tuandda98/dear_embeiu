import 'package:flutter/widgets.dart';

import '../../models/sleep_night.dart';
import '../../theme/person_palette.dart';

/// One night drawn as a moon (feature sleep v3 "lịch trăng"): the fuller the
/// moon, the fuller the sleep. The whole disc is always drawn faintly so the
/// eye can tell how far from "full" a night was. [phase] null = no data → a
/// dashed ring.
class MoonGlyph extends StatelessWidget {
  const MoonGlyph({
    super.key,
    required this.size,
    required this.color,
    required this.phase,
    this.onSky = false,
    this.emptyColor = const Color(0x8CFFFFFF),
    this.faintAlpha = 0.16,
  });

  final double size;

  /// The person's colour (from [PersonPalette]).
  final Color color;

  /// 0–4 (see [sleepPhaseFor]); null when the night has no data.
  final int? phase;

  /// On the night-sky calendar: colour lifted toward white + a soft glow.
  final bool onSky;
  final Color emptyColor;
  final double faintAlpha;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MoonPainter(
          fraction: phase == null ? null : kSleepPhaseFractions[phase!],
          color: color,
          onSky: onSky,
          emptyColor: emptyColor,
          faintAlpha: faintAlpha,
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({
    required this.fraction,
    required this.color,
    required this.onSky,
    required this.emptyColor,
    required this.faintAlpha,
  });

  final double? fraction;
  final Color color;
  final bool onSky;
  final Color emptyColor;
  final double faintAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final f = fraction;
    if (f == null) {
      _dashedRing(canvas, center, r - 0.5);
      return;
    }
    final lit = onSky ? PersonPalette.onSky(color) : color;
    final faint = onSky
        ? PersonPalette.onSky(color, 0.22)
        : color.withValues(alpha: faintAlpha);
    final path = _litPath(r, f);
    if (onSky) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawCircle(center, r, Paint()..color = faint);
    canvas.drawPath(path, Paint()..color = lit);
  }

  /// Right half-disc plus (gibbous) or minus (crescent) the terminator
  /// ellipse — the same geometry as the design mockup.
  static Path _litPath(double r, double f) {
    if (f >= 0.999) {
      return Path()..addOval(Rect.fromCircle(center: Offset(r, r), radius: r));
    }
    final rx = (1 - 2 * f).abs() * r;
    return Path()
      ..moveTo(r, 0)
      ..arcToPoint(Offset(r, 2 * r), radius: Radius.circular(r))
      ..arcToPoint(
        Offset(r, 0),
        radius: Radius.elliptical(rx, r),
        clockwise: f > 0.5,
      )
      ..close();
  }

  void _dashedRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = emptyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 2.0;
    final circumference = 2 * 3.141592653589793 * radius;
    final count = (circumference / (dash * 2)).floor().clamp(4, 200);
    final step = 2 * 3.141592653589793 / count;
    final sweep = step / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, i * step, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.onSky != onSky ||
      old.emptyColor != emptyColor ||
      old.faintAlpha != faintAlpha;
}
