import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/photo.dart';
import '../providers/reaction_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'reaction_bar.dart';
import 'shared_photo_view.dart';

/// "Memory cinema" — one large card that slowly plays through the couple's
/// recent photos (Apple-Photos-Memories style), replacing the polaroid strip:
/// crossfade between slides + a slow Ken Burns zoom on each, caption/date on
/// a bottom scrim, position dots, and an optional "on this day" badge slide.
///
/// Auto-advances every [_slideDuration]; a horizontal swipe navigates manually
/// (and restarts the clock), a tap opens the fullscreen preview on the photo
/// currently showing via [onPhotoTap] — auto-play pauses while the preview is
/// up and resumes on return.
class MemoryCinemaCard extends StatefulWidget {
  const MemoryCinemaCard({
    super.key,
    required this.photos,
    required this.onPhotoTap,
    this.onThisDayId,
    this.height = 240,
  });

  /// Slides, in play order. Hero tags are `cinema-photo-{id}` — the caller's
  /// preview must use the same tags for the flight to connect.
  final List<Photo> photos;

  /// Opens the fullscreen preview at the given slide index. Returns when the
  /// preview is dismissed so auto-play can resume.
  final Future<void> Function(int index) onPhotoTap;

  /// Photo id that gets the "on this day" badge (special memory slide).
  final String? onThisDayId;

  final double height;

  @override
  State<MemoryCinemaCard> createState() => _MemoryCinemaCardState();
}

class _MemoryCinemaCardState extends State<MemoryCinemaCard> {
  static const _slideDuration = Duration(seconds: 7);
  static const _crossfade = Duration(milliseconds: 700);

  int _index = 0;
  Timer? _timer;

  /// Whether auto-play may run right now. False while the OS Reduce Motion
  /// setting is on (WCAG 2.3.3 — manual swipe stays available) OR while this
  /// tab is hidden: TickerMode only mutes `.animate` tickers, it does NOT
  /// stop a `Timer.periodic`, so the gate is read here and re-checked in
  /// [didChangeDependencies] (both TickerMode.valuesOf and MediaQuery
  /// register dependencies, so visibility/setting flips re-run it).
  bool _autoPlayAllowed = false;

  // No initState timer: TickerMode/MediaQuery can't be read there —
  // didChangeDependencies runs before the first build and starts auto-play.

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final allowed = TickerMode.valuesOf(context).enabled &&
        !AppMotion.reduceMotion(context);
    // Only touch the timer when the gate actually flips: this method also
    // re-runs for unrelated inherited widgets (e.g. provider watches higher in
    // build), and restarting on each of those would keep resetting the 7s
    // auto-advance window so the slide never moves.
    if (allowed != _autoPlayAllowed || (allowed && _timer == null)) {
      _autoPlayAllowed = allowed;
      _restartTimer();
    }
  }

  @override
  void didUpdateWidget(MemoryCinemaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The feed shifting (new upload, photo deleted) may shrink the list.
    if (_index >= widget.photos.length) {
      _index = 0;
    }
    if (oldWidget.photos.length != widget.photos.length) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (_autoPlayAllowed && widget.photos.length > 1) {
      _timer = Timer.periodic(_slideDuration, (_) => _advance(1));
    }
  }

  void _advance(int delta) {
    if (!mounted || widget.photos.length < 2) {
      return;
    }
    setState(() {
      _index = (_index + delta + widget.photos.length) % widget.photos.length;
    });
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 150) {
      return;
    }
    HapticFeedback.selectionClick();
    _advance(velocity < 0 ? 1 : -1);
    _restartTimer();
  }

  Future<void> _openCurrent() async {
    HapticFeedback.selectionClick();
    // Pause while the preview is up — resuming mid-flight would yank the
    // hero's return target to another slide.
    _timer?.cancel();
    await widget.onPhotoTap(_index);
    if (mounted) {
      _restartTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const SizedBox.shrink();
    }
    final photo = widget.photos[_index.clamp(0, widget.photos.length - 1)];

    return GestureDetector(
      onHorizontalDragEnd: _onSwipe,
      child: Container(
        height: widget.height,
        width: double.infinity,
        // Card-radius 28 — sits inside the standard 16px page gutter like
        // every other Home card (user 2026-06-11, reverting the full-bleed
        // take from 2026-06-10).
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildSlide(photo),
              // Bottom scrim so the caption/date/dots always read, whatever
              // the photo underneath. Pointer-transparent.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x8C000000), // black .55
                        Color(0x00000000),
                      ],
                      stops: [0.0, 0.55],
                    ),
                  ),
                ),
              ),
              // Tap anywhere → fullscreen preview of the showing slide.
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: AppColors.white.withValues(alpha: 0.12),
                    onTap: _openCurrent,
                  ),
                ),
              ),
              if (photo.id == widget.onThisDayId)
                Positioned(top: 14, left: 14, child: _buildOnThisDayBadge(photo)),
              Positioned(
                top: 14,
                right: 14,
                child: ReactionCountBadge(
                  reactions:
                      context.watch<ReactionProvider>().reactionsFor(photo.id),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 14,
                child: IgnorePointer(child: _buildCaptionRow(photo)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Current slide: crossfade between photos, slow Ken Burns zoom on each.
  /// Reduce Motion drops both the Ken Burns zoom and the crossfade — slides
  /// (manual swipes) cut instantly to a static frame.
  Widget _buildSlide(Photo photo) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final decodeWidth = (MediaQuery.of(context).size.width *
            MediaQuery.of(context).devicePixelRatio)
        .round();
    final slide = SizedBox.expand(
      key: ValueKey('cinema-slide-${photo.id}'),
      child: Hero(
        tag: 'cinema-photo-${photo.id}',
        createRectTween: (begin, end) =>
            MaterialRectCenterArcTween(begin: begin, end: end),
        transitionOnUserGestures: true,
        child: _withKenBurns(
          reduceMotion: reduceMotion,
          photo: photo,
          child: SharedPhotoView(
            photo: photo,
            fit: BoxFit.cover,
            decodeWidth: decodeWidth,
            placeholder: Container(color: AppColors.surfaceLight),
          ),
        ),
      ),
    );
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : _crossfade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      // Tight constraints — the default layoutBuilder centers loose children,
      // which lets tall photos letterbox (same fix as the counter backdrop).
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
      child: slide,
    );
  }

  /// Ken Burns: a zoom slightly LONGER than the slide, so motion never
  /// visibly stops before the crossfade. New slide → new switcher key →
  /// fresh one-shot controller. Reduce Motion returns the photo untouched.
  Widget _withKenBurns({
    required bool reduceMotion,
    required Photo photo,
    required Widget child,
  }) {
    if (reduceMotion) {
      return child;
    }
    return child.animate(key: ValueKey('kenburns-${photo.id}')).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.10, 1.10),
          duration: _slideDuration + const Duration(seconds: 2),
          curve: Curves.linear,
        );
  }

  Widget _buildOnThisDayBadge(Photo photo) {
    final yearsAgo = DateTime.now().year - photo.uploadDate.year;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentLoveDeep.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.onThisDayShort(yearsAgo),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCaptionRow(Photo photo) {
    final caption = photo.caption?.trim();
    final date = DateFormat(context.l10n.fullDateFormat).format(photo.uploadDate);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (caption?.isNotEmpty == true) ...[
                Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                date,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildDots(),
      ],
    );
  }

  Widget _buildDots() {
    if (widget.photos.length < 2) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.photos.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: i == _index ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.white
                  .withValues(alpha: i == _index ? 0.95 : 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
