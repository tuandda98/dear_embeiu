import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../screens/money/money_screen.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_math.dart';
import '../content_card.dart';
import '../icon_badge.dart';
import '../ink_tile.dart';
import '../shimmer_skeleton.dart';
import '../today_constellation.dart' show MidnightBuilder;
import 'add_transaction_sheet.dart';
import 'money_ui.dart';

/// What the Home row shows (design §3.1, `home-entry.html` 9 states).
enum MoneyHomeEntryKind {
  normal,
  noBudget,
  over,
  monthEmpty,
  loading,
  stale,
  error,
  waiting,
  neverLogged,
}

/// The Home row for Sổ tiền (feature expenses, Home C §14–15): only the
/// SHARED book's month spending — never a balance, never the own book. A
/// couple still waiting gets their own book with only today's entry count.
class MoneyHomeEntry extends StatelessWidget {
  const MoneyHomeEntry({super.key, required this.waiting, this.onRetry});

  /// The couple still waits for the partner.
  final bool waiting;

  /// "Thử lại" when the shared book failed to load and nothing is cached.
  final VoidCallback? onRetry;

  /// Pure state pick, kept here so a test can walk every state.
  static MoneyHomeEntryKind kindOf(
    MoneyProvider money, {
    required bool waiting,
  }) {
    final own = money.own;
    final shared = money.shared;
    // Never had an entry, any date (one limit(1) read per session).
    bool never(MoneyBookState? b) => b != null && b.everLogged == false;
    if (waiting) {
      return never(own)
          ? MoneyHomeEntryKind.neverLogged
          : MoneyHomeEntryKind.waiting;
    }
    if (shared == null) return MoneyHomeEntryKind.loading;
    if (!shared.txLoaded) {
      return shared.loadError != null
          ? MoneyHomeEntryKind.error
          : MoneyHomeEntryKind.loading;
    }
    if (never(shared) && never(own)) return MoneyHomeEntryKind.neverLogged;
    if (shared.loadError != null || shared.txs.any((t) => t.pending)) {
      return MoneyHomeEntryKind.stale;
    }
    final month = MoneyMath.monthKey(DateTime.now());
    final totals = MoneyMath.monthTotals(
      money.visibleTxs(MoneyBookKind.shared),
      month,
    );
    final status = money.budgetStatus(MoneyBookKind.shared, '', month: month);
    if (status != null && status.spent > status.budget) {
      return MoneyHomeEntryKind.over;
    }
    if (totals.expense == 0) return MoneyHomeEntryKind.monthEmpty;
    if (status == null) return MoneyHomeEntryKind.noBudget;
    return MoneyHomeEntryKind.normal;
  }

  @override
  Widget build(BuildContext context) =>
      // Rebuilt at 0:00 (and on resume): the month / "today" roll over and
      // the own book's live window moves (refreshDay no-ops otherwise).
      MidnightBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    // No Firebase (local-only mode): Sổ tiền lives in Firestore, no row.
    if (money.own == null) return const SizedBox.shrink();
    WidgetsBinding.instance.addPostFrameCallback((_) => money.refreshDay());
    final kind = kindOf(money, waiting: waiting);
    final now = DateTime.now();
    final month = MoneyMath.monthKey(now);
    final sharedTotals = MoneyMath.monthTotals(
      money.visibleTxs(MoneyBookKind.shared),
      month,
    );
    final spent = vnd(
      context,
      sharedTotals.expense,
      book: MoneyBookKind.shared,
    );
    final status = money.budgetStatus(MoneyBookKind.shared, '', month: month);
    final book = waiting ? MoneyBookKind.own : MoneyBookKind.shared;

