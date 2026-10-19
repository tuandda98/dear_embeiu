/// No Dart API: the app talks to `MethodChannel('dear_embeiu/widget')`
/// directly (lib/services/home_widget_bridge.dart). This package only exists
/// so the Android handler is registered by GeneratedPluginRegistrant in EVERY
/// FlutterEngine — including the one firebase_messaging starts for the
/// background handler, where MainActivity.configureFlutterEngine never runs.
library;
