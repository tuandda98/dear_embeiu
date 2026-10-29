import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Pill segmented control (design expenses §3.2, §8): a white thumb slides
/// under the selected label (260ms easeInOutCubic, jumps under Reduce
/// Motion). The selection is set at once; the thumb only follows (UI UX Pro
/// Max "Cancellable State Transitions").
///
/// Same look as the mode bars of `setup_screen` / `decision_wheel_screen`,
/// which still draw their own copy — moving them here is a later cleanup.
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.height = 48,
    this.onSurface = false,
    this.enabled = true,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;
  final double height;

  /// Inside a white sheet: `surfaceLight` track instead of the frosted one.
  final bool onSurface;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    final index = values.indexOf(selected).clamp(0, values.length - 1);
    return LayoutBuilder(
      builder: (context, constraints) {
        const inset = 4.0;
        final width = (constraints.maxWidth - inset * 2) / values.length;
        // No padding on the track: the segments' tap areas run the full
        // pill height (44+, UI UX Pro Max "Touch Target Size"); only the
        // thumb and the labels keep the 4 inset.
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: onSurface
                ? AppColors.surfaceLight
                : AppColors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: onSurface
                ? null
                : Border.all(color: AppColors.white.withValues(alpha: 0.65)),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                left: inset + width * index,
                top: inset,
                bottom: inset,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      // The end cells take the side inset too, so each
                      // label stays centred on its thumb.
                      child: _segment(
                        context,
                        values[i],
                        values[i] == selected,
                        EdgeInsets.only(
                          left: i == 0 ? inset : 0,
                          right: i == values.length - 1 ? inset : 0,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segment(
    BuildContext context,
    T value,
    bool isSelected,
    EdgeInsets edge,
  ) {
    final ink = isSelected
        ? AppColors.textPrimary
        : AppColors.textPrimary.withValues(alpha: 0.72);
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.accentRose.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          onTap: !enabled || isSelected ? null : () => onChanged(value),
          child: Padding(
            padding: edge,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labelOf(value),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