    final title = switch (kind) {
      MoneyHomeEntryKind.neverLogged => l10n.moneyTitle,
      MoneyHomeEntryKind.waiting => l10n.moneyHomeMine,
      _ => l10n.moneyHomeShared(moneyMonthShort(context, month)),
    };
    const subStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
    const figStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    String plainSub = '';
    Widget sub;
    switch (kind) {
      case MoneyHomeEntryKind.loading:
        sub = const ShimmerSkeleton(width: 170, height: 14, borderRadius: 999);
        plainSub = l10n.moneyHomeLoading;
      case MoneyHomeEntryKind.error:
        plainSub = l10n.moneyHomeError;
        sub = Text(
          plainSub,
          style: subStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case MoneyHomeEntryKind.waiting:
        final today = MoneyMath.dateKey(now);
        final n = money
            .visibleTxs(MoneyBookKind.own)
            .where((t) => t.date == today)
            .length;
        plainSub = l10n.moneyHomeTodayCount(n);
        sub = Text(
          plainSub,
          style: subStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case MoneyHomeEntryKind.neverLogged:
        plainSub = l10n.moneyHomeFirst;
        sub = Text(
          plainSub,
          style: subStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case MoneyHomeEntryKind.monthEmpty:
        plainSub = l10n.moneyHomeZero(vnd(context, 0, book: book));
        sub = Text(
          plainSub,
          style: subStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case MoneyHomeEntryKind.stale:
        final at = money.shared?.lastSyncAt;
        plainSub = at == null
            ? l10n.moneyHomeSpentNoBudget(spent)
            : l10n.moneyHomeStale(spent, moneyTime(context, at));
        sub = Row(
          children: [
            const Icon(
              IconsaxPlusLinear.cloud_cross,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                plainSub,
                style: subStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MoneyHomeEntryKind.over:
        final over = vnd(
          context,
          status!.spent - status.budget,
          book: MoneyBookKind.shared,
        );
        final head = l10n.moneyHomeSpentOnly(spent);
        final tail = l10n.moneyHomeOverPart(over);
        plainSub = '$head · $tail';
        sub = Text.rich(
          TextSpan(
            style: subStyle,
            children: [
              TextSpan(text: head),
              const TextSpan(text: ' · '),
              TextSpan(
                text: tail,
                style: const TextStyle(
                  color: AppColors.moneyNegative,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case MoneyHomeEntryKind.noBudget:
        plainSub = l10n.moneyHomeSpentNoBudget(spent);
        sub = _withFigure(plainSub, spent, subStyle, figStyle);
      case MoneyHomeEntryKind.normal:
        plainSub = l10n.moneyHomeSpent(spent, '${status!.percent}');
        sub = _withFigure(plainSub, spent, subStyle, figStyle);
    }

    void openScreen() => openMoneyScreen(context, book: book);
    final trailing = kind == MoneyHomeEntryKind.error
        ? TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(
              l10n.moneyRetry,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          )
        : Semantics(
            button: true,
            label: l10n.moneyAddTx,
            excludeSemantics: true,
            child: Material(
              color: AppColors.textPrimary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => AddTransactionSheet.show(context, book: book),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    IconsaxPlusLinear.add,
                    size: 22,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          );

    // The round "+" sits over the card's right edge with its own 44 target,
    // ≥ 8 from the row's text (design §3.1: two touch areas).
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Semantics(
            button: true,
            label: '$title, $plainSub',
            onTap: openScreen,
            excludeSemantics: true,
            child: InkTile(
              borderRadius: 24,
              onTap: openScreen,
              child: ContentCard(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  kind == MoneyHomeEntryKind.error ? 112 : 68,
                  16,
                ),
                child: Row(
                  children: [
                    const IconBadge(IconsaxPlusLinear.wallet_2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          sub,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(right: 16), child: trailing),
        ],
      ),
    );
  }

  /// "Đã chi **3.574.000 ₫** · 71% ngân sách" — the figure in navy w600.
  static Widget _withFigure(
    String text,
    String figure,
    TextStyle base,
    TextStyle fig,
  ) {
    final i = text.indexOf(figure);
    if (i < 0) {
      return Text(
        text,
        style: base,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(text: figure, style: fig),
          TextSpan(text: text.substring(i + figure.length)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
