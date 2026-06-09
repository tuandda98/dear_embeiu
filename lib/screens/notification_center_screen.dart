import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_notification.dart';
import '../providers/notification_inbox_provider.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

/// In-app notification center (feature notifications). Lists the current
/// couple's notifications newest-first, grouped into "Today" / "Earlier", lets
/// the user mark them read / clear them, and on tap routes to the relevant Home
/// tab (reusing the same [NotificationTapRouter] plumbing as a real push tap).
///
/// Visually it lives in the "Sunset Romance" world: the dawn-blush gradient
/// background + glassmorphism tiles, matching Home/Gallery instead of the plain
/// Material list it used to be.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<NotificationInboxProvider>();
    final items = provider.items;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(provider: provider, l10n: l10n),
              Expanded(
                child: provider.isLoading && items.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentLoveDeep,
                        ),
                      )
                    : items.isEmpty
                        ? _EmptyState(l10n: l10n)
                        : _NotificationList(items: items, l10n: l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand header: a glass back button + overflow menu over the gradient, with
/// the page title and a live unread summary — same type styles as Home.
class _Header extends StatelessWidget {
  const _Header({required this.provider, required this.l10n});

  final NotificationInboxProvider provider;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final unread = provider.unreadCount;
    final hasItems = provider.items.isNotEmpty;
    final subtitle = unread > 0 ? l10n.notifUnreadCount(unread) : l10n.notifAllCaughtUp;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GlassIconButton(
                icon: LucideIcons.arrowLeft,
                tooltip: l10n.back,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              if (hasItems) _OverflowMenu(provider: provider, l10n: l10n),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.notifCenterTitle, style: AppTheme.pageTitleStyle()),
          if (hasItems) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: AppTheme.pageSubtitleStyle()),
          ],
        ],
      ),
    );
  }
}

/// Newest-first list split into "Today" / "Earlier" sections, each tile a
/// swipe-to-delete glass card.
class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.items, required this.l10n});

  final List<AppNotification> items;
  final AppLocalizations l10n;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = <AppNotification>[];
    final earlier = <AppNotification>[];
    for (final n in items) {
      final d = n.createdAt;
      if (d != null && _isSameDay(d, now)) {
        today.add(n);
      } else {
        earlier.add(n);
      }
    }

    final children = <Widget>[];
    if (today.isNotEmpty) {
      children.add(_SectionHeader(label: l10n.notifGroupToday));
      children.addAll(today.map((n) => _DismissibleTile(notification: n, l10n: l10n)));
    }
    if (earlier.isNotEmpty) {
      children.add(_SectionHeader(label: l10n.notifGroupEarlier));
      children.addAll(earlier.map((n) => _DismissibleTile(notification: n, l10n: l10n)));
    }

    return ListView(
      padding: EdgeInsets.only(
        top: 4,
        bottom: MediaQuery.of(context).padding.bottom + 28,
      ),
      children: children,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.white.withValues(alpha: 0.92),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _DismissibleTile extends StatelessWidget {
  const _DismissibleTile({required this.notification, required this.l10n});

  final AppNotification notification;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Dismissible(
          key: ValueKey('notif-${notification.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppColors.accentLove.withValues(alpha: 0.20),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 22),
            child: const Icon(LucideIcons.trash2, color: AppColors.accentLoveDeep),
          ),
          onDismissed: (_) {
            context.read<NotificationInboxProvider>().remove(notification.id);
          },
          child: _NotificationTile(notification: notification, l10n: l10n),
        ),
      ),
    );
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

    return GlassCard(
      borderRadius: 22,
      blur: 14,
      padding: EdgeInsets.zero,
      fillAlpha: unread ? 0.30 : 0.18,
      borderAlpha: unread ? 0.75 : 0.30,
      borderColor: unread ? AppColors.accentLove : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            // Mark read, then route to the relevant Home tab via the shared
            // notification-tap plumbing and close the center. Home is already
            // mounted and listening, so it switches tab on the next frame.
            context.read<NotificationInboxProvider>().markRead(n.id);
            // Photo/reaction → deep-link to the exact photo; else just the tab.
            final photoId = n.photoId;
            if (photoId != null && photoId.isNotEmpty) {
              NotificationTapRouter.pendingPhotoId.value = photoId;
            }
            // Daily question → scroll its card into view on Home.
            if (n.type == AppNotificationType.dailyQuestion) {
              NotificationTapRouter.pendingHomeFocus.value = 'daily_question';
            }
            NotificationTapRouter.pendingHomeTab.value = n.targetHomeTab;
            Navigator.of(context).maybePop();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
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
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(alpha: 0.70),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        _relativeTime(n.createdAt, l10n),
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.50),
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
                    margin: const EdgeInsets.only(top: 5),
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
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  (IconData, Color) _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.photoPosted:
        return (LucideIcons.image, AppColors.accentLove);
      case AppNotificationType.photoReaction:
        return (LucideIcons.heart, AppColors.accentLoveDeep);
      case AppNotificationType.partnerJoined:
        return (LucideIcons.heartHandshake, AppColors.accentLavenderDeep);
      case AppNotificationType.partnerLeft:
        return (LucideIcons.heartCrack, AppColors.textSecondary);
      case AppNotificationType.loveNote:
        return (LucideIcons.mail, AppColors.accentLove);
      case AppNotificationType.dailyQuestion:
        return (LucideIcons.messageCircle, AppColors.accentLavenderDeep);
      case AppNotificationType.unknown:
        return (LucideIcons.bell, AppColors.textSecondary);
    }
  }
}

/// Glass header button matching the Home header pills (translucent fill +
/// highlight border, white icon).
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }
}

/// Overflow menu (mark all read / clear all) rendered as a glass pill.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.provider, required this.l10n});

  final NotificationInboxProvider provider;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
        ),
        child: const Icon(LucideIcons.moreHorizontal,
            color: AppColors.white, size: 22),
      ),
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
                const Icon(LucideIcons.checkCheck,
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
              const Icon(LucideIcons.trash2, size: 20, color: AppColors.error),
              const SizedBox(width: 12),
              Text(l10n.notifClearAll),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
        child: GlassCard(
          borderRadius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.accentLove.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.bellOff,
                  size: 40,
                  color: AppColors.accentLove,
                ),
              ),
              const SizedBox(height: 18),
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
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.70),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
