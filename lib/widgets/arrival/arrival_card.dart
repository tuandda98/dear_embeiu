import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/arrival.dart';
import '../../models/couple.dart';
import '../../providers/arrival_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../screens/arrival_manage_screen.dart';
import '../../screens/arrival_place_screen.dart';
import '../../screens/arrival_setup_screen.dart';
import '../../screens/care_message_screen.dart';
import '../../services/analytics_service.dart';
import '../../services/arrival_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/person_palette.dart';
import '../content_card.dart';
import '../icon_badge.dart';
import '../person_label.dart';
import '../shimmer_skeleton.dart';
import '../today_constellation.dart' show MidnightBuilder;
import 'arrival_format.dart';

/// Home card "Về đến nhà chưa?" (feature arrival, design §3 + Home C §15):
/// two lanes — Bạn left, người ấy right — tinted with each person's colour
/// (same ids as SleepCard), then "Về nhà rồi" + "Đến nơi rồi ⌄" outlined.
/// Only for an active couple ([ArrivalProvider.visible], D9) — HomeScreen
/// checks that before building it.
class ArrivalCard extends StatefulWidget {
  const ArrivalCard({super.key, required this.couple});

  final Couple couple;

  @override
  State<ArrivalCard> createState() => _ArrivalCardState();
}

class _ArrivalCardState extends State<ArrivalCard> {
  /// "✓ Đã báo Thảo" shows for 4 s after a sent manual event (§3.3).
  bool _justSent = false;
  Timer? _sentTimer;

  /// Slot of the last manual send from this card (for "Chưa gửi được …").
  String _lastSlot = kArrivalHome;

  @override
  void dispose() {
    _sentTimer?.cancel();
    super.dispose();
  }

  Future<void> _send(String slot) async {
    HapticFeedback.lightImpact();
    final arrival = context.read<ArrivalProvider>();
    _lastSlot = slot;
    AnalyticsService.instance.logArrivalManual(
      slot == kArrivalHome ? 'home' : 'custom',
    );
    final result = await arrival.sendManual(slot);
    _flash(result);
  }

  Future<void> _retry() async {
    final result = await context.read<ArrivalProvider>().retry();
    _flash(result);
  }

