import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/partner_reminder.dart';
import '../providers/partner_reminder_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/content_card.dart';
import '../widgets/sub_screen_header.dart';
import 'partner_reminder_form_screen.dart';

/// "Nhắc người ấy" (feature partner-nudge, 2026-06-29). Two tabs:
///  • Thúc ngay — send the partner an instant nudge (preset chip or free text).
///  • Đặt lịch — schedule reminders that ring on the partner's phone.
class NudgePartnerScreen extends StatefulWidget {
  const NudgePartnerScreen({super.key});

  @override
  State<NudgePartnerScreen> createState() => _NudgePartnerScreenState();
}

class _NudgePartnerScreenState extends State<NudgePartnerScreen> {
  final TextEditingController _composeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _composeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _composeController.dispose();
    super.dispose();
  }

  List<String> _presets(AppLocalizations l10n) => [
        l10n.partnerNudgePresetWater,
        l10n.partnerNudgePresetComeHome,
        l10n.partnerNudgePresetMissYou,
        l10n.partnerNudgePresetSleepEarly,
      ];

  Future<void> _sendNudge(String text, String source) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final provider = context.read<PartnerReminderProvider>();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!provider.canSendNudge) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(l10n.partnerNudgeCooldownToast)),
        );
      return;
    }
    HapticFeedback.lightImpact();
    final ok = await provider.sendNudge(trimmed);
    if (ok) {
      // Analytics — only the source (chip/custom), never the nudge text.
      AnalyticsService.instance.logNudgeSent(source);
    }
    if (!mounted) {
      return;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.partnerNudgeSentToast : l10n.partnerNudgeFailedToast,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SubScreenHeader(
                    badge: l10n.partnerNudgeBadge,
                    badgeIcon: IconsaxPlusLinear.notification_bing,
                    title: l10n.partnerNudgeTitle,
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  labelColor: AppColors.accentLoveDeep,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accentLove,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  tabs: [
                    Tab(text: l10n.partnerNudgeTabInstant),
                    Tab(text: l10n.partnerNudgeTabScheduled),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _InstantTab(
                        controller: _composeController,
                        presets: _presets(l10n),
                        onSend: _sendNudge,
                      ),
                      const _ScheduledTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Thúc ngay" — preset chips (1-tap send) + free-text compose.
class _InstantTab extends StatelessWidget {
  const _InstantTab({
    required this.controller,
    required this.presets,
    required this.onSend,
  });

  final TextEditingController controller;
  final List<String> presets;
  final Future<void> Function(String text, String source) onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canSend = controller.text.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerNudgeInstantHeader,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ContentCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final preset in presets)
                  _PresetChip(
                    label: preset,
                    onTap: () => onSend(preset, 'chip'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ContentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  maxLength: 200,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted:
                      canSend ? (value) => onSend(value, 'custom') : null,
                  decoration: InputDecoration(
                    hintText: l10n.partnerNudgeComposeHint,
                    counterText: '',
                    prefixIcon: const Icon(
                      IconsaxPlusBold.heart,
                      color: AppColors.accentRose,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: canSend
                        ? () async {
                            await onSend(controller.text, 'custom');
                            controller.clear();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentLove,
                      disabledBackgroundColor:
                          AppColors.accentLove.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(IconsaxPlusBold.send_2, size: 18),
                    label: Text(
                      l10n.partnerNudgeSendButton,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.accentRose.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Đặt lịch" — list of reminders I set for my partner + add button.
class _ScheduledTab extends StatelessWidget {
  const _ScheduledTab();

  Future<void> _openForm(BuildContext context, {PartnerReminder? existing}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PartnerReminderFormScreen(existing: existing),
      ),
    );
  }

  void _showCapacity(BuildContext context) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(l10n.partnerReminderCapacityToast)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<PartnerReminderProvider>(
      builder: (context, provider, _) {
        final mine = provider.mine;
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  l10n.partnerReminderScheduledHeader,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                if (mine.isEmpty)
                  _EmptyState(l10n: l10n)
                else
                  for (final reminder in mine) ...[
                    _ReminderTile(
                      reminder: reminder,
                      onTap: () => _openForm(context, existing: reminder),
                      onToggle: (v) => provider.toggleReminder(reminder, v),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                heroTag: 'partnerReminderAdd',
                backgroundColor: AppColors.accentLove,
                foregroundColor: AppColors.white,
                onPressed: () {
                  if (provider.isAtCapacity) {
                    _showCapacity(context);
                    return;
                  }
                  _openForm(context);
                },
                icon: const Icon(IconsaxPlusLinear.add, size: 20),
                label: Text(
                  l10n.partnerReminderAddButton,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(
        children: [
          const Icon(
            IconsaxPlusLinear.clock,
            color: AppColors.accentRose,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.partnerReminderEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.partnerReminderEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onTap,
    required this.onToggle,
  });

  final PartnerReminder reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute)
        .format(context);
    final repeat = partnerReminderRecurrenceLabel(reminder.recurrence, l10n);
    final subtitle = reminder.enabled
        ? '$repeat · $time'
        : '$repeat · $time · ${l10n.partnerReminderDisabledLabel}';
    return ContentCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                IconsaxPlusBold.notification_bing,
                color: AppColors.accentRose,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: reminder.enabled
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
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
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: reminder.enabled,
              onChanged: onToggle,
              activeThumbColor: AppColors.accentLove,
            ),
          ],
        ),
      ),
    );
  }
}
