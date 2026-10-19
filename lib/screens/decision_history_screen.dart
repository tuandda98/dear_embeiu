import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/decision.dart';
import '../providers/decision_provider.dart';
import '../services/analytics_service.dart';
import '../services/daily_question_service.dart';
import '../theme/app_colors.dart';
import '../utils/decision_suggester.dart';
import '../widgets/content_card.dart';
import '../widgets/decision_parts.dart';
import '../widgets/icon_badge.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';

/// "Đã quay" (feature decision-wheel, design D): top 5 food / plans over 90
/// days, then every pick grouped by its `date`, 30 per page. Rows are
/// read-only (D17).
class DecisionHistoryScreen extends StatefulWidget {
  const DecisionHistoryScreen({super.key});

  @override
  State<DecisionHistoryScreen> createState() => _DecisionHistoryScreenState();
}

class _DecisionHistoryScreenState extends State<DecisionHistoryScreen> {
  final ScrollController _scroll = ScrollController();
  final List<Decision> _items = <Decision>[];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logDecisionHistoryOpen();
    _scroll.addListener(_onScroll);
    context.read<DecisionProvider>().ensureRecent();
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final page = await context.read<DecisionProvider>().fetchPage();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await context.read<DecisionProvider>().fetchPage(
        startAfter: _lastDoc,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _lastDoc = page.lastDoc ?? _lastDoc;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _tryASpin() async {
    await openDecisionWheel(context, autoSpin: true);
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SubScreenHeader(
                  badge: l10n.decisionHistoryBadge,
                  badgeIcon: IconsaxPlusLinear.clock,
                ),
              ),
              Expanded(child: _buildBody(l10n, bottomInset)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, double bottomInset) {
    final padding = EdgeInsets.fromLTRB(16, 12, 16, 32 + bottomInset);
    if (_loading) {
      return ListView(
        padding: padding,
        children: [
          const Row(
            children: [
              Expanded(child: ShimmerSkeleton(height: 168, borderRadius: 24)),
              SizedBox(width: 12),
              Expanded(child: ShimmerSkeleton(height: 168, borderRadius: 24)),
            ],
          ),
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: ShimmerSkeleton(height: 72, borderRadius: 24),
            ),
        ],
      );
    }
    if (_error) {
      return _Message(
        icon: IconsaxPlusLinear.cloud_cross,
        title: l10n.decisionHistoryLoadError,
        ctaLabel: l10n.decisionRetry,
        ctaIcon: IconsaxPlusLinear.refresh,
        onCta: _reload,
      );
    }
    if (_items.isEmpty) {
      return _Message(
        icon: IconsaxPlusLinear.shuffle,
        title: l10n.decisionHistoryEmptyTitle,
        body: l10n.decisionHistoryEmptyBody,
        ctaLabel: l10n.decisionHistoryEmptyCta,
        ctaIcon: IconsaxPlusLinear.shuffle,
        onCta: _tryASpin,
      );
    }

    // Group by the pick's own `date` (the picker's day) so both phones agree.
    final groups = <String, List<Decision>>{};
    for (final d in _items) {
      groups.putIfAbsent(d.date, () => <Decision>[]).add(d);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      color: AppColors.accentLove,
      onRefresh: _reload,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          const _TopBlocks(),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.decisionRecent),
          for (var i = 0; i < dates.length; i++) ...[
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 18, bottom: 10),
              child: Text(
                _dayLabel(l10n, dates[i]).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            ContentCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Column(
                children: [
                  for (var j = 0; j < groups[dates[i]]!.length; j++) ...[
                    if (j > 0)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 48),
                        color: AppColors.surfaceLight,
                      ),
                    _HistoryRow(decision: groups[dates[i]]![j]),
                  ],
                ],
              ),
            ),
          ],
          if (_loadingMore || _hasMore)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.accentLove,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _dayLabel(AppLocalizations l10n, String date) {
    final now = DateTime.now();
    if (date == DailyQuestionService.dateKey(now)) return l10n.decisionDayToday;
    if (date == DecisionSuggester.dayKey(now, 1)) {
      return l10n.decisionDayYesterday;
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat.MMMEd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(parsed);
  }
}

class _TopBlocks extends StatelessWidget {
  const _TopBlocks();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DecisionProvider>();
    final eat = _TopBlock(
      kind: DecisionKind.eat,
      rows: provider.top(DecisionKind.eat),
    );
    final go = _TopBlock(
      kind: DecisionKind.go,
      rows: provider.top(DecisionKind.go),
    );
    final stack =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.of(context).size.width < 360;
    if (stack) {
      return Column(children: [eat, const SizedBox(height: 12), go]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: eat),
          const SizedBox(width: 12),
          Expanded(child: go),
        ],
      ),
    );
  }
}

class _TopBlock extends StatelessWidget {
  const _TopBlock({required this.kind, required this.rows});

  final DecisionKind kind;
  final List<(Decision, int)> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final english = decisionIsEnglish(context);
    return ContentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                decisionKindIcon(kind),
                tint: decisionKindTint(kind),
                size: 36,
                radius: 12,
                iconSize: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  kind == DecisionKind.eat
                      ? l10n.decisionTopEat
                      : l10n.decisionTopGo,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.decisionTopCaption,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text(
              l10n.decisionTopEmpty,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          for (var i = 0; i < rows.length; i++)
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      decisionLine(rows[i].$1, english: english),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Semantics(
                    label: l10n.decisionTopCountSemantics(rows[i].$2),
                    excludeSemantics: true,
                    child: Text(
                      '${rows[i].$2}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.decision});

  final Decision decision;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = decision;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconBadge(
            decisionKindIcon(d.kind),
            tint: decisionKindTint(d.kind),
            size: 36,
            radius: 12,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.kind == DecisionKind.custom && d.question.isNotEmpty)
                  Text(
                    d.question,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  decisionLine(d, english: decisionIsEnglish(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  decisionMeta(context, d),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (d.spins > 1)
            Semantics(
              label: l10n.decisionSpinsSemantics(d.spins),
              excludeSemantics: true,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.decisionSpinsBadge(d.spins),
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
    );
  }
}

/// Empty / error state (care timeline `_TimelineMessage` recipe, body in navy
/// α.72 — textSecondary fails on blush).
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.onCta,
    this.body,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String ctaLabel;
  final IconData ctaIcon;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 10),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 22),
            DecisionPillButton(
              label: ctaLabel,
              icon: ctaIcon,
              onPressed: () {
                HapticFeedback.selectionClick();
                onCta();
              },
            ),
          ],
        ),
      ),
    );
  }
}
