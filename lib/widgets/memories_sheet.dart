import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/photo.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Kỷ niệm" — a bottom sheet that previews the couple's shared memories
/// (Profile redesign 2026-06-18): total count, a strip of recent thumbnails,
/// photo milestones, and a CTA into the full gallery. Opened by the "Kỷ niệm"
/// badge instead of jumping straight to the tab, so it matches the other
/// tap-for-detail badges.
class MemoriesSheet extends StatelessWidget {
  const MemoriesSheet._({
    required this.photoCount,
    required this.recentPhotos,
    required this.onViewAll,
  });

  final int photoCount;
  final List<Photo> recentPhotos;
  final VoidCallback onViewAll;

  /// Photo-count milestones celebrated in the strip.
  static const List<int> milestones = [10, 50, 100, 300, 500, 1000];

  static Future<void> show(
    BuildContext context, {
    required int photoCount,
    required List<Photo> recentPhotos,
    required VoidCallback onViewAll,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemoriesSheet._(
        photoCount: photoCount,
        recentPhotos: recentPhotos,
        onViewAll: onViewAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nf = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final nextMilestone =
        milestones.cast<int?>().firstWhere((m) => m! > photoCount, orElse: () => null);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentCoral.withValues(alpha: 0.14),
                  ),
                  child: const Icon(IconsaxPlusBold.gallery,
                      size: 32, color: AppColors.accentCoral),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.profileMemoriesTitle,
                textAlign: TextAlign.center,
                style: AppTheme.displaySerif(
                  size: 20,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.profileMemoriesCountLabel(nf.format(photoCount)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (recentPhotos.isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildThumbStrip(),
              ],
              const SizedBox(height: 18),
              _buildMilestones(context, nf),
              if (nextMilestone != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.profileMemoriesNextLabel(
                    nf.format(nextMilestone - photoCount),
                    nf.format(nextMilestone),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).maybePop();
                    onViewAll();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.seeAll),
                      const SizedBox(width: 8),
                      const Icon(IconsaxPlusLinear.arrow_right_3, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbStrip() {
    final shown = recentPhotos.take(4).toList();
    final extra = photoCount - shown.length;
    return Row(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _thumb(shown[i]),
                    // Show "+N more" over the last tile when there are extras.
                    if (i == shown.length - 1 && extra > 0)
                      Container(
                        color: Colors.black.withValues(alpha: 0.42),
                        alignment: Alignment.center,
                        child: Text(
                          '+$extra',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _thumb(Photo photo) {
    if (photo.hasRemoteUrl) {
      return CachedNetworkImage(
        imageUrl: photo.remoteUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(color: AppColors.surfaceLight),
        errorWidget: (_, _, _) => _thumbFallback(),
      );
    }
    if (photo.hasLocalPath && File(photo.path).existsSync()) {
      return Image.file(File(photo.path), fit: BoxFit.cover);
    }
    return _thumbFallback();
  }

  Widget _thumbFallback() {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: const Icon(IconsaxPlusBold.gallery,
          size: 22, color: AppColors.textTertiary),
    );
  }

  Widget _buildMilestones(BuildContext context, NumberFormat nf) {
    // Show the milestone band around the couple's current count: the highest
    // reached plus the next two upcoming, so the strip always has near-term goals.
    final reachedTop =
        milestones.where((m) => m <= photoCount).fold<int>(0, (a, b) => b);
    final visible = <int>[];
    for (final m in milestones) {
      if (m <= reachedTop || visible.length < 4) {
        visible.add(m);
      }
      if (visible.length >= 4 && m > photoCount) {
        break;
      }
    }
    // Cap to the last 4 so the row never overflows.
    final chips = visible.length > 4 ? visible.sublist(visible.length - 4) : visible;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in chips) _MilestoneChip(value: nf.format(m), reached: m <= photoCount),
      ],
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.value, required this.reached});

  final String value;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final Color bg = reached
        ? AppColors.accentCoral.withValues(alpha: 0.14)
        : AppColors.surfaceLight;
    final Color fg =
        reached ? AppColors.accentLoveDeep : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reached) ...[
            const Icon(IconsaxPlusBold.tick_circle,
                size: 14, color: AppColors.accentLoveDeep),
            const SizedBox(width: 5),
          ],
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
