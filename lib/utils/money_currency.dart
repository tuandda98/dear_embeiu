/// The currencies a book can keep its money in (feature expenses, D31).
///
/// One currency per book, stored in `{book}/moneyMeta/main.currency` (missing
/// = VND). Every amount in that book is an `int` in the currency's smallest
/// unit: đồng, cent, yen. Nothing is ever converted: a book switches
/// currency only while it is still empty (see `MoneyProvider.canChangeCurrency`).
class MoneyCurrency {
  const MoneyCurrency._(
    this.code,
    this.symbol,
    this.decimals, {
    required this.viName,
    required this.enName,
    required this.quickAmounts,
    int? roundStep,
  }) : _roundStep = roundStep;

  /// ISO 4217, the value stored in Firestore.
  final String code;
  final String symbol;

  /// Digits after the decimal mark (0 for VND / JPY / KRW).
  final int decimals;

  /// What a screen reader says after the number ("120.000 đồng").
  final String viName;
  final String enName;

  /// The 4 chips above the keypad, in whole units of the currency.
  final List<int> quickAmounts;
  final int? _roundStep;

  /// Smallest units in one whole unit: 1 (VND), 100 (USD).
  int get minor {
    var m = 1;
    for (var i = 0; i < decimals; i++) {
      m *= 10;
    }
    return m;
  }

  /// "~X mỗi ngày / mỗi tháng" hints round to this, in smallest units:
  /// 1.000 ₫, 100 ¥, $1.
  int get roundStep => _roundStep ?? minor;

  bool get isVnd => code == 'VND';

  static const MoneyCurrency vnd = MoneyCurrency._(
    'VND',
    '₫',
    0,
    viName: 'đồng',
    enName: 'dong',
    quickAmounts: [50000, 100000, 200000, 500000],
    roundStep: 1000,
  );

  static const List<MoneyCurrency> all = [
    vnd,
    MoneyCurrency._(
      'USD',
      r'$',
      2,
      viName: 'đô la Mỹ',
      enName: 'US dollars',
      quickAmounts: [5, 10, 20, 50],
    ),
    MoneyCurrency._(
      'EUR',
      '€',
      2,
      viName: 'euro',
      enName: 'euros',
      quickAmounts: [5, 10, 20, 50],
    ),
    MoneyCurrency._(
      'GBP',
      '£',
      2,
      viName: 'bảng Anh',
      enName: 'pounds',
      quickAmounts: [5, 10, 20, 50],
    ),
    MoneyCurrency._(
      'AUD',
      r'A$',
      2,
      viName: 'đô la Úc',
      enName: 'Australian dollars',
      quickAmounts: [5, 10, 20, 50],
    ),
    MoneyCurrency._(
      'CAD',
      r'C$',
      2,
      viName: 'đô la Canada',
      enName: 'Canadian dollars',
      quickAmounts: [5, 10, 20, 50],
    ),
    MoneyCurrency._(
      'SGD',
      r'S$',
      2,
      viName: 'đô la Singapore',
      enName: 'Singapore dollars',
      quickAmounts: [5, 10, 20, 50],
    ),
    MoneyCurrency._(
      'JPY',
      '¥',
      0,
      viName: 'yên',
      enName: 'yen',
      quickAmounts: [500, 1000, 3000, 5000],
      roundStep: 100,
    ),
    MoneyCurrency._(
      'KRW',
      '₩',
      0,
      viName: 'won',
      enName: 'won',
      quickAmounts: [5000, 10000, 30000, 50000],
      roundStep: 1000,
    ),
    MoneyCurrency._(
      'CNY',
      '¥',
      2,
      viName: 'nhân dân tệ',
      enName: 'yuan',
      quickAmounts: [20, 50, 100, 200],
    ),
    MoneyCurrency._(
      'TWD',
      r'NT$',
      0,
      viName: 'đô la Đài Loan',
      enName: 'Taiwan dollars',
      quickAmounts: [100, 200, 500, 1000],
      roundStep: 10,
    ),
    MoneyCurrency._(
      'THB',
      '฿',
      2,
      viName: 'baht',
      enName: 'baht',
      quickAmounts: [50, 100, 200, 500],
    ),
  ];

  /// Codes the rules accept (keep `firestore.rules` moneyMetaOk in step).
  static final List<String> codes = [for (final c in all) c.code];

  /// Unknown / missing code → VND, so an old app never breaks on a new one.
  static MoneyCurrency of(Object? code) {
    for (final c in all) {
      if (c.code == code) return c;
    }
    return vnd;
  }

  @override
  String toString() => code;
}
