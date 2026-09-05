import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/care_message.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../services/care_message_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/section_header.dart';
import '../widgets/sub_screen_header.dart';

/// Opens the "send a care note" composer (feature care-message).
///
/// Exported as a function so any entry point (profile menu, a Home header
/// button added later) opens the screen the same way, with the same route name
/// for analytics/back-stack readability.
void openCareMessageScreen(BuildContext context) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'CareMessage'),
      builder: (_) => const CareMessageScreen(),
    ),
  );
}

/// "Gửi quan tâm" — compose a short title + body and push it straight to the
/// partner's lock screen (feature care-message).
///
/// Deliberately plain: quick-pick chips (the fast path — most notes are one of
/// six everyday nudges), two fields, one primary button, and a small history of
/// what the couple recently sent so the composer doesn't feel like a void.
class CareMessageScreen extends StatefulWidget {
  const CareMessageScreen({super.key});

  @override
  State<CareMessageScreen> createState() => _CareMessageScreenState();
}

class _CareMessageScreenState extends State<CareMessageScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final CareMessageService _service = CareMessageService();

  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _titleController.text.trim().isNotEmpty &&
      _bodyController.text.trim().isNotEmpty;

  void _applyQuickPick(String title, String body) {
    HapticFeedback.selectionClick();
    setState(() {
      _titleController.text = title;
      _bodyController.text = body;
    });
  }

  Future<void> _send(String coupleId, String uid) async {
    if (_isSending || !_canSend) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      bool ok;
      var queued = false;
      try {
        ok = await _service
            .send(
              coupleId: coupleId,
              uid: uid,
              title: _titleController.text,
              body: _bodyController.text,
            )
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        // Offline: Firestore has queued the write and delivers it once the
        // network is back. Don't spin forever (the user would back out and
        // resend → N duplicate pushes); say so and leave.
        ok = true;
        queued = true;
      }
      if (!mounted) return;
      if (!ok) {
        setState(() => _isSending = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.careMessageErrorToast),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            queued ? l10n.careMessageQueuedToast : l10n.careMessageSentToast,
          ),
        ),
      );
      navigator.maybePop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.careMessageErrorToast),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final couple = context.watch<CoupleProvider>().couple;
    final uid = context.watch<AuthProvider>().currentUser?.id ?? '';
    // A care note needs someone to receive it: no couple, or a couple still
    // waiting for the partner to join, means there is nobody to notify.
    final isPaired =
        couple != null && !couple.isWaitingForPartner && uid.isNotEmpty;
    final coupleId = couple?.id ?? '';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SubScreenHeader(
                  badge: l10n.careMessageBadge,
                  badgeIcon: IconsaxPlusBold.heart,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  children: [
                    if (!isPaired) ...[
                      ContentCard(
                        child: Row(
                          children: [
                            const Icon(
                              IconsaxPlusLinear.info_circle,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.careMessageNeedCouple,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SectionHeader(title: l10n.careMessageQuickPicksTitle),
                    const SizedBox(height: 12),
                    _QuickPicks(onPick: _applyQuickPick),
                    const SizedBox(height: 22),
                    _buildComposer(l10n),
                    const SizedBox(height: 18),
                    _buildSendButton(l10n, isPaired, coupleId, uid),
                    if (isPaired) ...[
                      const SizedBox(height: 28),
                      _RecentCareMessages(
                        service: _service,
                        coupleId: coupleId,
                        myUid: uid,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(AppLocalizations l10n) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(l10n.careMessageTitleLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            maxLength: CareMessage.maxTitleLength,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.careMessageTitleHint,
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel(l10n.careMessageBodyLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            maxLength: CareMessage.maxBodyLength,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.careMessageBodyHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(
    AppLocalizations l10n,
    bool isPaired,
    String coupleId,
    String uid,
  ) {
    final enabled = isPaired && _canSend && !_isSending;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? () => _send(coupleId, uid) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.textPrimary.withValues(
            alpha: 0.28,
          ),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: _isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                l10n.careMessageSendCta,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Six ready-made notes — the fast path. Tapping one fills BOTH fields so the
/// user can send immediately, or tweak the wording first.
class _QuickPicks extends StatelessWidget {
  const _QuickPicks({required this.onPick});

  final void Function(String title, String body) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final picks = <(String, String)>[
      (l10n.careQuick1Title, l10n.careQuick1Body),
      (l10n.careQuick2Title, l10n.careQuick2Body),
      (l10n.careQuick3Title, l10n.careQuick3Body),
      (l10n.careQuick4Title, l10n.careQuick4Body),
      (l10n.careQuick5Title, l10n.careQuick5Body),
      (l10n.careQuick6Title, l10n.careQuick6Body),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final pick in picks)
          Material(
            color: AppColors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              splashColor: AppColors.accentRose.withValues(alpha: 0.08),
              highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
              onTap: () => onPick(pick.$1, pick.$2),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Text(
                  pick.$1,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Recent care notes from BOTH members (newest first). Hidden entirely while
/// empty/loading so a brand-new couple never sees a dangling empty section.
class _RecentCareMessages extends StatefulWidget {
  const _RecentCareMessages({
    required this.service,
    required this.coupleId,
    required this.myUid,
  });

  final CareMessageService service;
  final String coupleId;
  final String myUid;

  @override
  State<_RecentCareMessages> createState() => _RecentCareMessagesState();
}

/// Stateful so the Firestore stream is created ONCE per couple — the parent
/// rebuilds on every keystroke (composer setState) and an inline
/// `watchRecent()` in build would tear down + re-open the listener each time.
class _RecentCareMessagesState extends State<_RecentCareMessages> {
  late Stream<List<CareMessage>> _stream = widget.service.watchRecent(
    widget.coupleId,
  );

  @override
  void didUpdateWidget(covariant _RecentCareMessages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coupleId != widget.coupleId) {
      _stream = widget.service.watchRecent(widget.coupleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final myUid = widget.myUid;
    return StreamBuilder<List<CareMessage>>(
      stream: _stream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <CareMessage>[];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: l10n.careMessageRecentTitle),
            const SizedBox(height: 12),
            for (final item in items) ...[
              _CareMessageTile(message: item, myUid: myUid),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _CareMessageTile extends StatelessWidget {
  const _CareMessageTile({required this.message, required this.myUid});

  final CareMessage message;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mine = message.isMine(myUid);
    return ContentCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  message.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.sectionTitleStyle().copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _relativeTime(message.createdAt, l10n),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.body,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mine ? l10n.careMessageFromMe : l10n.careMessageFromPartner,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: mine
                  ? AppColors.accentLoveDeep
                  : AppColors.accentLavenderDeep,
            ),
          ),
        ],
      ),
    );
  }

  /// Reuses the neutral relative-time strings shared across the app.
  String _relativeTime(DateTime? when, AppLocalizations l10n) {
    if (when == null) return l10n.loveNoteJustNow;
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return l10n.loveNoteJustNow;
    if (diff.inMinutes < 60) return l10n.loveNoteMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.loveNoteHoursAgo(diff.inHours);
    return l10n.loveNoteDaysAgo(diff.inDays);
  }
}
