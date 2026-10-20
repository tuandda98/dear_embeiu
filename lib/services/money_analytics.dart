import '../data/money_categories.dart';
import '../models/money.dart';
import 'analytics_service.dart';

// ── expenses (đợt 2) ── Sổ tiền analytics (overview D27). 🔒 Never an
// amount, a balance, a wallet name, a note or a custom category's name:
// only fixed enums, bools and ids of the built-in categories.
class MoneyAnalyticsEvents {
  MoneyAnalyticsEvents._();

  static const String txAdd = 'money_tx_add';
  static const String settle = 'money_settle';
  static const String goalReached = 'money_goal_reached';
  static const String screenOpen = 'money_screen_open';
  static const String reminderToggle = 'money_reminder_toggle';

  static const String pBook = 'book'; // own / shared
  static const String pType = 'type'; // MoneyTxType.name
  // built-in group id / custom / none
  static const String pCategory = 'category';
  static const String pWalletType = 'wallet_type';
  static const String pPayer = 'payer'; // me / partner / wallet / na
  static const String pSplit = 'split';
  static const String pVia = 'via'; // manual / chip / decision / recurring
  static const String pHasNote = 'has_note';
  static const String pLinked = 'linked';
  // home / profile / decision / push / inbox / reminder
  static const String pFrom = 'from';
  static const String pOn = 'on';
}

extension MoneyAnalytics on AnalyticsService {
  /// A new entry. [category] is the built-in group id ("food"), "custom"
  /// for a category the user added, "none" without one.
  void logMoneyTxAdd({
    required MoneyBookKind book,
    required MoneyTx tx,
    required String uid,
    required MoneyCategoryIndex categories,
    MoneyWalletType? walletType,
    required String via,
    required bool linked,
  }) {
    final String category;
    if (tx.categoryId.isEmpty) {
      category = 'none';
    } else if (categories.of(tx.categoryId, kind: tx.type).isCustom) {
      category = 'custom';
    } else {
      category = categories.groupOf(tx.categoryId);
    }
    final payer = tx.payer;
    logEvent(
      MoneyAnalyticsEvents.txAdd,
      params: {
        MoneyAnalyticsEvents.pBook: book.name,
        MoneyAnalyticsEvents.pType: tx.type.name,
        MoneyAnalyticsEvents.pCategory: category,
        MoneyAnalyticsEvents.pWalletType: walletType?.name ?? 'none',
        MoneyAnalyticsEvents.pPayer: payer == null
            ? 'na'
            : payer == kMoneyPayerWallet
            ? 'wallet'
            : payer == uid
            ? 'me'
            : 'partner',
        MoneyAnalyticsEvents.pSplit: (tx.splitMode ?? MoneySplitMode.none).wire,
        MoneyAnalyticsEvents.pVia: via,
        MoneyAnalyticsEvents.pHasNote: tx.note.trim().isNotEmpty,
        MoneyAnalyticsEvents.pLinked: linked,
      },
    );
  }

  void logMoneySettle() => logEvent(MoneyAnalyticsEvents.settle);

  void logMoneyGoalReached(MoneyBookKind book) => logEvent(
    MoneyAnalyticsEvents.goalReached,
    params: {MoneyAnalyticsEvents.pBook: book.name},
  );

  void logMoneyScreenOpen(String from) => logEvent(
    MoneyAnalyticsEvents.screenOpen,
    params: {MoneyAnalyticsEvents.pFrom: from},
  );

  void logMoneyReminderToggle(bool on) => logEvent(
    MoneyAnalyticsEvents.reminderToggle,
    params: {MoneyAnalyticsEvents.pOn: on},
  );
}
