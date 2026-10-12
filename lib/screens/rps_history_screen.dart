import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/rps_game.dart';
import '../providers/rps_game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/rps_choice_tile.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';
import 'rps_game_screen.dart';

/// Opens the rock-paper-scissors history (scoreboard + past rounds) —
/// feature rps-game. One route name for every entry point (Profile badge,
/// result screen, `rps_result` push tap).
void openRpsHistory(BuildContext context) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'RpsHistory'),
      builder: (_) => const RpsHistoryScreen(),
    ),
  );
}

/// "Lịch sử ván" — all-time scoreboard (Mình / Hoà / Người ấy) + finished
/// rounds newest-first grouped by day, same skeleton as the care timeline
/// (30/page, infinite scroll, pull-to-refresh). Data comes from
/// [RpsGameProvider] so a round that finishes while the screen is open is
/// prepended without a refetch.
class RpsHistoryScreen extends StatefulWidget {
  const RpsHistoryScreen({super.key});

  @override
  State<RpsHistoryScreen> createState() => _RpsHistoryScreenState();
}

class _RpsHistoryScreenState extends State<RpsHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<RpsGameProvider>();
      provider.loadTotalScore();
      if (!provider.isHistoryLoaded) {
        provider.loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      context.read<RpsGameProvider>().loadMoreHistory();
    }
  }

  Future<void> _refresh() async {
    final provider = context.read<RpsGameProvider>();
    await Future.wait(<Future<void>>[
      provider.loadHistory(),
      provider.loadTotalScore(force: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SubScreenHeader(
                  badge: l10n.rpsHistoryBadge,
                  badgeIcon: IconsaxPlusLinear.clock,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.accentLove,
                  child: _buildBody(l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final provider = context.watch<RpsGameProvider>();
    final firstLoad = !provider.isHistoryLoaded;
    if (firstLoad) {
      return const _HistoryLoading();
    }
    if (provider.history.isEmpty) {
      return _HistoryMessage(
        icon: IconsaxPlusLinear.game,
        title: l10n.rpsHistoryEmptyTitle,
        body: l10n.rpsHistoryEmptyBody,
        ctaLabel: l10n.rpsHistoryEmptyCta,
        onCta: () => openRpsGame(context),
      );
    }
    return _buildList(l10n, provider);
  }

  Widget _buildList(AppLocalizations l10n, RpsGameProvider provider) {
    final locale = Localizations.localeOf(context).toString();
    final myUid = provider.myUid ?? '';
    final rows = _buildRows(provider.history, l10n, locale);
    final loadingMore = provider.isLoadingHistory && provider.isHistoryLoaded;
    final tail = (provider.hasMoreHistory || loadingMore) ? 1 : 0;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      // +1 for the scoreboard on top.
      itemCount: 1 + rows.length + tail,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: _Scoreboard(
              score: provider.totalScore,
              winStreak: provider.currentWinStreak,
            ),
          );
        }
        final rowIndex = index - 1;
        if (rowIndex >= rows.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Column(
              children: [
                ShimmerSkeleton(height: 72, borderRadius: 22),
                SizedBox(height: 10),
                ShimmerSkeleton(height: 72, borderRadius: 22),
              ],
            ),
          );
        }
        final row = rows[rowIndex];
        if (row.dayLabel != null) {
          return Padding(
            padding: EdgeInsets.only(top: rowIndex == 0 ? 0 : 18, bottom: 10),
            child: Text(
              row.dayLabel!,
              style: const TextStyle(
                color: AppColors.accentLove,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _HistoryRow(game: row.game!, myUid: myUid, locale: locale),
        );
      },
    );
  }

  /// Flattens newest-first games into [day header, game, game, …] rows on the
  /// viewer's local calendar (same convention as care_timeline).
  List<_HistoryRowData> _buildRows(
    List<RpsGame> games,
    AppLocalizations l10n,
    String locale,
  ) {
    final rows = <_HistoryRowData>[];
    String? currentKey;
    for (final game in games) {
      final when = game.finishedAt;
      final key = when == null ? '' : _dayKey(when);
      if (key != currentKey) {
        currentKey = key;
        rows.add(_HistoryRowData.day(_dayLabel(when, l10n, locale)));
      }
      rows.add(_HistoryRowData.game(game));
    }
    return rows;
  }

  static String _dayKey(DateTime when) =>
      '${when.year}-${when.month}-${when.day}';

  String _dayLabel(DateTime? when, AppLocalizations l10n, String locale) {
    if (when == null) {
      return l10n.notifGroupToday.toUpperCase();
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) {
      return l10n.notifGroupToday.toUpperCase();
    }
    if (diff == 1) {
      return l10n.careTimelineYesterday.toUpperCase();
    }
    return DateFormat.yMMMMd(locale).format(when).toUpperCase();
  }
}

class _HistoryRowData {
  const _HistoryRowData.day(String label) : dayLabel = label, game = null;
  const _HistoryRowData.game(RpsGame this.game) : dayLabel = null;

  final String? dayLabel;
  final RpsGame? game;
}

// ── Scoreboard ───────────────────────────────────────────────────────────────

/// Three columns (mine · draws · theirs) with the all-time totals, a hairline
/// and the "N ván đã chơi · Chuỗi thắng: k" footer. Shimmers while the
/// aggregation is in flight.
class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.score, required this.winStreak});

  final RpsScore? score;
  final int winStreak;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = score;
    if (s == null) {
      return const ShimmerSkeleton(height: 96, borderRadius: 24);
    }
    final nf = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final total = nf.format(s.total);
    final footer = winStreak > 0
        ? '${l10n.rpsHistoryTotal(total)} · '
              '${l10n.rpsHistoryWinStreak(nf.format(winStreak))}'
        : l10n.rpsHistoryTotal(total);

    return Semantics(
      label: l10n.rpsScoreSemantics(
        nf.format(s.wins),
        nf.format(s.draws),
        nf.format(s.losses),
      ),
      child: ExcludeSemantics(
        child: ContentCard(
          child: Column(
            children: [
              Row(
                children: [
                  _ScoreColumn(
                    value: nf.format(s.wins),
                    label: l10n.rpsScoreMe,
                    color: AppColors.accentLove,
                  ),
                  _ScoreColumn(
                    value: nf.format(s.draws),
                    label: l10n.rpsScoreDraw,
                    color: AppColors.textSecondary,
                  ),
                  _ScoreColumn(
                    value: nf.format(s.losses),
                    label: l10n.rpsScorePartner,
                    color: AppColors.accentLavenderDeep,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.surfaceLight),
              const SizedBox(height: 12),
              Text(
                footer,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.textPrimary.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Row ──────────────────────────────────────────────────────────────────────

/// One finished round: time · my hand · vs · their hand · outcome pill. My
/// hand is always on the LEFT; the winning hand wears a 30pt tinted ring.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.game,
    required this.myUid,
    required this.locale,
  });

  final RpsGame game;
  final String myUid;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = game.result;
    final outcome = result?.outcomeFor(myUid) ?? RpsOutcome.draw;
    final mine = result?.choiceOf(myUid) ?? RpsChoice.none;
    final theirsUid = game.partnerOf(myUid) ?? '';
    final theirs = result?.choiceOf(theirsUid) ?? RpsChoice.none;
    final skipped = !mine.isHand || !theirs.isHand;
    final when = game.finishedAt;
    final time = when == null ? '' : DateFormat.Hm(locale).format(when);

    final String pillLabel;
    final Color pillFill;
    final Color pillInk;
    if (skipped && outcome == RpsOutcome.draw) {
      pillLabel = l10n.rpsOutcomeSkipped;
      pillFill = AppColors.textTertiary.withValues(alpha: 0.12);
      pillInk = AppColors.textTertiary;
    } else {
      switch (outcome) {
        case RpsOutcome.win:
          pillLabel = l10n.rpsOutcomeWin;
          pillFill = AppColors.accentLove.withValues(alpha: 0.12);
          pillInk = AppColors.accentLoveDeep;
        case RpsOutcome.lose:
          pillLabel = l10n.rpsOutcomeLoss;
          pillFill = AppColors.accentLavender.withValues(alpha: 0.12);
          pillInk = AppColors.accentLavenderDeep;
        case RpsOutcome.draw:
          pillLabel = l10n.rpsOutcomeDraw;
          pillFill = AppColors.surfaceLight;
          pillInk = AppColors.textSecondary;
      }
    }

    // PO 2026-09-14: a round only ONE side skipped keeps its win/lose pill
    // (it counts in the score) and the skipper's hand becomes a small
    // "⏳ Bỏ lượt" chip; both skipped → two ⏳ + the "Bỏ lượt" pill.
    final oneSideSkipped = skipped && outcome != RpsOutcome.draw;
    Widget hand(RpsChoice choice, Color? ring) =>
        oneSideSkipped && !choice.isHand
        ? _SkippedChip(label: l10n.rpsChoiceNone)
        : _HandGlyph(choice: choice, ring: ring);

    return Semantics(
      label: l10n.rpsHistoryRowSemantics(
        time,
        rpsChoiceLabel(l10n, mine),
        rpsChoiceLabel(l10n, theirs),
        pillLabel,
      ),
      child: ExcludeSemantics(
        child: ContentCard(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              hand(
                mine,
                outcome == RpsOutcome.win
                    ? AppColors.accentRose.withValues(alpha: 0.12)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.rpsVs,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary.withValues(alpha: 0.45),
                  ),
                ),
              ),
              hand(
                theirs,
                outcome == RpsOutcome.lose
                    ? AppColors.accentLavender.withValues(alpha: 0.12)
                    : null,
              ),
              const SizedBox(width: 8),
              // The pill absorbs any squeeze (≤320pt + a skipped chip): it
              // ellipsizes instead of overflowing the row.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: pillFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pillLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: pillInk,
                      ),
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

/// "⏳ Bỏ lượt" in place of a hand the player didn't throw in a round the
/// OTHER side won by timeout (PO 2026-09-14) — neutral textTertiary tint like
/// the "Bỏ lượt" pill, 30pt tall to line up with [_HandGlyph].
class _SkippedChip extends StatelessWidget {
  const _SkippedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${rpsChoiceGlyph(RpsChoice.none)} $label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          height: 1,
        ),
      ),
    );
  }
}

class _HandGlyph extends StatelessWidget {
  const _HandGlyph({required this.choice, required this.ring});

  final RpsChoice choice;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: ring == null
          ? null
          : BoxDecoration(color: ring, shape: BoxShape.circle),
      child: Opacity(
        opacity: choice.isHand ? 1 : 0.6,
        child: Text(
          rpsChoiceGlyph(choice),
          style: const TextStyle(fontSize: 22, height: 1),
        ),
      ),
    );
  }
}

// ── Loading / empty ──────────────────────────────────────────────────────────

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const ShimmerSkeleton(height: 96, borderRadius: 24),
        const SizedBox(height: 22),
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          const ShimmerSkeleton(height: 72, borderRadius: 22),
        ],
      ],
    );
  }
}

/// Centered empty state — scrollable so pull-to-refresh still works.
class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  final IconData icon;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.zero,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 38, color: AppColors.accentLove),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTheme.displaySerif(
                        size: 20,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onCta();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          ctaLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
