abstract final class AppUrls {
  static const privacyPolicy =
      'https://tuandda98.github.io/dear_embeiu/privacy-policy.html';

  /// Store links for the force-update screen. The live URL is read from the
  /// `config/app` Firestore doc (`iosStoreUrl` / `androidStoreUrl`); these are
  /// only the fallbacks if that field is missing. Play is derivable from the
  /// package id; the App Store one needs the numeric app id — fill it in once
  /// the app is live (until then set `iosStoreUrl` in the config doc directly).
  static const androidStore =
      'https://play.google.com/store/apps/details?id=com.tony.dearembeiu';
  static const iosStore = '';
}
