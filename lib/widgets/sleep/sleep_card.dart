import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/couple.dart';
import '../../models/sleep_night.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../screens/sleep_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/person_palette.dart';
import '../content_card.dart';
import '../icon_badge.dart';
import '../shimmer_skeleton.dart';
import 'moon_glyph.dart';
import 'sleep_format.dart';
import 'sleep_sheets.dart';

/// Home card "Đêm qua" (feature sleep, design §A). Hidden for 30 days when the
/// user taps "Ẩn" before turning tracking on (state A1).
class SleepCard extends StatelessWidget {
  const SleepCard({super.key, required this.couple});

  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final sleep = context.watch<SleepProvider>();
    if (sleep.cardHidden) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final enabled = sleep.enabled;

    final header = Row(
      children: [
        const IconBadge(
          IconsaxPlusLinear.moon,
          tint: AppColors.accentLavenderDeep,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.sleepCardTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (enabled)
          const Icon(
            IconsaxPlusLinear.arrow_right_3,
            size: 18,
            color: AppColors.textTertiary,
          ),
      ],
    );

    final Widget body;
    if (!sleep.isLoaded) {
      body = const Row(
        children: [
          Expanded(child: ShimmerSkeleton(height: 64)),
          SizedBox(width: 12),
          Expanded(child: ShimmerSkeleton(height: 64)),
        ],
      );
    } else if (!enabled) {
      body = const _SetupPitch();
    } else {
      body = _LastNight(couple: couple);
    }

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, const SizedBox(height: 14), body],
      ),
    );

    return ContentCard(
      padding: EdgeInsets.zero,
      child: enabled
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                splashColor: AppColors.accentRose.withValues(alpha: 0.08),
                highlightColor: AppColors.accentRose.withValues(alpha: 0.04),
                onTap: () {
                  HapticFeedback.selectionClick();
                  openSleepScreen(context);
                },
                child: content,
              ),
            )
          : content,
    );
  }
}

/// A1 — tracking is off: the pitch + "Bật theo dõi" / "Ẩn".
class _SetupPitch extends StatelessWidget {
  const _SetupPitch();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sleepSetupPitch,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => showSleepSetupSheet(context),
                icon: const Icon(IconsaxPlusBold.moon, size: 18),
                label: Text(l10n.sleepEnableCta),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.read<SleepProvider>().hideCard();
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text(
                l10n.sleepHide,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tracking on: two columns (me · partner) + the "asleep together" footer.
class _LastNight extends StatelessWidget {
  const _LastNight({required this.couple});

  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sleep = context.watch<SleepProvider>();
    final myUid = context.read<AuthProvider>().currentUser?.id;
    final key = SleepProvider.lastNightKey();
    final mine = sleep.myNights[key];
    final myColor = PersonPalette.colorOf(sleep.myColorId);
    final waiting = couple.isWaitingForPartner || !sleep.hasPartner;

    final meColumn = _Column(
      name: l10n.sleepYou,
      color: myColor,
      night: mine,
      empty: sleep.needsPermission
          ? _PermissionLost(onTap: sleep.openPermissionSettings)
          : _NotRecorded(dateKey: key),
    );
    if (waiting) {
      return meColumn; // A0 — no partner yet: me, full width.
    }

    final partnerName = SleepFormat.partnerName(context, couple, myUid);
    final theirs = sleep.partnerNights[key];
    final partnerColumn = _Column(
      name: partnerName,
      color: PersonPalette.colorOf(sleep.partnerColorId),
      night: theirs,
      empty: sleep.partnerShares
          ? _MutedLine(text: l10n.sleepNoData)
          : _MutedLine(
              text: l10n.sleepPartnerNotShared,
              icon: IconsaxPlusLinear.lock,
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: meColumn,
                ),
              ),
              Container(
                width: 1,
                color: AppColors.textSecondary.withValues(alpha: 0.10),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: partnerColumn,
                ),
              ),
            ],
          ),
        ),
        if (mine != null && theirs != null) ...[
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: AppColors.textSecondary.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 12),
          _TogetherFooter(mine: mine, theirs: theirs, partnerName: partnerName),
        ],
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.name,
    required this.color,
    required this.night,
    required this.empty,
  });

  final String name;
  final Color color;
  final SleepNight? night;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    final n = night;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonLabel(name: name, color: color),
        const SizedBox(height: 8),
        if (n == null)
          empty
        else
          Row(
            children: [
              MoonGlyph(size: 30, color: color, phase: n.phase),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DurationText(minutes: n.minutes),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          SleepFormat.range(context, n),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (n.isLabeled) SourcePill(source: n.source),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Coloured dot + micro-caps name (names never take the person colour).
class PersonLabel extends StatelessWidget {
  const PersonLabel({super.key, required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

/// "7g 15p" with big numbers and small units.
class DurationText extends StatelessWidget {
  const DurationText({super.key, required this.minutes, this.numberSize = 22});

  final int minutes;
  final double numberSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final number = TextStyle(
      color: AppColors.textPrimary,
      fontSize: numberSize,
      fontWeight: FontWeight.w800,
    );
    const unit = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    return Semantics(
      label: SleepFormat.long(l10n, minutes),
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            if (h > 0) ...[
              TextSpan(text: '$h', style: number),
              TextSpan(
                text: m > 0 ? '${l10n.sleepUnitHour} ' : l10n.sleepUnitHour,
                style: unit,
              ),
            ],
            if (m > 0 || h == 0) ...[
              TextSpan(text: '$m', style: number),
              TextSpan(text: l10n.sleepUnitMinute, style: unit),
            ],
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}

/// R1 — "✎ Đã sửa" / "✎ Ghi tay", shown to both partners.
class SourcePill extends StatelessWidget {
  const SourcePill({super.key, required this.source});

  final SleepSource source;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            IconsaxPlusLinear.edit_2,
            size: 10,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            source == SleepSource.manual
                ? l10n.sleepSourceManual
                : l10n.sleepSourceEdited,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A3 — tracking on, but no block ≥ 3 h last night.
class _NotRecorded extends StatelessWidget {
  const _NotRecorded({required this.dateKey});

  final String dateKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sleepNotRecorded,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        _UnderlinedLink(
          text: l10n.sleepLogManually,
          onTap: () => showSleepEditSheet(context, dateKey: dateKey),
        ),
      ],
    );
  }
}

/// A2 — Android usage access was turned off.
class _PermissionLost extends StatelessWidget {
  const _PermissionLost({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              IconsaxPlusLinear.warning_2,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.sleepNeedsPermission,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        _UnderlinedLink(text: l10n.sleepOpenSettings, onTap: onTap),
      ],
    );
  }
}

class _MutedLine extends StatelessWidget {
  const _MutedLine({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
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

class _UnderlinedLink extends StatelessWidget {
  const _UnderlinedLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}

class _TogetherFooter extends StatelessWidget {
  const _TogetherFooter({
    required this.mine,
    required this.theirs,
    required this.partnerName,
  });

  final SleepNight mine;
  final SleepNight theirs;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overlap = mine.overlapWith(theirs);
    final String text;
    if (overlap == 0) {
      text = l10n.sleepNoOverlap;
    } else {
      final gap = mine.bedAt.difference(theirs.bedAt).inMinutes;
      final first = gap.abs() >= 10
          ? ' · ${l10n.sleepWentFirst(gap < 0 ? l10n.sleepYou : partnerName, SleepFormat.short(l10n, gap.abs()))}'
          : '';
      text = '${l10n.sleepTogether(SleepFormat.short(l10n, overlap))}$first';
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            IconsaxPlusBold.heart,
            size: 12,
            color: AppColors.accentLove,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
