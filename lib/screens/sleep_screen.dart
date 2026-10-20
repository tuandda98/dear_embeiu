import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../widgets/status_bar_scrim.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/sleep_night.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/sleep_provider.dart';
import '../services/sleep_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/person_palette.dart';
import '../utils/sleep_calculator.dart';
import '../widgets/content_card.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/icon_badge.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sleep/moon_glyph.dart';
import '../widgets/person_label.dart';
import '../widgets/sleep/sleep_card.dart'
    show DurationText, SourcePill, TheirClockPill;
import '../widgets/sleep/sleep_format.dart';
import '../widgets/sleep/sleep_sheets.dart';
import '../widgets/sub_screen_header.dart';

void openSleepScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'Sleep'),
      builder: (_) => const SleepScreen(),
    ),
  );
}

enum _View { both, me, partner }

/// "Giấc ngủ" (feature sleep, design §B): the moon calendar, the selected
/// night, this month's numbers and the sharing / colour settings.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  late DateTime _month;
  late String _selected;
  _View _view = _View.both;
  int _monthDirection = 0;

  @override
  void initState() {
    super.initState();
    _selected = SleepProvider.lastNightKey();
    final d = sleepDateFromKey(_selected)!;
    _month = DateTime(d.year, d.month);
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) {
      return; // no future months
    }
    HapticFeedback.selectionClick();
    setState(() {
      _monthDirection = delta;
      _month = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sleep = context.watch<SleepProvider>();
    final couple = context.watch<CoupleProvider>().couple;
    final myUid = context.read<AuthProvider>().currentUser?.id;
    final partnerName = couple == null
        ? l10n.reactionPartnerFallback
        : SleepFormat.partnerName(context, couple, myUid);
    final view = sleep.partnerShares ? _view : _View.me;

    if (sleep.consumePartnerLoadFailed()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.sleepLoadFailed)));
        }
      });
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16 + MediaQuery.paddingOf(context).top,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SubScreenHeader(
                    badge: l10n.sleepBadge,
                    badgeIcon: IconsaxPlusLinear.moon,
                  ),
                  const SizedBox(height: 20),
                  if (sleep.needsPermission) ...[
                    _PermissionBanner(onOpen: sleep.openPermissionSettings),
                    const SizedBox(height: 12),
                  ],
                  if (sleep.healthHasNoData && !sleep.healthHintDismissed) ...[
                    _TipCard(
                      icon: IconsaxPlusLinear.health,
                      text: l10n.sleepIosHealthHint,
                      onOpen: sleep.openPermissionSettings,
                      onDismiss: sleep.dismissHealthHint,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (sleep.showMotionHint) ...[
                    _TipCard(
                      icon: IconsaxPlusLinear.mobile,
                      text: l10n.sleepMotionHint,
                      action: l10n.sleepMotionAllow,
                      onOpen: sleep.requestMotionPermission,
                      onDismiss: sleep.dismissMotionHint,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (sleep.partnerShares) ...[
                    _Segmented(
                      view: view,
                      partnerName: partnerName,
                      myColor: PersonPalette.colorOf(sleep.myColorId),
                      partnerColor: PersonPalette.colorOf(sleep.partnerColorId),
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _view = v);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!sleep.isLoaded)
                    const ShimmerSkeleton(height: 420, borderRadius: 24)
                  else
                    _MoonCalendar(
                      month: _month,
                      direction: _monthDirection,
                      view: view,
                      selected: _selected,
                      partnerName: partnerName,
                      onPrev: () => _shiftMonth(-1),
                      onNext: () => _shiftMonth(1),
                      onSelect: (key) {
                        HapticFeedback.selectionClick();
                        setState(() => _selected = key);
                      },
                    ),
                  const SizedBox(height: 16),
                  _NightDetail(
                    dateKey: _selected,
                    view: view,
                    partnerName: partnerName,
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(title: _monthTitle(context)),
                  const SizedBox(height: 12),
                  _MonthStats(month: _month, partnerName: partnerName),
                  const SizedBox(height: 24),
                  _SettingsCard(partnerName: partnerName),
                ],
              ),
            ),
            const StatusBarScrim(),
          ],
        ),
      ),
    );
  }

  String _monthTitle(BuildContext context) {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) {
      return context.l10n.sleepMonthSection;
    }
    return SleepFormat.monthTitle(context, _month);
  }
}

