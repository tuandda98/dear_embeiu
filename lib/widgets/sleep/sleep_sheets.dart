import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/sleep_night.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../services/sleep_platform.dart';
import '../../services/sleep_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/person_palette.dart';
import '../app_time_picker.dart';
import 'sleep_format.dart';

/// Bottom sheets of feature sleep (design §C/D/E): setup (2 steps), edit /
/// log a night, and "how is sleep worked out?".

Future<void> showSleepSetupSheet(BuildContext context) {
  HapticFeedback.selectionClick();
  return _show(context, const _SetupSheet(), 'SleepSetupSheet');
}

Future<void> showSleepEditSheet(
  BuildContext context, {
  required String dateKey,
}) {
  HapticFeedback.selectionClick();
  return _show(context, _EditSheet(dateKey: dateKey), 'SleepEditSheet');
}

Future<void> showSleepHowItWorksSheet(BuildContext context) {
  HapticFeedback.selectionClick();
  return _show(context, const _HowItWorksSheet(), 'SleepHowItWorksSheet');
}

Future<void> _show(BuildContext context, Widget sheet, String name) {
  final sleep = context.read<SleepProvider>();
  return showModalBottomSheet<void>(
    context: context,
    routeSettings: RouteSettings(name: name),
    isScrollControlled: true,
    // Taller than the screen (small phone, big text): stop under the status
    // bar / notch instead of hiding the handle and title behind it.
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        ChangeNotifierProvider<SleepProvider>.value(value: sleep, child: sheet),
  );
}

/// Blurred white sheet frame shared with the mood/streak sheets.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppColors.cardSurface,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text, {this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      height: 1.25,
    ),
  );
}

class _Disc extends StatelessWidget {
  const _Disc({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 28, color: color),
    ),
  );
}

class _HintBox extends StatelessWidget {
  const _HintBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          IconsaxPlusLinear.info_circle,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({
    required this.label,
    required this.onTap,
    this.underline = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool underline;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      minimumSize: const Size.fromHeight(44),
      foregroundColor: AppColors.textSecondary,
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: underline ? 13 : 14,
        fontWeight: FontWeight.w600,
        decoration: underline ? TextDecoration.underline : null,
      ),
    ),
  );
}

// ── C. Setup ────────────────────────────────────────────────────────────────

