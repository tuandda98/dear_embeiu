import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_urls.dart';
import '../l10n/app_localizations.dart';
import '../providers/arrival_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../services/analytics_service.dart';
import '../services/arrival_platform.dart';
import '../services/arrival_platform_native.dart'
    show arrivalBackgroundOptionLabel;
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/arrival/arrival_format.dart';
import '../widgets/arrival/arrival_scaffold.dart';
import '../widgets/content_card.dart';
import '../widgets/icon_badge.dart';
import 'arrival_manage_screen.dart';
import 'arrival_place_screen.dart';

/// "Bật báo về nhà" / switching "Tự báo" on (design §5, D8 steps 2–4).
/// Remote switch or build constant off (D13) → no auto: just turn sharing on
/// and open the manage screen.
Future<void> openArrivalSetup(
  BuildContext context, {
  required String from,
}) async {
  final arrival = context.read<ArrivalProvider>();
  if (!arrival.autoAvailable) {
    if (!arrival.myShare) {
      AnalyticsService.instance.logArrivalShareToggled(on: true, auto: false);
      await arrival.setShare(true);
    }
    if (context.mounted) await openArrivalManage(context, from: from);
    return;
  }
  AnalyticsService.instance.logArrivalSetupOpen(from);
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'ArrivalSetup'),
      // Opened from Cài đặt → Về đến nhà, closing lands back there, not Home.
      builder: (_) => ArrivalSetupScreen(backToHome: from != 'settings'),
    ),
  );
}

enum _Step { needPlace, disclosure, always, done, partial }

class ArrivalSetupScreen extends StatefulWidget {
  const ArrivalSetupScreen({super.key, this.backToHome = true});

  /// Last button reads "Về trang chủ" (opened from Home) or "Xong" (opened
  /// from the manage screen, where closing returns).
  final bool backToHome;

  /// Android's own words for "Cho phép mọi lúc" (D12), null elsewhere / on
  /// error → l10n fallback. Swappable in tests.
  @visibleForTesting
  static Future<String?> Function() backgroundLabel =
      arrivalBackgroundOptionLabel;

  @override
  State<ArrivalSetupScreen> createState() => _ArrivalSetupScreenState();
}

