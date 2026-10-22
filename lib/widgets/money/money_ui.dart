import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/money_categories.dart';
import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../providers/money_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/person_palette.dart';
import '../../utils/money_input.dart';
import '../../utils/money_math.dart';
import '../../utils/money_views.dart';
import '../content_card.dart';
import '../segmented_pill.dart';
import '../sub_screen_header.dart';

/// Shared pieces of the Sổ tiền screens (feature expenses, design §3, §5):
/// formatting helpers, the person names/colours, the entry row, day groups,
/// the plan bar, chips and the bottom-sheet frame.

// ── formatting ────────────────────────────────────────────────────────────

String moneyLang(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// `1.250.000 ₫` / `₫1,250,000` in the app language.
String vnd(BuildContext context, int amount) =>
    formatVnd(amount, locale: moneyLang(context));

/// What a screen reader says for an amount ("120.000 đồng"), never "₫".
String vndSpoken(BuildContext context, int amount) {
  final vi = moneyLang(context) == 'vi';
  final digits = NumberFormat.decimalPattern(
    vi ? 'vi' : 'en',
  ).format(amount.abs());
  final sign = amount < 0 ? (vi ? 'âm ' : 'minus ') : '';
  return '$sign$digits ${vi ? 'đồng' : 'dong'}';
}

DateTime moneyParseDate(String key) => DateTime(
  int.parse(key.substring(0, 4)),
  int.parse(key.substring(5, 7)),
  int.parse(key.substring(8, 10)),
);

/// "Tháng 10, 2026" / "October 2026".
String moneyMonthLabel(BuildContext context, String month) {
  final lang = moneyLang(context);
  final d = moneyParseDate('$month-01');
  if (lang == 'vi') return 'Tháng ${d.month}, ${d.year}';
  return DateFormat('MMMM y', lang).format(d);
}

/// "10" (vi, after "tháng") / "October".
String moneyMonthShort(BuildContext context, String month) {
  final lang = moneyLang(context);
  final d = moneyParseDate('$month-01');
  return lang == 'vi' ? '${d.month}' : DateFormat('MMMM', lang).format(d);
}

/// "20/10" / "Oct 20".
String moneyShortDate(BuildContext context, String key) {
  final lang = moneyLang(context);
  final d = moneyParseDate(key);
  return lang == 'vi' ? '${d.day}/${d.month}' : DateFormat.MMMd(lang).format(d);
}

/// "Hôm nay, 20/10" · "Hôm qua, 19/10" · "Chủ nhật, 18/10".
String moneyDayLabel(BuildContext context, String key, {DateTime? now}) {
  final l10n = context.l10n;
  final today = MoneyMath.dateKey(now ?? DateTime.now());
  final yesterday = MoneyMath.dateKey(
    (now ?? DateTime.now()).subtract(const Duration(days: 1)),
  );
  final date = moneyShortDate(context, key);
  if (key == today) return l10n.moneyDayToday(date);
  if (key == yesterday) return l10n.moneyDayYesterday(date);
  final lang = moneyLang(context);
  final d = moneyParseDate(key);
  final weekday = lang == 'vi'
      ? _viWeekdays[d.weekday % 7]
      : DateFormat.EEEE(lang).format(d);
  return '$weekday, $date';
}

const List<String> _viWeekdays = <String>[
  'Chủ nhật',
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
];

String moneyTime(BuildContext context, DateTime t) =>
    DateFormat.Hm(moneyLang(context)).format(t);

String moneyWalletTypeLabel(AppLocalizations l10n, MoneyWalletType t) =>
    switch (t) {
      MoneyWalletType.cash => l10n.moneyWalletCash,
      MoneyWalletType.bank => l10n.moneyWalletBank,
      MoneyWalletType.ewallet => l10n.moneyWalletEwallet,
      MoneyWalletType.credit => l10n.moneyWalletCredit,
      MoneyWalletType.goal => l10n.moneyWalletGoal,
    };

String moneySplitLabel(AppLocalizations l10n, MoneySplitMode? m) => switch (m) {
  MoneySplitMode.equal => l10n.moneySplitEqual,
  MoneySplitMode.treat => l10n.moneySplitTreat,
  MoneySplitMode.forPartner => l10n.moneySplitForPartner,
  MoneySplitMode.custom => l10n.moneySplitCustom,
  _ => '',
};

// ── people ────────────────────────────────────────────────────────────────

/// The two names + colours a money screen shows. From the couple (names)
/// and the sleep profile colours (`PersonPalette`, the colour each person
/// picked); a [MoneyPeopleScope] above overrides it (tests).
class MoneyPeople {
  const MoneyPeople({
    required this.myName,
    required this.partnerName,
    this.meColor = const Color(0xFF1C7ED6),
    this.partnerColor = const Color(0xFF0E9384),
    this.waiting = false,
    this.inviteCode = '',
  });

  final String myName;
  final String partnerName;
  final Color meColor;
  final Color partnerColor;

  /// The couple still waits for the partner (D5).
  final bool waiting;
  final String inviteCode;

  /// [listen] false from callbacks (tap handlers, post-frame): subscribing
  /// outside build trips provider's assertion and the action never runs.
  static MoneyPeople of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<MoneyPeopleScope>()
        : context.getInheritedWidgetOfExactType<MoneyPeopleScope>();
    if (scope != null) return scope.people;
    final l10n = context.l10n;
    var myName = l10n.moneyMe, partnerName = l10n.reactionPartnerFallback;
    var waiting = false;
    var code = '';
    Color me = const Color(0xFF1C7ED6), partner = const Color(0xFF0E9384);
    try {
      final couple = Provider.of<CoupleProvider>(
        context,
        listen: listen,
      ).couple;
      final uid = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser?.id;
      if (couple != null) {
        final creator = uid != null && uid == couple.createdByUserId;
        final p = (creator ? couple.person2Name : couple.person1Name).trim();
        final m = (creator ? couple.person1Name : couple.person2Name).trim();
        if (p.isNotEmpty) partnerName = p;
        if (m.isNotEmpty) myName = m;
        waiting = couple.isWaitingForPartner;
        code = couple.inviteCode;
      }
    } on ProviderNotFoundException {
      // Not under the app's providers (a test): fallbacks above.
    }
    try {
      final sleep = Provider.of<SleepProvider>(context, listen: false);
      me = PersonPalette.colorOf(sleep.myColorId);
      partner = PersonPalette.colorOf(sleep.partnerColorId);
    } on ProviderNotFoundException {
      // keep the defaults
    }
    return MoneyPeople(
      myName: myName,
      partnerName: partnerName,
      meColor: me,
      partnerColor: partner,
      waiting: waiting,
      inviteCode: code,
    );
  }
}

