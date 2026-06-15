import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../models/photo.dart';
import '../theme/app_colors.dart';
import 'shimmer_skeleton.dart';

class SharedPhotoView extends StatelessWidget {
  const SharedPhotoView({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.decodeWidth,
    this.decodeHeight,
  });

  final Photo photo;
  final BoxFit fit;
  final Widget? placeholder;

  /// Target decode width in *physical* pixels. Thumbnail call-sites should pass
  /// `logicalSize * devicePixelRatio` so a 4000px source isn't decoded at full
  /// resolution into a 64–140px slot (RAM/jank/OOM). Pass `null` for
  /// fullscreen/zoom previews to keep the image full-res.
  final int? decodeWidth;
  final int? decodeHeight;

  @override
  Widget build(BuildContext context) {
    // Prefer the remote (cached) image when present — avoids a synchronous
    // existsSync() stat on every build for the common Firebase flow.
    if (photo.hasRemoteUrl) {
      return CachedNetworkImage(
        imageUrl: photo.remoteUrl!,
        fit: fit,
        memCacheWidth: decodeWidth,
        memCacheHeight: decodeHeight,
        placeholder: (context, url) => _buildLoading(),
        errorWidget: (context, url, error) => _buildLocalOrFallback(),
      );
    }

    return _buildLocalOrFallback();
  }

  // Renders a local file (decoded to the requested cache size) when one exists,
  // otherwise the fallback. Only stats the filesystem when there is no usable
  // remote URL, so the hot Firebase path never blocks on existsSync().
  Widget _buildLocalOrFallback() {
    if (photo.hasLocalPath && File(photo.path).existsSync()) {
      return Image.file(
        File(photo.path),
        fit: fit,
        cacheWidth: decodeWidth,
        cacheHeight: decodeHeight,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
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
            IconsaxPlusLinear.gallery_remove,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        );
  }
}
