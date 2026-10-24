import '../l10n/app_localizations.dart';
import '../models/money.dart';

/// The ready-made saving challenges (D34 §4). [vndLimit]: the cap of a
/// [MoneyChallengeKind.cap] template in đồng; other currencies type their own.
class MoneyChallengeTemplate {
  const MoneyChallengeTemplate(
    this.id,
    this.kind,
    this.categoryIds,
    this.days, {
    this.vndLimit = 0,
  });

  final String id;
  final MoneyChallengeKind kind;
  final List<String> categoryIds;
  final int days;
  final int vndLimit;

  /// [limitText] fills the amount of a cap template ("500k").
  String title(AppLocalizations l, {String limitText = ''}) => switch (id) {
    'no_coffee_7' => l.moneyChTplNoCoffee7,
    'no_snack_7' => l.moneyChTplNoSnack7,
    'no_grab_7' => l.moneyChTplNoGrab7,
    'no_shop_7' => l.moneyChTplNoShop7,
    'no_clothes_14' => l.moneyChTplNoClothes14,
    'cook_home_14' => l.moneyChTplCookHome14,
    'no_tech_30' => l.moneyChTplNoTech30,
    'eat_out_cap_7' => l.moneyChTplEatOutCap7(limitText),
    'date_cap_7' => l.moneyChTplDateCap7(limitText),
    _ => l.moneyChTplAllCap7(limitText),
  };
}

const List<MoneyChallengeTemplate> kMoneyChallengeTemplates = [
  MoneyChallengeTemplate('no_coffee_7', MoneyChallengeKind.noSpend, [
    'food_coffee',
  ], 7),
  MoneyChallengeTemplate('no_snack_7', MoneyChallengeKind.noSpend, [
    'food_snack',
  ], 7),
  MoneyChallengeTemplate('no_grab_7', MoneyChallengeKind.noSpend, [
    'move_grab',
  ], 7),
  MoneyChallengeTemplate('no_shop_7', MoneyChallengeKind.noSpend, ['shop'], 7),
  MoneyChallengeTemplate('no_clothes_14', MoneyChallengeKind.noSpend, [
    'shop_clothes',
  ], 14),
  MoneyChallengeTemplate('cook_home_14', MoneyChallengeKind.noSpend, [
    'food_out',
  ], 14),
  MoneyChallengeTemplate('no_tech_30', MoneyChallengeKind.noSpend, [
    'shop_tech',
  ], 30),
  MoneyChallengeTemplate(
    'eat_out_cap_7',
    MoneyChallengeKind.cap,
    ['food_out'],
    7,
    vndLimit: 500000,
  ),
  MoneyChallengeTemplate(
    'date_cap_7',
    MoneyChallengeKind.cap,
    ['date'],
    7,
    vndLimit: 1000000,
  ),
  MoneyChallengeTemplate(
    'all_cap_7',
    MoneyChallengeKind.cap,
    [],
    7,
    vndLimit: 2000000,
  ),
];
