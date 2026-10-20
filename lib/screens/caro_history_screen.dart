import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/caro_game.dart';
import '../providers/caro_game_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/caro/caro_board.dart';
import '../widgets/caro/caro_common.dart';
import '../widgets/caro/caro_new_game_sheet.dart';
import '../widgets/content_card.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';
import 'caro_game_screen.dart';

void openCaroHistory(BuildContext context) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'CaroHistory'),
      builder: (_) => const CaroHistoryScreen(),
    ),
  );
}

/// "Lịch sử caro" (design §3.5): who leads, then the finished games newest
/// first, one card per month, 30 per page; a row opens the last board.
class CaroHistoryScreen extends StatefulWidget {
  const CaroHistoryScreen({super.key});

  @override
  State<CaroHistoryScreen> createState() => _CaroHistoryScreenState();
}

class _CaroHistoryScreenState extends State<CaroHistoryScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logCaroHistoryOpen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CaroGameProvider>().loadHistory();
    });
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 300) {
        final provider = context.read<CaroGameProvider>();
        if (provider.hasMoreHistory && !provider.historyFailed) {
          provider.loadMoreHistory();
        }
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _locale(BuildContext context) =>
      Localizations.localeOf(context).toString();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _rowDate(AppLocalizations l10n, DateTime? at, DateTime now) {
    if (at == null) return '';
    if (_sameDay(at, now)) return l10n.caroDateToday;
    if (_sameDay(at, now.subtract(const Duration(days: 1)))) {
      return l10n.caroDateYesterday;
    }
    return DateFormat('dd/MM', _locale(context)).format(at);
  }

  String _when(AppLocalizations l10n, DateTime? at, DateTime now) {
    if (at == null) return '';
    if (_sameDay(at, now)) return l10n.caroWhenToday;
    if (_sameDay(at, now.subtract(const Duration(days: 1)))) {
      return l10n.caroWhenYesterday;
    }
    return l10n.caroWhenOn(DateFormat('dd/MM', _locale(context)).format(at));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<CaroGameProvider>();
    final people = CaroPeople.of(context, l10n);
    final now = DateTime.now();
    final games = provider.history;
    // A failed first page shows only the error card (review UI #11).
    final loading =
        !provider.isHistoryLoaded && games.isEmpty && !provider.historyFailed;

    final items = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: SubScreenHeader(
          badge: l10n.caroHistoryBadge,
          badgeIcon: IconsaxPlusBold.game,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _summary(l10n, provider, people, games, now, loading),
      ),
    ];

    if (loading) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _skeletonRows(),
        ),
      );
    }

    // One card per month.
    String? month;
    var rows = <Widget>[];
    void flush() {
      if (month == null || rows.isEmpty) return;
      items
        ..add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Semantics(
              header: true,
              child: Text(
                month,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        )
        ..add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ContentCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Column(children: rows),
            ),
          ),
        );
      rows = <Widget>[];
    }

    for (final g in games) {
      final at = g.finishedAt ?? g.updatedAt;
      final m = at == null
          ? ''
          : toBeginningOfSentenceCase(
              (at.year == now.year
                      ? DateFormat.MMMM(_locale(context))
                      : DateFormat.yMMMM(_locale(context)))
                  .format(at),
            );
      if (m != month) {
        flush();
        month = m;
      }
      if (rows.isNotEmpty) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        );
      }
      rows.add(_row(l10n, people, g, now));
    }
    flush();

    if (provider.isLoadingHistory && games.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _skeletonRows(),
        ),
      );
    }
    if (provider.historyFailed) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: ContentCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.caroHistoryPageError,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: games.isEmpty
                      ? provider.loadHistory
                      : provider.loadMoreHistory,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: Text(
                    l10n.caroCtaRetry,
                    style: const TextStyle(
                      fontSize: 14,
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
    items.add(SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom));

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ListView(controller: _scroll, children: items),
        ),
      ),
    );
  }

  Widget _skeletonRows() => Column(
    children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerSkeleton(
            width: double.infinity,
            height: 60,
            borderRadius: 16,
          ),
        ),
    ],
  );

  Widget _summary(
    AppLocalizations l10n,
    CaroGameProvider provider,
    CaroPeople people,
    List<CaroGame> games,
    DateTime now,
    bool loading,
  ) {
    final mine = provider.myWins;
    final theirs = provider.partnerWins;
    final total = provider.state.totalFor(people.myUid, people.partnerUid);
    final empty =
        !loading && !provider.historyFailed && games.isEmpty && total == 0;
    late final String h1;
    late final String sub;
    if (empty) {
      h1 = l10n.caroHistoryEmpty;
      sub = l10n.caroHistoryEmptySub;
    } else {
      h1 = mine == theirs
          ? l10n.caroTied('$mine')
          : l10n.caroLeads(
              mine > theirs ? people.myName : people.partnerName,
              '${(mine - theirs).abs()}',
            );
      if (games.isEmpty) {
        sub = '';
      } else {
        // "từ {date}" only once every page is in: the oldest LOADED game
        // isn't the first one while more pages remain (review UI #10).
        final oldest = provider.hasMoreHistory ? null : games.last.finishedAt;
        final last = games.first;
        final when = _when(l10n, last.finishedAt, now);
        final winner = last.result?.winnerUid;
        if (oldest == null) {
          sub = winner == null
              ? l10n.caroHistorySubDrawNoSince('$total', when)
              : l10n.caroHistorySubNoSince(
                  '$total',
                  people.nameOf(winner),
                  when,
                );
        } else {
          final since = DateFormat('dd/MM', _locale(context)).format(oldest);
          sub = winner == null
              ? l10n.caroHistorySubDraw('$total', since, when)
              : l10n.caroHistorySub(
                  '$total',
                  since,
                  people.nameOf(winner),
                  when,
                );
        }
      }
    }
    final open = provider.openGame;
    return ContentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            h1,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CaroLanes(
            people: people,
            myWins: mine,
            partnerWins: theirs,
            mySide: CaroSide.x,
            partnerSide: CaroSide.o,
            midTop: l10n.caroLaneGames('$total'),
            midBottom: '',
          ),
          if (empty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => open != null
                    ? openCaroGame(context, gameId: open.id)
                    : showCaroNewGameSheet(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  open != null
                      ? l10n.caroOpenCurrent
                      : l10n.caroStartWith(people.partnerName),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    AppLocalizations l10n,
    CaroPeople people,
    CaroGame g,
    DateTime now,
  ) {
    final r = g.result;
    final winner = r?.winnerUid;
    final n = '${g.cells.length}';
    final title = winner == null
        ? l10n.caroRowDraw
        : l10n.caroRowWon(people.nameOf(winner));
    var sub = switch (r?.reason) {
      CaroResultReason.resign => l10n.caroRowResign(
        people.nameOf(g.endedBy),
        n,
      ),
      CaroResultReason.full => l10n.caroRowFull,
      _ => l10n.caroRowFive(n),
    };
    if (g.rule == CaroRule.free) sub += l10n.caroRowFreeSuffix;
    final date = _rowDate(l10n, g.finishedAt, now);
    return Semantics(
      button: true,
      label: '$title. $sub. $date',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openCaroReplay(context, g.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                CaroThumb(
                  game: g,
                  colorX: people.colorX(g),
                  colorO: people.colorO(g),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (winner != null) ...[
                            // Design §3.5: the winner's stone in their colour.
                            CaroStone(
                              side: g.sideOf(winner) ?? CaroSide.x,
                              color: people.colorOfUid(winner),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
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
