import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/photo.dart';
import '../services/love_tree_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Khoảnh khắc này" — the bottom sheet shown when a Love Tree flower is tapped
/// (feature love-tree v2 #1, 2026-06-18). It turns each bloomed flower into a
/// tiny memory map and each not-yet-bloomed milestone into a gentle nudge.
///
/// Tapping a flower (on the tree or in the milestone card) opens this; the
/// caller resolves the per-kind data (the bloom date for `days`, the matching
/// photo + its date for `photos`) and passes it in — this widget only renders.
///
/// Reuses the app's standard sheet shell (ClipRRect r28 + BackdropFilter +
/// cardSurface + grab handle), matching [StreakSheet] / [MemoriesSheet].
class MomentSheet extends StatelessWidget {
  const MomentSheet._({
    required this.kind,
    required this.value,
    required this.locked,
    this.bloomDate,
    this.photo,
    this.photoDate,
    this.remaining,
  });

  final FlowerKind kind;

  /// The milestone threshold (e.g. 100 days, 25 photos, 30-day streak).
  final int value;

  /// `true` for an unreached milestone tapped from the card (LOCKED branch).
  final bool locked;

  /// `days` only — the date the milestone bloomed (`anniversary + value days`).
  final DateTime? bloomDate;

  /// `photos` only — the resolved photo (the `value`-th oldest), or null when it
  /// couldn't be resolved (server count > loaded photos). Null → no thumbnail,
  /// no CTA, no date line.
  final Photo? photo;

  /// `photos` only — the upload date of [photo].
  final DateTime? photoDate;

  /// LOCKED only — how many days/photos/streak-days are still to go (clamped ≥1).
  final int? remaining;

  /// Opens the sheet for a BLOOMED flower.
  static Future<void> showBloomed(
    BuildContext context, {
    required FlowerKind kind,
    required int value,
    DateTime? bloomDate,
    Photo? photo,
    DateTime? photoDate,
  }) {
    HapticFeedback.selectionClick();
    return _present(
      context,
      MomentSheet._(
        kind: kind,
        value: value,
        locked: false,
        bloomDate: bloomDate,
        photo: photo,
        photoDate: photoDate,
      ),
    );
  }

  /// Opens the sheet for a LOCKED (not-yet-bloomed) milestone.
  static Future<void> showLocked(
    BuildContext context, {
    required FlowerKind kind,
    required int value,
    required int remaining,
  }) {
    HapticFeedback.selectionClick();
    return _present(
      context,
      MomentSheet._(
        kind: kind,
        value: value,
        locked: true,
        remaining: remaining,
      ),
    );
  }