class _ArrivalSetupScreenState extends State<ArrivalSetupScreen>
    with WidgetsBindingObserver {
  late _Step _step = context.read<ArrivalProvider>().placesWithLocation.isEmpty
      ? _Step.needPlace
      : _Step.disclosure;
  bool _busy = false;
  String? _osLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ArrivalSetupScreen.backgroundLabel().then((label) {
      if (mounted && label != null) setState(() => _osLabel = label);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Android answers "Cho phép mọi lúc" on a Settings page: the result only
  /// shows on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_step != _Step.always && _step != _Step.partial) return;
    _checkAlways();
  }

  Future<void> _checkAlways() async {
    final arrival = context.read<ArrivalProvider>();
    final s = await arrival.permissions.status();
    await arrival.onResume();
    if (mounted && s.canAuto) setState(() => _step = _Step.done);
  }

  ArrivalPermissions get _perms => context.read<ArrivalProvider>().permissions;

  static String _result(ArrivalPermissionState s, {required bool always}) {
    final ok = always
        ? s.level == ArrivalPermissionLevel.always
        : s.canReadOnce;
    if (!ok) return 'denied';
    return s.precise ? 'granted' : 'approximate';
  }

  Future<void> _setHome() async {
    final arrival = context.read<ArrivalProvider>();
    await openArrivalPlaceSearch(context, arrival.home);
    if (mounted && arrival.placesWithLocation.isNotEmpty) {
      setState(() => _step = _Step.disclosure);
    }
  }

  Future<void> _agree() async {
    setState(() => _busy = true);
    try {
      final arrival = context.read<ArrivalProvider>();
      if (!arrival.myShare) {
        AnalyticsService.instance.logArrivalShareToggled(on: true, auto: true);
        await arrival.setShare(true);
      }
      await arrival.setWantsAuto(true);
      var s = await _perms.status();
      if (!s.canReadOnce || !s.precise) {
        s = await _perms.requestWhenInUse();
        AnalyticsService.instance.logArrivalPermission(
          step: 'when_in_use',
          result: _result(s, always: false),
        );
      }
      if (!mounted) return;
      setState(() {
        _step = s.canAuto
            ? _Step.done
            : s.canReadOnce
            ? _Step.always
            : _Step.partial;
      });
      if (s.canAuto) await arrival.onResume();
    } catch (e) {
      // Permission plugin failed: manual still works (D7).
      debugPrint('arrival setup: $e');
      if (mounted) setState(() => _step = _Step.partial);
    } finally {
      // A plugin error must not leave the button spinning.
      if (mounted) setState(() => _busy = false);
    }
  }

  /// iOS answers in the sheet (or after 1 s when it shows nothing). Android
  /// answers when the user comes back from the "Cho phép mọi lúc" page
  /// (`onRequestPermissionsResult`); not granted → stay on step 2 (retry or
  /// "Để sau"), and a later resume re-reads [ArrivalPermissions.status].
  Future<void> _askAlways() async {
    setState(() => _busy = true);
    try {
      final arrival = context.read<ArrivalProvider>();
      var s = await _perms.requestAlways();
      if (!s.canAuto) s = await _perms.status();
      AnalyticsService.instance.logArrivalPermission(
        step: 'always',
        result: _result(s, always: true),
      );
      await arrival.onResume();
      if (!mounted) return;
      setState(() {
        if (s.canAuto) {
          _step = _Step.done;
        } else if (Platform.isIOS) {
          _step = _Step.partial;
        }
      });
    } catch (e) {
      debugPrint('arrival setup: $e'); // stay on step 2, buttons usable
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manual() async {
    final arrival = context.read<ArrivalProvider>();
    await arrival.setWantsAuto(false);
    if (mounted) setState(() => _step = _Step.partial);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arrival = context.watch<ArrivalProvider>();
    final couple = context.read<CoupleProvider>().couple;
    final uid = context.read<AuthProvider>().currentUser?.id;
    final partner = couple == null
        ? l10n.reactionPartnerFallback
        : ArrivalFormat.partnerName(l10n, couple, uid);
    final me = couple == null
        ? l10n.sleepYou
        : ArrivalFormat.myName(l10n, couple, uid);
    void close() => Navigator.of(context).pop();

    switch (_step) {
      case _Step.needPlace:
        return ArrivalScaffold(
          title: l10n.arrivalNeedPlaceTitle,
          bottom: [
            ArrivalPrimaryButton(
              key: const ValueKey('arrival-set-home'),
              label: l10n.arrivalSetHomeAddress,
              icon: IconsaxPlusLinear.search_normal,
              onPressed: _setHome,
            ),
            ArrivalTextButton(label: l10n.arrivalLater, onPressed: close),
          ],
          children: [
            ArrivalBody(l10n.arrivalNeedPlaceBody),
            const SizedBox(height: 20),
            ContentCard(
              child: Row(
                children: [
                  const IconBadge(IconsaxPlusLinear.home_2),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.arrivalHomeName, style: _rowTitle),
                        Text(l10n.arrivalNoAddressYet, style: _rowSub),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case _Step.disclosure:
        return ArrivalScaffold(
          title: l10n.arrivalDisclosureTitle(partner),
          bottom: [
            ArrivalPrimaryButton(
              key: const ValueKey('arrival-agree'),
              label: l10n.arrivalAgree,
              busy: _busy,
              onPressed: _agree,
            ),
            ArrivalTextButton(label: l10n.arrivalLater, onPressed: close),
          ],
          children: [
            const _Dots(step: 1),
            const SizedBox(height: 12),
            ArrivalBody(l10n.arrivalDisclosureBody),
            const SizedBox(height: 20),
            Text(l10n.arrivalPreviewLabel(partner), style: _label),
            const SizedBox(height: 8),
            _PushPreview(
              title: l10n.arrivalWidgetPlace(me, l10n.arrivalChipWork),
              body: l10n.arrivalPushBody,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ArrivalTextButton(
                label: l10n.arrivalPrivacyLink,
                underline: true,
                onPressed: () => launchUrl(
                  Uri.parse(AppUrls.privacyPolicy),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ],
        );
      case _Step.always:
        final ios = Platform.isIOS;
        final label = ios
            ? l10n.arrivalAlwaysLabelIos
            : (_osLabel ?? l10n.arrivalAlwaysLabelAndroid);
        final rows = ios
            ? [
                (l10n.arrivalOsNever, false),
                (l10n.arrivalOsAskNext, false),
                (l10n.arrivalOsWhileUsing, false),
                (label, true),
              ]
            : [
                (label, true),
                (l10n.arrivalOsAndroidWhileUsing, false),
                (l10n.arrivalOsAndroidAsk, false),
                (l10n.arrivalOsAndroidDeny, false),
              ];
        return ArrivalScaffold(
          title: l10n.arrivalAlwaysTitle(label),
          bottom: [
            ArrivalPrimaryButton(
              key: const ValueKey('arrival-ask-always'),
              label: ios ? l10n.arrivalContinue : l10n.arrivalOpenPermission,
              busy: _busy,
              onPressed: _askAlways,
            ),
            ArrivalTextButton(
              label: l10n.arrivalLaterManual,
              onPressed: _manual,
            ),
          ],
          children: [
            const _Dots(step: 2),
            const SizedBox(height: 12),
            ArrivalBody(l10n.arrivalAlwaysBody(label)),
            const SizedBox(height: 20),
            Text(l10n.arrivalNextLooksLike, style: _label),
            const SizedBox(height: 8),
            ContentCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    for (final (text, target) in rows)
                      Container(
                        color: target
                            ? AppColors.textPrimary.withValues(alpha: 0.06)
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(text, style: _rowTitle)),
                            if (target)
                              const Icon(
                                IconsaxPlusLinear.tick_circle,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ArrivalHintBox(
              ios ? l10n.arrivalSwipeHint : l10n.arrivalAutostartHint,
            ),
          ],
        );
      case _Step.done:
        return ArrivalScaffold(
          title: l10n.arrivalDoneTitle,
          bottom: [
            ArrivalPrimaryButton(
              label: widget.backToHome
                  ? l10n.arrivalBackHome
                  : l10n.arrivalSetupDone,
              onPressed: close,
            ),
          ],
          children: [
            ArrivalBody(l10n.arrivalDoneBody(partner)),
            const SizedBox(height: 20),
            if (arrival.canAddPlace)
              ContentCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => openArrivalNewPlace(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const IconBadge(IconsaxPlusLinear.location),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.arrivalDoneRow, style: _rowTitle),
                              Text(l10n.arrivalDoneRowSub, style: _rowSub),
                            ],
                          ),
                        ),
                        const Icon(
                          IconsaxPlusLinear.arrow_right_3,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      case _Step.partial:
        return ArrivalScaffold(
          title: l10n.arrivalPartialTitle,
          bottom: [
            ArrivalPrimaryButton(
              label: widget.backToHome
                  ? l10n.arrivalBackHome
                  : l10n.arrivalSetupDone,
              onPressed: close,
            ),
          ],
          children: [ArrivalBody(l10n.arrivalPartialBody(partner))],
        );
    }
  }
}

const _label = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);
const _rowTitle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 15,
  fontWeight: FontWeight.w700,
);
const _rowSub = TextStyle(color: AppColors.textSecondary, fontSize: 12);

/// Two step dots (disclosure = 1, Always = 2).
class _Dots extends StatelessWidget {
  const _Dots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        for (var i = 1; i <= 2; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          AnimatedContainer(
            duration: AppMotion.reduceMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 240),
            width: i == step ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == step
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Mock lock-screen push "Tuấn đã đến Công ty / Nhắn một câu hỏi thăm nhé".
class _PushPreview extends StatelessWidget {
  const _PushPreview({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => ContentCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IconBadge(IconsaxPlusBold.heart, size: 36, iconSize: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _rowTitle),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
