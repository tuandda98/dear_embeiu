import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_l10n.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/couple_provider.dart';
import 'providers/custom_reminders_provider.dart';
import 'providers/daily_question_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_inbox_provider.dart';
import 'providers/partner_reminder_provider.dart';
import 'providers/photo_provider.dart';
import 'providers/reaction_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/streak_provider.dart';
import 'screens/force_update_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/guest_counter_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/session_route_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_bootstrap_service.dart';
import 'services/install_state_service.dart';
import 'services/push_notification_service.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw edge-to-edge so the app's pink gradient fills the whole screen
  // (incl. the bottom home-indicator / Android nav-bar area) instead of
  // leaving a black bar there. System bars are made transparent with dark
  // icons to suit the light pink backgrounds.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await Hive.initFlutter();

  // Initialise locale-aware date formatting once, up front. DateFormat.yMMMd
  // (and friends) throw for non-en locales unless their symbols have been
  // loaded, so this must run before any localized DateFormat is used.
  await initializeDateFormatting();

  // Gap D — preload the saved locale BEFORE runApp so a returning user goes
  // straight into their chosen language without a frame of the wrong one.
  final initialLocale = await _readSavedLocale();

  final authService = AuthService();

  // Robustness (app-robustness A7): only the work the very first frame depends
  // on runs before runApp — Firebase (for the Crashlytics hook + so providers
  // see it ready), the FCM background-message handler (must be registered early
  // on the main isolate or terminated-state pushes are dropped), and the
  // fresh-install purge (must finish BEFORE the splash resolves a route, or a
  // reinstall could restore the previous install's session). Everything else —
  // analytics binding, push permission/token sync, the local-notification
  // engine, custom-reminder rescheduling — is deferred to just after the first
  // frame so the splash paints immediately instead of waiting on a slow network.
  await FirebaseBootstrapService.initialize();

  if (!kIsWeb && FirebaseBootstrapService.isFirebaseReady) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final bool isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (isMobile) {
    // Register synchronously (no network) before runApp so a tap-to-open from a
    // terminated state isn't missed; the heavier PushNotificationService.init
    // (permission prompt + getToken) is deferred below.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Built here (not lazily) so it survives into MyApp; loaded/rescheduled after
  // the first frame so it never blocks cold start.
  final customRemindersProvider = CustomRemindersProvider();

  // Correctness-critical: the reinstall purge must complete before the splash
  // resolves a route, so it stays on the pre-runApp path.
  await InstallStateService().handleFreshInstall(
    onFreshInstall: () => authService.purgePersistedSession(),
  );

  runApp(MyApp(
    authService: authService,
    initialLocale: initialLocale,
    customRemindersProvider: customRemindersProvider,
  ));

  // Deferred, non-route-critical bootstrap — runs after the first frame so the
  // splash is already on screen. Each step is best-effort and self-contained.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initDeferredServices(
      customRemindersProvider: customRemindersProvider,
      isMobile: isMobile,
    ));
  });
}

/// Runs the bootstrap work that the first frame doesn't depend on (analytics,
/// push permission/token sync, the local-notification engine, custom-reminder
/// rescheduling). Kept sequential to preserve any ordering, but off the
/// cold-start critical path. Failures are isolated so one slow/failed step
/// can't stall the rest (app-robustness A7).
Future<void> _initDeferredServices({
  required CustomRemindersProvider customRemindersProvider,
  required bool isMobile,
}) async {
  // Analytics (feature: analytics) — bind the SDK after Firebase is up. Safe
  // no-op when Firebase isn't ready or the user opted out.
  try {
    await AnalyticsService.instance.init();
  } catch (_) {/* analytics is best-effort */}

  if (isMobile) {
    try {
      await PushNotificationService.instance.initialize();
    } catch (_) {/* push stays disabled; re-tried on resume */}
  }

  // Prepare local scheduled-notification infrastructure (timezone + channel)
  // for the retention "love reminders" feature.
  try {
    await ReminderService.instance.initialize();
  } catch (_) {/* reminders engine unavailable this session */}

  // Restore user-created custom reminders and re-arm their OS schedule.
  // D7 — only (re)arm while the master "love reminders" toggle is on (which is
  // when OS permission was granted); otherwise cancel any lingering schedule so
  // they don't silently fire.
  try {
    await customRemindersProvider.load();
    if (await _readMasterRemindersEnabled()) {
      await customRemindersProvider.rescheduleAllEnabled();
    } else {
      await customRemindersProvider.cancelAllSchedules();
    }
  } catch (_) {/* custom reminders left as-is */}
}

