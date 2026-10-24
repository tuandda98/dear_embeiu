import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/money_challenges.dart';
import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_input.dart';
import '../../utils/money_math.dart';
import '../../utils/money_recap.dart';
import '../segmented_pill.dart';
import 'money_ui.dart';

/// Saving challenges + "Nhìn lại tháng" on the Sổ tiền overview (D34 §4–5).

// ── thử thách ─────────────────────────────────────────────────────────────

/// Running challenges with their progress, the ones that ended in the last
/// week (won or not), and "Thử thách mới".
class MoneyChallengesCard extends StatelessWidget {
  const MoneyChallengesCard({super.key, required this.book});

  final MoneyBookKind book;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final state = money.book(book);
    if (state == null) return const SizedBox.shrink();
    final today = money.today;
    final weekAgo = MoneyMath.dateKey(
      DateTime.now().subtract(const Duration(days: 7)),
    );
    final shown = [
      for (final c in state.challenges)
        if (!c.cancelled) (c: c, st: money.challengeStatus(book, c)),
    ].where((e) => !e.st.ended || e.st.lastDay.compareTo(weekAgo) >= 0);
    final canStart = money.canStartChallenge(book);
    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyCardHeader(title: l10n.moneyChallengesTitle),
          for (final e in shown)
            _ChallengeRow(
              book: book,
              challenge: e.c,
              status: e.st,
              today: today,
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: canStart
                ? MoneyLink(
                    label: l10n.moneyChallengeNew,
                    onTap: () => showMoneyChallengeNew(context, book: book),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.moneyChallengeMax,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({
    required this.book,
    required this.challenge,
    required this.status,
    required this.today,
  });

  final MoneyBookKind book;
  final MoneyChallenge challenge;
  final MoneyChallengeStatus status;
  final String today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = challenge, st = status;
    final cap = c.kind == MoneyChallengeKind.cap;
    final String line;
    final String? badge;
    if (st.won) {
      line = '';
      badge = '🎉 ${l10n.moneyChallengeWon}';
    } else if (st.failed || st.ended) {
      line = '';
      badge = l10n.moneyChallengeLost;
    } else {
      final left = c.days - st.daysPassed + 1;
      final progress = cap
          ? l10n.moneyChallengeSpentOf(
              vnd(context, st.spent, book: book),
              vnd(context, c.limit, book: book),
            )
          : l10n.moneyChallengeCleanDays('${st.cleanDays}', '${c.days}');
      line = '$progress · ${l10n.moneyChallengeDaysLeft('$left')}';
      badge = null;
    }
    final frac = cap
        ? (c.limit == 0 ? 0.0 : (st.spent / c.limit).clamp(0.0, 1.0))
        : (st.cleanDays / c.days).clamp(0.0, 1.0);
    final running = st.running;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: running ? () => _askStop(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    badge,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: st.won
                          ? AppColors.moneyPositive
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            if (running) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceLight,
                  color: cap && frac >= 0.8
                      ? AppColors.accentLavender
                      : AppColors.moneyPositive,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                line,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _askStop(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showMoneyConfirm(
      context,
      title: challenge.title,
      body: '',
      confirm: l10n.moneyChallengeStop,
      cancel: l10n.moneyCancel,
      destructive: true,
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<MoneyProvider>().cancelChallenge(book, challenge.id);
    } catch (e) {
      debugPrint('money: stop challenge failed: $e');
      if (context.mounted) {
        showMoneySnack(context, message: l10n.moneyWriteFailed);
      }
    }
  }
}

/// "Thử thách mới": the ready-made list (titles only) + "Tự tạo". A cap
/// template in a currency other than VND opens the form to type the limit.
Future<void> showMoneyChallengeNew(
  BuildContext context, {
  required MoneyBookKind book,
}) async {
  final l10n = context.l10n;
  final money = context.read<MoneyProvider>();
  final vndBook = money.currencyOf(book).isVnd;
  String title(MoneyChallengeTemplate t) => t.title(
    l10n,
    limitText: vndBook ? vndShort(context, t.vndLimit, book: book) : '…',
  );
  final picked = await showMoneySheet<Object>(
    context,
    name: 'MoneyChallengeNewSheet',
    builder: (sheet) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(sheet).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: MoneySheetTitle(title: l10n.moneyChallengeNew),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              children: [
                for (final t in kMoneyChallengeTemplates)
                  ListTile(
                    minTileHeight: 52,
                    title: Text(title(t)),
                    onTap: () => Navigator.of(sheet).pop(t),
                  ),
                ListTile(
                  minTileHeight: 52,
                  leading: const Icon(Icons.add_rounded),
                  title: Text(l10n.moneyChallengeCustom),
                  onTap: () => Navigator.of(sheet).pop(true),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || picked == null) return;
  if (picked is MoneyChallengeTemplate &&
      (picked.kind == MoneyChallengeKind.noSpend || vndBook)) {
    await _start(
      context,
      book,
      MoneyChallenge(
        id: '',
        title: title(picked),
        kind: picked.kind,
        categoryIds: picked.categoryIds,
        limit: picked.kind == MoneyChallengeKind.cap ? picked.vndLimit : 0,
        startDate: money.today,
        days: picked.days,
        templateId: picked.id,
      ),
    );
    return;
  }
  await showMoneySheet<void>(
    context,
    name: 'MoneyChallengeFormSheet',
    builder: (_) => _ChallengeForm(
      book: book,
      template: picked is MoneyChallengeTemplate ? picked : null,
    ),
  );
}

Future<bool> _start(
  BuildContext context,
  MoneyBookKind book,
  MoneyChallenge c,
) async {
  final l10n = context.l10n;
  try {
    await context.read<MoneyProvider>().startChallenge(book, c);
    if (context.mounted) {
      showMoneySnack(context, message: l10n.moneyChallengeStarted(c.title));
    }
    return true;
  } catch (e) {
    debugPrint('money: start challenge failed: $e');
    if (context.mounted) {
      showMoneySnack(context, message: l10n.moneyWriteFailed);
    }
    return false;
  }
}

/// "Tự tạo": name, no spending / spend under, categories (groups), limit,
/// 7 / 14 / 30 days. Starts today.
class _ChallengeForm extends StatefulWidget {
  const _ChallengeForm({required this.book, this.template});

  final MoneyBookKind book;
  final MoneyChallengeTemplate? template;

  @override
  State<_ChallengeForm> createState() => _ChallengeFormState();
}

class _ChallengeFormState extends State<_ChallengeForm> {
  late final TextEditingController _name = TextEditingController();
  final TextEditingController _limit = TextEditingController();
  late MoneyChallengeKind _kind =
      widget.template?.kind ?? MoneyChallengeKind.noSpend;
  late final Set<String> _cats = {...?widget.template?.categoryIds};
  late int _days = widget.template?.days ?? 7;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  int? get _limitValue {
    final r = moneyParse(context, _limit.text, book: widget.book);
    return r.ok ? r.value : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final idx = money.book(widget.book)?.categories;
    final groups = [
      for (final c in idx?.pickable(MoneyTxType.expense) ?? const [])
        if (c.isGroup) c,
    ];
    final cap = _kind == MoneyChallengeKind.cap;
    final name = _name.text.trim();
    final ok =
        name.isNotEmpty &&
        name.length <= MoneyChallenge.titleMax &&
        (cap ? _limitValue != null : _cats.isNotEmpty);
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        s,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneySheetTitle(title: l10n.moneyChallengeCustom),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            maxLength: MoneyChallenge.titleMax,
            onChanged: (_) => setState(() {}),
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
            decoration: InputDecoration(
              labelText: l10n.moneyName,
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedPill<MoneyChallengeKind>(
            height: 44,
            onSurface: true,
            values: MoneyChallengeKind.values,
            selected: _kind,
            labelOf: (k) => k == MoneyChallengeKind.cap
                ? l10n.moneyChallengeKindCap
                : l10n.moneyChallengeKindNoSpend,
            onChanged: (k) => setState(() => _kind = k),
          ),
          if (cap) ...[
            const SizedBox(height: 12),
            MoneyNumberField(
              controller: _limit,
              label: l10n.moneyChallengeLimit,
              max: kMoneyTxMax,
              onChanged: (_) => setState(() {}),
            ),
          ],
          label(l10n.moneyCategory),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (cap)
                MoneyChip(
                  label: l10n.moneyChallengeAll,
                  selected: _cats.isEmpty,
                  onTap: () => setState(_cats.clear),
                ),
              for (final g in groups)
                MoneyChip(
                  emoji: g.emoji,
                  label: g.name,
                  selected: _cats.contains(g.id),
                  onTap: () => setState(() {
                    if (!_cats.remove(g.id) &&
                        _cats.length < MoneyChallenge.categoriesMax) {
                      _cats.add(g.id);
                    }
                  }),
                ),
            ],
          ),
          label(l10n.moneyChallengeLength),
          Wrap(
            spacing: 8,
            children: [
              for (final d in MoneyChallenge.lengths)
                MoneyChip(
                  radio: true,
                  label: l10n.moneyChallengeDays('$d'),
                  selected: _days == d,
                  onTap: () => setState(() => _days = d),
                ),
            ],
          ),
          const SizedBox(height: 20),
          MoneyPrimaryButton(
            label: l10n.moneyChallengeStart,
            busy: _busy,
            onPressed: !ok
                ? null
                : () async {
                    setState(() => _busy = true);
                    final started = await _start(
                      context,
                      widget.book,
                      MoneyChallenge(
                        id: '',
                        title: name,
                        kind: _kind,
                        categoryIds: _cats.toList(),
                        limit: cap ? _limitValue! : 0,
                        startDate: money.today,
                        days: _days,
                        templateId: widget.template?.id ?? '',
                      ),
                    );
                    if (!context.mounted) return;
                    if (started) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _busy = false);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

// ── nhìn lại tháng ────────────────────────────────────────────────────────

/// Day 1–7 of a month: last month's good news (D34 §5). Closing it hides it
/// for that book and month on this phone.
class MoneyRecapCard extends StatefulWidget {
  const MoneyRecapCard({super.key, required this.book});

  final MoneyBookKind book;

  static const String _box = 'app_settings';

  static String _key(MoneyBookKind book, String month) =>
      'money_recap_${book.name}_$month';

  /// The first 7 days of a month and not closed yet.
  static bool shouldShow(MoneyBookKind book, DateTime now) {
    if (now.day > 7) return false;
    final month = MoneyMath.addMonths(MoneyMath.monthKey(now), -1);
    if (!Hive.isBoxOpen(_box)) return true;
    try {
      return Hive.box<String>(_box).get(_key(book, month)) == null;
    } catch (_) {
      return true;
    }
  }

  @override
  State<MoneyRecapCard> createState() => _MoneyRecapCardState();
}

class _MoneyRecapCardState extends State<MoneyRecapCard> {
  Future<List<MoneyRecapLine>>? _lines;
  bool _closed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lines ??= context.read<MoneyProvider>().recap(widget.book);
  }

  void _close(String month) {
    setState(() => _closed = true);
    if (!Hive.isBoxOpen(MoneyRecapCard._box)) return;
    try {
      Hive.box<String>(
        MoneyRecapCard._box,
      ).put(MoneyRecapCard._key(widget.book, month), '1');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_closed) return const SizedBox.shrink();
    final l10n = context.l10n;
    final month = MoneyMath.addMonths(MoneyMath.monthKey(DateTime.now()), -1);
    final before = MoneyMath.addMonths(month, -1);
    String text(MoneyRecapLine r) => switch (r.kind) {
      MoneyRecapKind.keptBudget => l10n.moneyRecapKeptBudget,
      MoneyRecapKind.spentLess => l10n.moneyRecapSpentLess(
        vnd(context, r.value, book: widget.book),
        moneyMonthShort(context, before),
      ),
      MoneyRecapKind.saved => l10n.moneyRecapSaved(
        vnd(context, r.value, book: widget.book),
      ),
      MoneyRecapKind.challenges => l10n.moneyRecapChallenges('${r.value}'),
      MoneyRecapKind.logged => l10n.moneyRecapLogged('${r.value}', '${r.of}'),
    };
    return FutureBuilder<List<MoneyRecapLine>>(
      future: _lines,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final lines = snap.data!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MoneyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyCardHeader(
                  title: l10n.moneyRecapTitle(moneyMonthLabel(context, month)),
                  trailing: IconButton(
                    tooltip: l10n.moneyClose,
                    onPressed: () => _close(month),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(height: 4),
                if (lines.isEmpty)
                  Text(
                    l10n.moneyRecapEmpty,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                for (final r in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.moneyPositive,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text(r),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