// ── Banners ─────────────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                IconsaxPlusLinear.warning_2,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.sleepPermissionBanner,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: AppColors.textPrimary,
              ),
              child: Text(
                l10n.sleepOpenSettings,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dismissible tip: state M (iOS, no Health data → Sleep Schedule) and the
/// one-time motion offer (vòng vá 1, P2-6 — with an [action] button).
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.text,
    required this.onOpen,
    required this.onDismiss,
    this.action,
  });

  final IconData icon;
  final String text;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final action = this.action;
    // `*…*` in the copy marks the bold part.
    final parts = text.split('*');
    return Material(
      color: AppColors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.accentLove),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        children: [
                          for (var i = 0; i < parts.length; i++)
                            TextSpan(
                              text: parts[i],
                              style: i.isOdd
                                  ? const TextStyle(fontWeight: FontWeight.w800)
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  ),
                  HeaderIconButton(
                    icon: IconsaxPlusLinear.close_circle,
                    iconSize: 20,
                    iconColor: AppColors.textSecondary,
                    semanticsLabel: l10n.sleepHintDismiss,
                    onTap: onDismiss,
                  ),
                ],
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Segmented ───────────────────────────────────────────────────────────────

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.view,
    required this.partnerName,
    required this.myColor,
    required this.partnerColor,
    required this.onChanged,
  });

  final _View view;
  final String partnerName;
  final Color myColor;
  final Color partnerColor;
  final ValueChanged<_View> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        _pill(context, _View.both, l10n.sleepViewBoth, null),
        const SizedBox(width: 8),
        _pill(context, _View.me, l10n.sleepYou, myColor),
        const SizedBox(width: 8),
        Flexible(
          child: _pill(context, _View.partner, partnerName, partnerColor),
        ),
      ],
    );
  }

  Widget _pill(BuildContext context, _View value, String label, Color? dot) {
    final selected = view == value;
    final duration = AppMotion.reduceMotion(context)
        ? Duration.zero
        : AppMotion.fast;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.curve,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.textPrimary
                : AppColors.textSecondary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.textPrimary : AppColors.white,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Moon calendar (night-sky card) ──────────────────────────────────────────

const Color _skyTop = Color(0xFF2E2A52);
const Color _skyMid = Color(0xFF3A3160);
const Color _skyBottom = Color(0xFF45396C);
const Color _moonCream = Color(0xFFFFF6D6);
const Color _skyHeart = Color(0xFFFF8FA3);

class _MoonCalendar extends StatelessWidget {
  const _MoonCalendar({
    required this.month,
    required this.direction,
    required this.view,
    required this.selected,
    required this.partnerName,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  final DateTime month;
  final int direction;
  final _View view;
  final String selected;
  final String partnerName;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final sleep = context.watch<SleepProvider>();
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final reduce = AppMotion.reduceMotion(context);
    final weekdays = List<String>.generate(
      7,
      (i) => DateFormat.E(locale).format(DateTime(2024, 1, 1 + i)),
    );
    final myColor = PersonPalette.colorOf(sleep.myColorId);
    final partnerColor = PersonPalette.colorOf(sleep.partnerColorId);

    final grid = GestureDetector(
      key: ValueKey('${month.year}-${month.month}-${view.name}'),
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v > 250) {
          onPrev();
        } else if (v < -250) {
          onNext();
        }
      },
      child: _MonthGrid(
        month: month,
        view: view,
        selected: selected,
        partnerName: partnerName,
        myNights: sleep.myNights,
        partnerNights: sleep.partnerNights,
        myColor: myColor,
        partnerColor: partnerColor,
        onSelect: onSelect,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyMid, _skyBottom],
          stops: [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _skyTop.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ponytail: stars are static (no twinkle) — Reduce Motion for free;
          // add a slow twinkle like the love tree if the card feels flat.
          const Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _SkyArrow(
                      icon: IconsaxPlusLinear.arrow_left_2,
                      label: l10n.sleepPrevMonth,
                      onTap: onPrev,
                    ),
                    Expanded(
                      child: Text(
                        SleepFormat.monthTitle(context, month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _SkyArrow(
                      icon: IconsaxPlusLinear.arrow_right_3,
                      label: l10n.sleepNextMonth,
                      onTap: isCurrentMonth ? null : onNext,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final w in weekdays)
                      Expanded(
                        child: Center(
                          child: Text(
                            w.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.66),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: reduce ? Duration.zero : AppMotion.fast,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: Offset(direction * 0.03, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: grid,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: AppColors.white.withValues(alpha: 0.14),
                ),
                const SizedBox(height: 12),
                _Legend(
                  both: view == _View.both,
                  partnerName: partnerName,
                  myColor: myColor,
                  partnerColor: partnerColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyArrow extends StatelessWidget {
  const _SkyArrow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // excludeSemantics drops the InkWell's tap action: TalkBack / VoiceOver
    // need it on this node.
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              icon,
              size: 20,
              color: AppColors.white.withValues(alpha: onTap == null ? 0.3 : 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.view,
    required this.selected,
    required this.partnerName,
    required this.myNights,
    required this.partnerNights,
    required this.myColor,
    required this.partnerColor,
    required this.onSelect,
  });

  final DateTime month;
  final _View view;
  final String selected;
  final String partnerName;
  final Map<String, SleepNight> myNights;
  final Map<String, SleepNight> partnerNights;
  final Color myColor;
  final Color partnerColor;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _dayCell(context, DateTime(month.year, month.month, d), today),
    ];
    // The 0.70 shape, but never shorter than what a cell holds at the reader's
    // text size: day number + today bar 8 + moon 22 + margin 4 + ring 3
    // (+1 to spare).
    final minHeight = _lineHeight(context, 12) + 38;
    return LayoutBuilder(
      builder: (context, c) => GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisExtent: math.max(c.maxWidth / 7 / 0.70, minHeight),
        children: cells,
      ),
    );
  }

  Widget _dayCell(BuildContext context, DateTime date, DateTime today) {
    final l10n = context.l10n;
    final key = sleepDateKey(date);
    final future = date.isAfter(today);
    final isToday = date == today;
    final isSelected = key == selected;
    final mine = myNights[key];
    final theirs = partnerNights[key];
    final both = view == _View.both;
    final heart =
        both &&
        mine != null &&
        theirs != null &&
        mine.overlapWith(theirs) >= kSleepTogetherHeartMinutes;

    Widget moon(SleepNight? n, Color color, double size) =>
        MoonGlyph(size: size, color: color, phase: n?.phase, onSky: true);

    final Widget moons;
    if (future) {
      moons = const SizedBox(height: 22);
    } else if (both) {
      // Two moons need 32dp; a 320dp phone's cell has ~31.
      moons = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            moon(mine, myColor, 14),
            const SizedBox(width: 4),
            moon(theirs, partnerColor, 14),
          ],
        ),
      );
    } else {
      final n = view == _View.partner ? theirs : mine;
      moons = moon(n, view == _View.partner ? partnerColor : myColor, 22);
    }

    String part(String name, SleepNight? n) {
      if (n == null) {
        return l10n.sleepSemanticsNoData(name);
      }
      // Read as the pill shows it: "Ghi tay" is not "Đã sửa".
      final label = switch (n.source) {
        SleepSource.manual => ' ${l10n.sleepManualSemantics}',
        SleepSource.edited => ' ${l10n.sleepEditedSemantics}',
        _ => '',
      };
      return '${l10n.sleepSemanticsSlept(name, SleepFormat.long(l10n, n.minutes), SleepFormat.phase(l10n, n.phase))}'
          '$label';
    }

    final summary = [
      if (view != _View.partner) part(l10n.sleepYou, mine),
      if (view != _View.me) part(partnerName, theirs),
      if (heart) l10n.sleepMoonTogether,
    ].join('; ');

    final reduce = AppMotion.reduceMotion(context);
    final VoidCallback? tap = future ? null : () => onSelect(key);
    return Semantics(
      label: future
          ? '${date.day}'
          : l10n.sleepDaySemantics('${date.day}', summary),
      selected: isSelected,
      button: !future,
      excludeSemantics: true,
      onTap: tap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 160),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.white.withValues(alpha: 0.85)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: AppColors.white.withValues(
                        alpha: future ? 0.34 : 0.92,
                      ),
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 2,
                    margin: const EdgeInsets.only(top: 1, bottom: 5),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  moons,
                ],
              ),
              if (heart)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    IconsaxPlusBold.heart,
                    size: 10,
                    color: _skyHeart,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.both,
    required this.partnerName,
    required this.myColor,
    required this.partnerColor,
  });

  final bool both;
  final String partnerName;
  final Color myColor;
  final Color partnerColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.sleepLegend0,
      l10n.sleepLegend1,
      l10n.sleepLegend2,
      l10n.sleepLegend3,
      l10n.sleepLegend4,
    ];
    final caption = TextStyle(
      color: AppColors.white.withValues(alpha: 0.82),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final keyStyle = TextStyle(
      color: AppColors.white.withValues(alpha: 0.80),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    Widget dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: Column(
                  children: [
                    MoonGlyph(
                      size: 18,
                      color: _moonCream,
                      phase: i,
                      faintAlpha: 0.22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.sleepMoonTagline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (both) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  dot(PersonPalette.onSky(myColor)),
                  const SizedBox(width: 5),
                  Text(l10n.sleepMoonLeft, style: keyStyle),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  dot(PersonPalette.onSky(partnerColor)),
                  const SizedBox(width: 5),
                  // A long name ends in "…" instead of running off the card.
                  Flexible(
                    child: Text(
                      l10n.sleepMoonRight(partnerName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: keyStyle,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconsaxPlusBold.heart, size: 10, color: _skyHeart),
                  const SizedBox(width: 5),
                  // 320dp at 200%: wraps instead of running 19px off the card.
                  Flexible(
                    child: Text(l10n.sleepMoonTogether, style: keyStyle),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  // 16 fixed stars (x, y, radius, alpha) — same idea as the love-tree sky.
  static const List<List<double>> _stars = [
    [0.06, 0.04, 1.2, 0.45],
    [0.18, 0.09, 0.8, 0.30],
    [0.31, 0.03, 1.0, 0.40],
    [0.44, 0.08, 0.7, 0.28],
    [0.57, 0.02, 1.1, 0.50],
    [0.69, 0.07, 0.8, 0.35],
    [0.83, 0.04, 1.0, 0.45],
    [0.94, 0.10, 0.7, 0.30],
    [0.11, 0.30, 0.7, 0.25],
    [0.92, 0.36, 0.9, 0.35],
    [0.04, 0.55, 0.8, 0.30],
    [0.97, 0.62, 0.7, 0.28],
    [0.08, 0.80, 1.0, 0.40],
    [0.90, 0.84, 0.8, 0.32],
    [0.38, 0.95, 0.7, 0.25],
    [0.64, 0.97, 0.9, 0.35],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      canvas.drawCircle(
        Offset(size.width * s[0], size.height * s[1]),
        s[2],
        Paint()..color = Colors.white.withValues(alpha: s[3]),
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) => false;
}

// ── Night detail ────────────────────────────────────────────────────────────

class _NightDetail extends StatelessWidget {
  const _NightDetail({
    required this.dateKey,
    required this.view,
    required this.partnerName,
  });

  final String dateKey;
  final _View view;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sleep = context.watch<SleepProvider>();
    final mine = sleep.myNights[dateKey];
    final theirs = sleep.partnerNights[dateKey];
    final myColor = PersonPalette.colorOf(sleep.myColorId);
    final partnerColor = PersonPalette.colorOf(sleep.partnerColorId);
    final showMe = view != _View.partner;
    final showPartner = view != _View.me && sleep.partnerShares;
    final lockedPartner = sleep.hasPartner && !sleep.partnerShares;
    final editable = sleepNightEditable(dateKey);

    final lanes = <({String name, Color color, SleepNight? night})>[
      if (showMe) (name: l10n.sleepYou, color: myColor, night: mine),
      if (showPartner) (name: partnerName, color: partnerColor, night: theirs),
    ];
    final overlapNights = view == _View.both && mine != null && theirs != null
        ? (mine, theirs)
        : null;

    // Reduce Motion: no AnimatedSize at all — with a zero duration it
    // re-lays itself out mid-layout (debug assert when another night of a
    // different height is picked).
    Widget sized(Widget child) => AppMotion.reduceMotion(context)
        ? child
        : AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: child,
          );
    return ContentCard(
      padding: const EdgeInsets.all(16),
      child: sized(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              SleepFormat.nightTitle(l10n, dateKey),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _Timeline(
              key: ValueKey('$dateKey-${view.name}'),
              dateKey: dateKey,
              lanes: lanes,
              overlap: overlapNights,
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.10),
            ),
            const SizedBox(height: 4),
            if (showMe)
              _PersonRow(
                name: l10n.sleepYou,
                color: myColor,
                night: mine,
                emptyText: l10n.sleepNotRecorded,
                hint: mine == null && editable ? l10n.sleepManualHint : null,
                onEdit: editable
                    ? () => showSleepEditSheet(context, dateKey: dateKey)
                    : null,
                locked: !editable,
                isMe: true,
              ),
            if (showPartner)
              _PersonRow(
                name: partnerName,
                color: partnerColor,
                night: theirs,
                emptyText: l10n.sleepPartnerNightEmpty,
                theirClock: theirs != null && SleepFormat.onOtherClock(theirs),
              ),
            if (lockedPartner && view != _View.partner)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      IconsaxPlusLinear.lock,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.sleepPartnerNotSharedLong(partnerName),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (overlapNights != null) ...[
              const SizedBox(height: 8),
              _OverlapFooter(mine: mine!, theirs: theirs!),
            ],
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    super.key,
    required this.dateKey,
    required this.lanes,
    required this.overlap,
  });

  final String dateKey;
  final List<({String name, Color color, SleepNight? night})> lanes;
  final (SleepNight, SleepNight)? overlap;

  static const double _labelWidth = 64;
  static const double _rowGap = 6;

  /// The axis runs 18:00 the evening before → 14:00, the same window nights
  /// are worked out in (a 12:30 wake-up used to be drawn at 12:00).
  static const int span = 20 * 60;

  @override
  Widget build(BuildContext context) {
    if (lanes.isEmpty) {
      return const SizedBox.shrink();
    }
    final wake = sleepDateFromKey(dateKey) ?? DateTime.now();
    final reduce = AppMotion.reduceMotion(context);
    // A lane is as tall as its name at the reader's text size: a fixed 16
    // cut the "y" of "Nguyễn" (the name's line is 18 even at 100%).
    final rowHeight = math.max(16.0, _lineHeight(context, 12).ceilToDouble());
    final height = lanes.length * rowHeight + (lanes.length - 1) * _rowGap;

    // Each bar on its own night's clock (audit D2): the partner abroad sleeps
    // 23:00–07:00 on their clock, not 13:00–21:00 on mine.
    ({int from, int to, List<int> wakeUps})? bar(SleepNight? n) => n == null
        ? null
        : (
            from: _sinceEvening(n.bedClock, wake),
            to: _sinceEvening(n.wakeClock, wake),
            wakeUps: n.wakeUps,
          );

    // "Asleep together" = where the two drawn bars meet, when both nights are
    // read on one clock: this phone's, or the same one abroad (the test of
    // `SleepFormat.onOtherClock`). Otherwise the band is skipped (the footer
    // below still counts the minutes). Comparing minutes instead lost the band
    // to the seconds both bars drop, and a DST night drew it an hour off.
    ({int from, int to})? together;
    final o = overlap;
    if (o != null) {
      final (a, b) = o;
      int? clock(SleepNight n) => SleepFormat.onOtherClock(n) ? n.tz : null;
      final (ba, bb) = (bar(a)!, bar(b)!);
      final from = math.max(ba.from, bb.from);
      final to = math.min(ba.to, bb.to);
      if (clock(a) == clock(b) && a.overlapWith(b) > 0 && to > from) {
        together = (from: from, to: to);
      }
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: _labelWidth + 8),
          child: _HourAxis(),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _labelWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < lanes.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : _rowGap),
                      child: SizedBox(
                        height: rowHeight,
                        child: Text(
                          lanes[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: reduce ? 1 : 0, end: 1),
                duration: reduce ? Duration.zero : AppMotion.slow,
                curve: AppMotion.curve,
                builder: (context, progress, _) => CustomPaint(
                  size: Size(double.infinity, height),
                  painter: _LanePainter(
                    lanes: [
                      for (final l in lanes)
                        (color: l.color, bar: bar(l.night)),
                    ],
                    together: together,
                    progress: progress,
                    rowHeight: rowHeight,
                    rowGap: _rowGap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One line of inherited [fontSize] text at the reader's text size (the
/// theme's body style sets the line height, 1.5).
double _lineHeight(BuildContext context, double fontSize) =>
    MediaQuery.textScalerOf(context).scale(fontSize) *
    (DefaultTextStyle.of(context).style.height ?? 1.5);

/// Minutes from 18:00 the evening before [wakeDay] to [clock] — a reading of
/// a night's own clock (`SleepNight.bedClock` / `wakeClock`), so only its
/// fields count, never its time zone.
int _sinceEvening(DateTime clock, DateTime wakeDay) =>
    DateTime.utc(clock.year, clock.month, clock.day, clock.hour, clock.minute)
        .difference(
          DateTime.utc(wakeDay.year, wakeDay.month, wakeDay.day - 1, 18),
        )
        .inMinutes;

/// "18h · 22h · 2h · 6h · 10h · 14h" over the lanes. When big text would make
/// neighbours overlap, every other tick is labelled instead — the labels keep
/// the size the reader asked for.
class _HourAxis extends StatelessWidget {
  const _HourAxis();

  static const TextStyle _style = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    // Measured with the inherited style too (font, line height), like the Text.
    final widest = TextPainter(
      text: TextSpan(
        text: '22h',
        style: DefaultTextStyle.of(context).style.merge(_style),
      ),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout();
    final labelWidth = widest.width;
    final height = widest.height;
    widest.dispose();
    Widget label(int i) =>
        Text('${(18 + i * 4) % 24}h', maxLines: 1, style: _style);
    return LayoutBuilder(
      builder: (context, c) {
        final step = c.maxWidth / 5; // 4 h
        // An edge label plus half of its neighbour must fit in the gap.
        final need = labelWidth * 1.5 + 4;
        final every = need <= step ? 1 : (need <= step * 2 ? 2 : 5);
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i <= 5; i += every)
                if (i == 0)
                  Positioned(left: 0, child: label(i))
                else if (i == 5)
                  Positioned(right: 0, child: label(i))
                else
                  Positioned(
                    left: step * i,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: label(i),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _LanePainter extends CustomPainter {
  _LanePainter({
    required this.lanes,
    required this.together,
    required this.progress,
    required this.rowHeight,
    required this.rowGap,
  });

  /// Per lane: minutes on the axis (see [_sinceEvening]); wake-ups are
  /// minutes after `from`.
  final List<({Color color, ({int from, int to, List<int> wakeUps})? bar})>
  lanes;
  final ({int from, int to})? together;
  final double progress;
  final double rowHeight;
  final double rowGap;

  double _x(int minute, double width) =>
      width * minute.clamp(0, _Timeline.span) / _Timeline.span;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final t = together;
    if (t != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(_x(t.from, w), -4, _x(t.to, w), size.height + 4),
          const Radius.circular(8),
        ),
        Paint()..color = AppColors.textPrimary.withValues(alpha: 0.07),
      );
    }
    final reveal = w * progress;
    for (var i = 0; i < lanes.length; i++) {
      final top = i * (rowHeight + rowGap) + (rowHeight - 10) / 2;
      final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, w, 10),
        const Radius.circular(999),
      );
      canvas.drawRRect(track, Paint()..color = AppColors.surfaceLight);
      final n = lanes[i].bar;
      if (n == null) {
        continue;
      }
      final x1 = _x(n.from, w);
      final x2 = _x(n.to, w).clamp(x1, reveal < x1 ? x1 : reveal);
      if (x2 <= x1) {
        continue;
      }
      canvas.save();
      canvas.clipRRect(track);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x1, top, x2, top + 10),
          const Radius.circular(999),
        ),
        Paint()..color = lanes[i].color,
      );
      for (final m in n.wakeUps) {
        final x = _x(n.from + m, w);
        if (x > x1 && x < x2) {
          canvas.drawRect(
            Rect.fromLTWH(x - 1, top, 2, 10),
            Paint()..color = AppColors.white,
          );
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LanePainter old) => true;
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.color,
    required this.night,
    required this.emptyText,
    this.hint,
    this.onEdit,
    this.locked = false,
    this.isMe = false,
    this.theirClock = false,
  });

  final String name;
  final Color color;
  final SleepNight? night;
  final String emptyText;
  final String? hint;
  final VoidCallback? onEdit;
  final bool locked;
  final bool isMe;

  /// The partner's times are on their clock, not this phone's (audit D2).
  final bool theirClock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final n = night;
    const strong = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    const sub = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                MoonGlyph(
                  size: 18,
                  color: color,
                  phase: n?.phase,
                  faintAlpha: 0.18,
                  emptyColor: AppColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (n != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    SleepFormat.short(l10n, n.minutes),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (isMe)
                  onEdit != null
                      // Its own stop, after the night it edits.
                      ? Semantics(
                          container: true,
                          child: HeaderIconButton(
                            icon: IconsaxPlusLinear.edit_2,
                            iconSize: 18,
                            semanticsLabel: l10n.sleepEditButton,
                            onTap: onEdit!,
                          ),
                        )
                      : const SizedBox(width: 44),
              ],
            ),
          ),
          // The times on a line of their own: beside the name they were cut
          // to "23:…" on small phones and big text (audit N4).
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              n == null
                  ? emptyText
                  : '${SleepFormat.time(context, n.bedClock)} → ${SleepFormat.time(context, n.wakeClock)}',
              style: n == null
                  ? strong.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    )
                  : strong,
            ),
          ),
          if (n != null)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${SleepFormat.awakenings(l10n, n)} · ${SleepFormat.phase(l10n, n.phase).toLowerCase()}',
                    style: sub,
                  ),
                  if (n.isLabeled) SourcePill(source: n.source),
                  if (theirClock) const TheirClockPill(),
                ],
              ),
            ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(hint!, style: sub),
            ),
          if (isMe && locked)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                l10n.sleepEditLocked,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
    // TalkBack / VoiceOver: one stop per person — name, duration, times and
    // details read together — then the edit button, which used to cut in
    // between the duration and the times (audit N4b).
    return Semantics(container: true, child: row);
  }
}

