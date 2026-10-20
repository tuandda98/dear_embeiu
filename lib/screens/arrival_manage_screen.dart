import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/arrival.dart';
import '../providers/arrival_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/sleep_provider.dart';
import '../services/analytics_service.dart';
import '../services/arrival_platform.dart';
import '../theme/app_colors.dart';
import '../theme/person_palette.dart';
import '../widgets/arrival/arrival_format.dart';
import '../widgets/arrival/arrival_scaffold.dart';
import '../widgets/content_card.dart';
import '../widgets/icon_badge.dart';
import '../widgets/person_label.dart';
import 'arrival_place_screen.dart';
import 'arrival_setup_screen.dart';

/// Settings "Về đến nhà" (design §6, mock `manage.html`). [from] =
/// `home_card` · `settings` (analytics `arrival_setup_open`).
Future<void> openArrivalManage(BuildContext context, {required String from}) {
  AnalyticsService.instance.logArrivalSetupOpen(from);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'ArrivalManage'),
      builder: (_) => const ArrivalManageScreen(),
    ),
  );
}

class ArrivalManageScreen extends StatefulWidget {
  const ArrivalManageScreen({super.key});

  @override
  State<ArrivalManageScreen> createState() => _ArrivalManageScreenState();
}

class _ArrivalManageScreenState extends State<ArrivalManageScreen>
    with WidgetsBindingObserver {
  ArrivalPermissionState? _perm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPerm();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadPerm();
  }

  Future<void> _loadPerm() async {
    try {
      final s = await context.read<ArrivalProvider>().permissions.status();
      if (mounted) setState(() => _perm = s);
    } catch (_) {
      // Leave the section as it was.
    }
  }

  Future<void> _toggleShare(bool on, String partner, String me) async {
    final arrival = context.read<ArrivalProvider>();
    if (on) {
      AnalyticsService.instance.logArrivalShareToggled(
        on: true,
        auto: arrival.wantsAuto,
      );
      await arrival.setShare(true);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final withLocation = arrival.placesWithLocation.length;
    var alsoPlaces = false;
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(l10n.arrivalTurnOffTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.arrivalTurnOffBody(partner, me)),
              if (withLocation > 0) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  key: const ValueKey('arrival-turnoff-places'),
                  value: alsoPlaces,
                  onChanged: (v) => setLocal(() => alsoPlaces = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    l10n.arrivalTurnOffAlsoPlaces(withLocation),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text(l10n.arrivalCancel),
            ),
            TextButton(
              key: const ValueKey('arrival-turnoff-confirm'),
              onPressed: () => Navigator.of(d).pop(true),
              child: Text(l10n.arrivalTurnOff),
            ),
          ],
        ),
      ),
    );
    if (yes != true) return;
    AnalyticsService.instance.logArrivalShareToggled(on: false, auto: false);
    await arrival.setShare(false, deletePlaces: alsoPlaces);
  }

  Future<void> _toggleAuto(bool on) async {
    final arrival = context.read<ArrivalProvider>();
    if (on) {
      await openArrivalSetup(context, from: 'settings');
    } else {
      await arrival.setWantsAuto(false);
    }
    await _loadPerm();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arrival = context.watch<ArrivalProvider>();
    final sleep = context.watch<SleepProvider>();
    final couple = context.watch<CoupleProvider>().couple;
    final uid = context.read<AuthProvider>().currentUser?.id;
    final partner = couple == null
        ? l10n.reactionPartnerFallback
        : ArrivalFormat.partnerName(l10n, couple, uid);
    final me = couple == null
        ? l10n.sleepYou
        : ArrivalFormat.myName(l10n, couple, uid);
    final myColor = PersonPalette.colorOf(sleep.myColorId);
    final now = DateTime.now();

    final children = <Widget>[
      Text(l10n.arrivalSeesLabel(partner), style: _label),
      const SizedBox(height: 8),
      _SeesLane(
        name: me,
        color: myColor,
        share: arrival.myShare,
        event: arrival.myLast,
        now: now,
      ),
      const SizedBox(height: 16),
      ContentCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          children: [
            _SwitchRow(
              key: const ValueKey('arrival-share-switch'),
              icon: IconsaxPlusLinear.heart,
              title: l10n.arrivalShareTitle(partner),
              subtitle: arrival.myShare
                  ? l10n.arrivalShareSub(partner)
                  : l10n.arrivalShareOffSub(partner),
              value: arrival.myShare,
              onChanged: (v) => _toggleShare(v, partner, me),
            ),
            if (arrival.myShare && arrivalAutoBuildAllowed) ...[
              const Divider(height: 1),
              _autoRow(context, l10n, arrival),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        l10n.arrivalPlacesTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      ArrivalBody(l10n.arrivalPlacesSub, muted: true),
      const SizedBox(height: 12),
      ContentCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (final p in arrival.places)
              _PlaceRow(
                place: p,
                paused: !arrival.myShare || arrival.autoRemoteOff,
                onTap: () => openArrivalEditPlace(context, p),
              ),
            if (arrival.canAddPlace)
              _PlaceRow.add(
                title: l10n.arrivalAddPlace,
                subtitle: l10n.arrivalSlotsLeft(
                  kArrivalMaxCustom - arrival.customPlaces.length,
                ),
                onTap: () => openArrivalNewPlace(context),
              ),
          ],
        ),
      ),
    ];

    if (arrival.myShare && arrival.wantsAuto && arrival.autoAvailable) {
      children.addAll([
        const SizedBox(height: 24),
        Text(
          l10n.arrivalPermTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _PermissionCard(
          state: _perm,
          onOpenSettings: arrival.permissions.openSettings,
        ),
        if (Platform.isIOS) ...[
          const SizedBox(height: 12),
          ArrivalHintBox(l10n.arrivalSwipeHint),
        ],
      ]);
    }

    return ArrivalScaffold(children: children);
  }

  Widget _autoRow(
    BuildContext context,
    AppLocalizations l10n,
    ArrivalProvider arrival,
  ) {
    final String sub;
    Widget? cta;
    var enabled = true;
    if (!arrival.autoAvailable) {
      sub = l10n.arrivalAutoRemoteOff;
      enabled = false;
    } else if (arrival.placesWithLocation.isEmpty) {
      sub = l10n.arrivalAutoNeedPlace;
      enabled = false;
      cta = _SmallOutline(
        label: l10n.arrivalSetHomeAddress,
        onPressed: () => openArrivalPlaceSearch(context, arrival.home),
      );
    } else if (arrival.needsAlways) {
      // Still switchable: the user must be able to turn auto back off.
      sub = l10n.arrivalAutoNeedAlways;
      cta = _SmallOutline(
        label: l10n.arrivalOpenSettings,
        onPressed: arrival.permissions.openSettings,
      );
    } else {
      sub = l10n.arrivalAutoSub(
        arrival.placesWithLocation
            .map((p) => ArrivalFormat.placeName(l10n, p))
            .join(', '),
      );
    }
    return _SwitchRow(
      key: const ValueKey('arrival-auto-switch'),
      icon: IconsaxPlusLinear.location,
      title: l10n.arrivalAutoTitle,
      subtitle: sub,
      value: arrival.wantsAuto && arrival.autoAvailable,
      onChanged: enabled ? _toggleAuto : null,
      cta: cta,
    );
  }
}

