import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/money_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../utils/money_math.dart';
import '../../widgets/header_icon_button.dart';
import '../../widgets/money/add_transaction_sheet.dart';
import '../../widgets/money/money_currency_sheet.dart';
import '../../widgets/money/money_ui.dart';
import '../../widgets/segmented_pill.dart';
import '../../widgets/shimmer_skeleton.dart';
import '../../widgets/sub_screen_header.dart';
import '../../widgets/today_constellation.dart' show MidnightBuilder;
import 'money_budgets_screen.dart';
import 'money_categories_screen.dart';
import 'money_first_run.dart';
import 'money_report_screen.dart';
import 'money_search_screen.dart';
import 'money_wallets_screen.dart';
// ── expenses (đợt 2) ── stage 3B
import '../../services/money_analytics.dart';
import '../../widgets/money/money_reminder_tile.dart';
import '../../widgets/money/settle_sheet.dart';
import 'money_goal_screen.dart';

// ── expenses (đợt 2) · stage 3A: budgets / report / search entry points ──
/// Route name for a Sổ tiền sub-screen (screen_view label).
Route<void> _moneyRoute(Widget screen) => MaterialPageRoute<void>(
  settings: RouteSettings(
    name: switch (screen) {
      MoneyWalletsScreen() => 'MoneyWallets',
      MoneyCategoriesScreen() => 'MoneyCategories',
      MoneyBudgetsScreen() => 'MoneyBudgets',
      MoneyReportScreen() => 'MoneyReport',
      MoneySearchScreen() => 'MoneySearch',
      _ => 'MoneySub',
    },
  ),
  builder: (_) => screen,
);

void _openSub(BuildContext context, Widget screen) =>
    Navigator.of(context).push(_moneyRoute(screen));

/// Opens Sổ tiền ([book] null = the tab used last on this phone).
/// ── expenses (đợt 2) ── stage 3B: [focusWalletId] (a `money_goal*` push /
/// inbox tap) opens that fund on top; [from] feeds `money_screen_open`.
Future<void> openMoneyScreen(
  BuildContext context, {
  MoneyBookKind? book,
  String? focusWalletId,
  String from = 'home',
}) {
  AnalyticsService.instance.logMoneyScreenOpen(from);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'MoneyScreen'),
      builder: (_) =>
          MoneyScreen(initialBook: book, focusWalletId: focusWalletId),
    ),
  );
}

