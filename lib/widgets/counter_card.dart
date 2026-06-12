import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'shared_couple_photo_view.dart';

/// Hero counter card — the emotional centerpiece of the home screen.
///
/// "Aurora glass" redesign (2026-06-10): the heart badge is gone; the card
/// leads with the couple name ([headerExtra]), an eyebrow flanked by hairlines,
/// then the glowing numerals. Depth comes from layered aurora glows (white +
/// lavender + coral, slowly breathing), a glass hairline border and a soft
/// halo behind the numbers — premium/futuristic while staying 100% on the
/// existing Sunset Romance tokens.
class CounterCard extends StatelessWidget {
  final int years;
  final int months;
  final int days;
  final VoidCallback? onTap;
  /// When null, falls back to the localized "you've been together for" label.
  final String? title;
  final String? subtitle;
  final String? footer;

  /// Optional widget rendered (centered) below the footer pill — the streak
  /// chip integration point (feature streak). Null by default so every other
  /// call-site is unaffected.
  final Widget? footerExtra;

  /// Optional full-width block rendered at the very bottom of the card —
  /// the milestone progress integration point (Home v2). Unlike [footerExtra]
  /// it is NOT centered, so progress bars can stretch edge to edge.
  final Widget? progressFooter;

  /// Optional widget rendered at the very top of the card — the couple-name
  /// slot (Home v2: the names moved from the page header into this card).
  /// Null leaves every other call-site unaffected.
  final Widget? headerExtra;

  /// Optional couple photo shown as the card BACKGROUND, dimmed under a
  /// Sunset Romance scrim so the white content keeps its contrast — the
  /// "memory behind the numbers" treatment. Both null → plain gradient card
  /// exactly as before (guest screen, no-photo couples).
  final String? photoLocalPath;
  final String? photoRemoteUrl;

  /// Slide-in side for a background change (+1 = from the right, -1 = from
  /// the left) — set by the swipe gesture that picked the new photo.
  final int photoSwipeDirection;

  /// When provided, the card displays a single hero number (total days)
  /// instead of the years/months/days breakdown.
  final int? totalDays;

  /// When provided (with [totalDays]), a live hh:mm:ss clock ticks below the
  /// hero number — elapsed time since the start of [liveSince]'s day, so it
  /// always agrees with a date-only total-days count.
  final DateTime? liveSince;

  const CounterCard({
    super.key,
    this.years = 0,
    this.months = 0,
    this.days = 0,
    this.totalDays,
    this.liveSince,
    this.onTap,
    this.title,
    this.subtitle,
    this.footer,
    this.footerExtra,
    this.progressFooter,
    this.headerExtra,
    this.photoLocalPath,
    this.photoRemoteUrl,
    this.photoSwipeDirection = 1,
  });

