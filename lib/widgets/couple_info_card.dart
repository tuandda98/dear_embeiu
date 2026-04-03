import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_colors.dart';

class CoupleInfoCard extends StatelessWidget {
  final String person1Name;
  final String person2Name;
  final String? couplePhotoPath;
  final VoidCallback? onTap;

  const CoupleInfoCard({
    Key? key,
    required this.person1Name,
    required this.person2Name,
    this.couplePhotoPath,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGradientStart.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              // Photo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                  image: couplePhotoPath != null && File(couplePhotoPath!).existsSync()
                      ? DecorationImage(
                          image: FileImage(File(couplePhotoPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: AppColors.white.withOpacity(0.3),
                ),
                child: couplePhotoPath == null
                    ? Icon(
                        Icons.favorite,
                        color: AppColors.white.withOpacity(0.6),
                        size: 40,
                      )
                    : null,
              ),
              SizedBox(width: 16),
              // Names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person1Name,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '&',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      person2Name,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit,
                color: AppColors.white.withOpacity(0.7),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