/// "Sổ tiền" overview (design §3.2 + §15): Của mình · Chung, the month card,
/// who-paid lanes (shared), Gần đây, Tiêu vào đâu (own), wallets, the
/// waiting-partner card (D5), and the pink add button.
///
/// Stage 3 adds search (⌕), budgets, report, settle-up; their entry points
/// stay hidden until then rather than opening a "coming soon" page.
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key, this.initialBook, this.focusWalletId});

  final MoneyBookKind? initialBook;

  // ── expenses (đợt 2) ── stage 3B
  /// Shared fund to open once the wallets are in (push / inbox tap).
  final String? focusWalletId;

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  static const String _prefsBox = 'app_settings';
  static const String _tabKey = 'money_last_tab';

  late MoneyBookKind _book = widget.initialBook ?? _lastTab();
  late String _month = MoneyMath.monthKey(DateTime.now());
  bool _fabShown = true;
  bool _sharedStarterAsked = false;
  MoneyWriteError? _shownError;
  // ── expenses (đợt 2) ── stage 3B
  late String? _focusWallet = widget.focusWalletId;

  /// A `money_goal*` tap: open that fund once the shared wallets are known
  /// (gone / not a fund / no shared book any more → just the overview).
  void _openFocusedFund(MoneyProvider money) {
    final id = _focusWallet;
    if (id == null) return;
    final s = money.shared;
    // Wallets not in yet → try again on the next build.
    if (s == null || (!s.walletsFromServer && s.wallets.isEmpty)) return;
    _focusWallet = null;
    final w = s.wallets.where((x) => x.id == id).firstOrNull;
    if (w == null || !w.isGoal) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        openMoneyGoal(context, book: MoneyBookKind.shared, walletId: id);
      }
    });
  }

  static MoneyBookKind _lastTab() {
    if (!Hive.isBoxOpen(_prefsBox)) return MoneyBookKind.shared;
    try {
      return Hive.box<String>(_prefsBox).get(_tabKey) == 'own'
          ? MoneyBookKind.own
          : MoneyBookKind.shared;
    } catch (_) {
      return MoneyBookKind.shared;
    }
  }

  void _setBook(MoneyBookKind b) {
    setState(() {
      _book = b;
      _month = MoneyMath.monthKey(DateTime.now());
    });
    if (!Hive.isBoxOpen(_prefsBox)) return;
    try {
      Hive.box<String>(_prefsBox).put(_tabKey, b.name);
    } catch (_) {}
  }

  void _shiftMonth(int delta, MoneyProvider money) {
    final next = MoneyMath.addMonths(_month, delta);
    if (next.compareTo(MoneyMath.monthKey(DateTime.now())) > 0) return;
    setState(() => _month = next);
    money.viewMonth(_book, next);
  }

  /// A refused queued write (rules: the partner edited first…) shows once.
  void _surfaceWriteError(MoneyProvider money) {
    final e = money.lastWriteError;
    if (e == null || identical(e, _shownError)) return;
    _shownError = e;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = context.l10n;
      money.acknowledgeWriteError();
      if (e.isPermissionDenied) {
        showMoneySnack(
          context,
          message: l10n.moneyConflictTitle(
            MoneyPeople.of(context, listen: false).partnerName,
          ),
          detail: l10n.moneyConflictBody,
        );
      } else {
        showMoneySnack(context, message: l10n.moneyWriteFailed);
      }
    });
  }

  /// First visit to the shared tab: the pair's "Ví chung" (D8).
  void _ensureSharedStarter(MoneyProvider money) {
    final s = money.shared;
    if (_sharedStarterAsked || s == null || !s.walletsFromServer) return;
    if (s.wallets.any(
      (w) => w.id == money.defaultWalletId(MoneyBookKind.shared),
    )) {
      return;
    }
    _sharedStarterAsked = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => money.ensureDefaultWallet(MoneyBookKind.shared),
    );
  }

  Future<void> _shareInvite(String code) async {
    if (code.isEmpty) return;
    final message = context.l10n.inviteShareMessage(code);
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? (box.localToGlobal(Offset.zero) & box.size)
        : null;
    AnalyticsService.instance.logInviteShared('share_sheet');
    try {
      context.read<ReminderProvider>().markInviteShared(code);
    } on ProviderNotFoundException {
      // tests
    }
    try {
      await SharePlus.instance.share(
        ShareParams(text: message, sharePositionOrigin: origin),
      );
    } catch (_) {}
  }

  void _openMenu() {
    final l10n = context.l10n;
    showMoneySheet<void>(
      context,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(IconsaxPlusLinear.wallet_2),
              title: Text(l10n.moneyWallets),
              minTileHeight: 52,
              onTap: () {
                Navigator.of(sheet).pop();
                _push(MoneyWalletsScreen(book: _book));
              },
            ),
            // D31: which money this book counts in.
            ListTile(
              leading: const Icon(IconsaxPlusLinear.dollar_circle),
              title: Text(l10n.moneyCurrencyTitle),
              trailing: Text(
                () {
                  final c = context.read<MoneyProvider>().currencyOf(_book);
                  return '${c.code} · ${c.symbol}';
                }(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              minTileHeight: 52,
              onTap: () {
                Navigator.of(sheet).pop();
                showMoneyCurrencySheet(context, book: _book);
              },
            ),
            ListTile(
              leading: const Icon(IconsaxPlusLinear.category_2),
              title: Text(l10n.moneyCategories),
              minTileHeight: 52,
              onTap: () {
                Navigator.of(sheet).pop();
                _push(MoneyCategoriesScreen(book: _book));
              },
            ),
            // ── expenses (đợt 2) · stage 3A ──
            ListTile(
              leading: const Icon(IconsaxPlusLinear.chart_2),
              title: Text(l10n.moneyBudgets),
              minTileHeight: 52,
              onTap: () {
                Navigator.of(sheet).pop();
                _push(MoneyBudgetsScreen(book: _book));
              },
            ),
            ListTile(
              leading: const Icon(IconsaxPlusLinear.chart_1),
              title: Text(l10n.moneyReport),
              minTileHeight: 52,
              onTap: () {
                Navigator.of(sheet).pop();
                _push(MoneyReportScreen(book: _book, month: _month));
              },
            ),
            // ── expenses (đợt 2) ── stage 3B: Nhắc tối (D18).
            ListTile(
              leading: const Icon(IconsaxPlusLinear.notification_bing),
              title: Text(l10n.moneyMenuReminder),
              minTileHeight: 52,
              onTap: () {
                Navigator.of(sheet).pop();
                showMoneySheet<void>(
                  context,
                  builder: (_) => const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: MoneyReminderTile(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // The pushed screen may have switched the book on show: take it back.
  void _push(Widget screen) =>
      Navigator.of(context).push(_moneyRoute(screen)).then((_) {
        if (mounted) setState(() {});
      });

  void _editTx(MoneyTx t) =>
      AddTransactionSheet.show(context, book: _book, editing: t);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final people = MoneyPeople.of(context);
    if (_book == MoneyBookKind.shared && !money.hasShared) {
      _book = MoneyBookKind.own;
    }
    money.activeBook = _book;
    _surfaceWriteError(money);
    _openFocusedFund(money);
    if (_book == MoneyBookKind.shared) _ensureSharedStarter(money);
    final firstRun = _book == MoneyBookKind.own && money.needsFirstRun;
    final state = money.book(_book);
    final fresh =
        !firstRun &&
        _book == MoneyBookKind.own &&
        state != null &&
        state.everLogged == false;
    final showFab = !firstRun && !fresh && state != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: showFab
          ? AnimatedSlide(
              duration: AppMotion.reduceMotion(context)
                  ? Duration.zero
                  : AppMotion.fast,
              curve: AppMotion.curve,
              offset: _fabShown ? Offset.zero : const Offset(0, 2),
              child: _Fab(
                onTap: () => AddTransactionSheet.show(context, book: _book),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SubScreenHeader(
                  badge: l10n.moneyBadge,
                  badgeIcon: IconsaxPlusLinear.wallet_2,
                  trailing: firstRun || state == null
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── expenses (đợt 2) · stage 3A ──
                            HeaderIconButton(
                              icon: IconsaxPlusLinear.search_normal_1,
                              semanticsLabel: l10n.moneySearchLabel,
                              onTap: () =>
                                  _push(MoneySearchScreen(book: _book)),
                            ),
                            HeaderIconButton(
                              icon: IconsaxPlusLinear.more,
                              semanticsLabel: l10n.moneyMoreLabel,
                              onTap: _openMenu,
                            ),
                          ],
                        ),
                ),
              ),
              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (n) {
                    final down = n.direction == ScrollDirection.reverse;
                    final up = n.direction == ScrollDirection.forward;
                    if (down && _fabShown) setState(() => _fabShown = false);
                    if (up && !_fabShown) setState(() => _fabShown = true);
                    return false;
                  },
                  child: MidnightBuilder(
                    builder: (context) => ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        112 + MediaQuery.of(context).padding.bottom,
                      ),
                      children: [
                        if (firstRun)
                          const MoneyFirstRun()
                        else if (state == null)
                          const _LoadingBlock()
                        else ...[
                          if (money.hasShared) ...[
                            SegmentedPill<MoneyBookKind>(
                              values: MoneyBookKind.values,
                              selected: _book,
                              labelOf: (b) => b == MoneyBookKind.own
                                  ? l10n.moneyTabMine
                                  : l10n.moneyTabShared,
                              onChanged: _setBook,
                            ),
                            const SizedBox(height: 12),
                          ],
                          ?_offlineNotice(context, money, state),
                          ..._body(context, money, state, people, fresh),
                        ],
                      ],
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

  Widget? _offlineNotice(
    BuildContext context,
    MoneyProvider money,
    MoneyBookState state,
  ) {
    final l10n = context.l10n;
    final pending = state.txs.where((t) => t.pending).length;
    final stale = state.isShared ? pending > 0 : state.netSumsStale;
    if (!stale || state.loadError != null) return null;
    final at = state.isShared ? state.lastSyncAt : state.netSumsAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(
                IconsaxPlusLinear.cloud_cross,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  at == null
                      ? l10n.moneyOfflineNoTime(pending)
                      : l10n.moneyOffline(moneyTime(context, at), pending),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    MoneyProvider money,
    MoneyBookState state,
    MoneyPeople people,
    bool fresh,
  ) {
    final shared = _book == MoneyBookKind.shared;
    final txs = money.txsForMonth(_book, _month);
    final rowCtx = MoneyRowContext.of(context, money, _book);
    const gap = SizedBox(height: 16);
    final showWaiting = !shared && people.waiting;
    if (fresh) {
      return [
        _MonthCard(
          book: _book,
          month: _month,
          txs: const <MoneyTx>[],
          fresh: true,
          onShift: (d) => _shiftMonth(d, money),
        ),
        gap,
        _FirstEntryCard(
          onPick: (cat) =>
              AddTransactionSheet.show(context, book: _book, categoryId: cat),
          onAdd: () => AddTransactionSheet.show(context, book: _book),
        ),
        gap,
        _WalletsCard(book: _book, onOpen: _push),
        if (showWaiting) ...[
          gap,
          _WaitingCard(onInvite: () => _shareInvite(people.inviteCode)),
        ],
      ];
    }
    return [
      _MonthCard(
        book: _book,
        month: _month,
        txs: txs,
        onShift: (d) => _shiftMonth(d, money),
      ),
      if (shared && txs != null) ...[gap, _LanesCard(txs: txs, month: _month)],
      gap,
      _RecentCard(
        book: _book,
        month: _month,
        txs: txs,
        ctx: rowCtx,
        onTapTx: _editTx,
      ),
      if (!shared &&
          txs != null &&
          txs.any((t) => t.type == MoneyTxType.expense)) ...[
        gap,
        _WhereCard(book: _book, month: _month, txs: txs),
      ],
      gap,
      _WalletsCard(book: _book, onOpen: _push),
      if (showWaiting) ...[
        gap,
        _WaitingCard(onInvite: () => _shareInvite(people.inviteCode)),
      ],
    ];
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.moneyAddTx,
      excludeSemantics: true,
      child: Material(
        color: AppColors.accentLove,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              IconsaxPlusLinear.add,
              size: 28,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton(width: 140, height: 16),
          SizedBox(height: 12),
          ShimmerSkeleton(width: 170, height: 30),
          SizedBox(height: 12),
          ShimmerSkeleton(height: 8, borderRadius: 999),
        ],
      ),
    );
  }
}

const TextStyle _labelStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

/// Month card (design §3.2 / §15 #4): spent (30) + left in budget (20),
/// plan bar with today's tick, one finding, and (own book) Thu | Thu trừ chi.
class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.book,
    required this.month,
    required this.txs,
    required this.onShift,
    this.fresh = false,
  });

  final MoneyBookKind book;
  final String month;

  /// null = this month is still loading.
  final List<MoneyTx>? txs;
  final ValueChanged<int> onShift;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final state = money.book(book)!;
    final now = DateTime.now();
    final current = month == MoneyMath.monthKey(now);
    final loading = txs == null || !state.txLoaded;
    final list = txs ?? const <MoneyTx>[];
    final totals = MoneyMath.monthTotals(list, month);
    final budget = money.budgetFor(book, '');
    final status = budget == null
        ? null
        : MoneyMath.budgetStatus(totals.expense, budget.amount);
    final daysTotal = MoneyMath.daysInMonth(month);
    final passed = current ? now.day : daysTotal;
    final shared = book == MoneyBookKind.shared;

    Widget figure(Widget child, double w, double h) =>
        loading ? ShimmerSkeleton(width: w, height: h) : child;

    String? finding;
    if (!loading && !fresh) {
      if (list.isEmpty) {
        finding = l10n.moneyEmptyMonth(moneyMonthShort(context, month));
      } else if (status != null && current) {
        finding = shared ? _sharedFinding(context, money, list, passed) : null;
        if (finding == null) {
          if (status.left < 0) {
            finding = l10n.moneyFindingOver(vnd(context, -status.left));
          } else {
            final daysLeft = (daysTotal - passed).clamp(1, daysTotal);
            final step = moneyCurrency(context).roundStep;
            final perDay = (status.left ~/ daysLeft) ~/ step * step;
            finding = l10n.moneyFindingPerDay(
              '$passed',
              '$daysTotal',
              '${status.percent}',
              vnd(context, perDay),
            );
          }
        }
      } else if (shared && current) {
        finding = _sharedFinding(context, money, list, passed);
      }
    }

    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l10n.moneyPrevMonth,
                      onPressed: () => onShift(-1),
                      icon: const Icon(
                        IconsaxPlusLinear.arrow_left_2,
                        size: 18,
                      ),
                      color: AppColors.textPrimary,
                      visualDensity: VisualDensity.compact,
                    ),
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(
                          moneyMonthLabel(context, month),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.moneyNextMonth,
                      onPressed: current ? null : () => onShift(1),
                      icon: const Icon(
                        IconsaxPlusLinear.arrow_right_3,
                        size: 18,
                      ),
                      color: AppColors.textPrimary,
                      disabledColor: AppColors.textTertiary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              // ── expenses (đợt 2) · stage 3A ──
              if (!fresh) ...[
                MoneyLink(
                  label: l10n.moneyReport,
                  onTap: () => _openSub(
                    context,
                    MoneyReportScreen(book: book, month: month),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shared
                          ? l10n.moneyMonthSpentShared
                          : l10n.moneyMonthSpentMine,
                      style: _labelStyle,
                    ),
                    const SizedBox(height: 2),
                    figure(
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MoneyAmountText(totals.expense, size: 30),
                      ),
                      170,
                      30,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status == null
                        ? l10n.moneyBudgetNone
                        : l10n.moneyBudgetLeftLabel,
                    style: _labelStyle,
                  ),
                  // ── expenses (đợt 2) · stage 3A: "Đặt ›" ──
                  if (status == null && !fresh)
                    MoneyLink(
                      label: l10n.moneyBudgetSetLink,
                      onTap: () => MoneyBudgetSheet.show(
                        context,
                        book: book,
                        categoryId: '',
                      ),
                    ),
                  if (status != null) ...[
                    const SizedBox(height: 2),
                    figure(MoneyAmountText(status.left, size: 20), 100, 20),
                  ],
                ],
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 12),
            if (loading)
              const ShimmerSkeleton(height: 8, borderRadius: 999)
            else
              MoneyPlanBar(
                spent: totals.expense,
                budget: status.budget,
                todayFrac: current && list.isNotEmpty
                    ? passed / daysTotal
                    : null,
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    l10n.moneyBudgetUsed('${status.percent}'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.moneyBudgetOfShort(vnd(context, status.budget)),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (state.loadError != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  IconsaxPlusLinear.warning_2,
                  size: 18,
                  color: AppColors.moneyNegative,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.lastSyncAt == null
                        ? l10n.moneyLoadErrorNoTime
                        : l10n.moneyLoadError(
                            moneyTime(context, state.lastSyncAt!),
                          ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: MoneyOutlineButton(
                label: l10n.moneyRetry,
                onPressed: () => money.retry(book),
              ),
            ),
          ] else if (loading) ...[
            const SizedBox(height: 12),
            const ShimmerSkeleton(width: 260, height: 14),
          ] else if (finding != null) ...[
            const SizedBox(height: 12),
            Text(
              finding,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (!shared && !fresh) ...[
            const SizedBox(height: 12),
            _SplitStrip(
              loading: loading,
              income: totals.income,
              left: totals.left,
            ),
          ],
        ],
      ),
    );
  }

  /// "Ăn uống chung đã dùng 97% ngân sách, còn 58.000 ₫ cho 11 ngày." — the
  /// group budget closest to its limit (≥ 80 %).
  String? _sharedFinding(
    BuildContext context,
    MoneyProvider money,
    List<MoneyTx> list,
    int passed,
  ) {
    final state = money.book(book)!;
    final idx = state.categories;
    MoneyBudget? best;
    MoneyBudgetStatus? bestStatus;
    for (final b in state.budgets) {
      if (b.isTotal) continue;
      final spent = MoneyMath.spentIn(
        list,
        month,
        categoryId: b.categoryId,
        groupOf: idx.groupOf,
      );
      final st = MoneyMath.budgetStatus(spent, b.amount);
      if (st.level < 80) continue;
      if (bestStatus == null || st.percent > bestStatus.percent) {
        best = b;
        bestStatus = st;
      }
    }
    if (best == null || bestStatus == null) return null;
    final daysLeft = (MoneyMath.daysInMonth(month) - passed).clamp(1, 31);
    return context.l10n.moneyFindingCategory(
      idx.of(best.categoryId).name,
      '${bestStatus.percent}',
      vnd(context, bestStatus.left < 0 ? 0 : bestStatus.left),
      '$daysLeft',
    );
  }
}