  bool get _hasPhoto =>
      (photoRemoteUrl?.trim().isNotEmpty ?? false) ||
      (photoLocalPath?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Reduce Motion (WCAG 2.3.3): the aurora layers render a static frame —
    // the glow stays (it's part of the surface), only the breathing stops.
    final reduceMotion = AppMotion.reduceMotion(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.sunsetRomance,
          borderRadius: BorderRadius.circular(28),
          // Glass hairline — catches the eye as a thin rim of light.
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.30),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.sunset1.withValues(alpha: 0.36),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
            // Faint lavender bloom pushes the card off the background.
            BoxShadow(
              color: AppColors.accentLavender.withValues(alpha: 0.18),
              blurRadius: 48,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // ── Couple photo behind everything + ADAPTIVE dark scrim: the
              // backdrop measures the photo's average luminance once (cached)
              // and dims bright photos harder, so white text stays readable
              // on any photo while dark photos keep almost no veil.
              if (_hasPhoto)
                Positioned.fill(
                  child: _AdaptivePhotoBackdrop(
                    localPath: photoLocalPath,
                    remoteUrl: photoRemoteUrl,
                    swipeDirection: photoSwipeDirection,
                  ),
                ),
              // ── Aurora layers — slow, offset breathing so the surface
              // feels alive without demanding attention.
              _buildGlow(
                alignment: Alignment.topLeft,
                opacity: 0.42,
                breatheMs: 3200,
                animated: !reduceMotion,
              ),
              _buildGlow(
                alignment: Alignment.bottomRight,
                opacity: 0.30,
                color: AppColors.accentLavender,
                breatheMs: 4000,
                animated: !reduceMotion,
              ),
              _buildGlow(
                alignment: Alignment.topRight,
                opacity: 0.20,
                color: AppColors.accentCoral,
                size: 160,
                breatheMs: 3600,
                animated: !reduceMotion,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (headerExtra != null) ...[
                      Center(child: headerExtra!),
                      const SizedBox(height: 12),
                    ],
                    _buildEyebrow(title ?? l10n.youveBeenTogetherFor),
                    const SizedBox(height: 20),
                    if (totalDays != null) ...[
                      _buildHeroNumber(totalDays!),
                      const SizedBox(height: 6),
                      Text(
                        l10n.daysUnit.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                        ),
                      ),
                      if (liveSince != null) ...[
                        const SizedBox(height: 16),
                        _LiveElapsedClock(since: liveSince!),
                      ],
                    ] else
                      _buildBreakdownRow(context),
                    if (subtitle != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: 18),
                      _buildFooterPill(footer!),
                    ],
                    if (footerExtra != null) ...[
                      const SizedBox(height: 14),
                      Center(child: footerExtra!),
                    ],
                    if (progressFooter != null) ...[
                      const SizedBox(height: 18),
                      progressFooter!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Eyebrow label flanked by thin light hairlines — the luxury-editorial
  /// treatment that replaced the heart badge.
  Widget _buildEyebrow(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHairline(fadeToRight: false),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildHairline(fadeToRight: true),
      ],
    );
  }

  Widget _buildHairline({required bool fadeToRight}) {
    return Container(
      width: 28,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: fadeToRight
              ? [
                  AppColors.white.withValues(alpha: 0.55),
                  AppColors.white.withValues(alpha: 0.0),
                ]
              : [
                  AppColors.white.withValues(alpha: 0.0),
                  AppColors.white.withValues(alpha: 0.55),
                ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(BuildContext context) {
    final l10n = context.l10n;
    final items = <(int, String)>[];
    if (years > 0) items.add((years, l10n.yearsTogether));
    if (months > 0) items.add((months, l10n.monthsRemaining));
    // Always show days (even if 0, or when it's the only non-zero unit)
    if (days > 0 || items.isEmpty) items.add((days, l10n.daysUnit));

    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) widgets.add(_buildDividerDot());
      widgets.add(_buildCounterItem(items[i].$1, items[i].$2));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widgets,
    );
  }

  Widget _buildHeroNumber(int days) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: AppColors.white.withValues(alpha: 0.55),
                blurRadius: 48,
              ),
            ],
          ),
        ),
        Text(
          '$days',
          style: AppTheme.dayCountStyle(),
        ),
      ],
    );
  }

  Widget _buildCounterItem(int value, String label) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTheme.displaySerif(
            size: 58,
            color: AppColors.white,
            weight: FontWeight.w600,
            letterSpacing: -1.2,
            height: 1,
          ).copyWith(
            // Soft halo behind each numeral — the "lit from within" look.
            shadows: [
              Shadow(
                color: AppColors.white.withValues(alpha: 0.45),
                blurRadius: 22,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.82),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }

  /// Small glowing dot between counter units — softer and more modern than
  /// the old full-height divider line.
  Widget _buildDividerDot() {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.55),
        boxShadow: [
          BoxShadow(
            color: AppColors.white.withValues(alpha: 0.45),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_rounded,
            color: AppColors.white,
            size: 14,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One aurora layer: a radial glow that slowly "breathes" (scale + fade on
  /// an offset period per layer, so the motion never reads as a loop).
  /// [animated] = false (OS Reduce Motion) renders the same glow as a static
  /// frame — no repeating controller at all.
  Widget _buildGlow({
    required Alignment alignment,
    required double opacity,
    Color color = AppColors.white,
    double size = 220,
    required int breatheMs,
    bool animated = true,
  }) {
    final glow = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: !animated
              ? glow
              : glow
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.12, 1.12),
                    duration: Duration(milliseconds: breatheMs),
                    curve: Curves.easeInOut,
                  )
                  .fade(
                    begin: 0.85,
                    end: 1.0,
                    duration: Duration(milliseconds: breatheMs),
                    curve: Curves.easeInOut,
                  ),
        ),
      ),
    );
  }
}