  static Future<void> _present(BuildContext context, Widget child) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = LoveTreeService.nucleusColor(kind);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + viewInsets),
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _grabHandle(),
                const SizedBox(height: 20),
                _hero(color),
                const SizedBox(height: 14),
                Text(
                  _title(l10n),
                  textAlign: TextAlign.center,
                  style: AppTheme.displaySerif(
                    size: 20,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                ..._middle(context, l10n),
                const SizedBox(height: 14),
                Text(
                  _copy(l10n),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                ..._cta(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grabHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textTertiary.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );

  /// 72×72 nucleus disc — the flower's nucleus blown up, or a locked padlock.
  Widget _hero(Color color) {
    if (locked) {
      return Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textTertiary.withValues(alpha: 0.10),
          ),
          child: const Icon(IconsaxPlusLinear.lock_1,
              size: 30, color: AppColors.textTertiary),
        ),
      );
    }
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 20),
          ],
        ),
        child: Icon(LoveTreeService.nucleusIcon(kind), size: 34, color: color),
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    switch (kind) {
      case FlowerKind.days:
        return l10n.loveTreeMomentDaysTitle(value);
      case FlowerKind.photos:
        return l10n.loveTreeMomentPhotosTitle(value);
      case FlowerKind.streak:
        return l10n.loveTreeMomentStreakTitle(value);
    }
  }

  String _copy(AppLocalizations l10n) {
    if (locked) {
      // Locked hint sits in the middle slot; the copy line here repeats the
      // bloomed warmth so the sheet never feels like a dead end.
      switch (kind) {
        case FlowerKind.days:
          return l10n.loveTreeMomentDaysCopy;
        case FlowerKind.photos:
          return l10n.loveTreeMomentPhotosCopy;
        case FlowerKind.streak:
          return l10n.loveTreeMomentStreakCopy;
      }
    }
    switch (kind) {
      case FlowerKind.days:
        return l10n.loveTreeMomentDaysCopy;
      case FlowerKind.photos:
        return l10n.loveTreeMomentPhotosCopy;
      case FlowerKind.streak:
        return l10n.loveTreeMomentStreakCopy;
    }
  }

  /// The middle block (date line + photo thumbnail / locked hint).
  List<Widget> _middle(BuildContext context, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final df = DateFormat.yMMMMd(locale);

    if (locked) {
      final n = remaining ?? 1;
      final String hint;
      switch (kind) {
        case FlowerKind.days:
          hint = l10n.loveTreeLockedDays(n);
          break;
        case FlowerKind.photos:
          hint = l10n.loveTreeLockedPhotos(n);
          break;
        case FlowerKind.streak:
          hint = l10n.loveTreeLockedStreak(n);
          break;
      }
      return [
        const SizedBox(height: 4),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ];
    }

    switch (kind) {
      case FlowerKind.days:
        if (bloomDate == null) {
          return const [];
        }
        return [
          const SizedBox(height: 4),
          _dateLine(l10n.loveTreeMomentBloomedOn(df.format(bloomDate!))),
        ];
      case FlowerKind.streak:
        // No date — the encouraging copy line speaks for it.
        return const [];
      case FlowerKind.photos:
        // No resolvable photo → only title + copy (guard against the
        // server-aggregate count exceeding the loaded photos).
        if (photo == null) {
          return const [];
        }
        return [
          if (photoDate != null) ...[
            const SizedBox(height: 4),
            _dateLine(l10n.loveTreeMomentPhotoTakenOn(df.format(photoDate!))),
          ],
          const SizedBox(height: 18),
          _thumbnail(photo!),
        ];
    }
  }

  Widget _dateLine(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _thumbnail(Photo p) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _thumbImage(p),
      ),
    );
  }

  Widget _thumbImage(Photo p) {
    if (p.hasRemoteUrl) {
      return CachedNetworkImage(
        imageUrl: p.remoteUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(color: AppColors.surfaceLight),
        errorWidget: (_, _, _) => _thumbFallback(),
      );
    }
    if (p.hasLocalPath && File(p.path).existsSync()) {
      return Image.file(File(p.path), fit: BoxFit.cover);
    }
    return _thumbFallback();
  }

  Widget _thumbFallback() => Container(
        color: AppColors.surfaceLight,
        alignment: Alignment.center,
        child: const Icon(IconsaxPlusBold.gallery,
            size: 28, color: AppColors.textTertiary),
      );

  /// The optional CTA: "View in Gallery" for bloomed photos, or the locked
  /// nudges (Add a memory / Answer today). days/streak bloomed → no CTA.
  List<Widget> _cta(BuildContext context, AppLocalizations l10n) {
    if (locked) {
      switch (kind) {
        case FlowerKind.days:
          return const []; // days has no destination — let it pass.
        case FlowerKind.photos:
          return _ctaButton(
            context,
            label: l10n.loveTreeLockedPhotosCta,
            onTap: () => _goToCompose(context),
          );
        case FlowerKind.streak:
          return _ctaButton(
            context,
            label: l10n.loveTreeLockedStreakCta,
            onTap: () => _goToDailyQuestion(context),
          );
      }
    }
    // Bloomed: only `photos` WITH a resolved photo gets the gallery CTA.
    if (kind == FlowerKind.photos && photo != null) {
      return _ctaButton(
        context,
        label: l10n.loveTreeMomentViewInGallery,
        icon: IconsaxPlusLinear.arrow_right_3,
        onTap: () => _goToGallery(context, photo!.id),
      );
    }
    return const [];
  }

  List<Widget> _ctaButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return [
      const SizedBox(height: 22),
      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  // ── Navigation bridges (same pattern as _NurtureCard) ──────────────────────
  // The Love Tree is pushed over Home; signal the destination via the router,
  // then close the sheet AND pop the tree so Home applies it. Never push '/home'
  // directly (that bypasses the realtime watchers — CLAUDE.md §2).

  void _goToGallery(BuildContext context, String photoId) {
    NotificationTapRouter.pendingHomeTab.value = 2; // Gallery tab
    NotificationTapRouter.pendingPhotoId.value = photoId;
    _closeToHome(context);
  }

  void _goToCompose(BuildContext context) {
    NotificationTapRouter.pendingHomeTab.value = 2; // Gallery tab
    NotificationTapRouter.pendingCompose.value = true;
    _closeToHome(context);
  }

  void _goToDailyQuestion(BuildContext context) {
    NotificationTapRouter.pendingHomeTab.value = 0; // Home tab
    NotificationTapRouter.pendingHomeFocus.value = 'daily_question';
    _closeToHome(context);
  }

  /// Closes the sheet, then pops the Love Tree screen back to Home so the router
  /// signal is consumed there.
  void _closeToHome(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // close the sheet
    navigator.maybePop(); // pop the Love Tree route → back to Home
  }
}
