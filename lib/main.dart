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
import 'providers/couple_provider.dart';
import 'providers/custom_reminders_provider.dart';
import 'providers/daily_question_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/love_note_provider.dart';
import 'providers/photo_provider.dart';
import 'providers/reminder_provider.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/guest_counter_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/splash_screen.dart';
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
  await FirebaseBootstrapService.initialize();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService.instance.initialize();
  }
  // Prepare local scheduled-notification infrastructure (timezone + channel)
  // for the retention "love reminders" feature.
  await ReminderService.instance.initialize();

  // Restore user-created custom reminders and re-arm their OS schedule on cold
  // start. Built here (rather than lazily in MultiProvider) so the reschedule
  // happens once at launch; AppL10n is already set up for the fallback body.
  final customRemindersProvider = CustomRemindersProvider();
  await customRemindersProvider.load();
  // D7 — custom reminders may only be (re)armed while the master "love
  // reminders" toggle is on (which is when OS permission was granted). When the
  // master toggle is off their schedule was already cancelled, so on cold start
  // we must NOT re-arm them; otherwise they'd silently fire again.
  if (await _readMasterRemindersEnabled()) {
    await customRemindersProvider.rescheduleAllEnabled();
  } else {
    await customRemindersProvider.cancelAllSchedules();
  }

  await InstallStateService().handleFreshInstall(
    onFreshInstall: () => authService.purgePersistedSession(),
  );

  if (!kIsWeb && FirebaseBootstrapService.isFirebaseReady) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(MyApp(
    authService: authService,
    initialLocale: initialLocale,
    customRemindersProvider: customRemindersProvider,
  ));
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.dispose();
    super.dispose();
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
        ChangeNotifierProvider(create: (_) => LoveNoteProvider()),
        ChangeNotifierProvider(create: (_) => DailyQuestionProvider()),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(initialLocale: widget.initialLocale),
        ),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..load()),
        ChangeNotifierProvider<CustomRemindersProvider>.value(
          value: widget.customRemindersProvider,
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
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
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            routes: {
              AppRoutes.authGate: (_) => const AuthGateScreen(),
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.register: (_) => const RegisterScreen(),
              AppRoutes.home: (_) => const HomeScreen(),
              AppRoutes.setup: (_) => const SetupScreen(),
              // Guest counter is a pure-local trial flow (Apple 5.1.1). It does
              // NOT go through SessionResolver/authGate — it opens directly
              // without any authentication.
              AppRoutes.guest: (_) => const GuestCounterScreen(),
            },
          );
        },
      ),
    );
  }
}
