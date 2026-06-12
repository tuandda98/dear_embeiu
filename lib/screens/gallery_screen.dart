import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/photo.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../services/push_notification_service.dart';
import '../providers/reaction_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/love_lottie.dart';
import '../widgets/reaction_bar.dart';
import '../widgets/shared_couple_photo_view.dart';
import '../widgets/shared_photo_view.dart';
import '../widgets/shimmer_skeleton.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  /// Opens the shared fullscreen photo preview (PageView + Hero) for a list of
  /// [photos]. Reused outside the gallery (e.g. the Home "On this day" card) so
  /// the preview UI lives in one place. [heroTags] must match [photos] length;
  /// pass read-only previews without edit/report callbacks when appropriate.
  static Future<void> openPreview(
    BuildContext context, {
    required List<Photo> photos,
    required List<String> heroTags,
    required int initialIndex,
    Couple? couple,
  }) async {
    if (photos.isEmpty || initialIndex < 0 || initialIndex >= photos.length) {
      return;
    }

    final photo = photos[initialIndex];
    if (!(photo.hasLocalPath && File(photo.path).existsSync()) &&
        !photo.hasRemoteUrl) {
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullscreenPhotoPreview(
          photos: photos,
          heroTags: heroTags,
          initialIndex: initialIndex,
          couple: couple,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const double _floatingTopShowcaseMaxHeight = 340;
  static const double _floatingTopShowcaseMinHeight = 122;

  // Per-photo heart-burst trigger counters; bump to replay the burst on a
  // double-tap (feed card). Keyed by photo id.
  final Map<String, int> _burstTriggers = <String, int>{};

  // Deep-link target: a tapped photo/reaction notification wants this exact
  // photo opened fullscreen. Set from [NotificationTapRouter.pendingPhotoId]
  // (cold-start in initState, warm via listener); consumed in build once the
  // photo list has loaded. Cleared when handled or when the photo is gone.
  String? _pendingDeepLinkPhotoId;

  @override
  void initState() {
    super.initState();
    _pendingDeepLinkPhotoId = NotificationTapRouter.pendingPhotoId.value;
    NotificationTapRouter.consumePhotoRequest();
    NotificationTapRouter.pendingPhotoId.addListener(_onDeepLinkPhotoRequest);
  }

  @override
  void dispose() {
    NotificationTapRouter.pendingPhotoId.removeListener(_onDeepLinkPhotoRequest);
    super.dispose();
  }

  /// Warm deep-link: a tap arrived while the app is running.
  void _onDeepLinkPhotoRequest() {
    final id = NotificationTapRouter.pendingPhotoId.value;
    if (id == null) return;
    NotificationTapRouter.consumePhotoRequest();
    if (!mounted) return;
    setState(() => _pendingDeepLinkPhotoId = id);
  }

  /// Opens the pending deep-link photo once [photos] is available. No-ops if
  /// already handled; silently lands on the grid if the photo was deleted.
  void _openDeepLinkPhoto(String id, List<Photo> photos, Couple? couple) {
    if (_pendingDeepLinkPhotoId != id) return;
    _pendingDeepLinkPhotoId = null;
    final idx = photos.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final heroTags = [for (var i = 0; i < photos.length; i++) 'deeplink-$i'];
    GalleryScreen.openPreview(
      context,
      photos: photos,
      heroTags: heroTags,
      initialIndex: idx,
      couple: couple,
    );
  }

  /// Double-tap on a photo: drop a ❤️ (never a toggle-off — D2/§3) + burst.
  /// No-ops when there's no active Firebase couple (reactions are hidden).
  void _onDoubleTapPhoto(Photo photo) {
    final reactionProvider = context.read<ReactionProvider>();
    final myUid = context.read<AuthProvider>().currentUser?.id;
    if (!reactionProvider.isReady || myUid == null) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _burstTriggers[photo.id] = (_burstTriggers[photo.id] ?? 0) + 1;
    });

    // Double-tap only ever ADDS a heart; if the user already reacted ❤️ keep it.
    if (reactionProvider.myReaction(photo.id, myUid) != '❤️') {
      reactionProvider.setReaction(photo.id, '❤️');
    }
  }


  Future<String?> _showCaptionDialog({
    required String title,
    required String hint,
    String initialValue = '',
  }) async {
    final l10n = context.l10n;
    final captionController = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: captionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, captionController.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndAddPhoto() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      return;
    }
    if (!currentUser.hasCouple) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.galleryNeedsCoupleToUpload)),
        );
      }
      return;
    }

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (pickedFile == null || !mounted) {
      return;
    }

    final l10n = context.l10n;
    final caption = await _showCaptionDialog(
      title: l10n.addCaptionOptionalTitle,
      hint: l10n.addCaptionOptionalHint,
    );

    // null = user pressed Cancel (dismiss dialog) = cancel entire upload
    if (caption == null || !mounted) {
      return;
    }

    try {
      await context.read<PhotoProvider>().addPhoto(
        pickedFile.path,
        currentUser: currentUser,
        caption: caption.isNotEmpty ? caption : null,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PhotoProvider>().errorMessage ?? context.l10n.photoAddError,
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.photoAddedSuccess)),
    );
  }

  Future<void> _pickMultiplePhotos() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      return;
    }
    if (!currentUser.hasCouple) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.galleryNeedsCoupleToUpload)),
        );
      }
      return;
    }

    final pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (pickedFiles.isEmpty || !mounted) {
      return;
    }

    final l10n = context.l10n;
    final total = pickedFiles.length;

    // Single overlay across the whole batch (no per-photo flicker); one failed
    // upload is skipped and counted, never aborts the rest.
    final successCount = await context.read<PhotoProvider>().addPhotosBatch(
          pickedFiles.map((f) => f.path).toList(),
          currentUser: currentUser,
          progress: (current, totalCount) =>
              l10n.uploadingPhotoProgress(current, totalCount),
        );

    if (!mounted) {
      return;
    }

    HapticFeedback.mediumImpact();
    final failed = total - successCount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? l10n.multiplePhotosAdded(successCount)
              : l10n.multiPhotosResultPartial(successCount, total, failed),
        ),
      ),
    );
  }

  Future<void> _editCaption(Photo photo) async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      return;
    }

    final l10n = context.l10n;
    final caption = await _showCaptionDialog(
      title: l10n.editCaptionTitle,
      hint: l10n.editCaptionHint,
      initialValue: photo.caption ?? '',
    );

    if (caption == null || !mounted) {
      return;
    }

    try {
      await context.read<PhotoProvider>().updatePhotoCaption(
        photo.id,
        caption,
        currentUser: currentUser,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PhotoProvider>().errorMessage ?? context.l10n.captionUpdateError,
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.captionUpdatedSuccess)),
    );
  }

  Future<void> _deletePhoto(Photo photo) async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      return;
    }

    final l10n = context.l10n;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePhotoTitle),
        content: Text(l10n.deletePhotoContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.keepPhotoBtn),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.deletePhotoBtn,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await context.read<PhotoProvider>().deletePhoto(
        photo.id,
        currentUser: currentUser,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PhotoProvider>().errorMessage ?? context.l10n.photoDeleteError,
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.photoDeletedSuccess)),
    );
  }

  // Opens the report bottom-sheet (Apple Guideline 1.2 UGC). Tapping a reason
  // submits immediately; cancel/dismiss writes nothing. Reporting is
  // best-effort and always shows an optimistic confirmation (no error state).
  Future<void> _reportPhoto(Photo photo) async {
    final reason = await _showReportReasonSheet();
    if (reason == null || !mounted) {
      return;
    }

    final reporterUid = context.read<AuthProvider>().currentUser?.id ?? '';
    await context.read<PhotoProvider>().reportPhoto(
          photo: photo,
          reporterUid: reporterUid,
          reason: reason,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.reportSentConfirm)),
    );
  }

  // Returns a stable reason code (`inappropriate` / `spam` / `other`) or null
  // if the user cancelled. The localized labels are display-only.
  Future<String?> _showReportReasonSheet() {
    final l10n = context.l10n;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardSurface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  l10n.reportPhotoTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.reportPhotoSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                _buildReportReasonTile(
                  sheetContext,
                  label: l10n.reportReasonInappropriate,
                  code: 'inappropriate',
                ),
                const SizedBox(height: 10),
                _buildReportReasonTile(
                  sheetContext,
                  label: l10n.reportReasonSpam,
                  code: 'spam',
                ),
                const SizedBox(height: 10),
                _buildReportReasonTile(
                  sheetContext,
                  label: l10n.reportReasonOther,
                  code: 'other',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(
                      l10n.reportCancel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportReasonTile(
    BuildContext sheetContext, {
    required String label,
    required String code,
  }) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(sheetContext).pop(code),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFeedDate(DateTime date) {
    final l10n = context.l10n;
    return DateFormat(
      l10n.feedDateFormat,
      Localizations.localeOf(context).languageCode,
    ).format(date);
  }

  String _feedPostedByLabel(Photo photo) {
    return context.l10n.postedByLabel(photo.posterName);
  }

  List<Photo> _photosUploadedToday(List<Photo> photos) {
    final now = DateTime.now();
    return photos
        .where(
          (p) =>
              p.uploadDate.year == now.year &&
              p.uploadDate.month == now.month &&
              p.uploadDate.day == now.day,
        )
        .toList();
  }

  String _feedHeroTag(Photo photo, int index) {
    return 'feed-photo-${photo.id}-$index';
  }

  Future<void> _openPhotoPreview(
    List<Photo> photos, {
    required int initialIndex,
    Couple? couple,
    required List<String> heroTags,
  }) async {
    if (!mounted || photos.isEmpty || initialIndex < 0 || initialIndex >= photos.length) {
      return;
    }

    final photo = photos[initialIndex];
    if (!(photo.hasLocalPath && File(photo.path).existsSync()) && !photo.hasRemoteUrl) {
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) => _FullscreenPhotoPreview(
          photos: photos,
          heroTags: heroTags,
          initialIndex: initialIndex,
          couple: couple,
          onEditCaption: _editCaption,
          onReport: _reportPhoto,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  String _initialsFromCouple(Couple? couple) {
    if (couple == null) {
      return '♥';
    }

    final first = couple.person1Name.trim().isNotEmpty
        ? couple.person1Name.trim().characters.first.toUpperCase()
        : 'A';
    final second = couple.person2Name.trim().isNotEmpty
        ? couple.person2Name.trim().characters.first.toUpperCase()
        : 'B';
    return '$first$second';
  }

  Widget _buildCoupleAvatar(Couple? couple, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.9), width: 2),
      ),
      child: ClipOval(
        child: SharedCouplePhotoView(
          localPath: couple?.couplePhotoPath,
          remoteUrl: couple?.couplePhotoUrl,
          fit: BoxFit.cover,
          // Avatar-sized slot → decode at the circle's physical size, not full-res.
          decodeWidth:
              (size * MediaQuery.of(context).devicePixelRatio).round(),
          placeholder: Center(
            child: Text(
              _initialsFromCouple(couple),
              style: TextStyle(
                color: AppColors.white,
                fontSize: size * 0.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Gallery content surface (design-unify C7): SOLID white like every other
  // content card (B4) — no more translucent .84–.94 fills + white hairline
  // borders. Shadow defaults to the standard black .06 blur 16 offset(0,10);
  // the feed card keeps its slightly softer/longer shadow via the params.
  BoxDecoration _gallerySurfaceDecoration({
    required double radius,
    double shadowAlpha = 0.06,
    double blurRadius = 16,
    Offset offset = const Offset(0, 10),
  }) {
    return BoxDecoration(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: shadowAlpha),
          blurRadius: blurRadius,
          offset: offset,
        ),
      ],
    );
  }

  Widget _buildPastelStoryBadge(
    String label, {
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    double fontSize = 10,
    Color? textColor,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withValues(alpha: 0.92),
            AppColors.secondaryGradientStart.withValues(alpha: 0.88),
            AppColors.secondaryGradientEnd.withValues(alpha: 0.82),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.56)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: (textColor ?? AppColors.textPrimary).withValues(alpha: 0.78),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.12,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildGalleryEyebrow(String label) {
    // Header-sync vòng 5: boxed eyebrow chip, light-surface navy-ink recolor
    // of the original (user request 2026-06-11).
    return EyebrowChip(label: label, icon: LucideIcons.sparkles);
  }

  TextStyle _galleryCardTitleStyle({double size = 16}) {
    return TextStyle(
      color: AppColors.textPrimary.withValues(alpha: 0.90),
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.18,
    );
  }

  TextStyle _galleryBodyStyle({
    Color? color,
    double size = 13,
    double alpha = 0.82,
    FontWeight weight = FontWeight.w500,
    double height = 1.5,
  }) {
    return TextStyle(
      color: (color ?? AppColors.textSecondary).withValues(alpha: alpha),
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0.02,
    );
  }

  TextStyle _galleryMetaStyle({
    Color? color,
    double size = 12,
    double alpha = 0.68,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      color: (color ?? AppColors.textPrimary).withValues(alpha: alpha),
      fontSize: size,
      fontWeight: weight,
      height: 1.24,
      letterSpacing: 0.08,
    );
  }

  Widget _buildFeedStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: _galleryMetaStyle(
              color: AppColors.textPrimary,
              size: 11,
              alpha: 0.80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerCard(Couple? couple, int photoCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _gallerySurfaceDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoupleAvatar(couple, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (couple == null)
                      Text(
                        context.l10n.addNewMemoryTitle,
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.88),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                          height: 1.2,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AnimatedCoupleName(
                            person1Name: couple.person1Name,
                            person2Name: couple.person2Name,
                            creatorUserId: couple.createdByUserId,
                            spacing: 4,
                            runSpacing: 2,
                            heartSize: 13,
                            heartColor: AppColors.accentRose,
                            textStyle: TextStyle(
                              color: AppColors.textPrimary.withValues(alpha: 0.88),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.15,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            context.l10n.whatNewToday,
                            style: TextStyle(
                              color: AppColors.textPrimary.withValues(alpha: 0.88),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.15,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.composerSubtitle,
                      style: _galleryBodyStyle(
                        color: AppColors.textPrimary,
                        size: 12,
                        alpha: 0.58,
                        weight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MarqueeRow(
            children: [
              _buildFeedStatChip(
                icon: LucideIcons.galleryHorizontalEnd,
                label: context.l10n.momentsCount(photoCount),
                color: AppColors.accentRose,
              ),
              _buildFeedStatChip(
                icon: LucideIcons.bookOpen,
                label: context.l10n.privateFeedLabel,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: context.watch<PhotoProvider>().isLoading ? null : _pickAndAddPhoto,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentRose,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    minimumSize: Size.zero,
                    // r16 = in-card button token (C7.8).
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(LucideIcons.camera, size: 16),
                  label: Text(context.l10n.postNewPhotoBtn),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: context.watch<PhotoProvider>().isLoading ? null : _pickMultiplePhotos,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.24)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    minimumSize: Size.zero,
                    // r16 = in-card button token (C7.8).
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(LucideIcons.layoutGrid, size: 16),
                  label: Text(context.l10n.addMultipleBtn),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTopShowcase(Couple? couple, int photoCount) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGalleryEyebrow(context.l10n.privateGalleryBadge),
          const SizedBox(height: 6),
          Text(
            context.l10n.galleryTitle,
            style: AppTheme.pageTitleStyle().copyWith(fontSize: 26),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.gallerySubtitle,
            style: AppTheme.pageSubtitleStyle().copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          _buildComposerCard(couple, photoCount),
        ],
      ),
    );
  }

  Widget _buildCompactTopShowcase(Couple? couple, int photoCount) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _gallerySurfaceDecoration(radius: 24),
        child: Row(
          children: [
            _buildCoupleAvatar(couple, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                    if (couple == null)
                      Text(
                        context.l10n.addNewMemoryTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _galleryCardTitleStyle(size: 15),
                      )
                    else
                      AnimatedCoupleName(
                        person1Name: couple.person1Name,
                        person2Name: couple.person2Name,
                        creatorUserId: couple.createdByUserId,
                        spacing: 5,
                        runSpacing: 4,
                        heartSize: 14,
                        heartColor: AppColors.accentRose,
                        textStyle: _galleryCardTitleStyle(size: 15),
                      ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.compactCaption(photoCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _galleryMetaStyle(
                      color: AppColors.textSecondary,
                      size: 11,
                      alpha: 0.82,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: context.watch<PhotoProvider>().isLoading ? null : _pickAndAddPhoto,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
              ),
              icon: const Icon(LucideIcons.camera, size: 18),
              tooltip: context.l10n.postNewPhotoBtn,
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: context.watch<PhotoProvider>().isLoading ? null : _pickMultiplePhotos,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accentCoral.withValues(alpha: 0.14),
                foregroundColor: AppColors.accentCoral,
              ),
              icon: const Icon(LucideIcons.layoutGrid, size: 18),
              tooltip: context.l10n.addMultipleBtn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCTACard(Couple? couple, List<Photo> allPhotos) {
    final todayPhotos = _photosUploadedToday(allPhotos);
    if (todayPhotos.isEmpty) {
      return _buildAddTodayPromptCard(couple);
    }
    return _buildTodayMemoriesCard(couple, todayPhotos);
  }

  Widget _buildAddTodayPromptCard(Couple? couple) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _gallerySurfaceDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.sun,
                  color: AppColors.accentRose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.galleryTodayEmptyTitle,
                      style: _galleryCardTitleStyle(size: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.galleryTodayEmptySubtitle,
                      style: _galleryBodyStyle(
                        size: 12,
                        alpha: 0.60,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  context.watch<PhotoProvider>().isLoading
                      ? null
                      : _pickAndAddPhoto,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(LucideIcons.camera, size: 17),
              label: Text(context.l10n.galleryRecordTodayMoment),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMemoriesCard(Couple? couple, List<Photo> todayPhotos) {
    final heroTags = List.generate(
      todayPhotos.length,
      (i) => 'today-cta-${todayPhotos[i].id}',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _gallerySurfaceDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.checkCircle,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.galleryTodayMomentsCount(todayPhotos.length),
                  style: _galleryCardTitleStyle(size: 15),
                ),
              ),
              _buildPastelStoryBadge(
                context.l10n.galleryTodayBadge,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: todayPhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final photo = todayPhotos[index];
                return Hero(
                  tag: heroTags[index],
                  createRectTween: (begin, end) =>
                      MaterialRectCenterArcTween(begin: begin, end: end),
                  transitionOnUserGestures: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 96,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SharedPhotoView(
                            photo: photo,
                            fit: BoxFit.cover,
                            // 96px slot → decode small (≈ 96 * DPR) to avoid
                            // decoding a full-res bitmap for a strip thumbnail.
                            decodeWidth: (96 *
                                    MediaQuery.of(context).devicePixelRatio)
                                .round(),
                            placeholder: Container(
                              color: AppColors.surfaceLight,
                            ),
                          ),
                          // Ripple over the photo (white .12 on imagery, like
                          // the cinema card) — replaces the bare
                          // GestureDetector (C7.7).
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              splashColor:
                                  AppColors.white.withValues(alpha: 0.12),
                              onTap: () => _openPhotoPreview(
                                todayPhotos,
                                initialIndex: index,
                                couple: couple,
                                heroTags: heroTags,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFeedCard(Couple? couple, Photo photo, int index) {
    final displayCaption = photo.caption?.trim().isNotEmpty == true
        ? photo.caption!.trim()
        : context.l10n.momentNumberFallback(index + 1);
    final heroTag = _feedHeroTag(photo, index);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: _gallerySurfaceDecoration(
        radius: 28,
        shadowAlpha: 0.05,
        blurRadius: 20,
        offset: const Offset(0, 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoupleAvatar(couple, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (couple == null)
                          Text(
                            context.l10n.youTwoLabel,
                            style: _galleryCardTitleStyle(size: 16),
                          )
                        else
                          AnimatedCoupleName(
                            person1Name: couple.person1Name,
                            person2Name: couple.person2Name,
                            creatorUserId: couple.createdByUserId,
                            spacing: 5,
                            runSpacing: 4,
                            heartSize: 14,
                            heartColor: AppColors.accentRose,
                            textStyle: _galleryCardTitleStyle(size: 16),
                          ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.72),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _feedPostedByLabel(photo),
                              overflow: TextOverflow.ellipsis,
                              style: _galleryMetaStyle(
                                color: AppColors.textSecondary,
                                size: 12,
                                alpha: 0.72,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.72),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatFeedDate(photo.uploadDate),
                            style: _galleryMetaStyle(
                              color: AppColors.textSecondary,
                              size: 12,
                              alpha: 0.68,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_PhotoFeedAction>(
                  icon: Icon(
                    LucideIcons.moreHorizontal,
                    color: AppColors.textSecondary.withValues(alpha: 0.76),
                  ),
                  onSelected: (action) {
                    if (action == _PhotoFeedAction.editCaption) {
                      _editCaption(photo);
                      return;
                    }

                    if (action == _PhotoFeedAction.report) {
                      _reportPhoto(photo);
                      return;
                    }

                    _deletePhoto(photo);
                  },
                  itemBuilder: (context) {
                    final currentUserId = context.read<AuthProvider>().currentUser?.id;
                    return [
                      PopupMenuItem(
                        value: _PhotoFeedAction.editCaption,
                        child: Text(context.l10n.editCaptionAction),
                      ),
                      if (currentUserId != null)
                        PopupMenuItem(
                          value: _PhotoFeedAction.delete,
                          child: Text(context.l10n.deletePhotoAction),
                        ),
                      PopupMenuItem(
                        value: _PhotoFeedAction.report,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.flag,
                              size: 18,
                              color: AppColors.accentRose,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.l10n.reportPhotoAction,
                              style: const TextStyle(color: AppColors.accentRose),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () => _openPhotoPreview(
                context.read<PhotoProvider>().feedPhotos,
                initialIndex: index,
                couple: couple,
                heroTags: List.generate(
                  context.read<PhotoProvider>().feedPhotos.length,
                  (photoIndex) => _feedHeroTag(
                    context.read<PhotoProvider>().feedPhotos[photoIndex],
                    photoIndex,
                  ),
                ),
              ),
              onDoubleTap: () => _onDoubleTapPhoto(photo),
              // Card 28 − 4 = 24: keeps the −4 nested-radius ratio (C7.3).
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Hero(
                  tag: heroTag,
                  createRectTween: (begin, end) =>
                      MaterialRectCenterArcTween(begin: begin, end: end),
                  transitionOnUserGestures: true,
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SharedPhotoView(
                          photo: photo,
                          fit: BoxFit.cover,
                          // Full-width feed card → decode at screen width (in
                          // physical px). With source already capped at 1920px
                          // this is effectively native, but bounds older/legacy
                          // full-res uploads to the visible size.
                          decodeWidth: (MediaQuery.of(context).size.width *
                                  MediaQuery.of(context).devicePixelRatio)
                              .round(),
                          placeholder: Container(
                            color:
                                AppColors.surfaceLight.withValues(alpha: 0.94),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.imageOff,
                              size: 40,
                              color:
                                  AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        HeartBurstOverlay(
                          trigger: _burstTriggers[photo.id] ?? 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (displayCaption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Text(
                displayCaption,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.84),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.62,
                  letterSpacing: 0.02,
                ),
              ),
            )
          else
            const SizedBox(height: 14),
          _FeedReactionBar(couple: couple, photo: photo),
        ],
      ),
    );
  }

  List<_FeedItem> _buildFeedItems(List<Photo> photos) {
    final items = <_FeedItem>[];
    String? lastKey;
    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      final key = '${photo.uploadDate.month}-${photo.uploadDate.year}';
      if (key != lastKey) {
        items.add(_FeedMonthHeader(photo.uploadDate));
        lastKey = key;
      }
      items.add(_FeedPhotoItem(photo, i));
    }
    return items;
  }

  Widget _buildMonthHeaderWidget(DateTime date) {
    final label = context.l10n.galleryMonthLabel(
      date.month.toString(),
      date.year.toString(),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            // Header ink vòng 4 (2026-06-11): near-solid white chip + navy ink
            // — the thin glass chip with white type failed contrast on blush.
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.65)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.white.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  // Re-arms the Firestore photo stream (pull-to-refresh / "Try again").
  Future<void> _retrySync() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    await context.read<PhotoProvider>().syncForUser(currentUser);
  }

  // Distinct from the empty state: shown when the stream errored AND we have no
  // photos to fall back on — so the user knows it's a load failure (not "no
  // memories yet") and can retry.
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: _gallerySurfaceDecoration(radius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.cloudOff,
                  color: AppColors.accentRose,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.galleryLoadErrorTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.92),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.galleryLoadErrorSubtitle,
                textAlign: TextAlign.center,
                style: _galleryBodyStyle(size: 13, alpha: 0.82, height: 1.62),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed:
                    context.watch<PhotoProvider>().isLoading ? null : _retrySync,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRose,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  // r16 = in-card button token (C7.8).
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(LucideIcons.refreshCw),
                label: Text(context.l10n.galleryRetryBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFeedState(Couple? couple) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
            decoration: _gallerySurfaceDecoration(radius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  color: AppColors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              if (couple == null)
                Text(
                  context.l10n.startNewfeedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.92),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                    height: 1.12,
                  ),
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      context.l10n.postFirstMomentOf,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.92),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                        height: 1.12,
                      ),
                    ),
                    AnimatedCoupleName(
                      person1Name: couple.person1Name,
                      person2Name: couple.person2Name,
                      creatorUserId: couple.createdByUserId,
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      heartSize: 18,
                      heartColor: AppColors.accentRose,
                      textStyle: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.92),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              // Khoảnh khắc "empty gallery" (feature lottie-moments). Chưa có
              // file → SizedBox 0px (layout y hệt cũ); có file → animation lặp êm.
              const LoveLottie(
                slot: LoveLottieSlot.emptyGallery,
                height: 140,
                repeat: true,
              ),
              Text(
                context.l10n.emptyFeedContent,
                textAlign: TextAlign.center,
                style: _galleryBodyStyle(size: 13, alpha: 0.82, height: 1.62),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: context.watch<PhotoProvider>().isLoading ? null : _pickAndAddPhoto,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRose,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  // r16 = in-card button token (C7.8).
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(LucideIcons.imagePlus),
                label: Text(context.l10n.postFirstPhotoBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<PhotoProvider, CoupleProvider>(
        builder: (context, photoProvider, coupleProvider, _) {
          // Feed = the contiguous paginated prefix (pagination D1); on-this-day
          // extras live only in `sortedPhotos` so the timeline has no holes.
          final photos = photoProvider.feedPhotos;
          final couple = coupleProvider.couple;

          // Deep-link: open the exact photo a tapped notification asked for,
          // once the list has loaded (handles cold-start where photos arrive
          // after the tap). Gated + self-clearing so it fires at most once.
          final deepLinkId = _pendingDeepLinkPhotoId;
          if (deepLinkId != null && !photoProvider.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openDeepLinkPhoto(deepLinkId, photos, couple);
            });
          }

          final feedItems = _buildFeedItems(photos);
          // Stream errored AND nothing to show → it's a load failure, not an
          // empty library. Render a retryable error state instead of "post your
          // first photo" so the user never thinks their memories vanished.
          final hasLoadError =
              photoProvider.errorMessage != null && photos.isEmpty;

          return BlockingLoadingOverlay(
            isVisible: photoProvider.isLoading,
            message: photoProvider.loadingMessage,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.secondaryGradient,
              ),
              child: RefreshIndicator(
                onRefresh: _retrySync,
                color: AppColors.accentRose,
                backgroundColor: AppColors.white,
                // Infinite scroll (pagination D1): nearing the bottom of the
                // OUTER feed scrollable (depth 0 — ignore nested horizontal
                // scrollers) fetches the next page of older photos. The
                // provider guards re-entrancy, so spamming this is safe.
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.depth == 0 &&
                        notification.metrics.axis == Axis.vertical &&
                        notification.metrics.extentAfter < 600) {
                      photoProvider.loadMorePhotos();
                    }
                    return false;
                  },
                  child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                  SliverPersistentHeader(
                    floating: false,
                    pinned: true,
                    delegate: _GalleryFloatingShowcaseHeaderDelegate(
                      minHeaderExtent: _floatingTopShowcaseMinHeight,
                      maxHeaderExtent: _floatingTopShowcaseMaxHeight,
                      // D2: show the aggregate TOTAL, not just the loaded page.
                      compactChild:
                          _buildCompactTopShowcase(couple, photoProvider.photoCount),
                      expandedChild:
                          _buildFloatingTopShowcase(couple, photoProvider.photoCount),
                    ),
                  ),
                  if (photos.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _buildTodayCTACard(couple, photos),
                      ),
                    ),
                  if (hasLoadError) ...[
                    SliverToBoxAdapter(child: _buildErrorState()),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: widget.bottomInset + 24),
                    ),
                  ]
                  else if (photos.isEmpty) ...[
                    SliverToBoxAdapter(child: _buildEmptyFeedState(couple)),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: widget.bottomInset + 24),
                    ),
                  ]
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = feedItems[index];
                          if (item is _FeedMonthHeader) {
                            return _buildMonthHeaderWidget(item.date);
                          }
                          final p = item as _FeedPhotoItem;
                          final card =
                              _buildPhotoFeedCard(couple, p.photo, p.originalIndex);
                          // Only the first few cards get the staggered entrance;
                          // deeper cards (revealed by scrolling) appear normally
                          // so a long feed never lags or re-animates on recycle.
                          if (p.originalIndex < 6) {
                            return EntranceReveal(
                              order: p.originalIndex,
                              child: card,
                            );
                          }
                          return card;
                        }, childCount: feedItems.length),
                      ),
                    ),
                    // Pagination footer: shimmer while the next page loads;
                    // a gentle sign-off once a LONG feed (>1 page) is fully
                    // loaded. Short feeds get neither.
                    if (photoProvider.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: ShimmerSkeleton(
                            width: double.infinity,
                            height: 120,
                            borderRadius: 24,
                          ),
                        ),
                      )
                    else if (!photoProvider.hasMorePhotos && photos.length > 30)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: Text(
                            context.l10n.galleryEndOfFeed,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: widget.bottomInset + 32),
                    ),
                  ],
                  ],
                ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Isolated widget so only the reaction bar rebuilds on ReactionProvider changes,
/// not the entire GalleryScreen (prevents "dirty widget in wrong build scope" crash
/// caused by context.watch inside _GalleryScreenState conflicting with the
/// _MarqueeRow animation layout callback).
class _FeedReactionBar extends StatelessWidget {
  const _FeedReactionBar({required this.couple, required this.photo});

  final Couple? couple;
  final Photo photo;

  @override
  Widget build(BuildContext context) {
    final reactionProvider = context.watch<ReactionProvider>();
    final myUid = context.read<AuthProvider>().currentUser?.id;
    if (!reactionProvider.isReady || myUid == null || couple == null) {
      return const SizedBox(height: 16);
    }
    return ReactionBar(photo: photo, couple: couple!, myUid: myUid);
  }
}

enum _PhotoFeedAction { editCaption, delete, report }

sealed class _FeedItem {}

class _FeedMonthHeader extends _FeedItem {
  _FeedMonthHeader(this.date);
  final DateTime date;
}

class _FeedPhotoItem extends _FeedItem {
  _FeedPhotoItem(this.photo, this.originalIndex);
  final Photo photo;
  final int originalIndex;
}

class _MarqueeRow extends StatefulWidget {
  const _MarqueeRow({required this.children});
  final List<Widget> children;

  @override
  State<_MarqueeRow> createState() => _MarqueeRowState();
}

// AnimationController + Transform.translate: no ScrollController, no SliverList,
// no GlobalKey, no LayoutBuilder.
// LayoutBuilder was removed because it creates an invokeLayoutCallback scope that
// conflicts with SliverList's layout scope whenever ReactionProvider rebuilds
// _FeedReactionBar — causing "dirty widget in wrong build scope" →
// "each child must be laid out exactly once" → semantics.parentDataDirty cascade.
// MediaQuery supplies containerWidth from the build phase (no locked scope).
class _MarqueeRowState extends State<_MarqueeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  static const double _speed = 45.0;
  // Enough repeats so the Row is always much wider than the container.
  static const int _repeatFactor = 8;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    // Start after first frame so MediaQuery width is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  void _maybeStart() {
    if (!mounted || _animation.isAnimating) return;
    // Reduce Motion (A8.3): never start the marquee — build renders the chip
    // row statically instead.
    if (AppMotion.reduceMotion(context)) return;
    _animation.repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce Motion (WCAG 2.3.3, A8.3): render the chip row statically — same
    // frame (ClipRect + OverflowBox), no repeat, no Transform sweep.
    if (AppMotion.reduceMotion(context)) {
      if (_animation.isAnimating) {
        _animation.stop();
      }
      return SizedBox(
        height: 30,
        child: ExcludeSemantics(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final chip in widget.children)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: chip,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Use screen width — close enough for timing (this is a full-width header).
    // Avoids LayoutBuilder which would create an invokeLayoutCallback scope.
    final containerWidth = MediaQuery.of(context).size.width;

    if (!_animation.isAnimating && containerWidth > 0) {
      _animation.duration = Duration(
        milliseconds: (containerWidth / _speed * 1000).round().clamp(500, 20000),
      );
      // (Re)start after this frame — covers both first build and Reduce
      // Motion being switched back off mid-session.
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
    }

    final count = widget.children.length;
    final items = List.generate(
      count * _repeatFactor,
      (i) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: widget.children[i % count],
      ),
    );
    return SizedBox(
      height: 30,
      child: ExcludeSemantics(
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _animation,
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
              builder: (_, child) => Transform.translate(
                offset: Offset(-_animation.value * containerWidth, 0),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryFloatingShowcaseHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  const _GalleryFloatingShowcaseHeaderDelegate({
    required this.minHeaderExtent,
    required this.maxHeaderExtent,
    required this.compactChild,
    required this.expandedChild,
  });

  final double minHeaderExtent;
  final double maxHeaderExtent;
  final Widget compactChild;
  final Widget expandedChild;

  @override
  double get minExtent => minHeaderExtent;

  @override
  double get maxExtent => maxHeaderExtent;

  @override
  FloatingHeaderSnapConfiguration get snapConfiguration =>
      FloatingHeaderSnapConfiguration(
        curve: Curves.easeOutCubic,
        duration: Duration(milliseconds: 250),
      );

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final progress = (shrinkOffset / range).clamp(0.0, 1.0);
    const compactRevealStart = 0.14;
    final handoffProgress = progress <= compactRevealStart
        ? 0.0
        : ((progress - compactRevealStart) / (1 - compactRevealStart)).clamp(0.0, 1.0);
    final compactProgress = Curves.easeInOutCubic.transform(handoffProgress);
    final expandedOpacity = 1 - Curves.easeOutCubic.transform(progress);
    final compactOpacity = Curves.easeInOut.transform(handoffProgress);
    final compactScale = lerpDouble(0.998, 1.0, compactProgress) ?? 1.0;
    final compactTranslateY = lerpDouble(3, 0, compactProgress) ?? 0.0;
    final expandedTranslateY = lerpDouble(0, -6, progress) ?? 0.0;
    final backgroundShadowProgress = Curves.easeOutCubic.transform(compactOpacity);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.secondaryGradient.colors.first.withValues(alpha: 0.96),
            AppColors.secondaryGradient.colors.last.withValues(alpha: 0.82),
            AppColors.secondaryGradient.colors.last.withValues(alpha: 0.16),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 0.78, 1.0],
        ),
        boxShadow: overlapsContent && backgroundShadowProgress > 0.4
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.018 * backgroundShadowProgress),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: maxExtent,
              maxHeight: maxExtent,
              child: IgnorePointer(
                ignoring: compactOpacity > 0.6,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: Transform.translate(
                    offset: Offset(0, expandedTranslateY),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: expandedChild,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: minExtent,
                child: IgnorePointer(
                  ignoring: compactOpacity < 0.08,
                  child: Opacity(
                    opacity: compactOpacity,
                    child: Transform.translate(
                      offset: Offset(0, compactTranslateY),
                      child: Transform.scale(
                        scale: compactScale,
                        alignment: Alignment.topCenter,
                        child: compactChild,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GalleryFloatingShowcaseHeaderDelegate oldDelegate) {
    return oldDelegate.minHeaderExtent != minHeaderExtent ||
        oldDelegate.maxHeaderExtent != maxHeaderExtent ||
        oldDelegate.compactChild != compactChild ||
        oldDelegate.expandedChild != expandedChild;
  }
}

class _FullscreenPhotoPreview extends StatefulWidget {
  const _FullscreenPhotoPreview({
    required this.photos,
    required this.heroTags,
    required this.initialIndex,
    required this.couple,
    this.onEditCaption,
    this.onReport,
  });

  final List<Photo> photos;
  final List<String> heroTags;
  final int initialIndex;
  final Couple? couple;
  final void Function(Photo photo)? onEditCaption;
  final void Function(Photo photo)? onReport;

  @override
  State<_FullscreenPhotoPreview> createState() => _FullscreenPhotoPreviewState();
}

class _FullscreenPhotoPreviewState extends State<_FullscreenPhotoPreview>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _dismissResetController;
  late final List<TransformationController> _transformationControllers;
  late final List<VoidCallback> _transformationListeners;
  late final List<double> _pageScales;
  late int _currentIndex;
  double _verticalDragOffset = 0;
  // Tracks whether we've already buzzed for the current drag so the
  // light haptic fires only once, the moment the dismiss threshold is crossed.
  bool _dismissThresholdHapticFired = false;
  // Per-photo heart-burst trigger counters (bump to replay) for double-tap.
  final Map<String, int> _burstTriggers = <String, int>{};

  static const double _dismissDistanceThreshold = 140;
  static const double _dismissVelocityThreshold = 1000;
  static const double _dismissProgressDistance = 240;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _dismissResetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _pageScales = List<double>.filled(widget.photos.length, 1);
    _transformationControllers = List.generate(
      widget.photos.length,
      (_) => TransformationController(),
    );
    _transformationListeners = List<VoidCallback>.generate(widget.photos.length, (index) {
      return () {
        final nextScale = _transformationControllers[index].value.getMaxScaleOnAxis();
        if ((_pageScales[index] - nextScale).abs() < 0.01) {
          return;
        }

        _pageScales[index] = nextScale;
        if (mounted && index == _currentIndex) {
          setState(() {});
        }
      };
    });

    for (var i = 0; i < _transformationControllers.length; i++) {
      _transformationControllers[i].addListener(_transformationListeners[i]);
    }
  }

  @override
  void dispose() {
    for (var i = 0; i < _transformationControllers.length; i++) {
      _transformationControllers[i].removeListener(_transformationListeners[i]);
      _transformationControllers[i].dispose();
    }
    _dismissResetController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatFeedDate(DateTime date) {
    final l10n = context.l10n;
    return DateFormat(
      l10n.feedDateFormat,
      Localizations.localeOf(context).languageCode,
    ).format(date);
  }

  String _previewPostedByLabel(Photo photo) {
    return context.l10n.postedByLabel(photo.posterName);
  }

  /// Double-tap on the fullscreen image: drop a ❤️ + burst (never toggle-off).
  /// No-ops without an active Firebase couple. InteractiveViewer does not
  /// double-tap-zoom by default, so this gesture is exclusive to the burst.
  void _onDoubleTapPhoto(Photo photo) {
    final reactionProvider = context.read<ReactionProvider>();
    final myUid = context.read<AuthProvider>().currentUser?.id;
    if (!reactionProvider.isReady || myUid == null) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _burstTriggers[photo.id] = (_burstTriggers[photo.id] ?? 0) + 1;
    });

    if (reactionProvider.myReaction(photo.id, myUid) != '❤️') {
      reactionProvider.setReaction(photo.id, '❤️');
    }
  }

  bool get _canDismissWithDrag => _pageScales[_currentIndex] <= 1.02;

  double get _dismissProgress =>
      (_verticalDragOffset / _dismissProgressDistance).clamp(0.0, 1.0);

  void _onVerticalDragStart(DragStartDetails details) {
    if (!_canDismissWithDrag) {
      return;
    }

    _dismissThresholdHapticFired = false;
    _dismissResetController.stop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_canDismissWithDrag) {
      return;
    }

    final delta = details.primaryDelta ?? 0;
    final nextOffset = (_verticalDragOffset + delta).clamp(0.0, double.infinity);
    if ((nextOffset - _verticalDragOffset).abs() < 0.1) {
      return;
    }

    // Buzz once when the drag first reaches the release-to-dismiss threshold,
    // so the user feels the "let go now" point. Reset below it for re-cross.
    if (!_dismissThresholdHapticFired &&
        nextOffset >= _dismissDistanceThreshold) {
      _dismissThresholdHapticFired = true;
      HapticFeedback.lightImpact();
    } else if (_dismissThresholdHapticFired &&
        nextOffset < _dismissDistanceThreshold) {
      _dismissThresholdHapticFired = false;
    }

    setState(() {
      _verticalDragOffset = nextOffset;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_canDismissWithDrag) {
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    if (_verticalDragOffset >= _dismissDistanceThreshold ||
        velocity >= _dismissVelocityThreshold) {
      Navigator.of(context).pop();
      return;
    }

    _animateDismissOffsetToZero();
  }

  void _animateDismissOffsetToZero() {
    final start = _verticalDragOffset;
    if (start <= 0) {
      if (mounted && _verticalDragOffset != 0) {
        setState(() => _verticalDragOffset = 0);
      }
      return;
    }

    final animation = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: _dismissResetController, curve: Curves.easeOutCubic),
    );

    void listener() {
      if (!mounted) {
        return;
      }
      setState(() {
        _verticalDragOffset = animation.value;
      });
    }

    _dismissResetController
      ..removeListener(listener)
      ..reset()
      ..addListener(listener);

    _dismissResetController.forward().whenCompleteOrCancel(() {
      _dismissResetController.removeListener(listener);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];
    final dismissProgress = _dismissProgress;
    final contentScale = lerpDouble(1, 0.93, dismissProgress) ?? 1;
    final overlayOpacity = (1 - (dismissProgress * 1.15)).clamp(0.0, 1.0);
    final backgroundAlpha = (0.94 - (dismissProgress * 0.74)).clamp(0.0, 0.94);
    final verticalDragHandlersEnabled = _canDismissWithDrag;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: backgroundAlpha),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart:
            verticalDragHandlersEnabled ? _onVerticalDragStart : null,
        onVerticalDragUpdate:
            verticalDragHandlersEnabled ? _onVerticalDragUpdate : null,
        onVerticalDragEnd: verticalDragHandlersEnabled ? _onVerticalDragEnd : null,
        child: Transform.translate(
          offset: Offset(0, _verticalDragOffset),
          child: Transform.scale(
            scale: contentScale,
            child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _verticalDragOffset = 0;
                });
              },
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                final image = SharedPhotoView(
                  photo: photo,
                  fit: BoxFit.contain,
                );

                final child = Center(
                  child: InteractiveViewer(
                    transformationController: _transformationControllers[index],
                    minScale: 0.9,
                    maxScale: 4,
                    child: index == widget.initialIndex
                        ? Hero(
                            tag: widget.heroTags[index],
                            createRectTween: (begin, end) =>
                                MaterialRectCenterArcTween(begin: begin, end: end),
                            transitionOnUserGestures: true,
                            child: image,
                          )
                        : image,
                  ),
                );

                // Double-tap → ❤️ + burst, drawn over the image. The burst is
                // pointer-ignoring so it never blocks pan/zoom underneath.
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: () => _onDoubleTapPhoto(photo),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      HeartBurstOverlay(trigger: _burstTriggers[photo.id] ?? 0),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Opacity(
              opacity: overlayOpacity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onReport != null) ...[
                    IconButton.filledTonal(
                      onPressed: () => widget.onReport!(currentPhoto),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.28),
                        foregroundColor: AppColors.white,
                      ),
                      icon: const Icon(LucideIcons.flag),
                      tooltip: context.l10n.reportPhotoAction,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.onEditCaption != null)
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onEditCaption!(currentPhoto);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.28),
                        foregroundColor: AppColors.white,
                      ),
                      icon: const Icon(LucideIcons.pencil),
                      tooltip: context.l10n.galleryEditCaptionTooltip,
                    ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.28),
                      foregroundColor: AppColors.white,
                    ),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Opacity(
              opacity: overlayOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.36),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.couple == null)
                        Text(
                          context.l10n.youTwoLabel,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.96),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.15,
                          ),
                        )
                      else
                        AnimatedCoupleName(
                          person1Name: widget.couple!.person1Name,
                          person2Name: widget.couple!.person2Name,
                          creatorUserId: widget.couple!.createdByUserId,
                          spacing: 6,
                          runSpacing: 4,
                          heartSize: 14,
                          heartColor: AppColors.white,
                          textStyle: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.96),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.15,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        _previewPostedByLabel(currentPhoto),
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.06,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFeedDate(currentPhoto.uploadDate),
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06,
                        ),
                      ),
                      if (currentPhoto.caption?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Text(
                          currentPhoto.caption!.trim(),
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.94),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.58,
                          ),
                        ),
                      ],
                      _PreviewReactionRow(photo: currentPhoto, couple: widget.couple),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 124,
              child: Opacity(
                opacity: overlayOpacity,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Isolated widget so only the on-dark reaction row rebuilds on ReactionProvider
/// changes, not the entire _FullscreenPhotoPreviewState.
class _PreviewReactionRow extends StatelessWidget {
  const _PreviewReactionRow({required this.photo, required this.couple});

  final Photo photo;
  final Couple? couple;

  @override
  Widget build(BuildContext context) {
    final reactionProvider = context.watch<ReactionProvider>();
    final myUid = context.read<AuthProvider>().currentUser?.id;
    if (!reactionProvider.isReady || myUid == null || couple == null) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 1,
          color: AppColors.white.withValues(alpha: 0.12),
        ),
        ReactionBar(
          photo: photo,
          couple: couple!,
          myUid: myUid,
          onDark: true,
          padding: const EdgeInsets.only(top: 10),
        ),
      ],
    );
  }
}