  void _flash(ArrivalSendResult result) {
    if (!mounted) return;
    if (result == ArrivalSendResult.dropped) {
      // Nothing was written (place gone, send already running, couple not
      // active any more): say so instead of a silent button.
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.arrivalSendFailed(_what(l10n)))),
        );
      return;
    }
    if (result != ArrivalSendResult.sent) return;
    _sentTimer?.cancel();
    setState(() => _justSent = true);
    _sentTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _justSent = false);
    });
  }

  /// "Về nhà rồi" / "Đã đến Phòng gym" — what the last send was.
  String _what(AppLocalizations l10n) {
    if (_lastSlot == kArrivalHome) return l10n.arrivalManualHome;
    final arrival = context.read<ArrivalProvider>();
    final place = arrival.places.where((p) => p.slot == _lastSlot).firstOrNull;
    return place == null
        ? l10n.arrivalManualOther
        : l10n.arrivalEnterPlace(ArrivalFormat.placeName(l10n, place));
  }

  Future<void> _pickPlace() async {
    final slot = await showArrivalPickSheet(context, widget.couple);
    if (slot != null && mounted) await _send(slot);
  }

  @override
  Widget build(BuildContext context) {
    return MidnightBuilder(builder: _build);
  }

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arrival = context.watch<ArrivalProvider>();
    final sleep = context.watch<SleepProvider>();
    final myUid = context.read<AuthProvider>().currentUser?.id;
    final partnerName = ArrivalFormat.partnerName(l10n, widget.couple, myUid);
    final now = DateTime.now();

    final pitch =
        arrival.isLoaded &&
        !arrival.myShare &&
        !arrival.partnerShares &&
        arrival.myLast == null;

    final header = Semantics(
      button: !pitch,
      label: pitch ? null : l10n.arrivalOpenManageA11y,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: pitch
            ? null
            : () => openArrivalManage(context, from: 'home_card'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              const IconBadge(IconsaxPlusLinear.home_2),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.arrivalCardTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!pitch)
                const Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );

    final children = <Widget>[header, const SizedBox(height: 12)];
    if (!arrival.isLoaded) {
      children.addAll(const [
        Row(
          children: [
            Expanded(child: ShimmerSkeleton(height: 120)),
            SizedBox(width: 8),
            Expanded(child: ShimmerSkeleton(height: 120)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ShimmerSkeleton(height: 44)),
            SizedBox(width: 8),
            Expanded(child: ShimmerSkeleton(height: 44)),
          ],
        ),
      ]);
    } else {
      if (pitch) {
        children.add(
          Text(
            l10n.arrivalPitch(partnerName),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        );
      } else {
        children.add(_lanes(context, l10n, arrival, sleep, partnerName, now));
      }
      children
        ..add(const SizedBox(height: 12))
        ..add(_footer(context, l10n, arrival))
        ..add(_strip(l10n, arrival, partnerName));
    }

    return ContentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _lanes(
    BuildContext context,
    AppLocalizations l10n,
    ArrivalProvider arrival,
    SleepProvider sleep,
    String partnerName,
    DateTime now,
  ) {
    // ≥ 1.3× text: the two lanes stack (design §12).
    final stack = MediaQuery.textScalerOf(context).scale(10) >= 13;
    final mine = _mineLane(
      context,
      l10n,
      arrival,
      PersonPalette.colorOf(sleep.myColorId),
      partnerName,
      now,
      fill: !stack,
    );
    final theirs = _partnerLane(
      context,
      l10n,
      arrival,
      PersonPalette.colorOf(sleep.partnerColorId),
      partnerName,
      now,
      fill: !stack,
    );
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [mine, const SizedBox(height: 8), theirs],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: mine),
          const SizedBox(width: 8),
          Expanded(child: theirs),
        ],
      ),
    );
  }

  Widget _mineLane(
    BuildContext context,
    AppLocalizations l10n,
    ArrivalProvider arrival,
    Color color,
    String partnerName,
    DateTime now, {
    required bool fill,
  }) {
    final last = arrival.myLast;
    final body = <Widget>[];
    if (!arrival.myShare) {
      body.add(_smallLead(l10n.arrivalPartnerOff));
    } else if (last == null || ArrivalFormat.isStale(last, now)) {
      body.add(_smallLead(l10n.arrivalNoEventToday));
    } else {
      body.add(_EventBlock(event: last, now: now));
      final detected = _firstDetected(arrival, last);
      if (detected != null) {
        body.add(_OkLine(text: l10n.arrivalFirstDetected(detected)));
      }
    }
    if (_justSent) {
      body.add(_OkLine(text: l10n.arrivalSent(partnerName), live: true));
    }
    final status = arrival.myShare ? _mineStatus(context, l10n, arrival) : null;
    return _Lane(
      color: color,
      neutral: false,
      label: PersonLabel(name: l10n.sleepYou, color: color),
      body: body,
      bottom: status,
      fill: fill,
    );
  }

  /// "✓ App đã nhận ra Phòng gym" (D21): an automatic arrival within a day
  /// of saving that place by address.
  // ponytail: "first" = within 24 h of savedAt, not a stored flag; add a
  // per-place "seen" bit if people report it showing twice.
  String? _firstDetected(ArrivalProvider arrival, ArrivalEvent last) {
    if (last.source != ArrivalEventSource.auto ||
        last.type != ArrivalEventType.enter) {
      return null;
    }
    final place = arrival.places.where((p) => p.slot == last.place).firstOrNull;
    final saved = place?.location?.savedAt;
    if (place == null || saved == null) return null;
    final gap = last.at.difference(saved);
    if (gap.isNegative || gap > const Duration(hours: 24)) return null;
    return ArrivalFormat.placeName(AppLocalizations.of(context), place);
  }

  Widget? _mineStatus(
    BuildContext context,
    AppLocalizations l10n,
    ArrivalProvider arrival,
  ) {
    void manage() => openArrivalManage(context, from: 'home_card');
    if (arrival.autoRemoteOff) {
      return _MineStatus(
        icon: IconsaxPlusLinear.location_slash,
        text: l10n.arrivalMineRemoteOff,
        onTap: manage,
      );
    }
    if (arrival.needsAlways) {
      return _MineStatus(
        icon: IconsaxPlusLinear.location_slash,
        text: l10n.arrivalMineNeedAlways,
        onTap: manage,
        link: l10n.arrivalOpenSettings,
        onLink: () {
          AnalyticsService.instance.logArrivalCardAction('open_settings');
          arrival.permissions.openSettings();
        },
      );
    }
    if (arrival.autoRunning) {
      return _MineStatus(
        icon: IconsaxPlusLinear.location,
        text: l10n.arrivalMineAuto(
          ArrivalFormat.places(l10n, arrival.placesWithLocation),
        ),
        onTap: manage,
      );
    }
    if (arrival.placesWithLocation.isEmpty) {
      return _MineStatus(
        icon: IconsaxPlusLinear.location_slash,
        text: l10n.arrivalMineNoAddress,
        onTap: manage,
        link: l10n.arrivalSetAddress,
        onLink: () => openArrivalPlaceSearch(context, arrival.home),
      );
    }
    return _MineStatus(
      icon: IconsaxPlusLinear.location,
      text: l10n.arrivalMineManual,
      onTap: manage,
    );
  }

  Widget _partnerLane(
    BuildContext context,
    AppLocalizations l10n,
    ArrivalProvider arrival,
    Color color,
    String partnerName,
    DateTime now, {
    required bool fill,
  }) {
    final label = PersonLabel(name: partnerName, color: color);
    if (!arrival.partnerShares) {
      return _Lane(
        color: color,
        neutral: true,
        label: label,
        body: [_smallLead(l10n.arrivalPartnerOff)],
        fill: fill,
      );
    }
    final last = arrival.partnerLast;
    if (last == null || ArrivalFormat.isStale(last, now)) {
      return _Lane(
        color: color,
        neutral: false,
        label: label,
        body: [
          _smallLead(l10n.arrivalPartnerOn),
          const SizedBox(height: 2),
          _sub(l10n.arrivalPartnerOnSub(partnerName)),
        ],
        fill: fill,
      );
    }
    return _Lane(
      color: color,
      neutral: false,
      label: label,
      body: [
        AnimatedSwitcher(
          // Reduce Motion: fade 200 ms (§13).
          duration: AppMotion.reduceMotion(context)
              ? const Duration(milliseconds: 200)
              : const Duration(milliseconds: 280),
          child: _EventBlock(
            key: ValueKey(last.at.millisecondsSinceEpoch),
            event: last,
            now: now,
          ),
        ),
      ],
      bottom: Semantics(
        button: true,
        label: l10n.arrivalCareA11y(partnerName),
        excludeSemantics: true,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              AnalyticsService.instance.logArrivalCardAction('care_message');
              openCareMessageScreen(
                context,
                initialTitle: l10n.arrivalCareSuggestion,
                source: 'arrival',
              );
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              foregroundColor: AppColors.textPrimary,
            ),
            icon: const Icon(
              IconsaxPlusLinear.message_favorite,
              size: 16,
              color: AppColors.accentLoveDeep,
            ),
            label: Text(
              l10n.arrivalCareCta,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      fill: fill,
    );
  }

  Widget _footer(
    BuildContext context,
    AppLocalizations l10n,
    ArrivalProvider arrival,
  ) {
    final queued = arrival.lastResult == ArrivalSendResult.queued;
    final homeBtn = _OutlineAction(
      key: const ValueKey('arrival-home'),
      icon: _justSent
          ? IconsaxPlusLinear.tick_circle
          : queued
          ? IconsaxPlusLinear.cloud_cross
          : IconsaxPlusLinear.home_2,
      label: l10n.arrivalManualHome,
      pressed: _justSent || queued,
      onPressed: arrival.sending ? null : () => _send(kArrivalHome),
    );
    final List<Widget> buttons;
    if (!arrival.myShare) {
      buttons = [
        FilledButton(
          key: const ValueKey('arrival-enable'),
          onPressed: () => openArrivalSetup(context, from: 'home_card'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(l10n.arrivalEnableCta),
        ),
        homeBtn,
      ];
    } else {
      buttons = [
        homeBtn,
        if (arrival.customPlaces.isNotEmpty)
          Semantics(
            // Opens a dialog-like sheet (aria-haspopup in the mock).
            hint: l10n.arrivalPickTitle,
            child: _OutlineAction(
              key: const ValueKey('arrival-other'),
              icon: IconsaxPlusLinear.location,
              trailing: IconsaxPlusLinear.arrow_down,
              label: l10n.arrivalManualOther,
              onPressed: arrival.sending ? null : _pickPlace,
            ),
          ),
      ];
    }
    final stack = MediaQuery.textScalerOf(context).scale(10) >= 13;
    if (stack || buttons.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            buttons[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: buttons[0]),
        const SizedBox(width: 8),
        Expanded(child: buttons[1]),
      ],
    );
  }

  Widget _strip(
    AppLocalizations l10n,
    ArrivalProvider arrival,
    String partnerName,
  ) {
    final Widget child;
    switch (arrival.lastResult) {
      case ArrivalSendResult.queued:
        child = _InlineStrip(
          key: const ValueKey('arrival-queued'),
          icon: const Icon(
            IconsaxPlusLinear.cloud_cross,
            size: 18,
            color: AppColors.textPrimary,
          ),
          text: l10n.arrivalQueued(partnerName),
        );
      // `denied` = no longer allowed to write (left the couple): same strip,
      // "Thử lại" re-checks.
      case ArrivalSendResult.failed:
      case ArrivalSendResult.denied:
        final what = _what(l10n);
        child = _InlineStrip(
          key: const ValueKey('arrival-failed'),
          alert: true,
          icon: const Icon(
            IconsaxPlusLinear.danger,
            size: 18,
            color: AppColors.error,
          ),
          text: l10n.arrivalSendFailed(what),
          action: TextButton(
            onPressed: arrival.sending ? null : _retry,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(
              l10n.arrivalRetry,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        );
      default:
        child = const SizedBox.shrink();
    }
    return AnimatedSize(
      duration: AppMotion.reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  static Widget _smallLead(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    ),
  );

  static Widget _sub(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
  );
}

/// One lane: r16 pad 12, the person's colour α .10 (neutral = surfaceLight).
/// [bottom] sits at the foot of the lane so both lanes line up (§3.1).
class _Lane extends StatelessWidget {
  const _Lane({
    required this.color,
    required this.neutral,
    required this.label,
    required this.body,
    required this.fill,
    this.bottom,
  });

  final Color color;
  final bool neutral;
  final Widget label;
  final List<Widget> body;
  final Widget? bottom;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: neutral ? AppColors.surfaceLight : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          ...body,
          if (bottom != null) ...[
            if (fill) const Spacer() else const SizedBox(height: 4),
            bottom!,
          ],
        ],
      ),
    );
  }
}