const _label = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

/// "Thảo đang thấy" — my lane exactly as the partner's card shows it.
class _SeesLane extends StatelessWidget {
  const _SeesLane({
    required this.name,
    required this.color,
    required this.share,
    required this.event,
    required this.now,
  });

  final String name;
  final Color color;
  final bool share;
  final ArrivalEvent? event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = event;
    final String lead;
    String? meta;
    if (!share) {
      lead = l10n.arrivalPartnerOff;
    } else if (e == null || ArrivalFormat.isStale(e, now)) {
      lead = l10n.arrivalPartnerOn;
    } else {
      lead = ArrivalFormat.sentence(l10n, e);
      meta = [
        ArrivalFormat.when(context, e.at, now),
        if (e.battery != null) l10n.arrivalBattery(e.battery!),
      ].join(' · ');
    }
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: share ? color.withValues(alpha: 0.10) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonLabel(name: name, color: color),
            const SizedBox(height: 6),
            Text(
              lead,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (meta != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      ArrivalFormat.icon(e!.icon, home: e.isHome),
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      meta,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.cta,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: title,
                child: Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.accentRose,
                ),
              ),
            ],
          ),
          if (cta != null)
            Padding(
              padding: const EdgeInsets.only(left: 58, top: 8),
              child: cta,
            ),
        ],
      ),
    );
  }
}