class _SetupSheet extends StatefulWidget {
  const _SetupSheet();

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> with WidgetsBindingObserver {
  int _step = 0;
  bool _busy = false;
  bool _awaitingSettings = false;
  bool _stillOff = false;
  bool? _supported;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SleepPlatform.isSupported().then((v) {
      if (mounted) {
        setState(() => _supported = v);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Android: back from Settings → check Usage access, move on when granted —
  /// or when motion was allowed (it works without Usage access).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_awaitingSettings) {
      return;
    }
    context.read<SleepProvider>().checkPermission().then((granted) {
      if (!mounted) {
        return;
      }
      if (granted || context.read<SleepProvider>().motionGranted) {
        _awaitingSettings = false;
        _finishStep1(SleepMode.auto);
      } else {
        setState(() => _stillOff = true);
      }
    });
  }

  Future<void> _grant() async {
    HapticFeedback.selectionClick();
    final sleep = context.read<SleepProvider>();
    // Busy from the first prompt: a second tap mid-dialog would ask twice.
    setState(() => _busy = true);
    if (SleepPlatform.isAndroid) {
      // Motion first (an in-app prompt), then Usage access in Settings — still
      // offered when motion was allowed; coming back without it then finishes
      // on motion alone (didChangeAppLifecycleState).
      await sleep.requestMotionPermission();
      if (!mounted) {
        return;
      }
      if (await sleep.checkPermission()) {
        await _finishStep1(SleepMode.auto);
        return;
      }
      if (!mounted) {
        return;
      }
      // Free again: back from Settings with nothing allowed, the user must be
      // able to retry or pick manual.
      setState(() => _busy = false);
      _awaitingSettings = true;
      await sleep.requestPermission();
      return;
    }
    await sleep.requestPermission();
    await sleep.requestMotionPermission();
    await _finishStep1(SleepMode.health);
  }

  Future<void> _finishStep1(SleepMode mode) async {
    final sleep = context.read<SleepProvider>();
    setState(() => _busy = true);
    await sleep.enableTracking(mode);
    if (!mounted) {
      return;
    }
    final askShare =
        sleep.hasPartner && sleep.isUsingFirebase && !sleep.myShare;
    if (askShare) {
      setState(() {
        _busy = false;
        _step = 1;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _share() async {
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    await context.read<SleepProvider>().setShare(true);
    navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepDots(step: _step),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: duration,
            child: _step == 0
                ? KeyedSubtree(key: const ValueKey(0), child: _stepOne(context))
                : KeyedSubtree(
                    key: const ValueKey(1),
                    child: _stepTwo(context),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stepOne(BuildContext context) {
    final l10n = context.l10n;
    final supported = _supported ?? true;
    final body = !supported
        ? l10n.sleepSetupUnsupported
        : SleepPlatform.isIOS
        ? l10n.sleepSetupBodyIos
        : l10n.sleepSetupBodyAndroid;
    final hint = SleepPlatform.isIOS
        ? l10n.sleepSetupHintIos
        : (_stillOff
              ? l10n.sleepPermissionStillOff
              : l10n.sleepSetupHintAndroid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Disc(
          icon: IconsaxPlusLinear.moon,
          color: AppColors.accentLavenderDeep,
        ),
        const SizedBox(height: 16),
        _SheetTitle(l10n.sleepSetupTitle, center: true),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        for (final point in [
          l10n.sleepSetupPoint1,
          l10n.sleepSetupPoint2,
          l10n.sleepSetupPoint3,
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  IconsaxPlusBold.tick_circle,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (supported) ...[const SizedBox(height: 4), _HintBox(hint)],
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _busy
                ? null
                : (supported ? _grant : () => _finishStep1(SleepMode.manual)),
            child: Text(supported ? l10n.sleepGrantCta : l10n.sleepManualCta),
          ),
        ),
        if (supported)
          _QuietButton(
            label: l10n.sleepManualCta,
            onTap: _busy ? null : () => _finishStep1(SleepMode.manual),
          ),
      ],
    );
  }

  Widget _stepTwo(BuildContext context) {
    final l10n = context.l10n;
    final sleep = context.watch<SleepProvider>();
    final couple = context.read<CoupleProvider>().couple;
    final myUid = context.read<AuthProvider>().currentUser?.id;
    final partner = couple == null
        ? l10n.reactionPartnerFallback
        : SleepFormat.partnerName(context, couple, myUid);
    final latest = sleep.myNights.values.fold<SleepNight?>(
      null,
      (best, n) => best == null || n.date.compareTo(best.date) > 0 ? n : best,
    );
    final color = PersonPalette.colorOf(sleep.myColorId);
    final example =
        latest ??
        SleepNight(
          date: SleepProvider.lastNightKey(),
          bedAt: DateTime(2026, 1, 1, 23, 30),
          wakeAt: DateTime(2026, 1, 2, 7),
          source: SleepSource.auto,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Disc(
          icon: IconsaxPlusLinear.profile_2user,
          color: AppColors.accentLove,
        ),
        const SizedBox(height: 16),
        _SheetTitle(l10n.sleepShareAskTitle(partner), center: true),
        const SizedBox(height: 8),
        Text(
          l10n.sleepShareAskBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.sleepShareAskPreview(partner.toUpperCase()),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.sleepYou,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  SleepFormat.range(context, example),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                SleepFormat.short(l10n, example.minutes),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.sleepShareAskOnly,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _share,
            icon: const Icon(
              IconsaxPlusBold.heart,
              size: 16,
              color: AppColors.sunset1,
            ),
            label: Text(l10n.sleepShareAskCta),
          ),
        ),
        _QuietButton(
          label: l10n.sleepLater,
          onTap: _busy ? null : () => Navigator.of(context).maybePop(),
        ),
        _QuietButton(
          label: l10n.sleepBackToStep1,
          underline: true,
          onTap: _busy ? null : () => setState(() => _step = 0),
        ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < 2; i++)
        AnimatedContainer(
          duration: AppMotion.fast,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == step ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i == step
                ? AppColors.accentRose
                : AppColors.textTertiary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
    ],
  );
}

// ── D. Edit / log a night ───────────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.dateKey});

  final String dateKey;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late TimeOfDay _bed;
  late TimeOfDay _wake;
  late final TimeOfDay _initialBed;
  late final TimeOfDay _initialWake;
  bool _busy = false;
  SleepNight? _existing;

  /// The other clock a night from a trip was recorded on; null = this phone's.
  late final int? _tz;

  @override
  void initState() {
    super.initState();
    _existing = context.read<SleepProvider>().myNights[widget.dateKey];
    final n = _existing;
    // The times the screen shows: the night's own clock (audit D2).
    _bed = n == null
        ? const TimeOfDay(hour: 23, minute: 0)
        : TimeOfDay.fromDateTime(n.bedClock);
    _wake = n == null
        ? const TimeOfDay(hour: 7, minute: 0)
        : TimeOfDay.fromDateTime(n.wakeClock);
    _initialBed = _bed;
    _initialWake = _wake;
    _tz = n != null && SleepFormat.onOtherClock(n) ? n.tz : null;
  }

  /// Saving an untouched night would still stamp "Đã sửa" for the partner —
  /// only allow it once a time actually changed (a new night can always save).
  bool get _changed =>
      _existing == null || _bed != _initialBed || _wake != _initialWake;

  /// Real minutes asleep: across a DST change an hour more or less than the
  /// two clock readings suggest.
  int get _total {
    final t = _times;
    return t.wakeAt.difference(t.bedAt).inMinutes;
  }

  bool get _valid => _total >= 60 && _total <= 16 * 60;

  /// Both ends are built from the picked hour:minute — not wake minus a
  /// duration, which shifted a night across a DST change by an hour.
  ({DateTime bedAt, DateTime wakeAt}) get _times {
    final day = sleepDateFromKey(widget.dateKey) ?? DateTime.now();
    int minutes(TimeOfDay t) => t.hour * 60 + t.minute;
    // The night's window runs 18:00 the evening before → 14:00: a wake time
    // from 18:00 on belongs to the evening before, not to the next night.
    final wakeDay = _wake.hour >= 18 ? day.day - 1 : day.day;
    // A bed time later on the clock than the wake time (or equal) means the
    // night crossed midnight.
    final bedDay = minutes(_bed) < minutes(_wake) ? wakeDay : wakeDay - 1;
    // A night from a trip is picked on its own clock, so it is read back on
    // it: on this phone's it would move by the time difference.
    final tz = _tz;
    DateTime at(int d, TimeOfDay t) => tz == null
        ? DateTime(day.year, day.month, d, t.hour, t.minute)
        : DateTime.utc(
            day.year,
            day.month,
            d,
            t.hour,
            t.minute,
          ).subtract(Duration(minutes: tz)).toLocal();
    return (bedAt: at(bedDay, _bed), wakeAt: at(wakeDay, _wake));
  }

  Future<void> _pick({required bool bed}) async {
    final l10n = context.l10n;
    final picked = await showAppTimePicker(
      context,
      initialTime: bed ? _bed : _wake,
      title: bed ? l10n.sleepEditBedTitle : l10n.sleepEditWakeTitle,
      subtitle: l10n.sleepPickerSubtitle,
    );
    if (picked != null && mounted) {
      setState(() => bed ? _bed = picked : _wake = picked);
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final t = _times;
      await context.read<SleepProvider>().saveNight(
        widget.dateKey,
        t.bedAt,
        t.wakeAt,
        tz: _tz,
      );
      HapticFeedback.lightImpact();
      navigator.maybePop();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.sleepSaveFailed)));
    }
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await context.read<SleepProvider>().deleteNight(widget.dateKey);
      HapticFeedback.lightImpact();
      navigator.maybePop();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.sleepSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final logging =
        _existing == null || _existing!.source == SleepSource.manual;
    return _SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle(SleepFormat.nightTitle(l10n, widget.dateKey)),
          const SizedBox(height: 4),
          Text(
            _existing == null
                ? l10n.sleepManualSubtitle
                : l10n.sleepEditSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _TimeTile(
            icon: IconsaxPlusLinear.lamp_slash,
            label: l10n.sleepEditBedTitle,
            value: _bed.format(context),
            onTap: _busy ? null : () => _pick(bed: true),
          ),
          const SizedBox(height: 10),
          _TimeTile(
            icon: IconsaxPlusLinear.sun_fog,
            label: l10n.sleepEditWakeTitle,
            value: _wake.format(context),
            onTap: _busy ? null : () => _pick(bed: false),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                IconsaxPlusLinear.moon,
                size: 18,
                color: AppColors.accentLavenderDeep,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.sleepEditTotal(SleepFormat.long(l10n, _total)),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!_valid) ...[
            const SizedBox(height: 6),
            Text(
              l10n.sleepEditInvalid,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            logging ? l10n.sleepManualNote : l10n.sleepEditNote,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _busy || !_valid || !_changed ? null : _save,
              child: Text(l10n.save),
            ),
          ),
          if (_existing != null)
            TextButton.icon(
              onPressed: _busy ? null : _delete,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.textPrimary,
              ),
              icon: const Icon(
                IconsaxPlusLinear.trash,
                size: 16,
                color: AppColors.error,
              ),
              label: Text(
                l10n.sleepDeleteNight,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentRose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.accentLove),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
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
    );
  }
}

// ── E. How it works ─────────────────────────────────────────────────────────

class _HowItWorksSheet extends StatelessWidget {
  const _HowItWorksSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paragraphs = SleepPlatform.isIOS
        ? [
            l10n.sleepHowBody1Ios,
            l10n.sleepHowIphoneInBed,
            l10n.sleepHowMotion,
            l10n.sleepHowBody3,
            l10n.sleepHowBody4Ios,
          ]
        : [
            l10n.sleepHowBody1,
            l10n.sleepHowBody2,
            l10n.sleepHowMotion,
            l10n.sleepHowBody3,
            l10n.sleepHowBody4,
          ];
    return _SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle(l10n.sleepHowItWorks),
          const SizedBox(height: 12),
          for (final p in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                p,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.sleepGotIt),
            ),
          ),
        ],
      ),
    );
  }
}
