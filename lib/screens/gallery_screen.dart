import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/couple.dart';
import '../models/photo.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../theme/app_colors.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<PhotoProvider>().loadPhotos();
    });
  }

  Future<String?> _showCaptionDialog({
    String title = 'Thêm chú thích',
    String hint = 'Viết vài dòng về khoảnh khắc này...',
    String initialValue = '',
  }) async {
    final captionController = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, captionController.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndAddPhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null || !mounted) {
      return;
    }

    final caption = await _showCaptionDialog(
      title: 'Thêm chú thích (tùy chọn)',
      hint: 'Viết điều gì đó thật đáng nhớ...',
    );

    if (!mounted) {
      return;
    }

    await context.read<PhotoProvider>().addPhoto(
      pickedFile.path,
      caption: caption != null && caption.isNotEmpty ? caption : null,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thêm ảnh thành công!')),
    );
  }

  Future<void> _pickMultiplePhotos() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        if (mounted) {
          await context.read<PhotoProvider>().addPhoto(file.path);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${pickedFiles.length} ảnh!'),
          ),
        );
      }
    }
  }

  Future<void> _editCaption(Photo photo) async {
    final caption = await _showCaptionDialog(
      title: 'Chỉnh sửa chú thích',
      hint: 'Khoảnh khắc này đáng nhớ thế nào?',
      initialValue: photo.caption ?? '',
    );

    if (caption == null || !mounted) {
      return;
    }

    await context.read<PhotoProvider>().updatePhotoCaption(photo.id, caption);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật chú thích')),
    );
  }

  Future<void> _deletePhoto(Photo photo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh này?'),
        content: const Text('Khoảnh khắc này sẽ bị xóa khỏi nhật ký của hai bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await context.read<PhotoProvider>().deletePhoto(photo.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa ảnh')),
    );
  }

  String _formatFeedDate(DateTime date) {
    return DateFormat("dd 'thg' MM • HH:mm").format(date);
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
    if (!File(photo.path).existsSync()) {
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => _FullscreenPhotoPreview(
          photos: photos,
          heroTags: heroTags,
          initialIndex: initialIndex,
          coupleNames: couple == null
              ? 'Hai bạn'
              : '${couple.person1Name} & ${couple.person2Name}',
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
    final photoPath = couple?.couplePhotoPath;
    final hasPhoto = photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.9), width: 2),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.file(File(photoPath), fit: BoxFit.cover)
            : Center(
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
    );
  }

  Widget _buildFeedStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerCard(Couple? couple, int photoCount) {
    final title = couple == null
        ? 'Thêm một kỷ niệm mới hôm nay'
        : '${couple.person1Name} & ${couple.person2Name} hôm nay có gì mới?';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
            AppColors.surfaceLight,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCoupleAvatar(couple, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Biến thư viện thành một newfeed tình yêu thật riêng tư và đáng nhớ.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _pickAndAddPhoto,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentRose,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.add_a_photo_rounded),
                  label: const Text('Đăng ảnh mới'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickMultiplePhotos,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: AppColors.accentRose.withValues(alpha: 0.24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Thêm nhiều'),
                ),
              ),
            ],
          ),
        ],
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
        ? 'Cùng ngày này trong những năm trước, hai bạn đã lưu lại những khoảnh khắc này.'
        : 'Một dải story nhỏ để xem nhanh những khoảnh khắc mới nhất.';

    if (storyPhotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${storyPhotos.length}',
                style: TextStyle(
                  color: AppColors.accentRose,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: storyPhotos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
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
    final imageFile = File(photo.path);
    final hasPhoto = imageFile.existsSync();

    return GestureDetector(
      onTap: () => _openPhotoPreview(
        photos,
        initialIndex: index,
        couple: couple,
        heroTags: heroTags,
      ),
      child: Container(
        width: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
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
                          child: hasPhoto
                              ? Image.file(imageFile, fit: BoxFit.cover)
                              : DecoratedBox(
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
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isMemory ? 'Memory' : 'Mới',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                photo.caption?.trim().isNotEmpty == true
                    ? photo.caption!.trim()
                    : _formatShortDate(photo.uploadDate),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
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
        : 'Khoảnh khắc #${index + 1} được lưu lại cho hành trình yêu thương của hai bạn.';
    final hasPhoto = File(photo.path).existsSync();
    final coupleNames = couple == null
        ? 'Hai bạn'
        : '${couple.person1Name} & ${couple.person2Name}';
    final heroTag = _feedHeroTag(photo, index);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
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
                      Text(
                        coupleNames,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatFeedDate(photo.uploadDate),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (action) {
                    if (action == _PhotoFeedAction.editCaption) {
                      _editCaption(photo);
                      return;
                    }

                    _deletePhoto(photo);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _PhotoFeedAction.editCaption,
                      child: Text('Chỉnh sửa chú thích'),
                    ),
                    PopupMenuItem(
                      value: _PhotoFeedAction.delete,
                      child: Text('Xóa ảnh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasPhoto)
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
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
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
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  displayCaption,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.55,
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
                            color: AppColors.textSecondary.withValues(alpha: 0.18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Chỉnh sửa'),
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
                        label: const Text('Xóa'),
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
    final title = couple == null
        ? 'Bắt đầu tạo newfeed kỷ niệm'
        : 'Hãy đăng khoảnh khắc đầu tiên của ${couple.person1Name} & ${couple.person2Name}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
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
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Khi thêm ảnh, thư viện này sẽ trở thành một newfeed tình yêu riêng tư với những dòng thời gian thật dễ nhìn và cảm xúc.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _pickAndAddPhoto,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRose,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Đăng ảnh đầu tiên'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionCluster(double actionBottomOffset) {
    return Positioned(
      bottom: actionBottomOffset,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    onPressed: _pickMultiplePhotos,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accentCoral.withValues(alpha: 0.16),
                      foregroundColor: AppColors.accentCoral,
                    ),
                    icon: const Icon(Icons.collections_rounded),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    onPressed: _pickAndAddPhoto,
                    backgroundColor: AppColors.accentRose,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionBottomOffset = widget.bottomInset > 0
        ? widget.bottomInset - 8
        : 24.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<PhotoProvider, CoupleProvider>(
        builder: (context, photoProvider, coupleProvider, _) {
          final photos = photoProvider.sortedPhotos;
          final couple = coupleProvider.couple;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bgLight,
                  AppColors.surfaceLight.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thư Viện Ảnh',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Một newfeed riêng tư để lưu lại từng khoảnh khắc dịu dàng của hai bạn.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildComposerCard(couple, photos.length),
                            if (photos.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildStoryStripSection(couple, photos),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (photos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyFeedState(couple),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          widget.bottomInset + 88,
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
                _buildFloatingActionCluster(actionBottomOffset),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _PhotoFeedAction { editCaption, delete }

class _FullscreenPhotoPreview extends StatefulWidget {
  const _FullscreenPhotoPreview({
    required this.photos,
    required this.heroTags,
    required this.initialIndex,
    required this.coupleNames,
  });

  final List<Photo> photos;
  final List<String> heroTags;
  final int initialIndex;
  final String coupleNames;

  @override
  State<_FullscreenPhotoPreview> createState() => _FullscreenPhotoPreviewState();
}

class _FullscreenPhotoPreviewState extends State<_FullscreenPhotoPreview> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatFeedDate(DateTime date) {
    return DateFormat("dd 'thg' MM • HH:mm").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                final image = Image.file(
                  File(photo.path),
                  fit: BoxFit.contain,
                );

                final child = Center(
                  child: InteractiveViewer(
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
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.28),
                foregroundColor: AppColors.white,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
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
                    Text(
                      widget.coupleNames,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatFeedDate(currentPhoto.uploadDate),
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (currentPhoto.caption?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        currentPhoto.caption!.trim(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 124,
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
        ],
      ),
    );
  }
}

