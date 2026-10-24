import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../data/money_categories.dart';
import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/header_icon_button.dart';
import '../../widgets/money/money_ui.dart';
import '../../widgets/segmented_pill.dart';
import '../../widgets/sub_screen_header.dart';

/// "Danh mục" (design §3.6): each book has its own set. Rename / re-icon a
/// default (`overrides`), hide / show (`hiddenCategoryIds`), add groups and
/// subcategories (`customCategories`), delete an added one (old entries fall
/// back to "Khác"). Every change is one merge-write of `moneyMeta/main`.
class MoneyCategoriesScreen extends StatefulWidget {
  const MoneyCategoriesScreen({super.key, required this.book});

  final MoneyBookKind book;

  @override
  State<MoneyCategoriesScreen> createState() => _MoneyCategoriesScreenState();
}

class _MoneyCategoriesScreenState extends State<MoneyCategoriesScreen> {
  late MoneyBookKind _book = widget.book;
  // D34: spending categories only.
  static const MoneyTxType _kind = MoneyTxType.expense;
  final Set<String> _open = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    if (_book == MoneyBookKind.shared && !money.hasShared) {
      _book = MoneyBookKind.own;
    }
    money.activeBook = _book;
    final state = money.book(_book);
    final idx = state?.categories;
    final groups = <MoneyCategory>[];
    final kids = <String, List<MoneyCategory>>{};
    final hidden = <MoneyCategory>[];
    for (final c in idx?.all ?? const <MoneyCategory>[]) {
      if (c.kind != _kind) continue;
      if (c.isHidden) {
        hidden.add(c);
      } else if (c.isGroup) {
        groups.add(c);
      } else {
        (kids[c.parentId] ??= <MoneyCategory>[]).add(c);
      }
    }
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
                  badge: l10n.moneyCategoriesBadge,
                  badgeIcon: IconsaxPlusLinear.category_2,
                  trailing: HeaderIconButton(
                    icon: IconsaxPlusLinear.add,
                    semanticsLabel: l10n.moneyAddCategory,
                    onTap: () => _edit(null, parentId: ''),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    if (money.hasShared) ...[
                      SegmentedPill<MoneyBookKind>(
                        values: MoneyBookKind.values,
                        selected: _book,
                        labelOf: (b) => b == MoneyBookKind.own
                            ? l10n.moneyTabMine
                            : l10n.moneyTabShared,
                        onChanged: (b) => setState(() => _book = b),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      _book == MoneyBookKind.own
                          ? l10n.moneyCategoryScope
                          : l10n.moneyCategoryScopeShared,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary.withValues(alpha: 0.80),
                      ),
                    ),
                    const SizedBox(height: 12),
                    MoneyCard(
                      child: Column(
                        children: [
                          for (final g in groups)
                            ..._group(g, kids[g.id] ?? const []),
                        ],
                      ),
                    ),
                    if (hidden.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      MoneyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MoneyCardHeader(
                              title: l10n.moneyHidden,
                              trailing: Text(
                                l10n.moneyHiddenNote,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            for (final c in hidden) _hiddenRow(c),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _group(MoneyCategory g, List<MoneyCategory> children) {
    final l10n = context.l10n;
    final open = _open.contains(g.id);
    return [
      Semantics(
        button: true,
        expanded: open,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              setState(() => open ? _open.remove(g.id) : _open.add(g.id)),
          onLongPress: () => _edit(g),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _emoji(g.emoji),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _tagOf(g) ?? l10n.moneySubCount(children.length),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.moneyEditCategory,
                  onPressed: () => _edit(g),
                  icon: const Icon(
                    IconsaxPlusLinear.edit_2,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                AnimatedRotation(
                  turns: open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    IconsaxPlusLinear.arrow_right_3,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (open) ...[
        for (final c in children)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _edit(c),
            child: Padding(
              padding: const EdgeInsets.only(left: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    _emoji(c.emoji),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_tagOf(c) != null)
                            Text(
                              _tagOf(c)!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      IconsaxPlusLinear.edit_2,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _edit(null, parentId: g.id),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(
                    width: 28,
                    child: Icon(
                      IconsaxPlusLinear.add,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.moneyAddSub,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ];
  }

  String? _tagOf(MoneyCategory c) {
    final l10n = context.l10n;
    if (c.isCustom) return l10n.moneyCustom;
    if (c.originalName != null) return l10n.moneyRenamedFrom(c.originalName!);
    return null;
  }

  Widget _emoji(String e) => SizedBox(
    width: 28,
    child: ExcludeSemantics(
      child: Text(
        e,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20),
      ),
    ),
  );

  Widget _hiddenRow(MoneyCategory c) {
    final l10n = context.l10n;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          _emoji(c.emoji),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  l10n.moneyHiddenSub,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          MoneyOutlineButton(
            label: l10n.moneyShowAgain,
            icon: IconsaxPlusLinear.eye,
            onPressed: () => _setHidden(c, false),
          ),
        ],
      ),
    );
  }

  // ── writes ───────────────────────────────────────────────────────────

  MoneyMeta get _meta =>
      context.read<MoneyProvider>().book(_book)?.meta ?? MoneyMeta.empty;

  Future<void> _write(Map<String, dynamic> fields) async {
    try {
      await context.read<MoneyProvider>().setMeta(_book, fields);
    } catch (e) {
      debugPrint('money: meta write failed: $e');
      if (mounted) {
        showMoneySnack(context, message: context.l10n.moneyWriteFailed);
      }
    }
  }

  Future<void> _setHidden(MoneyCategory c, bool hide) {
    final ids = {..._meta.hiddenCategoryIds};
    hide ? ids.add(c.id) : ids.remove(c.id);
    return _write({'hiddenCategoryIds': ids.toList()});
  }

  Future<void> _edit(MoneyCategory? c, {String parentId = ''}) async {
    final meta = _meta;
    if (c == null &&
        meta.customCategories.length >= kMoneyCustomCategoriesMax) {
      showMoneySnack(context, message: context.l10n.moneyCategoryLimit);
      return;
    }
    final idx = context.read<MoneyProvider>().book(_book)?.categories;
    if (idx == null) return;
    final groups = [
      for (final g in idx.all)
        if (g.kind == _kind && g.isGroup && !g.isHidden && g.id != c?.id) g,
    ];
    final result = await showMoneySheet<_CategoryEdit>(
      context,
      builder: (_) => _CategoryEditSheet(
        category: c,
        parentId: c?.parentId ?? parentId,
        groups: groups,
      ),
    );
    if (result == null || !mounted) return;
    switch (result.action) {
      case _EditAction.hide:
        await _setHidden(c!, true);
      case _EditAction.delete:
        await _write({
          'customCategories': [
            for (final x in meta.customCategories)
              if (x.id != c!.id) x.toMap(),
          ],
          'hiddenCategoryIds': [
            for (final id in meta.hiddenCategoryIds)
              if (id != c!.id) id,
          ],
        });
      case _EditAction.save:
        if (c == null || c.isCustom) {
          final book = context.read<MoneyProvider>().book(_book)!;
          final updated = MoneyCustomCategory(
            id: c?.id ?? 'c_${book.service.newWalletId()}',
            kind: _kind,
            name: result.name,
            emoji: result.emoji,
            parentId: result.parentId,
          );
          await _write({
            'customCategories': [
              for (final x in meta.customCategories)
                if (x.id != updated.id) x.toMap(),
              updated.toMap(),
            ],
          });
        } else {
          final original = c.originalName ?? c.name;
          final def = kMoneyDefaultCategories
              .where((d) => d.id == c.id)
              .firstOrNull;
          await _write({
            'overrides': {
              c.id: {
                'name': result.name == original ? '' : result.name,
                'emoji': result.emoji == def?.emoji ? '' : result.emoji,
              },
            },
          });
        }
    }
  }
}

enum _EditAction { save, hide, delete }

class _CategoryEdit {
  const _CategoryEdit(
    this.action, {
    this.name = '',
    this.emoji = '',
    this.parentId = '',
  });

  final _EditAction action;
  final String name;
  final String emoji;
  final String parentId;
}

class _CategoryEditSheet extends StatefulWidget {
  const _CategoryEditSheet({
    required this.category,
    required this.parentId,
    required this.groups,
  });

  /// null = a new one.
  final MoneyCategory? category;
  final String parentId;
  final List<MoneyCategory> groups;

  @override
  State<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<_CategoryEditSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.category?.name ?? '',
  );
  late String _emoji = widget.category?.emoji ?? '⭐';
  late String _parentId = widget.parentId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.category;
    final isNew = c == null;
    final canMove = isNew ? _parentId.isNotEmpty : c.isCustom && !c.isGroup;
    final name = _name.text.trim();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneySheetTitle(
            title: isNew
                ? (_parentId.isEmpty ? l10n.moneyNewCategory : l10n.moneyNewSub)
                : l10n.moneyEditCategory,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Semantics(
                button: true,
                label: l10n.moneyPickEmoji,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final e = await pickMoneyEmoji(context, _emoji);
                    if (e != null) setState(() => _emoji = e);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: kMoneyCategoryNameMax,
                  onChanged: (_) => setState(() {}),
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
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
              ),
            ],
          ),
          if (c != null && !c.isCustom) ...[
            const SizedBox(height: 8),
            Text(
              l10n.moneyOriginalName(c.originalName ?? c.name),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (canMove && widget.groups.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.moneyInGroup,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final g in widget.groups)
                  MoneyChip(
                    radio: true,
                    emoji: g.emoji,
                    label: g.name,
                    selected: g.id == _parentId,
                    onTap: () => setState(() => _parentId = g.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          MoneyPrimaryButton(
            label: name.isEmpty ? l10n.moneyNameNeeded : l10n.moneySave,
            onPressed: name.isEmpty
                ? null
                : () => Navigator.of(context).pop(
                    _CategoryEdit(
                      _EditAction.save,
                      name: name,
                      emoji: _emoji,
                      parentId: _parentId,
                    ),
                  ),
          ),
          if (c != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pop(const _CategoryEdit(_EditAction.hide)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(IconsaxPlusLinear.eye_slash, size: 18),
              label: Text(l10n.moneyHideCategory),
            ),
          ],
          if (c != null && c.isCustom)
            TextButton.icon(
              onPressed: () async {
                final ok = await showMoneyConfirm(
                  context,
                  title: l10n.moneyDeleteCategoryAsk(c.name),
                  body: l10n.moneyDeleteCategoryBody,
                  confirm: l10n.moneyDelete,
                  destructive: true,
                );
                if (ok == true && context.mounted) {
                  Navigator.of(
                    context,
                  ).pop(const _CategoryEdit(_EditAction.delete));
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.moneyNegative,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(IconsaxPlusLinear.trash, size: 18),
              label: Text(l10n.moneyDeleteCategory),
            ),
        ],
      ),
    );
  }
}