class _OverlapFooter extends StatelessWidget {
  const _OverlapFooter({required this.mine, required this.theirs});

  final SleepNight mine;
  final SleepNight theirs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overlap = mine.overlapWith(theirs);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusBold.heart,
            size: 14,
            color: AppColors.accentLove,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              overlap == 0
                  ? l10n.sleepNoOverlapNight
                  : l10n.sleepTogether(SleepFormat.short(l10n, overlap)),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── This month ──────────────────────────────────────────────────────────────

class _MonthStats extends StatelessWidget {
  const _MonthStats({required this.month, required this.partnerName});

  final DateTime month;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sleep = context.watch<SleepProvider>();
    final prefix = '${month.year}-${month.month.toString().padLeft(2, '0')}-';
    bool inMonth(String key) => key.startsWith(prefix);
    final mine = sleepMonthStats(
      sleep.myNights.values.where((n) => inMonth(n.date)),
    );
    final shares = sleep.partnerShares;
    final theirs = shares
        ? sleepMonthStats(
            sleep.partnerNights.values.where((n) => inMonth(n.date)),
          )
        : null;
    final together = shares
        ? sleepTogetherStats(sleep.myNights, sleep.partnerNights, inMonth)
        : null;

    final myTile = _StatTile(
      name: l10n.sleepYou,
      color: PersonPalette.colorOf(sleep.myColorId),
      stats: mine,
    );
    return ContentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shares)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: myTile),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      name: partnerName,
                      color: PersonPalette.colorOf(sleep.partnerColorId),
                      stats: theirs,
                    ),
                  ),
                ],
              ),
            )
          else
            myTile,
          if (together != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    IconsaxPlusBold.heart,
                    size: 14,
                    color: AppColors.accentLove,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.sleepTogetherNights(together.heartNights)} · '
                    '${l10n.sleepTogetherAvg(SleepFormat.short(l10n, together.avgOverlap))}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.name,
    required this.color,
    required this.stats,
  });

  final String name;
  final Color color;
  final SleepMonthStats? stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = stats;
    const muted = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonLabel(name: name, color: color),
          const SizedBox(height: 8),
          if (s == null)
            Text(l10n.sleepNoData, style: muted)
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: DurationText(minutes: s.avgMinutes, numberSize: 20),
                ),
                Text(l10n.sleepPerNight, style: muted),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sleepAvgTimes(
                SleepFormat.minuteOfDay(context, s.avgBedMinute),
                SleepFormat.minuteOfDay(context, s.avgWakeMinute),
              ),
              style: muted,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.sleepFullNights(s.fullNights),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(l10n.sleepOfNights(s.nights), style: muted),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Settings ────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.partnerName});

  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sleep = context.watch<SleepProvider>();
    final divider = Padding(
      padding: const EdgeInsets.only(left: 74),
      child: Container(
        height: 1,
        color: AppColors.textSecondary.withValues(alpha: 0.10),
      ),
    );
    final String source;
    final IconData sourceIcon;
    if (!sleep.enabled || sleep.mode == SleepMode.manual) {
      source = l10n.sleepSourceManual;
      sourceIcon = IconsaxPlusLinear.edit;
    } else if (sleep.mode == SleepMode.health && !sleep.healthHasNoData) {
      source = l10n.sleepSourceHealth;
      sourceIcon = IconsaxPlusLinear.health;
    } else if (sleep.mode == SleepMode.health
        ? sleep.hasRecentAutoNight
        : sleep.onMotionOnly && sleep.motionGranted) {
      source = l10n.sleepSourceMotion;
      sourceIcon = IconsaxPlusLinear.mobile;
    } else if (sleep.mode == SleepMode.health) {
      // Health on, nothing in it yet: say so rather than "Ghi tay", which
      // read as "the permission didn't stick" (user report 2026-10-13).
      source = l10n.sleepSourceHealthEmpty;
      sourceIcon = IconsaxPlusLinear.health;
    } else {
      source = l10n.sleepSourcePhone;
      sourceIcon = IconsaxPlusLinear.mobile;
    }
    final canShare = sleep.isUsingFirebase && sleep.hasPartner;

    return ContentCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (canShare) ...[
            _SettingsRow(
              icon: IconsaxPlusLinear.profile_2user,
              tint: AppColors.accentLove,
              title: l10n.sleepShareToggle,
              subtitle: l10n.sleepShareToggleSub,
              trailing: Switch.adaptive(
                value: sleep.myShare,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.textPrimary,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  sleep.setShare(v);
                },
              ),
            ),
            divider,
          ],
          _ColorPicker(partnerName: partnerName),
          divider,
          _SettingsRow(
            icon: sourceIcon,
            tint: AppColors.accentLavenderDeep,
            title: l10n.sleepSourceRow(source),
            onTap: () => showSleepSetupSheet(context),
          ),
          divider,
          _SettingsRow(
            icon: IconsaxPlusLinear.info_circle,
            tint: AppColors.accentLavenderDeep,
            title: l10n.sleepHowItWorks,
            onTap: () => showSleepHowItWorksSheet(context),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.tint,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            IconBadge(icon, tint: tint),
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(
                        IconsaxPlusLinear.arrow_right_3,
                        size: 18,
                        color: AppColors.textTertiary,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.partnerName});

  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sleep = context.watch<SleepProvider>();
    final mine = sleep.myColorId;
    final partner = sleep.partnerColorChoice;
    final blocked = partner == null
        ? const <String>[]
        : PersonPalette.blockedBy(partner);

    final String subtitle;
    if (sleep.myColorAdjusted) {
      subtitle = l10n.sleepColorAutoChanged(SleepFormat.colorName(l10n, mine));
    } else if (partner == null) {
      subtitle = l10n.sleepMyColorSolo;
    } else if (blocked.isEmpty) {
      subtitle = l10n.sleepMyColorSubNoBlock(
        partnerName,
        SleepFormat.colorName(l10n, partner),
      );
    } else {
      subtitle = l10n.sleepMyColorSub(
        partnerName,
        SleepFormat.colorName(l10n, partner),
        blocked.map((id) => SleepFormat.colorName(l10n, id)).join(', '),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PersonPalette.colorOf(mine).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  IconsaxPlusLinear.colorfilter,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sleepMyColor,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 6,
            // Fixed height (not an aspect ratio) so narrow screens and large
            // text sizes don't clip the swatch label.
            mainAxisExtent: 48 + 18 * MediaQuery.textScalerOf(context).scale(1),
            children: [
              for (final c in PersonPalette.colors)
                _Swatch(
                  color: c.color,
                  label: c.id == partner
                      ? partnerName
                      : SleepFormat.colorName(l10n, c.id),
                  selected: c.id == mine,
                  taken: c.id == partner,
                  tooClose: blocked.contains(c.id),
                  semantics: c.id == partner
                      ? l10n.sleepColorTakenSemantics(partnerName)
                      : blocked.contains(c.id)
                      ? '${SleepFormat.colorName(l10n, c.id)}, ${l10n.sleepColorTooClose(partnerName)}'
                      : SleepFormat.colorName(l10n, c.id),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    sleep.setColor(c.id);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.taken,
    required this.tooClose,
    required this.semantics,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final bool taken;
  final bool tooClose;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = taken || tooClose;
    final duration = AppMotion.reduceMotion(context)
        ? Duration.zero
        : AppMotion.fast;
    final tap = disabled || selected ? null : onTap;
    return Semantics(
      button: true,
      enabled: !disabled,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      onTap: tap,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: tap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: duration,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.textPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: disabled ? 0.30 : 1),
                ),
                child: selected
                    ? const Icon(
                        IconsaxPlusBold.tick_circle,
                        size: 16,
                        color: AppColors.white,
                      )
                    : tooClose
                    ? CustomPaint(painter: _SlashPainter())
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.78),
      Offset(size.width * 0.78, size.height * 0.22),
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SlashPainter oldDelegate) => false;
}
