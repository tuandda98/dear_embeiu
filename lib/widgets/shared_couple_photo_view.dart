import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'shimmer_skeleton.dart';

class SharedCouplePhotoView extends StatelessWidget {
  const SharedCouplePhotoView({
    super.key,
    required this.localPath,
    this.remoteUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.decodeWidth,
    this.decodeHeight,
  });

  final String? localPath;
  final String? remoteUrl;
  final BoxFit fit;
  final Widget? placeholder;

  /// Target decode width in *physical* pixels for avatar-sized call-sites
  /// (pass `logicalSize * devicePixelRatio`). Avoids decoding a full-res couple
  /// photo into a 42–80px circle. `null` keeps the image full-res.
  final int? decodeWidth;
  final int? decodeHeight;

  @override
  Widget build(BuildContext context) {
    // Prefer the remote (cached) image when present — skips the synchronous
    // existsSync() stat on every build for the common Firebase flow.
    final normalizedRemoteUrl = remoteUrl?.trim();
    if (normalizedRemoteUrl != null && normalizedRemoteUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: normalizedRemoteUrl,
        fit: fit,
        memCacheWidth: decodeWidth,
        memCacheHeight: decodeHeight,
        placeholder: (context, url) => _buildLoading(),
        errorWidget: (context, url, error) => _buildLocalOrFallback(),
      );
    }

    return _buildLocalOrFallback();
  }

  Widget _buildLocalOrFallback() {
    final normalizedLocalPath = localPath?.trim();
    if (normalizedLocalPath != null &&
        normalizedLocalPath.isNotEmpty &&
        File(normalizedLocalPath).existsSync()) {
      return Image.file(
        File(normalizedLocalPath),
        fit: fit,
        cacheWidth: decodeWidth,
        cacheHeight: decodeHeight,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildLoading() {
    // Content-shaped shimmer; the parent clip (ClipOval) enforces the shape.
    return const ShimmerSkeleton.fill();
  }

  Widget _buildFallback() {
    return placeholder ??
        Container(
          color: AppColors.surfaceLight,
          alignment: Alignment.center,
          child: Icon(
            Icons.favorite_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        );
  }
}