class MoneyPeopleScope extends InheritedWidget {
  const MoneyPeopleScope({
    super.key,
    required this.people,
    required super.child,
  });

  final MoneyPeople people;

  @override
  bool updateShouldNotify(MoneyPeopleScope old) => old.people != people;
}

/// 18px letter avatar on a .14 tint with a 1.5 ring of the person's colour;
/// [color] null = the shared wallet ("C", grey).
class MoneyAvatar extends StatelessWidget {
  const MoneyAvatar({super.key, required this.letter, this.color});

  final String letter;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return ExcludeSemantics(
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withValues(alpha: 0.14),
          border: Border.all(color: c, width: 1.5),
        ),
        child: Text(
          letter.isEmpty ? '?' : letter.characters.first.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── amounts ───────────────────────────────────────────────────────────────

/// An amount with a smaller grey "₫" (design §3.2: the đồng sign is 16 next
/// to a 30 number). Right-aligned columns keep the units digit lined up
/// (Quicksand has no tabular figures, design §9).
class MoneyAmountText extends StatelessWidget {
  const MoneyAmountText(
    this.amount, {
    super.key,
    this.size = 15,
    this.color = AppColors.textPrimary,
    this.prefix = '',
    this.weight = FontWeight.w600,
    this.textAlign,
  });

  final int amount;
  final double size;
  final Color color;

  /// "+" for income ("−" comes from the amount's sign).
  final String prefix;
  final FontWeight weight;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final s = vnd(context, amount);
    final i = s.indexOf('₫');
    final unitSize = size >= 30 ? 16.0 : (size >= 20 ? 14.0 : size);
    final unit = TextSpan(
      text: '₫',
      style: TextStyle(
        fontSize: unitSize,
        color: size >= 20 ? AppColors.textSecondary : color,
        fontWeight: FontWeight.w600,
      ),
    );
    final before = s.substring(0, i), after = s.substring(i + 1);
    return Semantics(
      label: '$prefix${vndSpoken(context, amount)}',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            style: TextStyle(fontSize: size, fontWeight: weight, color: color),
            children: [
              TextSpan(text: prefix + before),
              unit,
              TextSpan(text: after),
            ],
          ),
          textAlign: textAlign,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}

// ── cards ─────────────────────────────────────────────────────────────────

/// Title 16 w700 + optional trailing (link / meta) on one row.
class MoneyCardHeader extends StatelessWidget {
  const MoneyCardHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Link 14 w700 navy + chevron 16, touch area 44.
class MoneyLink extends StatelessWidget {
  const MoneyLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoneyCard extends StatelessWidget {
  const MoneyCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ContentCard(child: child);
}

/// Plan bar (design §3.2): 8px track, spent part navy → warn ≥ 80 % → full
/// + negative ≥ 100 %; a "Hôm nay" tick at [todayFrac] (current month only).
class MoneyPlanBar extends StatelessWidget {
  const MoneyPlanBar({
    super.key,
    required this.spent,
    required this.budget,
    this.todayFrac,
    this.height = 8,
  });

  final int spent;
  final int budget;
  final double? todayFrac;
  final double height;

  static Color colorFor(int level) => level >= 100
      ? AppColors.moneyNegative
      : level >= 80
      ? AppColors.moneyWarn
      : AppColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    final status = MoneyMath.budgetStatus(spent, budget);
    final frac = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    return Semantics(
      label: context.l10n.moneyBudgetSemantics(
        '${status.percent}',
        vndSpoken(context, status.left < 0 ? 0 : status.left),
      ),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final tick = todayFrac;
            return SizedBox(
              height: tick == null ? height : height + 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (tick != null)
                    Positioned(
                      left: (w * tick - 30).clamp(0, w - 60),
                      width: 60,
                      top: 0,
                      child: Text(
                        context.l10n.moneyToday,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: tick == null ? 0 : 0,
                    height: height,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: frac,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorFor(status.level),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (tick != null)
                    Positioned(
                      left: (w * tick - 1).clamp(0, w - 2),
                      bottom: -4,
                      width: 2,
                      height: 16,
                      child: ColoredBox(
                        color: AppColors.textPrimary.withValues(alpha: 0.45),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Status pill (warn "97%", negative "Vượt 3%").
class MoneyPill extends StatelessWidget {
  const MoneyPill({super.key, required this.label, required this.negative});

  final String label;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: negative ? const Color(0xFFFFEDEA) : const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: negative ? const Color(0xFF831C1E) : const Color(0xFF8A4B00),
        ),
      ),
    );
  }
}

// ── chips ─────────────────────────────────────────────────────────────────

/// The one chip family of Sổ tiền (design §11): h40 r999, touch area 48,
/// `surfaceLight` (or white on blush), selected = navy + white text.
class MoneyChip extends StatelessWidget {
  const MoneyChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.emoji,
    this.icon,
    this.onBlush = false,
    this.radio = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? emoji;
  final IconData? icon;
  final bool onBlush;

  /// Part of a single-choice group (announced as selected / not).
  final bool radio;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.textPrimary;
    final bg = selected
        ? AppColors.textPrimary
        : onBlush
        ? AppColors.white.withValues(alpha: 0.86)
        : AppColors.surfaceLight;
    return Semantics(
      button: true,
      selected: radio ? selected : null,
      inMutuallyExclusiveGroup: radio ? true : null,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null && emoji!.isNotEmpty) ...[
                  ExcludeSemantics(
                    child: Text(emoji!, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 6),
                ],
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg,
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

/// A horizontally scrolling chip row (the last chip is cut on purpose so
/// the row reads as scrollable, design §15 trade-offs).
class MoneyChipRow extends StatelessWidget {
  const MoneyChipRow({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ── rows ──────────────────────────────────────────────────────────────────

/// Everything a list of entries needs to label itself, built once per
/// screen from the provider.
class MoneyRowContext {
  MoneyRowContext({
    required this.kind,
    required this.uid,
    required this.people,
    required this.categories,
    required this.wallets,
    this.hideWalletId,
  });

  factory MoneyRowContext.of(
    BuildContext context,
    MoneyProvider money,
    MoneyBookKind kind, {
    String? hideWalletId,
  }) {
    final book = money.book(kind);
    final other = money.book(
      kind == MoneyBookKind.own ? MoneyBookKind.shared : MoneyBookKind.own,
    );
    return MoneyRowContext(
      kind: kind,
      uid: money.uid ?? '',
      people: MoneyPeople.of(context),
      categories:
          book?.categories ??
          MoneyCategoryIndex(
            resolveMoneyCategories(MoneyMeta.empty, context.l10n),
          ),
      wallets: {
        for (final w in other?.wallets ?? const <MoneyWallet>[]) w.id: w,
        for (final w in book?.wallets ?? const <MoneyWallet>[]) w.id: w,
      },
      hideWalletId: hideWalletId,
    );
  }

  final MoneyBookKind kind;
  final String uid;
  final MoneyPeople people;
  final MoneyCategoryIndex categories;
  final Map<String, MoneyWallet> wallets;

  /// Wallet detail: the wallet's own name is left out of every sub line.
  final String? hideWalletId;

  bool get shared => kind == MoneyBookKind.shared;

  String walletName(String id) => wallets[id]?.name ?? '';

  String personName(BuildContext context, String? payer) {
    if (payer == kMoneyPayerWallet) return context.l10n.moneyJointWallet;
    if (payer == uid) return context.l10n.moneyMe;
    return people.partnerName;
  }

  Widget avatarFor(String? payer) {
    if (payer == kMoneyPayerWallet || payer == null) {
      return const MoneyAvatar(letter: 'C');
    }
    final me = payer == uid;
    return MoneyAvatar(
      letter: me ? people.myName : people.partnerName,
      color: me ? people.meColor : people.partnerColor,
    );
  }
}

/// One entry, 56 tall (design §3.2 "Gần đây"): emoji · note / category ·
/// sub line · amount (+ "chờ mạng" / "Thảo sửa 21:02" under it).
class MoneyTxRow extends StatelessWidget {
  const MoneyTxRow({
    super.key,
    required this.tx,
    required this.ctx,
    this.onTap,
    this.trailingNote,
    this.highlight,
    this.subPrefix,
  });

  final MoneyTx tx;
  final MoneyRowContext ctx;
  final VoidCallback? onTap;

  /// Extra line under the row (linked entry changed by the partner).
  final Widget? trailingNote;

  // ── expenses (đợt 2) · stage 3A: search results ──
  /// Search text: the matching part of the title is tinted rose .16.
  final String? highlight;

  /// Put before the sub line ("20/10" in search results).
  final String? subPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cat = ctx.categories.of(tx.categoryId, kind: tx.type);
    var glyph = cat.emoji;
    var plainGlyph = false;
    var title = tx.note.trim();
    Widget? avatar;
    String sub;
    final walletId = tx.outWalletId.isNotEmpty ? tx.outWalletId : tx.inWalletId;
    final walletName = walletId == ctx.hideWalletId
        ? ''
        : ctx.walletName(walletId);
    switch (tx.type) {
      case MoneyTxType.transfer:
        glyph = '↔';
        plainGlyph = true;
        sub = l10n.moneyTransferSub(
          ctx.walletName(tx.outWalletId),
          ctx.walletName(tx.inWalletId),
        );
        if (title.isEmpty) title = l10n.moneyTypeTransfer;
      case MoneyTxType.adjust:
        glyph = '±';
        plainGlyph = true;
        sub = walletName.isEmpty
            ? l10n.moneyNotSpending
            : l10n.moneyAdjustSub(walletName);
        if (title.isEmpty) title = l10n.moneyAdjustRow;
      case MoneyTxType.contribution:
        glyph = '→';
        plainGlyph = true;
        if (ctx.shared) {
          avatar = ctx.avatarFor(tx.payer);
          sub = l10n.moneyContribSub(ctx.personName(context, tx.payer));
          if (title.isEmpty) title = ctx.walletName(tx.inWalletId);
        } else {
          sub = l10n.moneyContribOwnSub(walletName);
          if (title.isEmpty) title = l10n.moneyWalletGoal;
        }
      case MoneyTxType.settle:
        glyph = '=';
        plainGlyph = true;
        sub = l10n.moneySettleSub(ctx.personName(context, tx.payer));
        if (title.isEmpty) title = l10n.moneySettle;
      case MoneyTxType.expense:
      case MoneyTxType.income:
        if (title.isEmpty) title = cat.name;
        if (ctx.shared && tx.payer != null) {
          avatar = ctx.avatarFor(tx.payer);
          if (tx.payer == kMoneyPayerWallet) {
            sub = l10n.moneyPaidFromJoint;
          } else {
            final split = tx.type == MoneyTxType.expense
                ? moneySplitLabel(l10n, tx.splitMode)
                : '';
            final who = ctx.personName(context, tx.payer);
            sub = split.isEmpty
                ? l10n.moneyPaidByNoSplit(who)
                : l10n.moneyPaidBy(who, split);
          }
        } else {
          sub = walletName.isEmpty ? cat.name : '${cat.name} · $walletName';
        }
    }

    final amountColor = switch (tx.type) {
      MoneyTxType.expense => AppColors.textPrimary,
      MoneyTxType.income => AppColors.moneyPositive,
      MoneyTxType.contribution when ctx.shared => AppColors.moneyPositive,
      _ => AppColors.textSecondary,
    };
    final prefix = switch (tx.type) {
      MoneyTxType.income => '+',
      MoneyTxType.contribution when ctx.shared => '+',
      _ => '',
    };
    final amount = tx.type == MoneyTxType.expense ? -tx.amount : tx.amount;
    String? underAmount;
    var pendingLine = false;
    if (tx.pending) {
      pendingLine = true;
      underAmount = l10n.moneyPending;
    } else if (ctx.shared &&
        tx.updatedBy != null &&
        tx.updatedBy != ctx.uid &&
        tx.updatedAt != null) {
      underAmount = l10n.moneyEditedBy(
        ctx.people.partnerName,
        moneyTime(context, tx.updatedAt!),
      );
    }
    if (subPrefix != null) sub = '$subPrefix · $sub';
    final semantics = [
      title,
      sub,
      if (tx.linkId != null && !ctx.shared) l10n.moneyLinkedBadge,
      '$prefix${vndSpoken(context, amount)}',
      ?underAmount,
    ].join(', ');
    final hit = highlight == null
        ? null
        : MoneyViews.matchRange(title, highlight!);

    final row = Semantics(
      button: onTap != null,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    glyph,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: plainGlyph ? 16 : 20,
                      color: plainGlyph ? AppColors.textSecondary : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        hit == null
                            ? TextSpan(text: title)
                            : TextSpan(
                                children: [
                                  TextSpan(text: title.substring(0, hit.$1)),
                                  TextSpan(
                                    text: title.substring(hit.$1, hit.$2),
                                    style: TextStyle(
                                      backgroundColor: AppColors.accentLove
                                          .withValues(alpha: 0.16),
                                    ),
                                  ),
                                  TextSpan(text: title.substring(hit.$2)),
                                ],
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (avatar != null) ...[
                            avatar,
                            const SizedBox(width: 6),
                          ],
                          if (tx.linkId != null && !ctx.shared) ...[
                            const Icon(
                              IconsaxPlusLinear.people,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              sub,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoneyAmountText(
                      amount,
                      size: 15,
                      color: amountColor,
                      prefix: prefix,
                    ),
                    if (underAmount != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pendingLine) ...[
                            const Icon(
                              IconsaxPlusLinear.cloud_cross,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            underAmount,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (trailingNote == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [row, trailingNote!],
    );
  }
}

/// Entries grouped by day, newest first, at most [maxDays] days; each day
/// header shows the day's spending (design §3.2).
class MoneyDayGroups extends StatelessWidget {
  const MoneyDayGroups({
    super.key,
    required this.txs,
    required this.ctx,
    required this.onTapTx,
    this.maxDays,
    this.now,
    this.noteFor,
  });

  final List<MoneyTx> txs;
  final MoneyRowContext ctx;
  final void Function(MoneyTx tx) onTapTx;
  final int? maxDays;
  final DateTime? now;

  /// Optional line under a row (linked drift banner).
  final Widget? Function(MoneyTx tx)? noteFor;

  @override
  Widget build(BuildContext context) {
    final byDay = <String, List<MoneyTx>>{};
    for (final t in txs) {
      (byDay[t.date] ??= <MoneyTx>[]).add(t);
    }
    var days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    if (maxDays != null && days.length > maxDays!) {
      days = days.sublist(0, maxDays);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final d in days) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    moneyDayLabel(context, d, now: now),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final spent = MoneyMath.spentIn(
                      byDay[d]!,
                      d.substring(0, 7),
                    );
                    if (spent == 0) return const SizedBox.shrink();
                    return Text(
                      context.l10n.moneyDaySpent(vnd(context, spent)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          for (final t in byDay[d]!)
            MoneyTxRow(
              tx: t,
              ctx: ctx,
              onTap: () => onTapTx(t),
              trailingNote: noteFor?.call(t),
            ),
        ],
      ],
    );
  }
}

/// Wallet row, 56 tall: emoji in a 28 box · name / type · balance.
class MoneyWalletRow extends StatelessWidget {
  const MoneyWalletRow({
    super.key,
    required this.wallet,
    required this.balance,
    this.sub,
    this.onTap,
    this.dim = false,
    this.below,
  });

  final MoneyWallet wallet;
  final int balance;
  final String? sub;
  final VoidCallback? onTap;
  final bool dim;

  /// Goal bar etc. under the name.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = sub ?? moneyWalletTypeLabel(l10n, wallet.type);
    return Opacity(
      opacity: dim ? 0.72 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: ExcludeSemantics(
                    child: Text(
                      wallet.emoji.isEmpty ? '👛' : wallet.emoji,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (below != null) ...[const SizedBox(height: 6), below!],
                      const SizedBox(height: 2),
                      Text(
                        line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MoneyAmountText(balance),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin goal bar (6px) under a goal wallet's name.
class MoneyGoalBar extends StatelessWidget {
  const MoneyGoalBar({super.key, required this.percent, this.height = 6});

  final int percent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: (percent / 100).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

// ── sheets & feedback ─────────────────────────────────────────────────────

/// White sheet, top radius 28, 40×4 handle (design §3.3).
Future<T?> showMoneySheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Flexible(child: builder(context)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Top row of a small sheet: close (44) · title 18 · optional trailing.
class MoneySheetTitle extends StatelessWidget {
  const MoneySheetTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.moneyClose,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              IconsaxPlusLinear.close_circle,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}

/// Primary navy pill h52; [enabled] false = `surfaceLight` + grey reason
/// (never a faded button, design §3.3).
class MoneyPrimaryButton extends StatelessWidget {
  const MoneyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled ? AppColors.textPrimary : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: busy ? null : onPressed,
          splashColor: AppColors.white.withValues(alpha: 0.12),
          child: SizedBox(
            height: 52,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: 20,
                            color: enabled
                                ? AppColors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: enabled
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outline pill h44 (Chuyển tiền / Sửa số dư).
class MoneyOutlineButton extends StatelessWidget {
  const MoneyOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.18),
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Snackbar with an optional second line + action (design §3.3, §4).
void showMoneySnack(
  BuildContext context, {
  required String message,
  String? detail,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        persist: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white.withValues(alpha: 0.86),
                  ),
                ),
              ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

/// Yes / no dialog r28; [destructive] paints the confirm red.
Future<bool?> showMoneyConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  String? cancel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      content: Text(body, style: const TextStyle(fontSize: 15)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancel ?? context.l10n.moneyCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive
                ? AppColors.moneyNegative
                : AppColors.textPrimary,
          ),
          child: Text(
            confirm,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Labelled number field (system number pad + the shared parser, design
/// §3.3 "Ô số dư ở các màn khác").
class MoneyNumberField extends StatelessWidget {
  const MoneyNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.max = kMoneyWalletMax,
    this.onChanged,
    this.autofocus = false,
    this.big = false,
  });

  final TextEditingController controller;
  final String label;
  final int max;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  /// 40 centred (adjust sheet) instead of a 44 row field.
  final bool big;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final raw = controller.text;
    final r = parseVndInput(raw, max: max);
    final error = raw.trim().isEmpty
        ? null
        : r.error == VndParseError.tooBig
        ? (max == kMoneyTxMax ? l10n.moneyAmountTooBig : l10n.moneyWalletTooBig)
        : r.error == VndParseError.invalid
        ? l10n.moneyAmountInvalid
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: big ? TextAlign.center : TextAlign.right,
          maxLength: 20,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          style: TextStyle(
            fontSize: big ? 40 : 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: big ? null : label,
            hintText: big ? label : null,
            suffixText: big ? null : '₫',
            filled: true,
            fillColor: AppColors.surfaceLight,
            isDense: !big,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: big ? 12 : 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.moneyNegative,
              ),
            ),
          ),
      ],
    );
  }
}

/// Small curated emoji grid (UI UX Pro Max "Chip Collection Reflow": wrap,
/// never one clipped row).
const List<String> kMoneyEmojiChoices = <String>[
  '💵',
  '🏦',
  '📱',
  '💙',
  '💳',
  '👛',
  '🐷',
  '🎯',
  '🏔️',
  '✈️',
  '🏠',
  '🚗',
  '🍜',
  '☕',
  '🛒',
  '🎁',
  '💊',
  '📚',
  '🎮',
  '👶',
  '🐶',
  '💍',
  '🌴',
  '⭐',
  '🧾',
  '💡',
  '🏋️',
  '🎬',
  '👗',
  '🍰',
  '⛽',
  '🧋',
];

Future<String?> pickMoneyEmoji(BuildContext context, String current) {
  return showMoneySheet<String>(
    context,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneySheetTitle(title: context.l10n.moneyPickEmoji),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final e in kMoneyEmojiChoices)
                Semantics(
                  button: true,
                  selected: e == current,
                  label: e,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).pop(e),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: e == current
                            ? AppColors.textPrimary.withValues(alpha: 0.10)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ── expenses (đợt 2) · stage 3A ──────────────────────────────────────────

/// Scaffold of the stage-3 money sub-screens: dawnBlush, the chip header
/// and, when the pair has a shared book, the Của mình · Chung switch.
/// [slivers] scroll under the pinned header.
class MoneyPage extends StatelessWidget {
  const MoneyPage({
    super.key,
    required this.badge,
    required this.icon,
    required this.book,
    required this.onBook,
    required this.slivers,
    this.trailing,
  });

  final String badge;
  final IconData icon;
  final MoneyBookKind book;
  final ValueChanged<MoneyBookKind> onBook;
  final List<Widget> slivers;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasShared = context.select<MoneyProvider, bool>((m) => m.hasShared);
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
                  badge: badge,
                  badgeIcon: icon,
                  trailing: trailing,
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (hasShared)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: SegmentedPill<MoneyBookKind>(
                            values: MoneyBookKind.values,
                            selected: book,
                            labelOf: (b) => b == MoneyBookKind.own
                                ? l10n.moneyTabMine
                                : l10n.moneyTabShared,
                            onChanged: onBook,
                          ),
                        ),
                      ),
                    ...slivers,
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 32 + MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item of a [MoneyPage] list: gutter 16, 16 above.
Widget moneyBlock(Widget child, {double top = 16}) => SliverPadding(
  padding: EdgeInsets.fromLTRB(16, top, 16, 0),
  sliver: SliverToBoxAdapter(child: child),
);