/// Sentence 18 w700 (≤ 3 lines) + icon · time · battery (+ "bấm tay").
class _EventBlock extends StatelessWidget {
  const _EventBlock({super.key, required this.event, required this.now});

  final ArrivalEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = event;
    final battery = e.battery;
    final low = battery != null && battery <= 20;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            ArrivalFormat.sentence(l10n, e),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                ArrivalFormat.icon(e.icon, home: e.isHome),
                size: 16,
                color: AppColors.textPrimary,
              ),
              Text(
                ArrivalFormat.when(context, e.at, now),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (battery != null && !low)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      IconsaxPlusLinear.battery_3full,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.arrivalBattery(battery),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              if (low)
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        IconsaxPlusLinear.battery_empty,
                        size: 14,
                        color: AppColors.warningInk,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.arrivalBatteryLow(battery),
                        style: const TextStyle(
                          color: AppColors.warningInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (e.source == ArrivalEventSource.manual)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.arrivalManualTag,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OkLine extends StatelessWidget {
  const _OkLine({required this.text, this.live = false});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: live,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            const Icon(
              IconsaxPlusLinear.tick_circle,
              size: 14,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Tự báo: Nhà và 2 nơi khác" — always tappable (D11: the sharer sees what
/// they share), optional underlined link under it.
class _MineStatus extends StatelessWidget {
  const _MineStatus({
    required this.icon,
    required this.text,
    required this.onTap,
    this.link,
    this.onLink,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final String? link;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          hint: l10n.arrivalOpenManageA11y,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(icon, size: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (link != null)
          TextButton(
            onPressed: onLink,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(
              link!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
}

/// Outlined pill h44, navy α .18 1.5 (Lead: outlined on Home). [pressed] =
/// navy α .06 fill while "just sent" / queued, same label + width.
class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.trailing,
    this.pressed = false,
  });

  final IconData icon;
  final IconData? trailing;
  final String label;
  final VoidCallback? onPressed;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const StadiumBorder(),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: pressed
            ? AppColors.textPrimary.withValues(alpha: 0.06)
            : Colors.transparent,
        side: BorderSide(
          color: AppColors.textPrimary.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.reduceMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: Icon(icon, key: ValueKey(icon), size: 16),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 2),
            Icon(trailing, size: 16),
          ],
        ],
      ),
    );
  }
}

class _InlineStrip extends StatelessWidget {
  const _InlineStrip({
    super.key,
    required this.icon,
    required this.text,
    this.action,
    this.alert = false,
  });

  final Widget icon;
  final String text;
  final Widget? action;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            if (action != null) action! else const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// Sheet "Bạn vừa đến đâu?" — custom places only (Home has its own button).
/// Returns the tapped slot (the card sends it), null when dismissed.
Future<String?> showArrivalPickSheet(BuildContext context, Couple couple) {
  final l10n = AppLocalizations.of(context);
  final arrival = context.read<ArrivalProvider>();
  final myUid = context.read<AuthProvider>().currentUser?.id;
  final partner = ArrivalFormat.partnerName(l10n, couple, myUid);
  final me = ArrivalFormat.myName(l10n, couple, myUid);
  return showModalBottomSheet<String>(
    context: context,
    routeSettings: const RouteSettings(name: 'ArrivalPickSheet'),
    backgroundColor: Colors.white,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.arrivalPickTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final p in arrival.customPlaces)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(sheet).pop(p.slot),
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      IconBadge(
                        ArrivalFormat.placeIcon(p),
                        tint: AppColors.textPrimary,
                        tintAlpha: 0.06,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name ?? '',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (arrival.canAddPlace)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    openArrivalNewPlace(context);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(IconsaxPlusLinear.add, size: 18),
                  label: Text(
                    l10n.arrivalAddPlace,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              l10n.arrivalPickNote(partner, me),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
