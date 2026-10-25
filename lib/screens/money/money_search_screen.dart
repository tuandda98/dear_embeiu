import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_input.dart';
import '../../utils/money_views.dart';
import '../../widgets/money/add_transaction_sheet.dart';
import '../../widgets/money/money_ui.dart';
import '../../widgets/shimmer_skeleton.dart';

/// "Tìm khoản" (design §3.9): note / category without accents, the last 3
/// months by default (12 at most), filters by wallet, category group,
/// amount and (shared) who paid. Dates are bounded on the server, the rest
/// is filtered on the phone (dev.md deviation 2). Also the "Tất cả ›" list.
class MoneySearchScreen extends StatefulWidget {
  const MoneySearchScreen({super.key, this.book = MoneyBookKind.own});

  final MoneyBookKind book;

  @override
  State<MoneySearchScreen> createState() => _MoneySearchScreenState();
}

class _MoneySearchScreenState extends State<MoneySearchScreen> {
  late MoneyBookKind _book = widget.book;
  final TextEditingController _q = TextEditingController();
  Timer? _debounce;
  int _months = 3;
  Set<String>? _wallets;
  Set<String>? _cats;
  String? _payer;
  int? _min;
  int? _max;

  ({List<MoneyTx> rows, bool capped})? _result;
  bool _error = false;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  int get _filterCount =>
      (_wallets == null ? 0 : 1) +
      (_cats == null ? 0 : 1) +
      (_payer == null ? 0 : 1) +
      (_min == null && _max == null ? 0 : 1) +
      (_months == 3 ? 0 : 1);

  Future<void> _search() async {
    if (!mounted) return;
    final money = context.read<MoneyProvider>();
    final id = ++_run;
    setState(() => _error = false);
    final (from, to) = MoneyViews.searchRange(money.today, _months);
    try {
      final r = await money.search(
        _book,
        from: from,
        to: to,
        query: _q.text,
        walletIds: _wallets,
        categoryIds: _cats,
        payer: _payer,
        minAmount: _min,
        maxAmount: _max,
      );
      if (!mounted || id != _run) return;
      setState(() => _result = r);
      // Run 1 is the automatic one on open, not a search the user made.
      if (id > 1) AnalyticsService.instance.logMoneySearch(_filterCount);
    } catch (e) {
      debugPrint('money: search failed: $e');
      if (mounted && id == _run) setState(() => _error = true);
    }
  }

