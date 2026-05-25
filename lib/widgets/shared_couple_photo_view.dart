import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SharedCouplePhotoView extends StatelessWidget {
  const SharedCouplePhotoView({
    super.key,
    required this.localPath,
    this.remoteUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final String? localPath;
  final String? remoteUrl;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final normalizedLocalPath = localPath?.trim();
    if (normalizedLocalPath != null &&
        normalizedLocalPath.isNotEmpty &&
        File(normalizedLocalPath).existsSync()) {
      return Image.file(
        File(normalizedLocalPath),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    final normalizedRemoteUrl = remoteUrl?.trim();
    if (normalizedRemoteUrl != null && normalizedRemoteUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: normalizedRemoteUrl,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _buildLoading(),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildLoading() {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2.2),
    );
  }

  Widget _buildFallback() {
    return placeholder ??
        Container(
          color: AppColors.surfaceLight,
          alignment: Alignment.center,
          child: Icon(
            Icons.favorite_rounded,
            color: AppColors.textSecondary.withOpacity( 0.5),
          ),
        );
  }
}

