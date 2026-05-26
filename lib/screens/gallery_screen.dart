import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/photo.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/shared_couple_photo_view.dart';
import '../widgets/shared_photo_view.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const double _floatingTopShowcaseMaxHeight = 340;
  static const double _floatingTopShowcaseMinHeight = 122;


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

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null || !mounted) {
      return;
    }

    final l10n = context.l10n;
    final caption = await _showCaptionDialog(
      title: l10n.addCaptionOptionalTitle,
      hint: l10n.addCaptionOptionalHint,
    );

    if (!mounted) {
      return;
    }

    try {
      await context.read<PhotoProvider>().addPhoto(
        pickedFile.path,
        currentUser: currentUser,
        caption: caption != null && caption.isNotEmpty ? caption : null,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.photoAddedSuccess)),
    );
  }

  Future<void> _pickMultiplePhotos() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      return;
    }

    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        if (mounted) {
          try {
            await context.read<PhotoProvider>().addPhoto(
              file.path,
              currentUser: currentUser,
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
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.multiplePhotosAdded(pickedFiles.length)),
          ),
        );
      }
    }
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

  String _formatFeedDate(DateTime date) {
    return DateFormat("dd 'thg' MM • HH:mm").format(date);
  }

  String _feedPostedByLabel(Photo photo) {
    return context.l10n.postedByLabel(photo.posterName);
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  List<Photo> _memoriesToday(List<Photo> photos) {
    final now = DateTime.now();
    return photos
        .where(
          (photo) =>
              photo.uploadDate.day == now.day &&
              photo.uploadDate.month == now.month,
        )
        .take(10)
        .toList();
  }

  List<Photo> _recentStoryPhotos(List<Photo> photos) {
    return photos.take(10).toList();
  }

  String _storyHeroTag(Photo photo, bool isMemory) {
    return 'story-photo-${photo.id}-${isMemory ? 'memory' : 'recent'}';
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

  int _daysTogether(Couple? couple) {
    if (couple == null) {
      return 0;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final anniversary = DateTime(
      couple.anniversaryDate.year,
      couple.anniversaryDate.month,
      couple.anniversaryDate.day,
    );
    return today.difference(anniversary).inDays;
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

  TextStyle _galleryDisplayStyle() {
    return AppTheme.pageTitleStyle();
  }

  TextStyle _gallerySectionTitleStyle() {
    return AppTheme.sectionTitleStyle();
  }

  TextStyle _galleryOnBackgroundBodyStyle({
    double size = 13,
    double alpha = 0.82,
    FontWeight weight = FontWeight.w500,
    double height = 1.5,
  }) {
    return TextStyle(
      color: AppColors.white.withValues(alpha: alpha),
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0.02,
    );
  }

  BoxDecoration _gallerySurfaceDecoration({
    required double radius,
    double fillAlpha = 0.9,
    double borderAlpha = 0.82,
    double shadowAlpha = 0.045,
    double blurRadius = 18,
    Offset offset = const Offset(0, 10),
  }) {
    return BoxDecoration(
      color: AppColors.white.withValues(alpha: fillAlpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.white.withValues(alpha: borderAlpha)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: AppColors.white.withValues(alpha: 0.72),
          ),
          const SizedBox(width: 6),
          Text(
            label,
                style: AppTheme.pageEyebrowStyle(alpha: 0.88),
          ),
        ],
      ),
    );
  }

  TextStyle _galleryCardTitleStyle({double size = 16.5}) {
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
      decoration: _gallerySurfaceDecoration(radius: 24, fillAlpha: 0.84),
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
                          fontSize: 14.5,
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
                            spacing: 4,
                            runSpacing: 2,
                            heartSize: 13,
                            heartColor: AppColors.accentRose,
                            textStyle: TextStyle(
                              color: AppColors.textPrimary.withValues(alpha: 0.88),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.15,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            context.l10n.whatNewToday,
                            style: TextStyle(
                              color: AppColors.textPrimary.withValues(alpha: 0.88),
                              fontSize: 14.5,
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
                        size: 11.5,
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
                icon: Icons.collections_rounded,
                label: '$photoCount khoảnh khắc',
                color: AppColors.accentRose,
              ),
              if (couple != null)
                _buildFeedStatChip(
                  icon: Icons.favorite_rounded,
                  label: '${_daysTogether(couple)} ngày bên nhau',
                  color: AppColors.accentCoral,
                ),
              _buildFeedStatChip(
                icon: Icons.auto_stories_rounded,
                label: 'Feed riêng của hai bạn',
                color: AppColors.info,
              ),
            ].whereType<Widget>().toList(),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.add_a_photo_rounded, size: 16),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.grid_view_rounded, size: 16),
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
        decoration: _gallerySurfaceDecoration(
          radius: 24,
          fillAlpha: 0.9,
          borderAlpha: 0.86,
          shadowAlpha: 0.035,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
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
                        style: _galleryCardTitleStyle(size: 15.3),
                      )
                    else
                      AnimatedCoupleName(
                        person1Name: couple.person1Name,
                        person2Name: couple.person2Name,
                        spacing: 5,
                        runSpacing: 4,
                        heartSize: 14,
                        heartColor: AppColors.accentRose,
                        textStyle: _galleryCardTitleStyle(size: 15.3),
                      ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.compactCaption(photoCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _galleryMetaStyle(
                      color: AppColors.textSecondary,
                      size: 11.1,
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
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              tooltip: 'Đăng ảnh mới',
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: context.watch<PhotoProvider>().isLoading ? null : _pickMultiplePhotos,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accentCoral.withValues(alpha: 0.14),
                foregroundColor: AppColors.accentCoral,
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              tooltip: 'Thêm nhiều',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryStripSection(Couple? couple, List<Photo> photos) {
    final memoriesToday = _memoriesToday(photos);
    final storyPhotos = memoriesToday.isNotEmpty
        ? memoriesToday
        : _recentStoryPhotos(photos);
    final storyHeroTags = List.generate(
      storyPhotos.length,
      (index) => _storyHeroTag(storyPhotos[index], memoriesToday.isNotEmpty),
    );
    final title = memoriesToday.isNotEmpty ? 'Memories today' : 'Ảnh gần đây';
    final subtitle = memoriesToday.isNotEmpty
        ? 'Những khoảnh khắc được lưu đúng ngày này, dịu dàng và rất riêng.'
        : 'Một dải story nhỏ để xem nhanh những khoảnh khắc mới nhất của hai bạn.';

    if (storyPhotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGalleryEyebrow(memoriesToday.isNotEmpty ? 'TODAY IN LOVE' : 'STORY STRIP'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    title,
                    style: _gallerySectionTitleStyle(),
                  ),
                  const SizedBox(width: 8),
                  _buildPastelStoryBadge(
                    '${storyPhotos.length}',
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    fontSize: 11,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: _galleryOnBackgroundBodyStyle(
                  size: 12.4,
                  alpha: 0.74,
                  height: 1.52,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: storyPhotos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final photo = storyPhotos[index];
              return _buildStoryCard(
                couple: couple,
                photo: photo,
                heroTag: storyHeroTags[index],
                photos: storyPhotos,
                heroTags: storyHeroTags,
                index: index,
                isMemory: memoriesToday.isNotEmpty,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCard({
    required Couple? couple,
    required Photo photo,
    required String heroTag,
    required List<Photo> photos,
    required List<String> heroTags,
    required int index,
    required bool isMemory,
  }) {
    return GestureDetector(
      onTap: () => _openPhotoPreview(
        photos,
        initialIndex: index,
        couple: couple,
        heroTags: heroTags,
      ),
      child: Container(
        width: 104,
        decoration: _gallerySurfaceDecoration(
          radius: 26,
          fillAlpha: 0.92,
          borderAlpha: 0.88,
          shadowAlpha: 0.05,
          blurRadius: 16,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox.expand(
                        child: Hero(
                          tag: heroTag,
                          createRectTween: (begin, end) =>
                              MaterialRectCenterArcTween(begin: begin, end: end),
                          transitionOnUserGestures: true,
                          child: SharedPhotoView(
                            photo: photo,
                            fit: BoxFit.cover,
                            placeholder: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildPastelStoryBadge(
                        isMemory ? context.l10n.memoryBadge : context.l10n.newBadge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Text(
                  photo.caption?.trim().isNotEmpty == true
                      ? photo.caption!.trim()
                      : _formatShortDate(photo.uploadDate),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: _galleryMetaStyle(
                    color: AppColors.textPrimary,
                    size: 11.2,
                    alpha: 0.88,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        radius: 30,
        fillAlpha: 0.94,
        borderAlpha: 0.9,
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
                            style: _galleryCardTitleStyle(size: 15.6),
                          )
                        else
                          AnimatedCoupleName(
                            person1Name: couple.person1Name,
                            person2Name: couple.person2Name,
                            spacing: 5,
                            runSpacing: 4,
                            heartSize: 14,
                            heartColor: AppColors.accentRose,
                            textStyle: _galleryCardTitleStyle(size: 15.6),
                          ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
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
                                size: 11.7,
                                alpha: 0.72,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.72),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatFeedDate(photo.uploadDate),
                            style: _galleryMetaStyle(
                              color: AppColors.textSecondary,
                              size: 11.7,
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
                    Icons.more_horiz_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.76),
                  ),
                  onSelected: (action) {
                    if (action == _PhotoFeedAction.editCaption) {
                      _editCaption(photo);
                      return;
                    }

                    _deletePhoto(photo);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _PhotoFeedAction.editCaption,
                      child: Text(context.l10n.editCaptionAction),
                    ),
                    PopupMenuItem(
                      value: _PhotoFeedAction.delete,
                      child: Text(context.l10n.deletePhotoAction),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () => _openPhotoPreview(
                context.read<PhotoProvider>().sortedPhotos,
                initialIndex: index,
                couple: couple,
                heroTags: List.generate(
                  context.read<PhotoProvider>().sortedPhotos.length,
                  (photoIndex) => _feedHeroTag(
                    context.read<PhotoProvider>().sortedPhotos[photoIndex],
                    photoIndex,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Hero(
                  tag: heroTag,
                  createRectTween: (begin, end) =>
                      MaterialRectCenterArcTween(begin: begin, end: end),
                  transitionOnUserGestures: true,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: SharedPhotoView(
                      photo: photo,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: AppColors.surfaceLight.withValues(alpha: 0.94),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeedStatChip(
                      icon: Icons.favorite_rounded,
                      label: 'Kỷ niệm #${index + 1}',
                      color: AppColors.accentRose,
                    ),
                    _buildFeedStatChip(
                      icon: Icons.calendar_month_rounded,
                      label: _formatShortDate(photo.uploadDate),
                      color: AppColors.info,
                    ),
                    _buildFeedStatChip(
                      icon: Icons.person_rounded,
                      label: photo.posterName,
                      color: AppColors.accentCoral,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  displayCaption,
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.84),
                    fontSize: 14.2,
                    fontWeight: FontWeight.w500,
                    height: 1.62,
                    letterSpacing: 0.02,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editCaption(photo),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color: AppColors.accentRose.withValues(alpha: 0.16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: Text(context.l10n.editAction),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _deletePhoto(photo),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentRose.withValues(alpha: 0.12),
                          foregroundColor: AppColors.accentRose,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: Text(context.l10n.deleteAction),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeedState(Couple? couple) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
            decoration: _gallerySurfaceDecoration(
              radius: 30,
              fillAlpha: 0.92,
              borderAlpha: 0.88,
              shadowAlpha: 0.05,
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
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
                  Icons.auto_stories_rounded,
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
                    fontSize: 20.5,
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
                        fontSize: 20.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                        height: 1.12,
                      ),
                    ),
                    AnimatedCoupleName(
                      person1Name: couple.person1Name,
                      person2Name: couple.person2Name,
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      heartSize: 18,
                      heartColor: AppColors.accentRose,
                      textStyle: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.92),
                        fontSize: 20.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Text(
                context.l10n.emptyFeedContent,
                textAlign: TextAlign.center,
                style: _galleryBodyStyle(size: 13.1, alpha: 0.82, height: 1.62),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: context.watch<PhotoProvider>().isLoading ? null : _pickAndAddPhoto,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRose,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.add_photo_alternate_rounded),
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
          final photos = photoProvider.sortedPhotos;
          final couple = coupleProvider.couple;

          return BlockingLoadingOverlay(
            isVisible: photoProvider.isLoading,
            message: photoProvider.loadingMessage,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.secondaryGradient,
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(
                    floating: false,
                    pinned: true,
                    delegate: _GalleryFloatingShowcaseHeaderDelegate(
                      minHeaderExtent: _floatingTopShowcaseMinHeight,
                      maxHeaderExtent: _floatingTopShowcaseMaxHeight,
                      compactChild: _buildCompactTopShowcase(couple, photos.length),
                      expandedChild: _buildFloatingTopShowcase(couple, photos.length),
                    ),
                  ),
                  if (photos.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 24, 0, 18),
                        child: _buildStoryStripSection(couple, photos),
                      ),
                    ),
                  if (photos.isEmpty) ...[
                    SliverToBoxAdapter(child: _buildEmptyFeedState(couple)),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: widget.bottomInset + 24),
                    ),
                  ]
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        widget.bottomInset + 32,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final photo = photos[index];
                          return _buildPhotoFeedCard(couple, photo, index);
                        }, childCount: photos.length),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _PhotoFeedAction { editCaption, delete }

class _MarqueeRow extends StatefulWidget {
  const _MarqueeRow({required this.children});
  final List<Widget> children;

  @override
  State<_MarqueeRow> createState() => _MarqueeRowState();
}

class _MarqueeRowState extends State<_MarqueeRow> {
  final ScrollController _controller = ScrollController();
  static const double _speed = 45.0; // pixels per second
  static const int _repeatFactor = 300;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loop());
  }

  Future<void> _loop() async {
    await Future.delayed(const Duration(milliseconds: 800));
    while (mounted && _controller.hasClients) {
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) {
        await Future.delayed(const Duration(milliseconds: 300));
        continue;
      }
      final remaining = max - _controller.offset;
      final durationMs = (remaining / _speed * 1000).round();
      if (durationMs <= 0) {
        _controller.jumpTo(0);
        continue;
      }
      await _controller.animateTo(
        max,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
      if (!mounted) break;
      _controller.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;
    return SizedBox(
      height: 30,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count * _repeatFactor,
        itemBuilder: (_, i) {
          final child = widget.children[i % count];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: child,
          );
        },
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
  });

  final List<Photo> photos;
  final List<String> heroTags;
  final int initialIndex;
  final Couple? couple;

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
    return DateFormat("dd 'thg' MM • HH:mm").format(date);
  }

  String _previewPostedByLabel(Photo photo) {
    return 'Đăng bởi ${photo.posterName}';
  }

  bool get _canDismissWithDrag => _pageScales[_currentIndex] <= 1.02;

  double get _dismissProgress =>
      (_verticalDragOffset / _dismissProgressDistance).clamp(0.0, 1.0);

  void _onVerticalDragStart(DragStartDetails details) {
    if (!_canDismissWithDrag) {
      return;
    }

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

                return child;
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Opacity(
              opacity: overlayOpacity,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.28),
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.close_rounded),
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
                          'Hai bạn',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.96),
                            fontSize: 15.6,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.15,
                          ),
                        )
                      else
                        AnimatedCoupleName(
                          person1Name: widget.couple!.person1Name,
                          person2Name: widget.couple!.person2Name,
                          spacing: 6,
                          runSpacing: 4,
                          heartSize: 14,
                          heartColor: AppColors.white,
                          textStyle: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.96),
                            fontSize: 15.6,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.15,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        _previewPostedByLabel(currentPhoto),
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.82),
                          fontSize: 12.4,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.06,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFeedDate(currentPhoto.uploadDate),
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.72),
                          fontSize: 12.1,
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
                            fontSize: 14.2,
                            fontWeight: FontWeight.w500,
                            height: 1.58,
                          ),
                        ),
                      ],
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

