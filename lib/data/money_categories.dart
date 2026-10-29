import '../l10n/app_localizations.dart';
import '../models/money.dart';

/// Default categories, shared by both books (feature expenses, D9). Ids are
/// fixed forever (stored on every entry); names come from the ARB
/// (`moneyCat…`); emoji is data the Designer picked (design §3.6).
/// Two levels: a group (`parentId == ''`) and its children.
class MoneyCategoryDef {
  const MoneyCategoryDef(this.id, this.parentId, this.kind, this.emoji);

  final String id;
  final String parentId;
  final MoneyTxType kind;
  final String emoji;
}

/// Where an unknown / deleted category lands ("Khác").
const String kMoneyCategoryOther = 'other';

const List<MoneyCategoryDef> kMoneyDefaultCategories = <MoneyCategoryDef>[
  MoneyCategoryDef('food', '', MoneyTxType.expense, '🍜'),
  MoneyCategoryDef('food_out', 'food', MoneyTxType.expense, '🍜'),
  MoneyCategoryDef('food_market', 'food', MoneyTxType.expense, '🛒'),
  MoneyCategoryDef('food_coffee', 'food', MoneyTxType.expense, '☕'),
  MoneyCategoryDef('food_snack', 'food', MoneyTxType.expense, '🥖'),
  MoneyCategoryDef('date', '', MoneyTxType.expense, '💕'),
  MoneyCategoryDef('date_movie', 'date', MoneyTxType.expense, '🎬'),
  MoneyCategoryDef('date_out', 'date', MoneyTxType.expense, '🎡'),
  MoneyCategoryDef('date_gift', 'date', MoneyTxType.expense, '🎁'),
  MoneyCategoryDef('move', '', MoneyTxType.expense, '🛵'),
  MoneyCategoryDef('move_fuel', 'move', MoneyTxType.expense, '⛽'),
  MoneyCategoryDef('move_parking', 'move', MoneyTxType.expense, '🅿️'),
  MoneyCategoryDef('move_grab', 'move', MoneyTxType.expense, '🚕'),
  MoneyCategoryDef('move_repair', 'move', MoneyTxType.expense, '🔧'),
  MoneyCategoryDef('home', '', MoneyTxType.expense, '🏠'),
  MoneyCategoryDef('home_rent', 'home', MoneyTxType.expense, '🔑'),
  MoneyCategoryDef('home_power', 'home', MoneyTxType.expense, '💡'),
  MoneyCategoryDef('home_water', 'home', MoneyTxType.expense, '🚿'),
  MoneyCategoryDef('home_net', 'home', MoneyTxType.expense, '📶'),
  MoneyCategoryDef('home_goods', 'home', MoneyTxType.expense, '🧺'),
  MoneyCategoryDef('bill', '', MoneyTxType.expense, '📱'),
  MoneyCategoryDef('bill_phone', 'bill', MoneyTxType.expense, '📞'),
  MoneyCategoryDef('bill_stream', 'bill', MoneyTxType.expense, '🎧'),
  MoneyCategoryDef('bill_soft', 'bill', MoneyTxType.expense, '💾'),
  MoneyCategoryDef('shop', '', MoneyTxType.expense, '🛍️'),
  MoneyCategoryDef('shop_clothes', 'shop', MoneyTxType.expense, '👕'),
  MoneyCategoryDef('shop_beauty', 'shop', MoneyTxType.expense, '💄'),
  MoneyCategoryDef('shop_tech', 'shop', MoneyTxType.expense, '🎮'),
  MoneyCategoryDef('health', '', MoneyTxType.expense, '💊'),
  MoneyCategoryDef('health_med', 'health', MoneyTxType.expense, '💊'),
  MoneyCategoryDef('health_doctor', 'health', MoneyTxType.expense, '🩺'),
  MoneyCategoryDef('health_sport', 'health', MoneyTxType.expense, '🏸'),
  MoneyCategoryDef('edu', '', MoneyTxType.expense, '📚'),
  MoneyCategoryDef('edu_fee', 'edu', MoneyTxType.expense, '🎓'),
  MoneyCategoryDef('edu_books', 'edu', MoneyTxType.expense, '📖'),
  MoneyCategoryDef('gift', '', MoneyTxType.expense, '🎁'),
  MoneyCategoryDef('gift_present', 'gift', MoneyTxType.expense, '🎀'),
  MoneyCategoryDef('gift_wedding', 'gift', MoneyTxType.expense, '💌'),
  MoneyCategoryDef('gift_lixi', 'gift', MoneyTxType.expense, '🧧'),
  MoneyCategoryDef('family', '', MoneyTxType.expense, '👪'),
  MoneyCategoryDef('family_parents', 'family', MoneyTxType.expense, '🤲'),
  MoneyCategoryDef('family_pet', 'family', MoneyTxType.expense, '🐶'),
  MoneyCategoryDef('travel', '', MoneyTxType.expense, '✈️'),
  MoneyCategoryDef('travel_ticket', 'travel', MoneyTxType.expense, '🎫'),
  MoneyCategoryDef('travel_stay', 'travel', MoneyTxType.expense, '🏨'),
  MoneyCategoryDef('travel_fun', 'travel', MoneyTxType.expense, '🎢'),
  MoneyCategoryDef('other', '', MoneyTxType.expense, '📦'),
];

final Map<String, MoneyCategoryDef> _defaultById = {
  for (final c in kMoneyDefaultCategories) c.id: c,
};