class _SmallOutline extends StatelessWidget {
  const _SmallOutline({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      shape: const StadiumBorder(),
      foregroundColor: AppColors.textPrimary,
      side: BorderSide(
        color: AppColors.textPrimary.withValues(alpha: 0.18),
        width: 1.5,
      ),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.paused,
    required this.onTap,
  }) : addTitle = null,
       addSubtitle = null;

  const _PlaceRow.add({
    required String title,
    required String subtitle,
    required this.onTap,
  }) : place = null,
       paused = false,
       addTitle = title,
       addSubtitle = subtitle;

  final ArrivalPlace? place;
  final bool paused;
  final VoidCallback onTap;
  final String? addTitle;
  final String? addSubtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = place;
    final String title;
    final String sub;
    final Widget badge;
    if (p == null) {
      title = addTitle!;
      sub = addSubtitle!;
      badge = const IconBadge(IconsaxPlusLinear.add);
    } else {
      title = ArrivalFormat.placeName(l10n, p);
      final loc = p.location;
      sub = loc == null
          ? l10n.arrivalNoAddressManual
          : paused
          ? l10n.arrivalPaused
          : loc.source == ArrivalLocationSource.current
          ? l10n.arrivalSavedFromCurrent(ArrivalFormat.shortDate(loc.savedAt))
          : ArrivalFormat.shortAddress(loc.address ?? '');
      badge = IconBadge(
        ArrivalFormat.placeIcon(p),
        tint: AppColors.textPrimary,
        tintAlpha: 0.06,
      );
    }
    return InkWell(
      key: ValueKey('arrival-place-${p?.slot ?? 'add'}'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            badge,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (p != null)
              const Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 18,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.state, required this.onOpenSettings});

  final ArrivalPermissionState? state;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = state;
    final always = s?.level == ArrivalPermissionLevel.always;
    final some = s?.canReadOnce ?? false;
    final precise = s?.precise ?? false;
    Widget row(
      IconData icon,
      String title,
      String? sub, {
      VoidCallback? onTap,
    }) {
      final content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 18,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      );
      return onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: content,
            );
    }

    return ContentCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          row(
            always
                ? IconsaxPlusLinear.tick_circle
                : IconsaxPlusLinear.location_slash,
            always
                ? l10n.arrivalPermAlways
                : some
                ? l10n.arrivalPermWhileUsing
                : l10n.arrivalPermNone,
            always ? l10n.arrivalPermAlwaysSub : l10n.arrivalPermWhileUsingSub,
          ),
          if (some)
            row(
              precise
                  ? IconsaxPlusLinear.tick_circle
                  : IconsaxPlusLinear.location_slash,
              precise ? l10n.arrivalPermPreciseOn : l10n.arrivalPermPreciseOff,
              l10n.arrivalPermPreciseSub,
            ),
          row(
            IconsaxPlusLinear.setting_2,
            l10n.arrivalPermOpenSettings,
            null,
            onTap: onOpenSettings,
          ),
        ],
      ),
    );
  }
}
