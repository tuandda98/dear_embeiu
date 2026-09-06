import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';

// ─── Public API ───────────────────────────────────────────────────────────────

/// Drop-in replacement for [showTimePicker].
/// Shows a scroll-wheel bottom sheet styled to the Sunset Romance brand.
Future<TimeOfDay?> showAppTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String title = 'Chọn giờ nhắc',
  String subtitle = 'Kéo để chọn giờ và phút',
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    builder: (_) => _AppTimePickerSheet(
      initialTime: initialTime,
      title: title,
      subtitle: subtitle,
    ),
  );
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _AppTimePickerSheet extends StatefulWidget {
  const _AppTimePickerSheet({
    required this.initialTime,
    required this.title,
    required this.subtitle,
  });

  final TimeOfDay initialTime;
  final String title;
  final String subtitle;

  @override
  State<_AppTimePickerSheet> createState() => _AppTimePickerSheetState();
}

class _AppTimePickerSheetState extends State<_AppTimePickerSheet> {
  static const double _itemH = 54;
  static const int _visibleItems = 5;

  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minCtrl;

  // ValueNotifiers so only the changed label rebuilds, not the whole sheet.
  late final ValueNotifier<int> _hourNotifier;
  late final ValueNotifier<int> _minNotifier;

  @override
  void initState() {
    super.initState();
    _hourNotifier = ValueNotifier(widget.initialTime.hour);
    _minNotifier = ValueNotifier(widget.initialTime.minute);
    _hourCtrl = FixedExtentScrollController(
      initialItem: widget.initialTime.hour,
    );
    _minCtrl = FixedExtentScrollController(
      initialItem: widget.initialTime.minute,
    );
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _hourNotifier.dispose();
    _minNotifier.dispose();
    super.dispose();
  }

  void _onHourChanged(int i) {
    _hourNotifier.value = i;
    HapticFeedback.selectionClick();
  }

  void _onMinChanged(int i) {
    _minNotifier.value = i;
    HapticFeedback.selectionClick();
  }

  void _confirm() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(
      TimeOfDay(
        hour: _hourNotifier.value,
        minute: _minNotifier.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Handle(),
          const SizedBox(height: 22),
          _Header(title: widget.title, subtitle: widget.subtitle),
          const SizedBox(height: 28),
          _WheelArea(
            hourCtrl: _hourCtrl,
            minCtrl: _minCtrl,
            hourNotifier: _hourNotifier,
            minNotifier: _minNotifier,
            itemH: _itemH,
            visibleItems: _visibleItems,
            onHourChanged: _onHourChanged,
            onMinChanged: _onMinChanged,
          ),
          const SizedBox(height: 28),
          _Footer(onCancel: () => Navigator.of(context).pop(), onConfirm: _confirm),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.sunsetRomance,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [AppColors.softCardShadow(opacity: 0.18)],
            ),
            child: const Icon(
              IconsaxPlusBold.clock,
              size: 22,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      );
}

class _WheelArea extends StatelessWidget {
  const _WheelArea({
    required this.hourCtrl,
    required this.minCtrl,
    required this.hourNotifier,
    required this.minNotifier,
    required this.itemH,
    required this.visibleItems,
    required this.onHourChanged,
    required this.onMinChanged,
  });

  final FixedExtentScrollController hourCtrl;
  final FixedExtentScrollController minCtrl;
  final ValueNotifier<int> hourNotifier;
  final ValueNotifier<int> minNotifier;
  final double itemH;
  final int visibleItems;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinChanged;

  @override
  Widget build(BuildContext context) {
    final totalH = itemH * visibleItems;

    return SizedBox(
      height: totalH,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection highlight band
          Positioned(
            top: (totalH - itemH) / 2,
            left: 0,
            right: 0,
            child: Container(
              height: itemH,
              decoration: BoxDecoration(
                color: AppColors.accentLove.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentLove.withValues(alpha: 0.14),
                  width: 1.2,
                ),
              ),
            ),
          ),
          // Wheels row
          Row(
            children: [
              // Hours
              Expanded(
                child: _Wheel(
                  controller: hourCtrl,
                  count: 24,
                  notifier: hourNotifier,
                  itemH: itemH,
                  onChanged: onHourChanged,
                ),
              ),
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
              ),
              // Minutes
              Expanded(
                child: _Wheel(
                  controller: minCtrl,
                  count: 60,
                  notifier: minNotifier,
                  itemH: itemH,
                  onChanged: onMinChanged,
                ),
              ),
            ],
          ),
          // Top & bottom fade overlays for depth
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: itemH * 1.5,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.cardSurface,
                      AppColors.cardSurface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: itemH * 1.5,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.cardSurface,
                      AppColors.cardSurface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.count,
    required this.notifier,
    required this.itemH,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int count;
  final ValueNotifier<int> notifier;
  final double itemH;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemH,
      perspective: 0.002,
      diameterRatio: 2.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (_, index) => ValueListenableBuilder<int>(
          valueListenable: notifier,
          builder: (context2, selected, child) {
            final isSelected = selected == index;
            return Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color: isSelected
                      ? AppColors.accentLove
                      : AppColors.textPrimary.withValues(alpha: 0.28),
                  fontSize: isSelected ? 30 : 22,
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w400,
                  height: 1,
                ),
                child: Text(index.toString().padLeft(2, '0')),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onCancel, required this.onConfirm});
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          // Cancel — ghost
          Expanded(
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: AppColors.textPrimary.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: const Text(
                'Huỷ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Confirm — rose filled pill
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.sunsetRomance,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [AppColors.softCardShadow(opacity: 0.22)],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onConfirm,
                  borderRadius: BorderRadius.circular(999),
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  child: const SizedBox(
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconsaxPlusBold.tick_circle,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Xác nhận',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
