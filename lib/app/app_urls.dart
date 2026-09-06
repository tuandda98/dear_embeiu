abstract final class AppUrls {
  static const privacyPolicy =
      'https://tuandda98.github.io/dear_embeiu/privacy-policy.html';

  /// Store links for the force-update screen. The live URL is read from the
  /// `config/app` Firestore doc (`iosStoreUrl` / `androidStoreUrl`); these are
  /// the fallbacks if that field is missing — both filled so the "Update" button
  /// never no-ops even when the config doc omits a URL (Tester F1, 2026-06-20).
  /// App Store id 6775165592 (app is live; iTunes lookup 2026-06-20).
  static const androidStore =
      'https://play.google.com/store/apps/details?id=com.tony.dearembeiu';
  static const iosStore = 'https://apps.apple.com/app/id6775165592';
}