String moneyDefaultCategoryName(AppLocalizations l, String id) => switch (id) {
  'food' => l.moneyCatFood,
  'food_out' => l.moneyCatFoodOut,
  'food_market' => l.moneyCatFoodMarket,
  'food_coffee' => l.moneyCatFoodCoffee,
  'food_snack' => l.moneyCatFoodSnack,
  'date' => l.moneyCatDate,
  'date_movie' => l.moneyCatDateMovie,
  'date_out' => l.moneyCatDateOut,
  'date_gift' => l.moneyCatDateGift,
  'move' => l.moneyCatMove,
  'move_fuel' => l.moneyCatMoveFuel,
  'move_parking' => l.moneyCatMoveParking,
  'move_grab' => l.moneyCatMoveGrab,
  'move_repair' => l.moneyCatMoveRepair,
  'home' => l.moneyCatHome,
  'home_rent' => l.moneyCatHomeRent,
  'home_power' => l.moneyCatHomePower,
  'home_water' => l.moneyCatHomeWater,
  'home_net' => l.moneyCatHomeNet,
  'home_goods' => l.moneyCatHomeGoods,
  'bill' => l.moneyCatBill,
  'bill_phone' => l.moneyCatBillPhone,
  'bill_stream' => l.moneyCatBillStream,
  'bill_soft' => l.moneyCatBillSoft,
  'shop' => l.moneyCatShop,
  'shop_clothes' => l.moneyCatShopClothes,
  'shop_beauty' => l.moneyCatShopBeauty,
  'shop_tech' => l.moneyCatShopTech,
  'health' => l.moneyCatHealth,
  'health_med' => l.moneyCatHealthMed,
  'health_doctor' => l.moneyCatHealthDoctor,
  'health_sport' => l.moneyCatHealthSport,
  'edu' => l.moneyCatEdu,
  'edu_fee' => l.moneyCatEduFee,
  'edu_books' => l.moneyCatEduBooks,
  'gift' => l.moneyCatGift,
  'gift_present' => l.moneyCatGiftPresent,
  'gift_wedding' => l.moneyCatGiftWedding,
  'gift_lixi' => l.moneyCatGiftLixi,
  'family' => l.moneyCatFamily,
  'family_parents' => l.moneyCatFamilyParents,
  'family_pet' => l.moneyCatFamilyPet,
  'travel' => l.moneyCatTravel,
  'travel_ticket' => l.moneyCatTravelTicket,
  'travel_stay' => l.moneyCatTravelStay,
  'travel_fun' => l.moneyCatTravelFun,
  'other' => l.moneyCatOther,
  _ => l.moneyCatOther,
};

/// A category as the book shows it: default or custom, with the book's
/// rename / icon / hidden tweaks applied.
class MoneyCategory {
  const MoneyCategory({
    required this.id,
    required this.parentId,
    required this.kind,
    required this.name,
    required this.emoji,
    this.isCustom = false,
    this.isHidden = false,
    this.originalName,
  });

  final String id;
  final String parentId;
  final MoneyTxType kind;
  final String name;
  final String emoji;
  final bool isCustom;
  final bool isHidden;

  /// Set when a default category was renamed ("gốc là “Cà phê, trà sữa”").
  final String? originalName;

  bool get isGroup => parentId.isEmpty;
}

/// Every category of a book (defaults first, in table order, then custom
/// ones), hidden ones included and flagged — the picker filters them, old
/// entries still show their name.
List<MoneyCategory> resolveMoneyCategories(MoneyMeta meta, AppLocalizations l) {
  return <MoneyCategory>[
    for (final def in kMoneyDefaultCategories)
      _withOverride(def, meta, moneyDefaultCategoryName(l, def.id)),
    for (final c in meta.customCategories)
      if (!_defaultById.containsKey(c.id))
        MoneyCategory(
          id: c.id,
          parentId: c.parentId,
          kind: c.kind,
          name: c.name,
          emoji: c.emoji,
          isCustom: true,
          isHidden: meta.hiddenCategoryIds.contains(c.id),
        ),
  ];
}

MoneyCategory _withOverride(MoneyCategoryDef def, MoneyMeta meta, String name) {
  final o = meta.overrides[def.id];
  final renamed = o != null && o.name.trim().isNotEmpty;
  return MoneyCategory(
    id: def.id,
    parentId: def.parentId,
    kind: def.kind,
    name: renamed ? o.name.trim() : name,
    emoji: (o != null && o.emoji.isNotEmpty) ? o.emoji : def.emoji,
    isHidden: meta.hiddenCategoryIds.contains(def.id),
    originalName: renamed ? name : null,
  );
}

/// Lookup for one book: id → category, unknown ids fall back to "Khác"
/// (a deleted custom category, D9).
class MoneyCategoryIndex {
  MoneyCategoryIndex(Iterable<MoneyCategory> categories)
    : _byId = {for (final c in categories) c.id: c};

  final Map<String, MoneyCategory> _byId;

  Iterable<MoneyCategory> get all => _byId.values;

  MoneyCategory of(String id) => _byId[id] ?? _byId[kMoneyCategoryOther]!;

  /// The group a category belongs to (itself when it is a group, or when
  /// its parent is gone).
  String groupOf(String id) {
    final c = _byId[id];
    if (c == null) return kMoneyCategoryOther;
    if (c.isGroup) return c.id;
    return _byId.containsKey(c.parentId) ? c.parentId : c.id;
  }

  /// What the picker offers: not hidden, of [kind].
  List<MoneyCategory> pickable(MoneyTxType kind) => [
    for (final c in _byId.values)
      if (c.kind == kind && !c.isHidden) c,
  ];
}