/// Reads the persisted locale from the `app_settings` Hive box (key `locale`)
/// before the widget tree is built. Returns null when the user follows the
/// system language or nothing has been saved yet. Tolerates any read failure.
Future<Locale?> _readSavedLocale() async {
  try {
    final box = await Hive.openBox<String>('app_settings');
    final saved = box.get('locale');
    if (saved != null && saved.isNotEmpty) {
      return Locale(saved);
    }
  } catch (_) {
    // Fall back to the system locale if settings can't be read.
  }
  return null;
}

/// Reads the master "love reminders" toggle from the `reminder_settings` Hive
/// box (key `enabled`, default false) before the widget tree is built. Used to
/// decide whether user-created custom reminders may be re-armed on cold start
/// (D7). The box is owned by [ReminderProvider]; Hive.openBox is idempotent so
/// reopening it here is safe. Any read failure is treated as "off".
Future<bool> _readMasterRemindersEnabled() async {
  try {
    final box = await Hive.openBox<dynamic>('reminder_settings');
    return box.get('enabled', defaultValue: false) as bool;
  } catch (_) {
    return false;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.authService,
    this.initialLocale,
    required this.customRemindersProvider,
  });

  final AuthService authService;
  final Locale? initialLocale;
  final CustomRemindersProvider customRemindersProvider;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthProvider _authProvider =
      AuthProvider(authService: widget.authService);

  // App-level navigator key (#3): lets the session-revocation listener route
  // from outside the widget tree without threading a context around.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authProvider.addListener(_handleAuthProviderChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.removeListener(_handleAuthProviderChanged);
    _authProvider.dispose();
    super.dispose();
  }

  /// When the session is revoked out from under us (#3 — token revoked, account
  /// deleted on another device, password changed), bounce back through the auth
  /// gate; the resolver then drops the user on the guest screen instead of
  /// leaving them stranded on a stale /home. Deferred to a post-frame callback
  /// so we never drive Navigator during a build/notify.
  void _handleAuthProviderChanged() {
    if (!_authProvider.sessionRevoked) {
      return;
    }
    _authProvider.acknowledgeSessionRevoked();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.authGate,
        (route) => false,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh the FCM token whenever the app returns to the foreground, so a
    // token rotation while the app was closed can't leave this device (and
    // therefore the partner's notifications) silently unregistered.
    if (state == AppLifecycleState.resumed) {
      _authProvider.refreshPushRegistration();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => CoupleProvider()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => ReactionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => DailyQuestionProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
        ChangeNotifierProvider(create: (_) => NotificationInboxProvider()),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(initialLocale: widget.initialLocale),
        ),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..load()),
        ChangeNotifierProvider<CustomRemindersProvider>.value(
          value: widget.customRemindersProvider,
        ),
        ChangeNotifierProvider(create: (_) => PartnerReminderProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: AppTheme.lightTheme,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('vi'),
            ],
            // Keep the non-widget localization layer (services, providers,
            // models, background isolates) in sync with the locale MaterialApp
            // actually resolves — including when following the system locale.
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              Locale resolved = supportedLocales.first;
              if (deviceLocale != null) {
                for (final locale in supportedLocales) {
                  if (locale.languageCode == deviceLocale.languageCode) {
                    resolved = locale;
                    break;
                  }
                }
              }
              AppL10n.setLocale(resolved);
              // Gap A — keep non-widget date/number formatting in sync with the
              // resolved locale so DateFormat() defaults match what the user
              // sees (e.g. "May 30" vs "30 thg 5"). Symbols were preloaded in
              // main() via initializeDateFormatting().
              Intl.defaultLocale = resolved.languageCode;
              return resolved;
            },
            home: const SessionRouteScreen(branded: true),
            // Auto screen_view logging (feature: analytics). Empty list when
            // analytics is unavailable (Firebase not ready) so nothing breaks.
            navigatorObservers: [
              if (AnalyticsService.instance.observer != null)
                AnalyticsService.instance.observer!,
            ],
            debugShowCheckedModeBanner: false,
            routes: {
              AppRoutes.authGate: (_) => const SessionRouteScreen(),
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.register: (_) => const RegisterScreen(),
              AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
              AppRoutes.verifyEmail: (_) => const VerifyEmailScreen(),
              AppRoutes.home: (_) => const HomeScreen(),
              AppRoutes.setup: (_) => const SetupScreen(),
              // Guest counter is a pure-local trial flow (Apple 5.1.1). It does
              // NOT go through SessionResolver/authGate — it opens directly
              // without any authentication.
              AppRoutes.guest: (_) => const GuestCounterScreen(),
              // Force-update gate (feature force-update): a dead-end screen
              // resolved by SessionResolver when this build is too old.
              AppRoutes.forceUpdate: (_) => const ForceUpdateScreen(),
            },
          );
        },
      ),
    );
  }
}
