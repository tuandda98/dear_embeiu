import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:io';
import '../models/photo.dart';
import '../theme/app_colors.dart';
import 'photo_item.dart';

class MasonryGallery extends StatelessWidget {
  final List<Photo> photos;
  final VoidCallback? onPhotoTap;
  final Function(String photoId)? onDeletePhoto;

  const MasonryGallery({
    Key? key,
    required this.photos,
    this.onPhotoTap,
    this.onDeletePhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có ảnh nào',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Thêm ảnh để bắt đầu tạo kỷ niệm',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return PhotoItem(
          photoPath: photo.path,
          caption: photo.caption,
          onTap: onPhotoTap,
          onDelete: onDeletePhoto != null
              ? () => onDeletePhoto!(photo.id)
              : null,
        );
      },
    );
  }
}

