import 'package:flutter/widgets.dart';

/// App-wide page-route observer (feature rps-game, Tester RPS-3): lets a
/// screen learn when another PAGE covers it (`didPushNext`) or uncovers it
/// again (`didPopNext`) via [RouteAware]. Typed on [PageRoute] on purpose —
/// dialogs / bottom sheets over a screen don't count as "left the screen".
///
/// Registered once in `MaterialApp.navigatorObservers` (main.dart). A screen
/// subscribes in `didChangeDependencies` and unsubscribes in `dispose`.
final RouteObserver<PageRoute<dynamic>> appPageRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
