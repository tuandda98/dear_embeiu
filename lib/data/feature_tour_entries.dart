import 'package:flutter/widgets.dart';
import '../screens/care_message_screen.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../l10n/app_localizations.dart';

/// One row of the "What's new" feature tour (feature: onboarding, 2026-09-05).
///
/// The tour is version-based and re-usable for every release: each entry
/// declares the build number it shipped in ([sinceBuild]) and the sheet only
/// shows the entries the user has not seen yet (`seen < sinceBuild <= current`).
///
/// Copy is resolved lazily through [AppLocalizations] so the list can stay a
/// top-level constant-ish value while still following the app language.
class FeatureTourEntry {
  const FeatureTourEntry({
    required this.sinceBuild,
    required this.icon,
    required this.title,
    required this.body,
    this.targetTab,
    this.onOpen,
  });

  /// Build number (`pubspec` `+N`) this feature shipped in.
  final int sinceBuild;

  final IconData icon;

  /// Localized title / body resolvers (no BuildContext needed at declaration).
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) body;

  /// Optional Home tab index (Home 0 · Chat 1 · Gallery 2 · Profile 3) — when
  /// set the row becomes tappable and jumps straight to the feature.
  final int? targetTab;

  /// Optional direct action (push a screen). Takes precedence over
  /// [targetTab] and works from Settings, where there is no tab bar.
  final void Function(BuildContext context)? onOpen;
}

/// The tour catalogue, oldest first.
///
/// To announce a new release: append entries with the NEW build number, nothing
/// else to wire up — [FeatureTour.maybeShow] picks them up automatically.
final List<FeatureTourEntry> featureTourEntries = <FeatureTourEntry>[
  // ---- Build 20 (1.6.0) ----------------------------------------------------
  FeatureTourEntry(
    sinceBuild: 20,
    icon: IconsaxPlusLinear.message_favorite,
    title: (l10n) => l10n.featureTourCareTitle,
    body: (l10n) => l10n.featureTourCareBody,
    onOpen: openCareMessageScreen,
  ),
  FeatureTourEntry(
    sinceBuild: 20,
    icon: IconsaxPlusLinear.message_question,
    title: (l10n) => l10n.featureTourQuestionsTitle,
    body: (l10n) => l10n.featureTourQuestionsBody,
  ),
  FeatureTourEntry(
    sinceBuild: 20,
    icon: IconsaxPlusLinear.user_add,
    title: (l10n) => l10n.featureTourInviteTitle,
    body: (l10n) => l10n.featureTourInviteBody,
  ),
];
