import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'animated_couple_name.dart';

class CoupleInfoCard extends StatelessWidget {
  const CoupleInfoCard({
    super.key,
    required this.person1Name,
    required this.person2Name,
    this.couplePhotoPath,
    this.onTap,
  });

  final String person1Name;
  final String person2Name;
  final String? couplePhotoPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        couplePhotoPath != null && couplePhotoPath!.isNotEmpty && File(couplePhotoPath!).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGradientStart.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                  image: hasPhoto
                      ? DecorationImage(
                          image: FileImage(File(couplePhotoPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: AppColors.white.withValues(alpha: 0.3),
                ),
                child: hasPhoto
                    ? null
                    : Icon(
                        Icons.favorite,
                        color: AppColors.white.withValues(alpha: 0.6),
                        size: 40,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedCoupleName(
                  person1Name: person1Name,
                  person2Name: person2Name,
                  spacing: 6,
                  runSpacing: 6,
                  heartSize: 16,
                  heartColor: AppColors.white,
                  textStyle: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.edit,
                color: AppColors.white.withValues(alpha: 0.7),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