class _SplitStrip extends StatelessWidget {
  const _SplitStrip({
    required this.loading,
    required this.income,
    required this.left,
  });

  final bool loading;
  final int income;
  final int left;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget cell(String label, Widget value) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            loading ? const ShimmerSkeleton(width: 100, height: 16) : value,
          ],
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(
              l10n.moneyIncome,
              MoneyAmountText(
                income,
                size: 16,
                prefix: income > 0 ? '+' : '',
                color: income > 0
                    ? AppColors.moneyPositive
                    : AppColors.textPrimary,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.white,
            ),
            cell(l10n.moneyIncomeMinusSpent, MoneyAmountText(left, size: 16)),
          ],
        ),
      ),
    );
  }
}

/// "Ai trả tháng này" (design §1 signature): Thảo · Ví chung · Mình, one
/// 3-part bar, and who has covered more since the first shared entry.
class _LanesCard extends StatelessWidget {
  const _LanesCard({required this.txs, required this.month});

  final List<MoneyTx> txs;
  final String month;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final people = MoneyPeople.of(context);
    final uid = money.uid ?? '';
    final partner = money.partnerUid;
    final paid = MoneyMath.paidBy(txs, month);
    final a = paid[partner] ?? 0, b = paid[kMoneyPayerWallet] ?? 0;
    final c = paid[uid] ?? 0;
    final total = a + b + c;
    // All-time, from the server aggregate + this phone's writes (null =
    // not known yet → skeleton), never re-added from the 45-day window.
    final balance = money.coupleBalance();

