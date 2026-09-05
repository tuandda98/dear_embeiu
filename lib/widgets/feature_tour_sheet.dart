import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/feature_tour_entries.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'entrance_reveal.dart';
import 'eyebrow_chip.dart';
import 'icon_badge.dart';

/// "Có gì mới" — version-based feature tour (feature: onboarding, 2026-09-05).
///
/// Shows ONCE per build: the last seen build number lives in the shared
/// `app_settings` Hive box (stored as a String because that box is opened as
/// `Box<String>` by `main()` / LocaleProvider). A fresh install only records
/// the current build and shows nothing — the tour must never stack on top of
/// the first-run intro.
///
/// Everything is fail-soft: any Hive / package_info problem simply skips the
/// sheet.
class FeatureTour {
  const FeatureTour._();

  static const String _boxName = 'app_settings';
  static const String _seenKey = 'feature_tour_seen_build';

  /// Called post-frame from Home. Shows the entries released between the last
  /// seen build and the current one, then records the current build.
  static Future<void> maybeShow(
    BuildContext context, {
    void Function(int tab)? onOpenTab,
  }) async {
    final info = await _packageInfo();
    if (info == null) {
      return;
    }
    final current = int.tryParse(info.buildNumber) ?? 0;
    if (current <= 0) {
      return;
    }

    final Box<String> box;
    try {
      box = Hive.isBoxOpen(_boxName)
          ? Hive.box<String>(_boxName)
          : await Hive.openBox<String>(_boxName);
    } catch (_) {
      return;
    }

    final seen = int.tryParse(box.get(_seenKey) ?? '');
    if (seen == null) {
      // First run after install (or after a cache wipe) — remember where we are
      // and stay quiet.
      await _remember(box, current);
      return;
    }
    if (seen >= current) {
      return;
    }

    final entries = featureTourEntries
        .where((e) => e.sinceBuild > seen && e.sinceBuild <= current)
        .toList();
    await _remember(box, current);

    if (entries.isEmpty || !context.mounted) {
      return;
    }
    await _open(context, entries, info.version, onOpenTab);
  }

  /// Manual entry point (Settings → "Có gì mới") — always shows every entry.
  static Future<void> showAll(
    BuildContext context, {
    void Function(int tab)? onOpenTab,
  }) async {
    final info = await _packageInfo();
    if (!context.mounted) {
      return;
    }
    // Opening it by hand also counts as "seen" for the current build.
    final current = int.tryParse(info?.buildNumber ?? '') ?? 0;
    if (current > 0) {
      try {
        final box = Hive.isBoxOpen(_boxName)
            ? Hive.box<String>(_boxName)
            : await Hive.openBox<String>(_boxName);
        await _remember(box, current);
      } catch (_) {
        // Cosmetic only.
      }
    }
    if (!context.mounted || featureTourEntries.isEmpty) {
      return;
    }
    await _open(context, featureTourEntries, info?.version, onOpenTab);
  }

  static Future<PackageInfo?> _packageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _remember(Box<String> box, int build) async {
    try {
      await box.put(_seenKey, '$build');
    } catch (_) {
      // Best-effort — worst case the sheet shows again next launch.
    }
  }

  static Future<void> _open(
    BuildContext context,
    List<FeatureTourEntry> entries,
    String? version,
    void Function(int tab)? onOpenTab,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeatureTourSheet(
        entries: entries,
        version: version,
        onOpenTab: onOpenTab,
      ),
    );
  }
}

class _FeatureTourSheet extends StatelessWidget {
  const _FeatureTourSheet({
    required this.entries,
    required this.version,
    required this.onOpenTab,
  });

  final List<FeatureTourEntry> entries;
  final String? version;
  final void Function(int tab)? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(child: EyebrowChip(label: l10n.featureTourBadge)),
            if (version != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.featureTourVersionTitle(version!),
                textAlign: TextAlign.center,
                style: AppTheme.displaySerif(
                  size: 20,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      EntranceReveal(
                        order: i,
                        child: _EntryRow(
                          entry: entries[i],
                          l10n: l10n,
                          onTap: entries[i].targetTab == null
                              ? null
                              : () {
                                  final tab = entries[i].targetTab!;
                                  Navigator.of(context).pop();
                                  onOpenTab?.call(tab);
                                },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.featureTourGotIt),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.l10n, this.onTap});

  final FeatureTourEntry entry;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(entry.icon, tint: AppColors.accentLavender),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title(l10n),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  entry.body(l10n),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );

    final decorated = Container(
      decoration: BoxDecoration(
        color: AppColors.accentLavender.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accentLavender.withValues(alpha: 0.10),
        ),
      ),
      child: content,
    );

    if (onTap == null) {
      return decorated;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
        child: decorated,
      ),
    );
  }
}
