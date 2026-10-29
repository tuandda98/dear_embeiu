import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/caro_game.dart';
import '../providers/caro_game_provider.dart';
import '../providers/rps_game_provider.dart';
import '../screens/caro_game_screen.dart';
import '../screens/caro_history_screen.dart';
import '../screens/rps_history_screen.dart';
import '../screens/rps_game_screen.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import 'caro/caro_board.dart';
import 'caro/caro_common.dart';
import 'caro/caro_new_game_sheet.dart';
import 'content_card.dart';
import 'icon_badge.dart';
import 'ink_tile.dart';
import 'rps_invite_card.dart' show rpsMedalAccent;
import 'shimmer_skeleton.dart';

/// What Home's caro line says (design §3.1 table, in priority order — my
/// move first).
enum CaroEntryKind {
  loading,
  error,
  invited,
  myTurn,
  stale,
  watching,
  waiting,
  justLost,
  justWon,
  justDraw,
  idle,
  first,
}

/// Pure state pick for the caro line. [open] = the couple's open game,
/// [last] = newest finished game, [total] = finished games counted in the
/// score.
CaroEntryKind caroEntryKindFor({
  required bool loaded,
  bool failed = false,
  required CaroGame? open,
  required CaroGame? last,
  required String myUid,
  required String partnerUid,
  required int total,
  required DateTime now,
}) {
  if (!loaded) return failed ? CaroEntryKind.error : CaroEntryKind.loading;
  if (open != null) {
    if (open.isMyTurn(myUid)) {
      return open.isFreshInvite && open.createdBy != myUid
          ? CaroEntryKind.invited
          : CaroEntryKind.myTurn;
    }
    if (open.isStale(now: now)) return CaroEntryKind.stale;
    if (open.isPresenceFresh(partnerUid, now: now)) {
      return CaroEntryKind.watching;
    }
    return CaroEntryKind.waiting;
  }
  final at = last?.finishedAt;
  if (last != null &&
      at != null &&
      now.difference(at) < const Duration(hours: 24)) {
    final r = last.result;
    if (r == null || r.isDraw) return CaroEntryKind.justDraw;
    return r.winnerUid == myUid
        ? CaroEntryKind.justWon
        : CaroEntryKind.justLost;
  }
  return total > 0 || last != null ? CaroEntryKind.idle : CaroEntryKind.first;
}

/// Home "Lúc rảnh" games (feature caro-game, design §3.1; Home D tiles,
/// 2026-10-29): two equal tiles side by side, Cờ caro left, Oẳn tù tì right.
/// A tile's CTA is solid navy only while the partner waits on me (C6), with
/// the rose dot; outlined otherwise. Hidden by the caller while the couple
/// still waits for a partner.
class PlayTogetherCard extends StatelessWidget {
  const PlayTogetherCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Equal heights so both CTAs sit on one line whatever the copy length.
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _CaroTile()),
          SizedBox(width: 12),
          Expanded(child: _RpsTile()),
        ],
      ),
    );
  }
}

/// "Đến lượt bạn. Thảo vừa đi nước 14." → ("Đến lượt bạn", "Thảo vừa đi
/// nước 14."): the tile shows the first sentence bold and the rest grey. A
/// full stop closing the first sentence is dropped, `?`/`!`/`…` are kept. One
/// sentence → (it without its full stop, ''). The entry copy is written as
/// "state. detail." for this; caro_tile_split_test pins every state.
/// ponytail: a partner name with ". " inside ("T. Anh") splits early — the
/// text is all still shown, only the bold/grey cut moves.
(String, String) splitEntryLine(String line) {
  final text = line.trim();
  final m = RegExp(r'^(.+?)([.!?…])\s+(\S.*)$', dotAll: true).firstMatch(text);
  if (m == null) {
    return (text.endsWith('.') ? text.substring(0, text.length - 1) : text, '');
  }
  final mark = m.group(2)!;
  return ('${m.group(1)}${mark == '.' ? '' : mark}', m.group(3)!);
}

