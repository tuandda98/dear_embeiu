import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_notification.dart';
import '../providers/notification_inbox_provider.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';

/// In-app notification center (feature notifications). Lists the current
/// couple's notifications newest-first, lets the user mark them read / clear
/// them, and on tap routes to the relevant Home tab (reusing the same
/// [NotificationTapRouter] plumbing as a real push tap).
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<NotificationInboxProvider>();
    final items = provider.items;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(l10n.notifCenterTitle),
        actions: [
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) async {
                if (value == 'read') {
                  await context.read<NotificationInboxProvider>().markAllRead();
                } else if (value == 'clear') {
                  await _confirmClearAll(context);
                }
              },
              itemBuilder: (context) => [
                if (provider.hasUnread)
                  PopupMenuItem<String>(
                    value: 'read',
                    child: Row(
                      children: [
                        const Icon(Icons.done_all_rounded,
                            size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Text(l10n.notifMarkAllRead),
                      ],
                    ),
                  ),
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.error),
                      const SizedBox(width: 12),
                      Text(l10n.notifClearAll),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: provider.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? _EmptyState(l10n: l10n)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 76,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final n = items[index];
                    return Dismissible(
                      key: ValueKey('notif-${n.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.error.withValues(alpha: 0.12),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error),
                      ),
                      onDismissed: (_) {
                        context.read<NotificationInboxProvider>().remove(n.id);
                      },
                      child: _NotificationTile(notification: n, l10n: l10n),
                    );
                  },
                ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notifClearAllConfirmTitle),
        content: Text(l10n.notifClearAllConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.notifClearAll),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<NotificationInboxProvider>().clearAll();
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.l10n});

  final AppNotification notification;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final subtitle = _subtitleFor(n);
    final unread = !n.read;

    return Material(
      color: unread
          ? AppColors.accentLove.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          // Mark read, then route to the relevant Home tab via the shared
          // notification-tap plumbing and close the center. Home is already
          // mounted and listening, so it switches tab on the next frame.
          context.read<NotificationInboxProvider>().markRead(n.id);
          NotificationTapRouter.pendingHomeTab.value = n.targetHomeTab;
          Navigator.of(context).maybePop();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(type: n.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleFor(n, l10n),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        height: 1.35,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      _relativeTime(n.createdAt, l10n),
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 10),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.accentLove,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(AppNotification n, AppLocalizations l10n) {
    final name = n.actorName.isNotEmpty ? n.actorName : l10n.posterNameFallback;
    switch (n.type) {
      case AppNotificationType.photoPosted:
        return l10n.notifPhotoPosted(name);
      case AppNotificationType.photoReaction:
        return l10n.notifPhotoReaction(name, n.emoji ?? '❤️');
      case AppNotificationType.partnerJoined:
        return l10n.notifPartnerJoined(name);
      case AppNotificationType.partnerLeft:
        return l10n.notifPartnerLeft(name);
      case AppNotificationType.loveNote:
        return l10n.notifLoveNote(name);
      case AppNotificationType.dailyQuestion:
        return l10n.notifDailyQuestion(name);
      case AppNotificationType.unknown:
        return l10n.notifGeneric;
    }
  }

  String? _subtitleFor(AppNotification n) {
    switch (n.type) {
      case AppNotificationType.loveNote:
        return n.noteExcerpt;
      case AppNotificationType.photoPosted:
        return n.caption;
      default:
        return null;
    }
  }

  /// Localized "x minutes/hours/days ago" (reuses the neutral relative-time
  /// strings shared with the love-note card).
  String _relativeTime(DateTime? when, AppLocalizations l10n) {
    if (when == null) {
      return l10n.loveNoteJustNow;
    }
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) {
      return l10n.loveNoteJustNow;
    }
    if (diff.inMinutes < 60) {
      return l10n.loveNoteMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.loveNoteHoursAgo(diff.inHours);
    }
    return l10n.loveNoteDaysAgo(diff.inDays);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.type});

  final AppNotificationType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconFor(type);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  (IconData, Color) _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.photoPosted:
        return (Icons.photo_outlined, AppColors.accentLove);
      case AppNotificationType.photoReaction:
        return (Icons.favorite_rounded, AppColors.accentLoveDeep);
      case AppNotificationType.partnerJoined:
        return (Icons.link_rounded, AppColors.accentLavender);
      case AppNotificationType.partnerLeft:
        return (Icons.link_off_rounded, AppColors.textSecondary);
      case AppNotificationType.loveNote:
        return (Icons.mail_outline_rounded, AppColors.accentLove);
      case AppNotificationType.dailyQuestion:
        return (Icons.chat_bubble_outline_rounded, AppColors.accentLavender);
      case AppNotificationType.unknown:
        return (Icons.notifications_none_rounded, AppColors.textSecondary);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.accentLove.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: AppColors.accentLove,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.notifCenterEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notifCenterEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
