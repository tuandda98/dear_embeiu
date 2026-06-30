import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_notification.dart';
import '../providers/daily_question_provider.dart';
import '../providers/notification_inbox_provider.dart';
import '../services/daily_question_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/content_card.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';
import 'journal_screen.dart';

/// In-app notification center (feature notifications). Lists the current
/// couple's notifications newest-first, grouped into "Today" / "Earlier", lets
/// the user mark them read / clear them, and on tap routes to the relevant Home
/// tab (reusing the same [NotificationTapRouter] plumbing as a real push tap).
///
/// Visually it lives in the "Sunset Romance" world: the dawn-blush gradient
/// background + solid white content tiles (design-unify C11 — glass is banned
/// in long scrolling lists, B11), matching Home/Gallery.
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
                    // Content-shaped skeleton tiles instead of a centered
                    // spinner (design-unify C11) — same gutter/radius as the
                    // real tiles so nothing jumps when items arrive.
                    ? ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 9),
                        itemCount: 5,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, _) =>
                            const ShimmerSkeleton(height: 84, borderRadius: 22),
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

/// Brand header: the standard white squircle back button (B3) + overflow menu
/// over the gradient, with the page title and a live unread summary — same
/// type styles as Home.
class _Header extends StatelessWidget {
  const _Header({required this.provider, required this.l10n});

  final NotificationInboxProvider provider;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final unread = provider.unreadCount;
    final hasItems = provider.items.isNotEmpty;
    final subtitle = unread > 0
        ? l10n.notifUnreadCount(unread)
        : l10n.notifAllCaughtUp;

