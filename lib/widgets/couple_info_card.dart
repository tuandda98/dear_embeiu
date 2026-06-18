import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';
import 'animated_couple_name.dart';
import 'shared_couple_photo_view.dart';

/// Soft white card showing the couple photo + names with a faint Dawn Blush
/// glow underneath. Sits beneath the hero counter on the home screen.
class CoupleInfoCard extends StatelessWidget {
  const CoupleInfoCard({
    super.key,
    required this.person1Name,
    required this.person2Name,
    this.couplePhotoPath,
    this.couplePhotoUrl,
    this.onTap,
  });

  final String person1Name;
  final String person2Name;
  final String? couplePhotoPath;
  final String? couplePhotoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.sunset1.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.dawnBlush,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sunset1.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: SharedCouplePhotoView(
                    localPath: couplePhotoPath,
                    remoteUrl: couplePhotoUrl,
                    fit: BoxFit.cover,
                    // 64px avatar → decode ≈ 64 * DPR.
                    decodeWidth:
                        (64 * MediaQuery.of(context).devicePixelRatio).round(),
                    placeholder: Container(
                      color: AppColors.surfaceLight,
                      child: const Icon(
                        IconsaxPlusBold.heart,
                        color: AppColors.accentLove,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our story',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedCoupleName(
                      person1Name: person1Name,
                      person2Name: person2Name,
                      spacing: 6,
                      runSpacing: 4,
                      heartSize: 12,
                      heartColor: AppColors.accentLove,
                      textStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLight,
                ),
                child: const Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