/// One game tile: 36 badge + name, the state's first sentence bold and the
/// rest grey, CTA pinned to the bottom. The whole tile is the tap target (the
/// CTA pill is visual only), read as one button like [CaroEntryRow]. Needs a
/// bounded height (the CTA is pushed down by a Spacer): Home wraps the pair in
/// [IntrinsicHeight].
class PlayTile extends StatelessWidget {
  const PlayTile({
    super.key,
    required this.view,
    required this.badge,
    required this.onTap,
  });

  final CaroEntryView view;
  final Widget badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (head, rest) = splitEntryLine(view.subtitle);
    return Semantics(
      button: true,
      label: view.semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: ContentCard(
        padding: EdgeInsets.zero,
        child: InkTile(
          borderRadius: 24,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    badge,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        view.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (view.loading) ...[
                  ShimmerSkeleton(width: 96, height: 16, borderRadius: 6),
                  const SizedBox(height: 6),
                  ShimmerSkeleton(width: 120, height: 12, borderRadius: 6),
                ] else ...[
                  Text(
                    head,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      rest,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
                const Spacer(),
                const SizedBox(height: 12),
                if (view.loading)
                  ShimmerSkeleton(height: 40, borderRadius: 999)
                else
                  _Cta(label: view.cta, filled: view.urgent, expand: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaroTile extends StatelessWidget {
  const _CaroTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final caro = context.watch<CaroGameProvider>();
    final people = CaroPeople.of(context, l10n);
    final now = DateTime.now();
    final open = caro.openGame;
    final last = caro.lastFinished;
    final kind = caroEntryKindFor(
      loaded: caro.isStateLoaded,
      failed: caro.stateFailed,
      open: open,
      last: last,
      myUid: people.myUid,
      partnerUid: people.partnerUid,
      total: caro.state.totalFor(people.myUid, people.partnerUid),
      now: now,
    );
    var score = people.score(l10n, caro.myWins, caro.partnerWins);
    if (caro.draws > 0) score = l10n.caroScoreDraws(score, '${caro.draws}');
    final view = caroEntryView(
      l10n,
      kind,
      partnerName: people.partnerName,
      score: score,
      moves: '${open?.cells.length ?? 0}',
      time: caroTime(context, open?.lastMoveAt),
      staleDays:
          '${open == null ? 0 : now.difference(open.lastMoveAt ?? open.createdAt ?? now).inDays}',
    );
    void onTap() {
      HapticFeedback.selectionClick();
      AnalyticsService.instance.logHomeEntryTap('caro', urgent: view.urgent);
      if (kind == CaroEntryKind.error) {
        context.read<CaroGameProvider>().retryState();
        return;
      }
      if (open != null) {
        openCaroGame(context, gameId: open.id, source: 'home');
      } else {
        final rematch =
            kind == CaroEntryKind.justLost ||
            kind == CaroEntryKind.justWon ||
            kind == CaroEntryKind.justDraw;
        quickStartCaroGame(context, rematchOf: rematch ? last?.id : null);
      }
    }

    return PlayTile(
      view: view,
      badge: CaroGlyph(
        mine: people.myColor,
        partner: people.partnerColor,
        size: 36,
        radius: 12,
        showDot: view.urgent,
      ),
      onTap: kind == CaroEntryKind.loading ? null : onTap,
    );
  }
}

/// Copy + CTA of one caro line (pure, testable).
class CaroEntryView {
  const CaroEntryView({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.urgent,
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final String cta;

  /// The partner waits on me → solid navy CTA + dot (C6).
  final bool urgent;
  final bool loading;

  /// What a screen reader says for the line: name, state, then the action
  /// ("Cờ caro. Rủ Thảo một ván, bạn đi trước, Rủ chơi"), since the CTA pill
  /// itself is left out of the tree.
  String get semanticsLabel {
    final head = (subtitle.isEmpty ? title : '$title. $subtitle').replaceFirst(
      RegExp(r'[.!?…]+$'),
      '',
    );
    return cta.isEmpty ? head : '$head, $cta';
  }
}

CaroEntryView caroEntryView(
  AppLocalizations l10n,
  CaroEntryKind kind, {
  required String partnerName,
  required String score,
  required String moves,
  required String time,
  required String staleDays,
}) {
  final title = l10n.caroGameTitle;
  CaroEntryView v(String sub, String cta, {bool urgent = false}) =>
      CaroEntryView(title: title, subtitle: sub, cta: cta, urgent: urgent);
  switch (kind) {
    case CaroEntryKind.loading:
      return CaroEntryView(
        title: title,
        subtitle: '',
        cta: '',
        urgent: false,
        loading: true,
      );
    case CaroEntryKind.error:
      return v(l10n.caroEntryError, l10n.caroCtaRetry);
    case CaroEntryKind.invited:
      return v(
        l10n.caroEntryInvited(partnerName),
        l10n.caroCtaJoin,
        urgent: true,
      );
    case CaroEntryKind.myTurn:
      return v(
        l10n.caroEntryMyTurn(partnerName, moves),
        l10n.caroCtaPlayOn,
        urgent: true,
      );
    case CaroEntryKind.stale:
      return v(l10n.caroEntryStale(staleDays), l10n.rpsEntryCtaOpen);
    case CaroEntryKind.watching:
      return v(l10n.caroEntryWatching(partnerName), l10n.rpsEntryCtaOpen);
    case CaroEntryKind.waiting:
      return v(
        l10n.caroEntryWaiting(partnerName, moves, time),
        l10n.rpsEntryCtaOpen,
      );
    case CaroEntryKind.justLost:
      return v(l10n.caroEntryJustLost(partnerName, score), l10n.caroCtaInvite);
    case CaroEntryKind.justWon:
      return v(l10n.caroEntryJustWon(score), l10n.caroCtaInvite);
    case CaroEntryKind.justDraw:
      return v(l10n.caroEntryJustDraw(score), l10n.caroCtaInvite);
    case CaroEntryKind.idle:
      return v(l10n.caroEntryIdle(score, partnerName), l10n.caroCtaInvite);
    case CaroEntryKind.first:
      return v(l10n.caroEntryFirst(partnerName), l10n.caroCtaInvite);
  }
}

/// One line of the card: 44 badge · title + subtitle · CTA h40. The whole
/// line is the tap target (min height 68).
class CaroEntryRow extends StatelessWidget {
  const CaroEntryRow({
    super.key,
    required this.view,
    required this.badge,
    required this.onTap,
  });

  final CaroEntryView view;
  final Widget badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: view.semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                badge,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (view.loading)
                        ShimmerSkeleton(width: 160, height: 14, borderRadius: 6)
                      else
                        Text(
                          view.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: view.urgent
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: view.urgent
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (view.loading)
                  ShimmerSkeleton(width: 72, height: 40, borderRadius: 999)
                else
                  _Cta(label: view.cta, filled: view.urgent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual-only 40pt pill (the whole line handles the tap).
class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.filled, this.expand = false});

  final String label;
  final bool filled;

  /// Full width (Home tiles) instead of hugging the label (rows).
  final bool expand;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    width: expand ? double.infinity : null,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: filled ? AppColors.textPrimary : null,
      borderRadius: BorderRadius.circular(999),
      border: filled
          ? null
          // Same outline as the arrival card's "Về nhà rồi" (navy .18, 1.5)
          // so every outlined button on Home matches.
          : Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.18),
              width: 1.5,
            ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: filled ? AppColors.white : AppColors.textPrimary,
      ),
    ),
  );
}

/// The rock-paper-scissors tile: same six states as the old `RpsInviteCard`,
/// navy/outlined per C6 instead of the gradient.
class _RpsTile extends StatelessWidget {
  const _RpsTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<RpsGameProvider>();
    final open = provider.openGame;
    final state = provider.openState;
    final urgent =
        state == RpsOpenState.myTurn || state == RpsOpenState.invitedByPartner;
    if (!provider.isHistoryLoaded && !provider.isLoadingHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.read<RpsGameProvider>().loadHistory();
      });
    }
    final String subtitle;
    final String cta;
    switch (state) {
      case RpsOpenState.myTurn:
        subtitle = l10n.rpsPartnerMovedTitle;
        cta = l10n.rpsEntryCtaThrow;
      case RpsOpenState.invitedByPartner:
        subtitle = l10n.rpsEntryInvitedTitle;
        cta = l10n.rpsEntryCtaJoin;
      case RpsOpenState.unplayed:
        subtitle = l10n.rpsEntryUnplayedTitle;
        cta = l10n.rpsEntryCtaThrow;
      case RpsOpenState.awaitingPartner:
        subtitle = l10n.rpsEntryAwaitingTitle;
        cta = l10n.rpsEntryCtaOpen;
      case RpsOpenState.myInvitePending:
        subtitle = l10n.rpsWaitingPartner;
        cta = l10n.rpsEntryCtaOpen;
      case RpsOpenState.none:
        final week = provider.weekScore;
        final nf = NumberFormat.decimalPattern(
          Localizations.localeOf(context).toString(),
        );
        subtitle = week.total == 0
            ? l10n.rpsEntryIdleSubtitle
            : l10n.rpsEntryWeekScore(
                nf.format(week.wins),
                nf.format(week.draws),
                nf.format(week.losses),
              );
        cta = l10n.rpsEntryCtaPlay;
    }
    return PlayTile(
      view: CaroEntryView(
        title: l10n.rpsGameTitle,
        subtitle: subtitle,
        cta: cta,
        urgent: urgent,
      ),
      badge: Stack(
        clipBehavior: Clip.none,
        children: [
          const IconBadge(
            IconsaxPlusBold.game,
            tint: rpsMedalAccent,
            size: 36,
            radius: 12,
            iconSize: 18,
          ),
          if (urgent)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.accentLove,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        AnalyticsService.instance.logHomeEntryTap('rps', urgent: urgent);
        openRpsGame(
          context,
          gameId: state == RpsOpenState.none ? null : open?.id,
        );
      },
    );
  }
}

/// Profile "Chơi cùng nhau" with nobody waiting (review UI #14): one badge
/// for two games, so a sheet with one row per game, each opening that
/// game's history. Rows reuse [CaroEntryRow] (68 tall, ≥48 tap target, 8+
/// apart — UI UX Pro Max `touch-target` / `touch-spacing`).
Future<void> showPlayTogetherHistorySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    routeSettings: const RouteSettings(name: 'PlayTogetherSheet'),
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheet) {
      final l10n = sheet.l10n;
      final caro = sheet.watch<CaroGameProvider>();
      final rps = sheet.watch<RpsGameProvider>();
      final people = CaroPeople.of(sheet, l10n);
      final week = rps.weekScore;
      void go(void Function(BuildContext) open) {
        Navigator.of(sheet).pop();
        if (context.mounted) open(context);
      }

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: CaroSheetHandle()),
              const SizedBox(height: 16),
              Text(
                l10n.caroPlayTogetherTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              CaroEntryRow(
                view: CaroEntryView(
                  title: l10n.caroGameTitle,
                  subtitle: people.score(l10n, caro.myWins, caro.partnerWins),
                  cta: l10n.rpsHistoryCta,
                  urgent: false,
                ),
                badge: CaroGlyph(
                  mine: people.myColor,
                  partner: people.partnerColor,
                ),
                onTap: () => go(openCaroHistory),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.textPrimary.withValues(alpha: 0.08),
              ),
              CaroEntryRow(
                view: CaroEntryView(
                  title: l10n.rpsGameTitle,
                  subtitle: week.total == 0
                      ? ''
                      : l10n.rpsEntryWeekScore(
                          '${week.wins}',
                          '${week.draws}',
                          '${week.losses}',
                        ),
                  cta: l10n.rpsHistoryCta,
                  urgent: false,
                ),
                badge: const IconBadge(
                  IconsaxPlusBold.game,
                  tint: rpsMedalAccent,
                ),
                onTap: () => go(openRpsHistory),
              ),
            ],
          ),
        ),
      );
    },
  );
}
