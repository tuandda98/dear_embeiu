import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'shimmer_skeleton.dart';

class BlockingLoadingOverlay extends StatelessWidget {
  const BlockingLoadingOverlay({
    super.key,
    required this.isVisible,
    this.message,
    required this.child,
  });

  final bool isVisible;
  final String? message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isVisible) ...[
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                color: Colors.black.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 240),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shimmer bars replace the spinner for a modern feel
                    // while keeping the blocking overlay mechanism intact.
                    const ShimmerSkeleton(
                      width: 180,
                      height: 12,
                      borderRadius: 999,
                    ),
                    const SizedBox(height: 10),
                    const ShimmerSkeleton(
                      width: 120,
                      height: 12,
                      borderRadius: 999,
                    ),
                    if (message?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 14),
                      Text(
                        message!.trim(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

