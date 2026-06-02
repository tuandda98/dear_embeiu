import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// A rounded placeholder box with a soft, brand-aligned shimmer sweep.
///
/// Use it to replace [CircularProgressIndicator] / blank loading states with
/// content-shaped skeletons in a later pass.
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
  });

  /// Expands to fill the parent's constraints (no intrinsic size).
  ///
  /// Handy as an image-loading placeholder inside a clipped box
  /// ([ClipRRect] / [ClipOval] / [AspectRatio]) where the parent already
  /// enforces the shape, so the corner radius can stay flat.
  const ShimmerSkeleton.fill({
    super.key,
    this.borderRadius = 0,
  })  : width = null,
        height = null;

  /// Box width. Null lets it expand to the parent's constraints.
  final double? width;

  /// Box height. Null lets it expand to the parent's constraints.
  final double? height;

  /// Corner radius of the skeleton box.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // Light, romantic tones rather than the default grey.
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.white,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
