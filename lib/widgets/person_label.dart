import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Coloured dot + micro-caps name (names never take the person colour).
class PersonLabel extends StatelessWidget {
  const PersonLabel({
    super.key,
    required this.name,
    required this.color,
    this.alignment = MainAxisAlignment.start,
  });

  final String name;
  final Color color;

  /// Where the label sits in its lane (the mood card centres it).
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