/// Live "time together" clock under the hero day count — TOTAL hours :
/// minutes : seconds elapsed since the anniversary (user 2026-06-11: "đếm số
/// giờ bên nhau chứ không phải thời gian thực" — the previous `% 24` made the
/// hours column equal the wall clock, which read as a plain real-time clock).
/// Recomputes from the wall clock every tick (never accumulates drift,
/// survives backgrounding) and anchors to the START of [since]'s day so it
/// always agrees with the date-only total-days number above it. Only this
/// tiny subtree rebuilds each second — the aurora layers and photo backdrop
/// are separate subtrees with constant animate params, so the tick never
/// touches them.
class _LiveElapsedClock extends StatefulWidget {
  const _LiveElapsedClock({required this.since});

  final DateTime since;

  @override
  State<_LiveElapsedClock> createState() => _LiveElapsedClockState();
}

class _LiveElapsedClockState extends State<_LiveElapsedClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Skip ticks while this tab is hidden (TickerMode rule §design-system):
      // Timer.periodic is not muted by TickerMode, so gate it by hand.
      if (mounted && TickerMode.valuesOf(context).enabled) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final start = DateTime(
      widget.since.year,
      widget.since.month,
      widget.since.day,
    );
    var elapsed = DateTime.now().difference(start);
    if (elapsed.isNegative) {
      elapsed = Duration.zero;
    }
    // TOTAL hours together (no % 24) — grows past 24 and keeps counting for
    // the whole relationship; minutes/seconds stay positional.
    final locale = Localizations.localeOf(context).toString();
    final hoursText =
        NumberFormat.decimalPattern(locale).format(elapsed.inHours);
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hours column sizes to its content (can be 5–6 digits, e.g.
          // "17.640"); minutes/seconds keep the fixed 2-digit width.
          _buildSegment(hoursText, l10n.hoursShort, fixedWidth: false),
          _buildSeparator(),
          _buildSegment(minutes.toString().padLeft(2, '0'), l10n.minutesShort),
          _buildSeparator(),
          _buildSegment(seconds.toString().padLeft(2, '0'), l10n.secondsShort),
        ],
      ),
    );
  }

  Widget _buildSegment(String value, String label, {bool fixedWidth = true}) {
    // Fixed width so digits flipping every second never shifts the layout
    // (minutes/seconds); the hours column grows with its digit count and only
    // changes once an hour, so layout shifts there are a non-issue.
    return SizedBox(
      width: fixedWidth ? 40 : null,
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1,
              shadows: [
                Shadow(
                  color: AppColors.white.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.70),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.white.withValues(alpha: 0.60),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

/// Couple photo + luminance-adaptive dark scrim (CounterCard background).
///
/// The photo's average luminance is computed ONCE from a 64px decode and
/// cached statically per photo key, then mapped to scrim strength: dark
/// photos get a whisper of a veil, bright photos (sky/beach/white walls —
/// where white text would drown) get a much deeper one. The scrim animates
/// to its adapted strength when the measurement lands.
class _AdaptivePhotoBackdrop extends StatefulWidget {
  const _AdaptivePhotoBackdrop({
    required this.localPath,
    required this.remoteUrl,
    this.swipeDirection = 1,
  });

  final String? localPath;
  final String? remoteUrl;
  final int swipeDirection;

  @override
  State<_AdaptivePhotoBackdrop> createState() => _AdaptivePhotoBackdropState();
}

class _AdaptivePhotoBackdropState extends State<_AdaptivePhotoBackdrop>
    with SingleTickerProviderStateMixin {
  /// Drives the directional slide between two backgrounds: the new photo
  /// glides in from the swipe side while the old one drifts away and fades.
  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _outgoingLocal = null;
          _outgoingRemote = null;
        });
      }
    });
  late final CurvedAnimation _swapCurve =
      CurvedAnimation(parent: _swap, curve: Curves.easeOutCubic);

  String? _outgoingLocal;
  String? _outgoingRemote;
  int _direction = 1;

  /// Photo stats cache (photo key → (luminance, busyness), both [0..1]);
  /// static so both call-sites and rebuilds reuse the same measurement.
  /// Busyness = mean absolute deviation of luma — a flower field is mid-bright
  /// but extremely noisy, and needs blur + a deeper veil that a plain
  /// average-luminance metric would never ask for.
  static final Map<String, (double, double)> _statsCache = {};

  double? _luminance;
  double? _busyness;
  String? _pendingKey;

  String? get _photoKey => _keyFor(widget.localPath, widget.remoteUrl);

  static String? _keyFor(String? local, String? remote) {
    final r = remote?.trim();
    if (r != null && r.isNotEmpty) {
      return r;
    }
    final l = local?.trim();
    if (l != null && l.isNotEmpty) {
      return l;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _resolveLuminance();
  }

  @override
  void didUpdateWidget(_AdaptivePhotoBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localPath != widget.localPath ||
        oldWidget.remoteUrl != widget.remoteUrl) {
      // Capture the previous photo and play the directional swap.
      _outgoingLocal = oldWidget.localPath;
      _outgoingRemote = oldWidget.remoteUrl;
      _direction = widget.swipeDirection >= 0 ? 1 : -1;
      _swap.forward(from: 0);
      _resolveLuminance();
    }
  }

  @override
  void dispose() {
    _swapCurve.dispose();
    _swap.dispose();
    super.dispose();
  }

  void _resolveLuminance() {
    final key = _photoKey;
    _pendingKey = key;
    if (key == null) {
      _luminance = null;
      _busyness = null;
      return;
    }
    final cached = _statsCache[key];
    if (cached != null) {
      _luminance = cached.$1;
      _busyness = cached.$2;
      return;
    }
    _computeLuminance(key);
  }

  Future<void> _computeLuminance(String key) async {
    try {
      final remote = widget.remoteUrl?.trim();
      final ImageProvider base = (remote != null && remote.isNotEmpty)
          ? CachedNetworkImageProvider(remote)
          : FileImage(File(widget.localPath!.trim()));
      // 64px decode: plenty for an average, costs ~16KB of pixels.
      final image = await _decode(ResizeImage(base, width: 64));
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (data == null) {
        return;
      }
      final bytes = data.buffer.asUint8List();
      final count = bytes.length ~/ 4;
      final lumas = List<double>.filled(count, 0);
      var total = 0.0;
      for (var i = 0; i + 3 < bytes.length; i += 4) {
        // Rec. 601 luma — perceptual brightness, not raw RGB average.
        final luma = (0.299 * bytes[i] +
                0.587 * bytes[i + 1] +
                0.114 * bytes[i + 2]) /
            255.0;
        lumas[i ~/ 4] = luma;
        total += luma;
      }
      final luminance = total / count;
      var deviation = 0.0;
      for (final luma in lumas) {
        deviation += (luma - luminance).abs();
      }
      final busyness = deviation / count;
      _statsCache[key] = (luminance, busyness);
      if (mounted && _pendingKey == key) {
        setState(() {
          _luminance = luminance;
          _busyness = busyness;
        });
      }
    } catch (_) {
      // Fail-soft: the default mid-strength scrim stays.
    }
  }

  Future<ui.Image> _decode(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        completer.completeError(error, stackTrace);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  /// 0 = dark photo, 1 = bright photo. Photos below L≈0.25 need no extra
  /// veil; ≈0.70 (beach/sky) maps to full strength. Unknown → mid default,
  /// matching the previous fixed scrim.
  double get _brightnessT {
    final l = _luminance;
    if (l == null) {
      return 0.30;
    }
    return ((l - 0.25) / 0.45).clamp(0.0, 1.0);
  }

  /// 0 = calm photo (sky, wall), 1 = chaotic texture (a field of flowers).
  /// MAD of luma ≈0.06 reads calm; ≈0.20+ is full chaos.
  double get _busynessT {
    final b = _busyness;
    if (b == null) {
      return 0.0;
    }
    return ((b - 0.06) / 0.14).clamp(0.0, 1.0);
  }

  /// One photo layer with its own frost level (looked up from the stats
  /// cache, so the OUTGOING photo keeps its blur during the swap).
  Widget _photoLayer(String? local, String? remote) {
    final key = _keyFor(local, remote);
    final stats = key == null ? null : _statsCache[key];
    final layerBusy =
        stats == null ? 0.0 : ((stats.$2 - 0.06) / 0.14).clamp(0.0, 1.0);
    final blurSigma = 3.6 * layerBusy;

    Widget photo = SharedCouplePhotoView(
      localPath: local,
      remoteUrl: remote,
      fit: BoxFit.cover,
      decodeWidth: (MediaQuery.of(context).size.width *
              MediaQuery.of(context).devicePixelRatio)
          .round(),
      // Both transparent: while downloading (or stuck/unreachable) and on
      // failure, the gradient base shows instead of a gray shimmer pane.
      placeholder: const SizedBox.shrink(),
      loading: const SizedBox.shrink(),
    );
    if (blurSigma > 0.3) {
      photo = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.mirror,
        ),
        // Slight zoom hides the soft edges blur sampling produces.
        child: Transform.scale(scale: 1 + 0.04 * layerBusy, child: photo),
      );
    }
    return photo;
  }

  @override
  Widget build(BuildContext context) {
    final t = _brightnessT;
    final busy = _busynessT;
    // Busy textures get an extra veil on top of the brightness-driven one…
    final topAlpha = (ui.lerpDouble(0.08, 0.40, t)! + 0.12 * busy).clamp(0.0, 0.55);
    final bottomAlpha =
        (ui.lerpDouble(0.22, 0.55, t)! + 0.12 * busy).clamp(0.0, 0.62);
    final hasOutgoing = _outgoingLocal != null || _outgoingRemote != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Directional swap, stacked like sliding a new print over the old one.
        // The OLD photo stays fully opaque underneath (only a 24px parallax
        // drift) and the NEW one turns opaque within the first 20% before
        // gliding over — so the pink gradient base never peeks through
        // mid-transition (it did when both layers cross-faded).
        if (hasOutgoing)
          AnimatedBuilder(
            animation: _swapCurve,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-_direction * 24.0 * _swapCurve.value, 0),
                child: child,
              );
            },
            child: SizedBox.expand(
              child: _photoLayer(_outgoingLocal, _outgoingRemote),
            ),
          ),
        AnimatedBuilder(
          animation: _swapCurve,
          builder: (context, child) {
            final v = hasOutgoing ? _swapCurve.value : 1.0;
            final slide = 1 - v;
            return Opacity(
              opacity: (v / 0.2).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(_direction * 260.0 * slide, 0),
                child: Transform.scale(scale: 1 + 0.06 * slide, child: child),
              ),
            );
          },
          child: SizedBox.expand(
            key: ValueKey('counter-bg-${_photoKey ?? 'none'}'),
            child: _photoLayer(widget.localPath, widget.remoteUrl),
          ),
        ),
        // Animates to the adapted strength once the measurement lands —
        // heavier at the bottom where the pills/progress sit.
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: topAlpha),
                Colors.black.withValues(alpha: bottomAlpha),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
