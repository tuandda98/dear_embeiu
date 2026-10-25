import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_math.dart';
import '../../utils/money_views.dart';
import '../../widgets/money/money_ui.dart';
import '../../widgets/segmented_pill.dart';
import '../../widgets/shimmer_skeleton.dart';

/// "Báo cáo" (design §3.8): the month (own: Thu | Chi | Còn lại, shared:
/// one big number), who paid (shared), spending by category with the
/// sub-categories one tap away, spending per month (6 / 12, from the
/// server's monthly sums — the live list only holds ~45 days) and by wallet.
class MoneyReportScreen extends StatefulWidget {
  const MoneyReportScreen({
    super.key,
    this.book = MoneyBookKind.own,
    this.month,
  });

  final MoneyBookKind book;

  /// 'YYYY-MM'; null = this month.
  final String? month;

  @override
  State<MoneyReportScreen> createState() => _MoneyReportScreenState();
}

class _MoneyReportScreenState extends State<MoneyReportScreen> {
  late MoneyBookKind _book = widget.book;
  int _range = 6;
  Map<String, MoneyMonthTotals?>? _trend;
  String? _trendKey;

  /// Groups open in "Chi theo danh mục"; null = the biggest one (mockup).
  Set<String>? _open;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logMoneyReportOpen(
      book: _book.name,
      view: 'month',
    );
  }

  void _loadTrend(MoneyProvider money, MoneyBookState state) {
    final view = '${_book.name}|$_range';
    // The live-window months are summed from the entries on hand, so an
    // entry added / edited / deleted while the screen is open reloads them
    // (a new snapshot = a new list; a pending delete changes the count).
    final key =
        '$view|${identityHashCode(state.txs)}|'
        '${money.visibleTxs(_book).length}';
    if (_trendKey == key) return;
    // Same view, newer data: keep the old bars until the new ones land.
    if (_trendKey?.startsWith('$view|') != true) _trend = null;
    _trendKey = key;
    money.trend(_book, _range).then((t) {
      if (mounted && _trendKey == key) setState(() => _trend = t);
    });
  }

  void _setBook(MoneyBookKind b) => setState(() {
    _book = b;
    _open = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    if (_book == MoneyBookKind.shared && !money.hasShared) {
      _book = MoneyBookKind.own;
    }
    money.activeBook = _book;
    final state = money.book(_book);
    final today = money.today;
    final month = widget.month ?? today.substring(0, 7);
    final txs = money.txsForMonth(_book, month);
    if (state != null && txs == null) {
      // Older than the live window: load that month once (one listener).
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => money.viewMonth(_book, month),
      );
    }
    if (state != null) _loadTrend(money, state);
    final loading = state == null || txs == null || !state.txLoaded;
    final list = txs ?? const <MoneyTx>[];
    final idx = state?.categories;
    final totals = MoneyMath.monthTotals(list, month);
    final cats = idx == null
        ? const <(String, int)>[]
        : MoneyMath.byCategory(list, month, groupOf: idx.groupOf);

    return MoneyPage(
      badge: l10n.moneyReportBadge,
      icon: IconsaxPlusLinear.chart_2,
      book: _book,
      onBook: _setBook,
      slivers: [
        moneyBlock(
          _MonthCard(
            book: _book,
            month: month,
            today: today,
            txs: list,
            totals: totals,
            cats: cats,
            loading: loading,
          ),
        ),
        if (!loading && cats.isNotEmpty && idx != null)
          moneyBlock(
            MoneyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MoneyCardHeader(
                    title: l10n.moneyReportByCategory,
                    trailing: Text(
                      l10n.moneyReportTapHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < cats.length; i++)
                    _CategoryBar(
                      emoji: idx.of(cats[i].$1).emoji,
                      name: idx.of(cats[i].$1).name,
                      amount: cats[i].$2,
                      percent: MoneyViews.percentOf(cats[i].$2, totals.expense),
                      frac: cats[i].$2 / cats.first.$2,
                      top: i == 0,
                      open: (_open ?? {cats.first.$1}).contains(cats[i].$1),
                      children: [
                        for (final (id, v) in MoneyViews.childrenOf(
                          list,
                          month,
                          cats[i].$1,
                          groupOf: idx.groupOf,
                        ))
                          (idx.of(id).name, v),
                      ],
                      onTap: () => setState(() {
                        final s = {
                          ...(_open ?? {cats.first.$1}),
                        };
                        if (!s.remove(cats[i].$1)) s.add(cats[i].$1);
                        _open = s;
                      }),
                    ),
                ],
              ),
            ),
          ),
        moneyBlock(
          MoneyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MoneyCardHeader(title: l10n.moneyReportByMonth),
                    ),
                    SizedBox(
                      width: 188,
                      child: SegmentedPill<int>(
                        values: const [6, 12],
                        selected: _range,
                        height: 44,
                        onSurface: true,
                        labelOf: (n) =>
                            n == 6 ? l10n.moneyReport6 : l10n.moneyReport12,
                        onChanged: (n) {
                          setState(() => _range = n);
                          AnalyticsService.instance.logMoneyReportOpen(
                            book: _book.name,
                            view: 'trend',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TrendBlock(
                  book: _book,
                  trend: _trend,
                  today: today,
                  budget: money.budgetFor(_book, '')?.amount,
                ),
              ],
            ),
          ),
        ),
        if (!loading) ?_walletCard(context, money, list, month),
      ],
    );
  }

  Widget? _walletCard(
    BuildContext context,
    MoneyProvider money,
    List<MoneyTx> list,
    String month,
  ) {
    final ctx = MoneyRowContext.of(context, money, _book);
    final rows = [
      for (final r in MoneyMath.byWallet(list, month))
        if (r.$1.isNotEmpty) r,
    ];
    if (rows.isEmpty) return null;
    return moneyBlock(
      MoneyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoneyCardHeader(title: context.l10n.moneyReportByWallet),
            const SizedBox(height: 4),
            for (final (id, v) in rows)
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: ExcludeSemantics(
                        child: Text(
                          ctx.wallets[id]?.emoji ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ctx.walletName(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    MoneyAmountText(v, size: 15),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.book,
    required this.month,
    required this.today,
    required this.txs,
    required this.totals,
    required this.cats,
    required this.loading,
  });

  final MoneyBookKind book;
  final String month;
  final String today;
  final List<MoneyTx> txs;
  final MoneyMonthTotals totals;
  final List<(String, int)> cats;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final idx = context.read<MoneyProvider>().book(book)?.categories;
    final shared = book == MoneyBookKind.shared;
    final current = month == today.substring(0, 7);

    String? finding;
    if (!loading && idx != null) {
      if (cats.isEmpty) {
        finding = l10n.moneyReportNoSpend(moneyMonthShort(context, month));
      } else {
        final (top, amount) = cats.first;
        final name = idx.of(top).name;
        final pct = '${MoneyViews.percentOf(amount, totals.expense)}';
        finding = shared
            ? l10n.moneyReportTopShared(name, pct)
            : l10n.moneyReportTopCategory(name, pct);
        final kids = MoneyViews.childrenOf(
          txs,
          month,
          top,
          groupOf: idx.groupOf,
        );
        if (kids.length > 1 && kids.first.$2 * 2 >= amount) {
          finding +=
              ' ${l10n.moneyReportTopChild(idx.of(kids.first.$1).name, vnd(context, kids.first.$2))}';
        }
      }
    }

    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyCardHeader(
            title: moneyMonthLabel(context, month),
            trailing: current
                ? Text(
                    l10n.moneyReportUpTo(moneyShortDate(context, today)),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          if (loading)
            const ShimmerSkeleton(width: 170, height: 30)
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyAmountText(totals.expense, size: 30),
            ),
          const SizedBox(height: 12),
          if (finding == null)
            const ShimmerSkeleton(width: 260, height: 14)
          else
            Text(
              finding,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

/// One horizontal bar of "Chi theo danh mục" (UI UX Pro Max: sorted bars,
/// not a treemap); tap opens the sub-categories, indented 30.
class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.percent,
    required this.frac,
    required this.top,
    required this.open,
    required this.children,
    required this.onTap,
  });

  final String emoji;
  final String name;
  final int amount;
  final int percent;
  final double frac;
  final bool top;
  final bool open;
  final List<(String, int)> children;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    final kid = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: '$name, $percent%, ${vndSpoken(context, amount)}',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.accentRose.withValues(alpha: 0.08),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        MoneyAmountText(amount, size: 15),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: frac.clamp(0.02, 1.0),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: top
                                ? AppColors.textPrimary
                                : AppColors.textPrimary.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Column(
                  children: [
                    for (final (n, v) in children)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 4, 0, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                n,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: kid,
                              ),
                            ),
                            Text(vnd(context, v), style: kid),
                          ],
                        ),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The 6 / 12-month columns + the line under them.
class _TrendBlock extends StatelessWidget {
  const _TrendBlock({
    required this.book,
    required this.trend,
    required this.today,
    required this.budget,
  });

  final MoneyBookKind book;
  final Map<String, MoneyMonthTotals?>? trend;
  final String today;
  final int? budget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = trend;
    if (t == null) return const ShimmerSkeleton(height: 168);
    final lang = moneyLang(context);
    final first = MoneyViews.firstActiveMonth(t);
    final thisMonth = today.substring(0, 7);
    final bars = <({String month, int? value, bool now})>[
      for (final e in t.entries)
        (
          month: e.key,
          // Before the book's first month = not drawn, never a fake 0.
          value: first == null || e.key.compareTo(first) < 0
              ? (e.key == thisMonth ? (e.value?.expense ?? 0) : null)
              : e.value?.expense,
          now: e.key == thisMonth,
        ),
    ];
    String label(String m) {
      final n = int.parse(m.substring(5, 7));
      return lang == 'vi'
          ? 'T$n'
          : DateFormat.MMM(lang).format(DateTime(2000, n));
    }

    final missing = t.entries.any(
      (e) =>
          e.value == null &&
          (first == null || e.key.compareTo(first) >= 0) &&
          e.key != thisMonth,
    );
    final notes = <String>[
      if (first != null && first.compareTo(t.keys.first) > 0)
        book == MoneyBookKind.shared
            ? l10n.moneyReportNewBook(moneyMonthShort(context, first))
            : l10n.moneyReportNewBookMine(moneyMonthShort(context, first)),
      if (missing) l10n.moneyReportMissing,
      if (budget == null)
        l10n.moneyReportPartialNoBudget(
          moneyMonthShort(context, thisMonth),
          moneyShortDate(context, today),
        )
      else
        l10n.moneyReportPartial(
          moneyMonthShort(context, thisMonth),
          moneyShortDate(context, today),
        ),
    ];
    final spoken = [
      for (final b in bars)
        if (b.value != null)
          '${label(b.month)} ${vndSpoken(context, b.value!)}',
    ].join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.moneyReportChartLabel('${bars.length}', spoken),
          excludeSemantics: true,
          child: SizedBox(
            height: 168,
            child: CustomPaint(
              painter: MoneyTrendPainter(
                bars: bars,
                budget: budget,
                monthLabel: label,
                short: (v) => vndShort(context, v),
                budgetLabel: (v) =>
                    l10n.moneyReportBudgetLine(vndShort(context, v)),
                tet: l10n.moneyReportTet,
                skipOddLabels: bars.length > 6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              n,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Columns of "Chi mỗi tháng" (design §3.8): square bars rounded 3 on top,
/// old months navy .30, this month `accentLove` + its value, 4 grid lines
/// with a darker 0, the total budget as a 4/3 dashed navy line, "Tết" over
/// the month it falls in. A null value is not drawn.
class MoneyTrendPainter extends CustomPainter {
  MoneyTrendPainter({
    required this.bars,
    required this.budget,
    required this.monthLabel,
    required this.short,
    required this.budgetLabel,
    required this.tet,
    this.skipOddLabels = false,
  });

  final List<({String month, int? value, bool now})> bars;
  final int? budget;
  final String Function(String month) monthLabel;
  final String Function(int v) short;
  final String Function(int v) budgetLabel;
  final String tet;
  final bool skipOddLabels;

  static const double _l = 34, _r = 4, _t = 22, _b = 22;

  void _text(
    Canvas c,
    String s,
    Offset at, {
    TextAlign align = TextAlign.center,
    bool ink = false,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11,
          fontWeight: ink ? FontWeight.w700 : FontWeight.w600,
          color: ink ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right || TextAlign.end => at.dx - p.width,
      TextAlign.left || TextAlign.start => at.dx,
      _ => at.dx - p.width / 2,
    };
    p.paint(c, Offset(dx, at.dy - p.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pw = w - _l - _r, ph = h - _t - _b;
    var max = budget ?? 0;
    for (final b in bars) {
      max = math.max(max, b.value ?? 0);
    }
    final scale = MoneyViews.chartScale(max);
    double y(num v) => _t + ph - v / scale.top * ph;

    final grid = Paint()..strokeWidth = 1;
    for (var v = 0; v <= scale.top; v += scale.step) {
      grid.color = v == 0
          ? AppColors.textPrimary.withValues(alpha: 0.25)
          : const Color(0xFFEFE7EF);
      canvas.drawLine(Offset(_l, y(v)), Offset(w - _r, y(v)), grid);
      _text(
        canvas,
        v == 0 ? '0' : short(v),
        Offset(_l - 6, y(v)),
        align: TextAlign.right,
      );
    }

    final bw = pw / bars.length;
    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final cx = _l + i * bw + bw / 2;
      if (b.value != null && b.value! > 0) {
        final rect = Rect.fromLTRB(
          _l + i * bw + bw * .22,
          y(b.value!),
          _l + i * bw + bw * .78,
          y(0),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          Paint()
            ..color = b.now
                ? AppColors.accentLove
                : AppColors.textPrimary.withValues(alpha: 0.30),
        );
      }
      if (b.value != null && b.now) {
        _text(canvas, short(b.value!), Offset(cx, y(b.value!) - 9), ink: true);
      } else if (b.value != null && MoneyViews.hasTet(b.month)) {
        _text(canvas, tet, Offset(cx, y(b.value!) - 9), ink: true);
      }
      if (!skipOddLabels || i.isEven || b.now) {
        _text(canvas, monthLabel(b.month), Offset(cx, h - 9));
      }
    }

    final bud = budget;
    if (bud != null && bud > 0) {
      final by = y(bud);
      final dash = Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 1;
      for (var x = _l; x < w - _r; x += 7) {
        canvas.drawLine(
          Offset(x, by),
          Offset(math.min(x + 4, w - _r), by),
          dash,
        );
      }
      _text(
        canvas,
        budgetLabel(bud),
        Offset(w - _r, by - 9),
        align: TextAlign.right,
        ink: true,
      );
    }
  }

  @override
  bool shouldRepaint(MoneyTrendPainter old) =>
      old.bars != bars || old.budget != budget;
}
