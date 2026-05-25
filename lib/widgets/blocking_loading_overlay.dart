import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
                color: Colors.black.withOpacity( 0.18),
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
                      color: Colors.black.withOpacity( 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: AppColors.accentRose,
                      ),
                    ),
                    if (message?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text(
                        message!.trim(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
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

