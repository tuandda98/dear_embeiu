import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

// To add a new language: append an entry to _kLanguages below.
const _kLanguages = [
  _Language(code: null,  flag: '🌐', label: 'System default'),
  _Language(code: 'en',  flag: '🇺🇸', label: 'English'),
  _Language(code: 'vi',  flag: '🇻🇳', label: 'Tiếng Việt'),
];

class _Language {
  const _Language({required this.code, required this.flag, required this.label});
  final String? code;
  final String flag;
  final String label;
}

/// Compact language picker button — tapping opens a bottom sheet list.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key, this.onDark = true});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleProvider>().locale;
    final selected = _kLanguages.firstWhere(
      (l) => l.code == current?.languageCode,
      orElse: () => _kLanguages.first,
    );

    final fgColor = onDark ? AppColors.white : AppColors.textPrimary;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: onDark
              ? AppColors.white.withValues(alpha: 0.14)
              : AppColors.textPrimary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: onDark
                ? AppColors.white.withValues(alpha: 0.22)
                : AppColors.textPrimary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected.flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              selected.code?.toUpperCase() ?? '—',
              style: TextStyle(
                color: fgColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded, size: 14, color: fgColor.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final provider = context.read<LocaleProvider>();
    final current = provider.locale?.languageCode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguageSheet(
        currentCode: current,
        onSelect: (lang) {
          if (lang.code == null) {
            provider.useSystemLocale();
          } else {
            provider.setLocale(Locale(lang.code!));
          }
        },
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.currentCode, required this.onSelect});

  final String? currentCode;
  final void Function(_Language) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.language_rounded, size: 18, color: AppColors.accentRose),
                const SizedBox(width: 8),
                Text(
                  'Language',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final lang in _kLanguages) ...[
            _LanguageTile(
              lang: lang,
              isSelected: lang.code == currentCode,
              onTap: () {
                Navigator.pop(context);
                onSelect(lang);
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.lang,
    required this.isSelected,
    required this.onTap,
  });

  final _Language lang;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentRose.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accentRose.withValues(alpha: 0.22)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                lang.label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.accentRose, size: 20),
          ],
        ),
      ),
    );
  }
}