    // Header redesign 2026-06-14: the shared SubScreenHeader (back → chip →
    // title → subtitle, all left-aligned at the gutter, + the overflow menu as
    // a trailing action). Stays FIXED above the list (the Dismissible list
    // below is too involved to absorb it as a scrolling first item).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SubScreenHeader(
        badge: l10n.notifCenterBadge,
        badgeIcon: IconsaxPlusLinear.notification,
        title: l10n.notifCenterTitle,
        subtitle: subtitle,
        trailing: hasItems ? _OverflowMenu(provider: provider, l10n: l10n) : null,
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
      children.addAll(
        today.map((n) => _DismissibleTile(notification: n, l10n: l10n)),
      );
    }
    if (earlier.isNotEmpty) {
      children.add(_SectionHeader(label: l10n.notifGroupEarlier));
      children.addAll(
        earlier.map((n) => _DismissibleTile(notification: n, l10n: l10n)),
      );
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
        // Header ink vòng 4: navy at .55 on the blush gradient — same recipe
        // as the page eyebrow; no shadow (that was the white-ink treatment).
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.55),
          fontSize: 12,
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
      // The B4 content shadow lives OUTSIDE the ClipRRect (the clip exists to
      // round the red swipe background and would swallow the tile's own
      // shadow otherwise).
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Dismissible(
            key: ValueKey('notif-${notification.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: AppColors.accentLove.withValues(alpha: 0.20),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 22),
              child: const Icon(
                IconsaxPlusLinear.trash,
                color: AppColors.accentLoveDeep,
              ),
            ),
            onDismissed: (_) {
              context.read<NotificationInboxProvider>().remove(notification.id);
            },
            child: _NotificationTile(notification: notification, l10n: l10n),
          ),
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

    // Solid white reading surface (B4, r22 tile variant) — glass is banned in
    // long scrolling lists (B11). Unread keeps its "NEW" language as a rose
    // outline + dot (same as the love-note card).
    return Container(
      foregroundDecoration: unread
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.accentLove.withValues(alpha: 0.45),
                width: 1.2,
              ),
            )
          : null,
      child: ContentCard(
        radius: 22,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            splashColor: AppColors.accentRose.withValues(alpha: 0.08),
            onTap: () {
              // Mark read, then route to the relevant Home tab via the shared
              // notification-tap plumbing and close the center. Home is already
              // mounted and listening, so it switches tab on the next frame.
              context.read<NotificationInboxProvider>().markRead(n.id);

              // Daily question: once BOTH answered the question lives in the
              // journal, so open the journal focused on that day. If it isn't
              // revealed yet (the viewer hasn't answered), this returns false
              // and we fall through to Home so they can answer it.
              if (n.type == AppNotificationType.dailyQuestion &&
                  _openJournalIfRevealed(context, n)) {
                return;
              }

              // Photo/reaction → deep-link to the exact photo; else just the tab.
              final photoId = n.photoId;
              if (photoId != null && photoId.isNotEmpty) {
                NotificationTapRouter.pendingPhotoId.value = photoId;
              }
              // Daily question (not yet revealed) → scroll its card in on Home.
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
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.70,
                              ),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          _relativeTime(n.createdAt, l10n),
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.50,
                            ),
                            fontSize: 12,
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
      ),
    );
  }

  /// Daily-question deep-link: the journal only contains days BOTH partners
  /// answered, so a tap opens the journal at that day ONLY when today's
  /// question is already revealed; the notification center is replaced so Back
  /// lands on Home. Returns false (→ caller routes to Home so the viewer can
  /// answer) when not revealed, or for an older notification we can't confirm
  /// from the live provider (which only streams today — pushes are same-day).
  bool _openJournalIfRevealed(BuildContext context, AppNotification n) {
    final today = DailyQuestionService.dateKey(DateTime.now());
    final date = (n.date == null || n.date!.isEmpty) ? today : n.date!;
    if (date != today) {
      return false;
    }
    if (!context.read<DailyQuestionProvider>().hasRevealed) {
      return false;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'Journal'),
        builder: (_) => JournalScreen(focusDate: date),
      ),
    );
    return true;
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
      case AppNotificationType.chatMessage:
        return l10n.notifChatMessage(name);
      case AppNotificationType.partnerNudge:
        return l10n.notifPartnerNudge(name);
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
      case AppNotificationType.partnerNudge:
        // The nudge IS its content — show the message under the title.
        return n.messageText;
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
        return (IconsaxPlusLinear.gallery, AppColors.accentLove);
      case AppNotificationType.photoReaction:
        return (IconsaxPlusLinear.heart, AppColors.accentLoveDeep);
      case AppNotificationType.partnerJoined:
        return (IconsaxPlusLinear.lovely, AppColors.accentLavenderDeep);
      case AppNotificationType.partnerLeft:
        return (IconsaxPlusLinear.heart_slash, AppColors.textSecondary);
      case AppNotificationType.loveNote:
        return (IconsaxPlusLinear.sms, AppColors.accentLove);
      case AppNotificationType.dailyQuestion:
        return (IconsaxPlusLinear.messages, AppColors.accentLavenderDeep);
      case AppNotificationType.chatMessage:
        return (IconsaxPlusLinear.messages, AppColors.accentLove);
      case AppNotificationType.partnerNudge:
        return (IconsaxPlusLinear.notification_bing, AppColors.accentLove);
      case AppNotificationType.unknown:
        return (IconsaxPlusLinear.notification, AppColors.textSecondary);
    }
  }
}

/// Overflow menu (mark all read / clear all) behind the standard white
/// header squircle (B3). Opens via [showMenu] anchored to the button (a
/// [PopupMenuButton] can't host [HeaderIconButton] — its inner InkWell would
/// swallow the tap); the menu items and actions are unchanged.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.provider, required this.l10n});

  final NotificationInboxProvider provider;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return HeaderIconButton(
      icon: IconsaxPlusLinear.more,
      onTap: () => _showOverflowMenu(context),
    );
  }

  Future<void> _showOverflowMenu(BuildContext context) async {
    // Anchor the menu under the squircle, like PopupMenuButton would.
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final value = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        if (provider.hasUnread)
          PopupMenuItem<String>(
            value: 'read',
            child: Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.tick_circle,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(l10n.notifMarkAllRead),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'clear',
          child: Row(
            children: [
              const Icon(IconsaxPlusLinear.trash, size: 20, color: AppColors.error),
              const SizedBox(width: 12),
              Text(l10n.notifClearAll),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted) return;
    if (value == 'read') {
      await context.read<NotificationInboxProvider>().markAllRead();
    } else if (value == 'clear') {
      await _confirmClearAll(context);
    }
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
        // Solid white content card (B4) — was glass, banned for reading
        // surfaces (B11).
        child: ContentCard(
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
                  IconsaxPlusLinear.notification_status,
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
                  fontSize: 16,
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
      ),
    );
  }
}