    Widget lane(
      Widget avatar,
      String name,
      int amount,
      CrossAxisAlignment al,
    ) => Expanded(
      child: Column(
        crossAxisAlignment: al,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: MoneyAmountText(amount, size: 16),
          ),
        ],
      ),
    );

    final String balanceLabel;
    final String? balanceSub;
    if (balance == null) {
      balanceLabel = '';
      balanceSub = null;
    } else if (balance > 0) {
      balanceLabel = l10n.moneyBalanceMeAhead;
      balanceSub = l10n.moneyBalanceMeAheadSub(people.partnerName);
    } else if (balance < 0) {
      balanceLabel = l10n.moneyBalancePartnerAhead(people.partnerName);
      balanceSub = l10n.moneyBalancePartnerAheadSub(people.partnerName);
    } else {
      balanceLabel = l10n.moneyBalanceEven;
      balanceSub = null;
    }

    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyCardHeader(
            title: l10n.moneyWhoPaid,
            trailing: Text(
              l10n.moneyLaneTotal(vnd(context, total)),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              lane(
                MoneyAvatar(
                  letter: people.partnerName,
                  color: people.partnerColor,
                ),
                people.partnerName,
                a,
                CrossAxisAlignment.start,
              ),
              lane(
                const MoneyAvatar(letter: 'C'),
                l10n.moneyJointWallet,
                b,
                CrossAxisAlignment.center,
              ),
              lane(
                MoneyAvatar(letter: people.myName, color: people.meColor),
                l10n.moneyMe,
                c,
                CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: l10n.moneyLanesSemantics(
              people.partnerName,
              vndSpoken(context, a),
              vndSpoken(context, b),
              vndSpoken(context, c),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: total == 0
                    ? const ColoredBox(color: AppColors.surfaceLight)
                    : Row(
                        children: [
                          for (final (v, color) in [
                            (a, people.partnerColor),
                            (b, AppColors.textPrimary.withValues(alpha: 0.35)),
                            (c, people.meColor),
                          ])
                            if (v > 0)
                              Expanded(
                                flex: v,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  child: ColoredBox(color: color),
                                ),
                              ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (balance == null) ...[
            const ShimmerSkeleton(width: 150, height: 13),
            const SizedBox(height: 6),
            const ShimmerSkeleton(width: 120, height: 20),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balanceLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      MoneyAmountText(balance.abs(), size: 20),
                    ],
                  ),
                ),
                // ── expenses (đợt 2) ── stage 3B: hidden once even (§4).
                if (balance != 0) ...[
                  const SizedBox(width: 12),
                  MoneyOutlineButton(
                    label: l10n.moneySettle,
                    onPressed: () => SettleSheet.show(context),
                  ),
                ],
              ],
            ),
          if (balanceSub != null) ...[
            const SizedBox(height: 2),
            Text(
              balanceSub,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Gần đây": the latest 3 days (shared 4) of the month shown, by day.
class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.book,
    required this.month,
    required this.txs,
    required this.ctx,
    required this.onTapTx,
  });

  final MoneyBookKind book;
  final String month;
  final List<MoneyTx>? txs;
  final MoneyRowContext ctx;
  final ValueChanged<MoneyTx> onTapTx;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.read<MoneyProvider>();
    final list = txs;
    Widget body;
    if (list == null || !(money.book(book)?.txLoaded ?? false)) {
      body = const Column(
        children: [
          SizedBox(height: 12),
          ShimmerSkeleton(height: 44),
          SizedBox(height: 8),
          ShimmerSkeleton(height: 44),
          SizedBox(height: 8),
          ShimmerSkeleton(height: 44),
        ],
      );
    } else if (list.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l10n.moneyRecentEmpty(
            moneyMonthShort(context, month),
            moneyMonthShort(context, MoneyMath.addMonths(month, -1)),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    } else {
      body = MoneyDayGroups(
        txs: list,
        ctx: ctx,
        maxDays: book == MoneyBookKind.own ? 3 : 4,
        onTapTx: onTapTx,
        noteFor: book == MoneyBookKind.own
            ? (t) => _driftNote(context, money, t)
            : null,
      );
    }
    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyCardHeader(
            title: l10n.moneyRecent,
            // ── expenses (đợt 2) · stage 3A: "Tất cả ›" = search, 3 months ──
            trailing: list == null || list.isEmpty
                ? null
                : MoneyLink(
                    label: l10n.moneySeeAll,
                    onTap: () =>
                        _openSub(context, MoneySearchScreen(book: book)),
                  ),
          ),
          body,
        ],
      ),
    );
  }

  /// "Thảo đã đổi khoản chung thành 520.000 ₫ · Cập nhật" (D11).
  Widget? _driftNote(BuildContext context, MoneyProvider money, MoneyTx t) {
    final drift = money.linkedDrift(t);
    if (drift == null) return null;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(left: 40, bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.info_circle,
            size: 18,
            color: Color(0xFF8A4B00),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.moneyLinkedChanged(
                MoneyPeople.of(context).partnerName,
                vnd(context, drift),
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A4B00)),
            ),
          ),
          TextButton(
            onPressed: () => money.syncLinkedAmount(t, drift),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8A4B00),
              minimumSize: const Size(44, 44),
            ),
            child: Text(
              l10n.moneyLinkedUpdate,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Tiêu vào đâu" (own book): the 4 biggest groups of the month.
class _WhereCard extends StatelessWidget {
  const _WhereCard({
    required this.book,
    required this.month,
    required this.txs,
  });

  final MoneyBookKind book;
  final String month;
  final List<MoneyTx> txs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.read<MoneyProvider>();
    final idx = money.book(book)!.categories;
    final rows = MoneyMath.byCategory(
      txs,
      month,
      groupOf: idx.groupOf,
    ).take(4).toList();
    final max = rows.isEmpty ? 1 : rows.first.$2;
    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyCardHeader(
            title: l10n.moneyWhere,
            // ── expenses (đợt 2) · stage 3A ──
            trailing: MoneyLink(
              label: l10n.moneyBudgets,
              onTap: () => _openSub(context, MoneyBudgetsScreen(book: book)),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++)
            Builder(
              builder: (context) {
                final (id, amount) = rows[i];
                final c = idx.of(id);
                final budget = money.budgetFor(book, id);
                final st = budget == null
                    ? null
                    : MoneyMath.budgetStatus(amount, budget.amount);
                final barColor = st == null || st.level < 80
                    ? (i == 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.22))
                    : MoneyPlanBar.colorFor(st.level);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              c.emoji,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (st != null) ...[
                            const SizedBox(width: 8),
                            if (st.level >= 100)
                              MoneyPill(
                                label: l10n.moneyOverPercent(
                                  '${st.percent - 100}',
                                ),
                                negative: true,
                              )
                            else if (st.level >= 80)
                              MoneyPill(
                                label: '${st.percent}%',
                                negative: false,
                              )
                            else
                              Text(
                                l10n.moneyBudgetPercentShort('${st.percent}'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                          const Spacer(),
                          MoneyAmountText(amount),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: FractionallySizedBox(
                          widthFactor: (amount / max).clamp(0.02, 1.0),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Wallets (own: "Ví" + total money; shared: "Ví chung & quỹ").
class _WalletsCard extends StatelessWidget {
  const _WalletsCard({required this.book, required this.onOpen});

  final MoneyBookKind book;
  final ValueChanged<Widget> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final state = money.book(book)!;
    final balances = money.balances(book);
    final ready = money.balancesReady(book);
    final shared = book == MoneyBookKind.shared;
    final month = MoneyMath.monthKey(DateTime.now());
    final active = [
      for (final w in state.wallets)
        if (!w.archived) w,
    ];
    final plain = [
      for (final w in active)
        if (!w.isGoal) w,
    ];
    final goals = [
      for (final w in active)
        if (w.isGoal) w,
    ];
    void open(MoneyWallet w) => w.isGoal
        // ── expenses (đợt 2) ── stage 3B
        ? onOpen(MoneyGoalScreen(book: book, walletId: w.id))
        : onOpen(MoneyWalletScreen(book: book, walletId: w.id));

    String? sharedSub(MoneyWallet w) {
      final each = MoneyMath.contributionsBy(
        money.visibleTxs(book),
        walletId: w.id,
        month: month,
      );
      final mine = each[money.uid] ?? 0, theirs = each[money.partnerUid] ?? 0;
      if (mine > 0 && mine == theirs) {
        return l10n.moneyJointContribEach(vnd(context, mine));
      }
      return null;
    }

    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyCardHeader(
            title: shared ? l10n.moneyWalletsShared : l10n.moneyWallets,
            trailing: shared || !ready
                ? null
                : Text(
                    l10n.moneyTotalAssetsValue(
                      vnd(context, money.totalAssets(book)),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
          if (!state.walletsFromServer && active.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: ShimmerSkeleton(height: 44),
            ),
          for (final w in plain)
            ready
                ? MoneyWalletRow(
                    wallet: w,
                    balance: balances[w.id] ?? w.openingBalance,
                    sub: shared ? sharedSub(w) : null,
                    onTap: () => open(w),
                  )
                : _skeletonRow(w),
          for (final w in goals)
            ready
                ? moneyGoalRow(
                    context,
                    money,
                    w,
                    balances[w.id] ?? 0,
                    () => open(w),
                  )
                : _skeletonRow(w),
          Align(
            alignment: Alignment.centerLeft,
            child: shared
                // ── expenses (đợt 2) ── stage 3B (design: shared card link).
                ? MoneyLink(
                    label: l10n.moneyContribute,
                    onTap: () => pickFundToContribute(context),
                  )
                : MoneyLink(
                    label: l10n.moneyManageWallets,
                    onTap: () => onOpen(MoneyWalletsScreen(book: book)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonRow(MoneyWallet w) => SizedBox(
    height: 56,
    child: Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            w.emoji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            w.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const ShimmerSkeleton(width: 90, height: 16),
      ],
    ),
  );
}

/// D5: a couple still waiting sees what the shared book will add.
class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.moneyWaitingCard,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          MoneyLink(label: l10n.moneySendInvite, onTap: onInvite),
        ],
      ),
    );
  }
}

/// Newcomer state (`money-new.html`): 4 common categories, one primary
/// "Ghi khoản", no FAB (§15 #7).
class _FirstEntryCard extends StatelessWidget {
  const _FirstEntryCard({required this.onPick, required this.onAdd});

  final ValueChanged<String> onPick;
  final VoidCallback onAdd;

  static const List<String> _ids = <String>[
    'food_coffee',
    'food_out',
    'move_fuel',
    'food_market',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final idx = context.read<MoneyProvider>().own!.categories;
    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyCardHeader(title: l10n.moneyFirstEntryTitle),
          const SizedBox(height: 6),
          Text(
            l10n.moneyFirstEntryBody,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final id in _ids)
                MoneyChip(
                  emoji: idx.of(id).emoji,
                  label: idx.of(id).name,
                  onTap: () => onPick(id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          MoneyPrimaryButton(
            label: l10n.moneyAddTx,
            icon: IconsaxPlusLinear.add,
            onPressed: onAdd,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.moneyFirstEntryFoot,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