  void _typed(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  void _setBook(MoneyBookKind b) {
    setState(() {
      _book = b;
      _wallets = null;
      _cats = null;
      _payer = null;
      _result = null;
    });
    _search();
  }

  void _apply(VoidCallback change) {
    setState(change);
    _search();
  }

  // ── filter sheets ───────────────────────────────────────────────────────

  Future<void> _pickRange() async {
    final l10n = context.l10n;
    final n = await _chipSheet<int>(
      title: l10n.moneySearchPeriod,
      options: [
        for (final m in const [1, 3, 6, 12])
          (m, l10n.moneySearchRange('$m'), null),
      ],
      selected: {_months},
      multi: false,
    );
    if (n != null && n.isNotEmpty) _apply(() => _months = n.first);
  }

  Future<void> _pickWallets(MoneyBookState state) async {
    final picked = await _chipSheet<String>(
      title: context.l10n.moneyWallet,
      options: [for (final w in state.wallets) (w.id, w.name, w.emoji)],
      selected: _wallets ?? {},
      multi: true,
    );
    if (picked != null) {
      _apply(() => _wallets = picked.isEmpty ? null : picked);
    }
  }

  Future<void> _pickCats(MoneyBookState state) async {
    final idx = state.categories;
    final groups = [
      for (final kind in const [MoneyTxType.expense, MoneyTxType.income])
        for (final c in idx.pickable(kind))
          if (c.isGroup) c,
    ];
    final picked = await _chipSheet<String>(
      title: context.l10n.moneyCategory,
      options: [for (final c in groups) (c.id, c.name, c.emoji)],
      selected: _cats ?? {},
      multi: true,
    );
    if (picked != null) _apply(() => _cats = picked.isEmpty ? null : picked);
  }

  Future<void> _pickPerson(MoneyProvider money) async {
    final l10n = context.l10n;
    final people = MoneyPeople.of(context);
    final picked = await _chipSheet<String>(
      title: l10n.moneySearchPerson,
      options: [
        (money.partnerUid, people.partnerName, null),
        (kMoneyPayerWallet, l10n.moneyJointWallet, null),
        (money.uid ?? '', l10n.moneyMe, null),
      ],
      selected: {?_payer},
      multi: false,
      clearable: true,
    );
    if (picked != null) {
      _apply(() => _payer = picked.isEmpty ? null : picked.first);
    }
  }

  Future<void> _pickAmount() async {
    final r = await showMoneySheet<({int? min, int? max})>(
      context,
      builder: (_) => _AmountSheet(min: _min, max: _max),
    );
    if (r != null) {
      _apply(() {
        _min = r.min;
        _max = r.max;
      });
    }
  }

  /// A sheet of chips (UI UX Pro Max "Chip Collection Reflow": wrapped).
  /// Single choice closes on tap; multi choice has Áp dụng / Bỏ lọc.
  /// Returns null when dismissed, {} for "Bỏ lọc".
  Future<Set<T>?> _chipSheet<T>({
    required String title,
    required List<(T, String, String?)> options,
    required Set<T> selected,
    required bool multi,
    bool clearable = false,
  }) {
    final l10n = context.l10n;
    return showMoneySheet<Set<T>>(
      context,
      builder: (sheet) {
        final picked = {...selected};
        return StatefulBuilder(
          builder: (sheet, setSheet) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneySheetTitle(title: title),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (v, label, emoji) in options)
                      MoneyChip(
                        label: label,
                        emoji: emoji,
                        radio: !multi,
                        selected: picked.contains(v),
                        onTap: () {
                          if (!multi) {
                            Navigator.of(sheet).pop({v});
                            return;
                          }
                          setSheet(() {
                            if (!picked.remove(v)) picked.add(v);
                          });
                        },
                      ),
                  ],
                ),
                if (multi) ...[
                  const SizedBox(height: 16),
                  MoneyPrimaryButton(
                    label: l10n.moneySearchApply,
                    onPressed: () => Navigator.of(sheet).pop(picked),
                  ),
                ],
                if (multi || clearable) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(sheet).pop(<T>{}),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(
                      l10n.moneySearchClearFilter,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _pickedLabel(
    String base,
    Set<String>? ids,
    String Function(String) name,
  ) {
    if (ids == null) return base;
    if (ids.length == 1) return name(ids.first);
    return context.l10n.moneySearchPickedCount(base, '${ids.length}');
  }

  String _amountLabel() {
    final l10n = context.l10n;
    final lang = moneyLang(context);
    String s(int v) => formatVndShort(v, locale: lang);
    if (_min != null && _max != null) return '${s(_min!)} – ${s(_max!)}';
    if (_min != null) return l10n.moneySearchFromOnly(s(_min!));
    if (_max != null) return l10n.moneySearchToOnly(s(_max!));
    return l10n.moneySearchAmount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    if (_book == MoneyBookKind.shared && !money.hasShared) {
      _book = MoneyBookKind.own;
    }
    final state = money.book(_book);
    final shared = _book == MoneyBookKind.shared;
    final people = MoneyPeople.of(context);
    final result = _result;

    String personName(String id) => id == kMoneyPayerWallet
        ? l10n.moneyJointWallet
        : id == money.uid
        ? l10n.moneyMe
        : people.partnerName;

    final filters = state == null
        ? const <Widget>[]
        : <Widget>[
            MoneyChip(
              label: l10n.moneySearchRange('$_months'),
              icon: IconsaxPlusLinear.calendar_1,
              selected: true,
              onBlush: true,
              onTap: _pickRange,
            ),
            MoneyChip(
              label: _pickedLabel(
                l10n.moneyWallet,
                _wallets,
                (id) =>
                    state.wallets.where((w) => w.id == id).firstOrNull?.name ??
                    '',
              ),
              selected: _wallets != null,
              onBlush: true,
              onTap: () => _pickWallets(state),
            ),
            MoneyChip(
              label: _pickedLabel(
                l10n.moneyCategory,
                _cats,
                (id) => state.categories.of(id).name,
              ),
              selected: _cats != null,
              onBlush: true,
              onTap: () => _pickCats(state),
            ),
            MoneyChip(
              label: _amountLabel(),
              selected: _min != null || _max != null,
              onBlush: true,
              onTap: _pickAmount,
            ),
            if (shared)
              MoneyChip(
                label: _payer == null
                    ? l10n.moneySearchPerson
                    : personName(_payer!),
                selected: _payer != null,
                onBlush: true,
                onTap: () => _pickPerson(money),
              ),
          ];

    final rowCtx = MoneyRowContext.of(context, money, _book);
    final rows = result?.rows ?? const <MoneyTx>[];
    final query = _q.text.trim();

    return MoneyPage(
      badge: l10n.moneySearchBadge,
      icon: IconsaxPlusLinear.search_normal_1,
      book: _book,
      onBook: _setBook,
      slivers: [
        moneyBlock(
          TextField(
            controller: _q,
            onChanged: _typed,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              _debounce?.cancel();
              _search();
            },
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: l10n.moneySearchHint,
              filled: true,
              fillColor: AppColors.white,
              constraints: const BoxConstraints(minHeight: 52),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              prefixIcon: const Icon(
                IconsaxPlusLinear.search_normal_1,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _q.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.moneySearchClear,
                      onPressed: () {
                        _q.clear();
                        _typed('');
                      },
                      icon: const Icon(
                        IconsaxPlusLinear.close_circle,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 8),
          sliver: SliverToBoxAdapter(
            child: MoneyChipRow(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: filters,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            sliver: SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: _ResultHead(
                      result: result,
                      error: _error,
                      query: query,
                      months: _months,
                      onRetry: _search,
                      onWiden: _months >= 12
                          ? null
                          : () => _apply(() => _months = 12),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final t = rows[i];
                      return MoneyTxRow(
                        tx: t,
                        ctx: rowCtx,
                        highlight: query.isEmpty ? null : query,
                        subPrefix: moneyShortDate(context, t.date),
                        onTap: () async {
                          await AddTransactionSheet.show(
                            context,
                            book: _book,
                            editing: t,
                          );
                          _search();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultHead extends StatelessWidget {
  const _ResultHead({
    required this.result,
    required this.error,
    required this.query,
    required this.months,
    required this.onRetry,
    required this.onWiden,
  });

  final ({List<MoneyTx> rows, bool capped})? result;
  final bool error;
  final String query;
  final int months;
  final VoidCallback onRetry;
  final VoidCallback? onWiden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = result;
    const body = TextStyle(fontSize: 14, color: AppColors.textPrimary);
    const meta = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    if (error && r == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                IconsaxPlusLinear.warning_2,
                size: 18,
                color: AppColors.moneyNegative,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.moneySearchError, style: body)),
            ],
          ),
          const SizedBox(height: 8),
          MoneyOutlineButton(label: l10n.moneyRetry, onPressed: onRetry),
        ],
      );
    }
    if (r == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShimmerSkeleton(width: 120, height: 16),
          SizedBox(height: 12),
          ShimmerSkeleton(height: 44),
          SizedBox(height: 8),
          ShimmerSkeleton(height: 44),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: MoneyCardHeader(
            title: l10n.moneySearchCount('${r.rows.length}'),
            trailing: MoneyAmountText(MoneyViews.resultTotal(r.rows), size: 16),
          ),
        ),
        if (query.isNotEmpty && r.rows.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(l10n.moneySearchAccent, style: meta),
        ],
        if (r.capped) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              l10n.moneySearchCap,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A4B00)),
            ),
          ),
        ],
        if (r.rows.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              query.isNotEmpty
                  ? l10n.moneySearchEmpty(query, '$months')
                  : l10n.moneySearchEmptyAll('$months'),
              style: body,
            ),
          ),
          if (onWiden != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: MoneyOutlineButton(
                label: l10n.moneySearch12,
                onPressed: onWiden!,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Khoảng tiền: Từ … Đến … (system number pad + the shared parser).
class _AmountSheet extends StatefulWidget {
  const _AmountSheet({this.min, this.max});

  final int? min;
  final int? max;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final TextEditingController _from = TextEditingController(
    text: widget.min == null ? '' : '${widget.min}',
  );
  late final TextEditingController _to = TextEditingController(
    text: widget.max == null ? '' : '${widget.max}',
  );

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  /// null = empty, -1 = not a number.
  int? _value(TextEditingController c) {
    if (c.text.trim().isEmpty) return null;
    final r = parseVndInput(c.text, max: kMoneyTxMax);
    return r.ok ? r.value : -1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = _value(_from), b = _value(_to);
    final ok = a != -1 && b != -1 && (a == null || b == null || a <= b);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneySheetTitle(title: l10n.moneySearchAmount),
          const SizedBox(height: 8),
          MoneyNumberField(
            controller: _from,
            label: l10n.moneySearchFrom,
            max: kMoneyTxMax,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          MoneyNumberField(
            controller: _to,
            label: l10n.moneySearchTo,
            max: kMoneyTxMax,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          MoneyPrimaryButton(
            label: ok ? l10n.moneySearchApply : l10n.moneySaveFixAmount,
            onPressed: ok
                ? () => Navigator.of(context).pop((min: a, max: b))
                : null,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop((min: null, max: null)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(0, 44),
            ),
            child: Text(
              l10n.moneySearchClearFilter,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
