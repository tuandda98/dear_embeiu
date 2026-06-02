import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/photo.dart';
import '../theme/app_colors.dart';
import 'shimmer_skeleton.dart';

class SharedPhotoView extends StatelessWidget {
  const SharedPhotoView({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final Photo photo;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    if (photo.hasLocalPath && File(photo.path).existsSync()) {
      return Image.file(
        File(photo.path),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (photo.hasRemoteUrl) {
      return CachedNetworkImage(
        imageUrl: photo.remoteUrl!,
        fit: fit,
        placeholder: (context, url) => _buildLoading(),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildLoading() {
    // Content-shaped shimmer; the parent clip enforces the final shape.
    return const ShimmerSkeleton.fill();
  }

  Widget _buildFallback() {
    return placeholder ??
        Container(
          color: AppColors.surfaceLight,
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.imageOff,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        );
  }
}

