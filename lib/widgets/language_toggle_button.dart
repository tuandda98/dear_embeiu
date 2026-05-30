import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

/// Single source of truth for the languages the app offers.
///
/// To add a language later:
///   1. Add its `Locale('xx')` to `supportedLocales` in `main.dart`.
///   2. Add its translations (this repo hand-maintains the generated
///      `lib/l10n/app_localizations_xx.dart` + a `case 'xx'` in the lookup).
///   3. Append ONE entry below — the pill, the picker and the profile row all
///      read from this list, so the UI updates itself. The picker also grows a
///      search field automatically once there are more than [_kSearchThreshold]
///      languages.
const List<AppLanguage> kAppLanguages = [
  AppLanguage(code: null, flag: '🌐', endonym: ''), // system default
  AppLanguage(code: 'en', flag: '🇺🇸', endonym: 'English'),
  AppLanguage(code: 'vi', flag: '🇻🇳', endonym: 'Tiếng Việt'),
];

/// Show the search field once the list grows past this many languages.
const int _kSearchThreshold = 6;

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.flag,
    required this.endonym,
  });

  /// BCP-47 language code, or null for "follow the device language".
  final String? code;
  final String flag;

  /// The language's name in its own language (e.g. "Tiếng Việt"). Empty for the
  /// system-default entry, whose label is localized at render time. Showing the
  /// endonym (not a translation) is best practice — users find their language
  /// regardless of the current app language.
  final String endonym;
}

/// Display label for [lang]: its endonym, or the localized "System default".
String appLanguageLabel(AppLanguage lang, AppLocalizations l10n) =>
    lang.code == null ? l10n.languageSystem : lang.endonym;

/// The [AppLanguage] currently in effect for [locale].
AppLanguage currentAppLanguage(Locale? locale) => kAppLanguages.firstWhere(
      (l) => l.code == locale?.languageCode,
      orElse: () => kAppLanguages.first,
    );

/// Opens the shared language picker bottom sheet. Reused by the auth-screen
/// pill and the profile language row so there is one picker to maintain.
Future<void> showLanguagePicker(BuildContext context) {
  final provider = context.read<LocaleProvider>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _LanguageSheet(
      currentCode: provider.locale?.languageCode,
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

/// Compact language pill — tapping opens the shared picker. Used on the auth
/// screens (top-right corner).
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key, this.onDark = true});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final selected = currentAppLanguage(context.watch<LocaleProvider>().locale);
    final fgColor = onDark ? AppColors.white : AppColors.textPrimary;

    return GestureDetector(
      onTap: () => showLanguagePicker(context),
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
            Icon(Icons.expand_more_rounded,
                size: 14, color: fgColor.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({required this.currentCode, required this.onSelect});

  final String? currentCode;
  final void Function(AppLanguage) onSelect;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mediaQuery = MediaQuery.of(context);
    final showSearch = kAppLanguages.length > _kSearchThreshold;

    final query = _query.trim().toLowerCase();
    final langs = query.isEmpty
        ? kAppLanguages
        : kAppLanguages.where((l) {
            final label = appLanguageLabel(l, l10n).toLowerCase();
            return label.contains(query) ||
                (l.code?.toLowerCase().contains(query) ?? false);
          }).toList();

    return Container(
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 12 + mediaQuery.viewInsets.bottom,
      ),
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.7),
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
                  l10n.languageTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (showSearch) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  hintText: l10n.languageSearchHint,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: langs.length,
              itemBuilder: (context, index) {
                final lang = langs[index];
                return _LanguageTile(
                  lang: lang,
                  label: appLanguageLabel(lang, l10n),
                  isSelected: lang.code == widget.currentCode,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelect(lang);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 8 + mediaQuery.padding.bottom),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.lang,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final AppLanguage lang;
  final String label;
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
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.accentRose, size: 20),
          ],
        ),
      ),
    );
  }
}
