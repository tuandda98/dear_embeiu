import 'package:intl/intl.dart';

import 'money_currency.dart';

/// Typing and printing amounts (feature expenses, overview D10 + D31).
///
/// Money is always an `int` in the book currency's smallest unit (đồng, cent,
/// yen), never a double. The `Vnd` names are the VND shortcuts the code had
/// before other currencies.

/// Most a single entry / budget may hold: 10 tỷ (rules enforce the same).
const int kMoneyTxMax = 10000000000;

/// Most a wallet's opening balance / goal target may hold: 100 tỷ.
const int kMoneyWalletMax = 100000000000;

/// Lowest opening balance (a credit card that owes 10 tỷ).
const int kMoneyWalletMin = -10000000000;

/// Why [parseVndInput] refused a string. The add sheet shows a different line
/// for each (design §3.3): empty → the hint, invalid → "Chưa hiểu số này",
/// tooBig → "Tối đa 10 tỷ một khoản". zero just keeps Save locked.
enum VndParseError { empty, invalid, zero, tooBig }

class VndParseResult {
  const VndParseResult._(this.value, this.error, this.hasUnit);

  /// The amount in đồng. Set for [tooBig] too, so the field can show it.
  final int? value;
  final VndParseError? error;

  /// The user typed a unit ("50k", "1tr2", "1 củ") → the sheet echoes
  /// "Bạn gõ “1tr2”" to confirm how it was read.
  final bool hasUnit;

  bool get ok => error == null;

  @override
  String toString() => ok ? 'VndParseResult($value)' : 'VndParseResult($error)';
}

const Map<String, int> _units = <String, int>{
  'k': 1000,
  'nghìn': 1000,
  'nghin': 1000,
  'ngàn': 1000,
  'ngan': 1000,
  'tr': 1000000,
  'triệu': 1000000,
  'trieu': 1000000,
  'củ': 1000000,
  'cu': 1000000,
  'm': 1000000,
  'tỷ': 1000000000,
  'ty': 1000000000,
  'tỉ': 1000000000,
  'ti': 1000000000,
  'tỏi': 1000000000,
  'toi': 1000000000,
  'b': 1000000000,
};

final RegExp _shape = RegExp(
  r'^(\d+(?:[.,]\d+)*)\s*([a-zà-ỹđ]+)?\s*(\d+)?$',
  unicode: true,
);
final RegExp _grouped = RegExp(r'^\d{1,3}(?:[.,]\d{3})+$');
final RegExp _digits = RegExp(r'^\d+$');
final RegExp _currencyTail = RegExp(r'\s*(₫|đ|vnd|vnđ)$', unicode: true);

/// "12.5" / "12,50" / "1,234.56": a decimal for a currency with cents.
final RegExp _decimal = RegExp(
  r'^(\d{1,3}(?:([.,])\d{3})*|\d+)([.,])(\d{1,2})$',
);

/// Reads what people actually type: "50k", "1tr", "1tr2" (1.200.000),
/// "1.5tr", "1.500k" (1.500.000), "2 triệu", "1 củ", "1 tỏi", "120000",
/// "1.200.000", "1,200,000".
/// Anything above [max] is [VndParseError.tooBig] (10 tỷ for an entry; pass
/// [kMoneyWalletMax] for a wallet balance).
VndParseResult parseVndInput(String? raw, {int max = kMoneyTxMax}) =>
    parseMoneyInput(raw, max: max);

/// [parseVndInput] for any [currency]: "12.50" → 1250 (cents), "1.2k" →
/// 120000 cents, "500" → 500 ¥. [max] is in the smallest unit too.
VndParseResult parseMoneyInput(
  String? raw, {
  MoneyCurrency currency = MoneyCurrency.vnd,
  int max = kMoneyTxMax,
}) {
  var s = (raw ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceFirst(_currencyTail, '');
  if (!currency.isVnd) {
    final code = currency.code.toLowerCase(),
        sym = currency.symbol.toLowerCase();
    if (s.startsWith(sym)) s = s.substring(sym.length).trim();
    if (s.endsWith(sym)) s = s.substring(0, s.length - sym.length).trim();
    if (s.endsWith(code)) s = s.substring(0, s.length - code.length).trim();
  }
  if (s.isEmpty) {
    return const VndParseResult._(null, VndParseError.empty, false);
  }
  final m = _shape.firstMatch(s);
  if (m == null) {
    return const VndParseResult._(null, VndParseError.invalid, false);
  }
  final number = m.group(1)!;
  final unitRaw = m.group(2);
  final tail = m.group(3);

  final hasUnit = unitRaw != null;
  final separators = RegExp('[.,]');
  // BigInt, never double: "1" + 400 zeros + "k" must say tooBig, not throw.
  BigInt big;
  if (hasUnit) {
    final unit = _units[unitRaw];
    if (unit == null) {
      return const VndParseResult._(null, VndParseError.invalid, true);
    }
    // "1.500k" / "2.000k" are 1.500.000 / 2.000.000: a mark followed by
    // exactly three digits groups thousands, like "1.500.000". Only one or
    // two digits after a single mark are a decimal ("1.5tr", "1,25tr").
    var whole = number, frac = '';
    if (_grouped.hasMatch(number)) {
      whole = number.replaceAll(separators, '');
    } else {
      final parts = number.split(separators);
      if (parts.length > 2 || (parts.length == 2 && parts[1].length > 2)) {
        return const VndParseResult._(null, VndParseError.invalid, true);
      }
      whole = parts[0];
      frac = parts.length == 2 ? parts[1] : '';
    }
    // "1tr2" = 1.200.000, "2tr05" = 2.050.000; "1.5tr2" reads as nothing.
    if (tail != null) {
      if (whole != number) {
        return const VndParseResult._(null, VndParseError.invalid, true);
      }
      frac = tail;
    }
    final u = BigInt.from(unit) * BigInt.from(currency.minor);
    big = BigInt.parse(whole) * u;
    if (frac.isNotEmpty) {
      final den = BigInt.from(10).pow(frac.length);
      // Rounded to the nearest smallest unit.
      big += (BigInt.parse(frac) * u * BigInt.two + den) ~/ (den * BigInt.two);
    }
  } else {
    if (tail != null) {
      return const VndParseResult._(null, VndParseError.invalid, false);
    }
    final dec = currency.decimals > 0 ? _decimal.firstMatch(number) : null;
    // "1.500" stays 1500 (thousands); "1.50" / "1,234.5" carry cents.
    final asDecimal =
        dec != null &&
        !_grouped.hasMatch(number) &&
        (dec.group(2) == null || dec.group(2) != dec.group(3));
    if (asDecimal) {
      final frac = dec.group(4)!.padRight(currency.decimals, '0');
      big =
          BigInt.parse(dec.group(1)!.replaceAll(separators, '')) *
              BigInt.from(currency.minor) +
          BigInt.parse(frac.substring(0, currency.decimals));
    } else {
      if (!_grouped.hasMatch(number) && !_digits.hasMatch(number)) {
        return const VndParseResult._(null, VndParseError.invalid, false);
      }
      big =
          BigInt.parse(number.replaceAll(separators, '')) *
          BigInt.from(currency.minor);
    }
  }
  if (big > BigInt.from(max)) {
    // Way past any cap may not even fit an int: show max + 1 then.
    final shown = big.isValidInt ? big.toInt() : max + 1;
    return VndParseResult._(shown, VndParseError.tooBig, hasUnit);
  }
  final value = big.toInt();
  if (value <= 0) return VndParseResult._(null, VndParseError.zero, hasUnit);
  return VndParseResult._(value, null, hasUnit);
}

/// The minus sign used for money (U+2212, not a hyphen).
const String kMoneyMinus = '−';

bool _isVi(String? locale) =>
    (locale ?? Intl.getCurrentLocale()).toLowerCase().startsWith('vi');

/// Full amount: `1.250.000 ₫` (vi) / `₫1,250,000` (en), negatives `−320.000 ₫`.
/// A no-break space keeps "₫" on the number's line.
String formatVnd(int amount, {String? locale}) =>
    formatMoney(amount, MoneyCurrency.vnd, locale: locale);

/// Full amount in [currency]: `1.250.000 ₫` / `₫1,250,000`, `12,50 $` /
/// `$12.50`, `¥3,000`.
String formatMoney(int amount, MoneyCurrency currency, {String? locale}) {
  final vi = _isVi(locale);
  if (!currency.isVnd) {
    final text = NumberFormat.currency(
      locale: vi ? 'vi' : 'en',
      symbol: currency.symbol,
      decimalDigits: currency.decimals,
    ).format(amount.abs() / currency.minor);
    return '${amount < 0 ? kMoneyMinus : ''}$text';
  }
  final digits = NumberFormat.decimalPattern(
    vi ? 'vi' : 'en',
  ).format(amount.abs());
  final sign = amount < 0 ? kMoneyMinus : '';
  return vi ? '$sign$digits ₫' : '$sign₫$digits';
}

/// Short amount for chips, chart axes and the balance line: `50k`, `1,2tr`,
/// `3,5 tỷ` (vi) / `50K`, `1.2M`, `3.5B` (en). Never for wallet balances or
/// month totals (D10).
String formatVndShort(int amount, {String? locale}) =>
    formatMoneyShort(amount, MoneyCurrency.vnd, locale: locale);

/// [formatVndShort] for any [currency]. VND keeps `50k` / `1,2tr`; the
/// others always use K / M / B with the symbol: `$12.5`, `$1.2K`, `1,2K $`.
String formatMoneyShort(int amount, MoneyCurrency currency, {String? locale}) {
  final vi = _isVi(locale);
  if (!currency.isVnd) {
    final sign = amount < 0 ? kMoneyMinus : '';
    final major = amount.abs() / currency.minor;
    const steps = <(double, String)>[(1e9, 'B'), (1e6, 'M'), (1e3, 'K')];
    var body = '';
    for (final (unit, suffix) in steps) {
      if (major < unit) continue;
      var tenths = (major * 10 / unit).round();
      var sfx = suffix;
      if (tenths >= 10000 && suffix != 'B') {
        tenths = (major * 10 / (unit * 1000)).round();
        sfx = suffix == 'K' ? 'M' : 'B';
      }
      body = '${_tenths(tenths, vi)}$sfx';
      break;
    }
    if (body.isEmpty) {
      // Under a thousand: whole units, cents only when there are any.
      final cents = amount.abs() % currency.minor;
      body = cents == 0
          ? '${amount.abs() ~/ currency.minor}'
          : NumberFormat.decimalPatternDigits(
              locale: vi ? 'vi' : 'en',
              decimalDigits: currency.decimals,
            ).format(major);
    }
    return vi
        ? '$sign$body\u00a0${currency.symbol}'
        : '$sign${currency.symbol}$body';
  }
  final a = amount.abs();
  final sign = amount < 0 ? kMoneyMinus : '';
  const steps = <(int, String, String)>[
    (1000000000, ' tỷ', 'B'),
    (1000000, 'tr', 'M'),
    (1000, 'k', 'K'),
  ];
  for (var i = 0; i < steps.length; i++) {
    final (unit, viSuffix, enSuffix) = steps[i];
    if (a < unit) continue;
    final tenths = (a * 10 / unit).round();
    // 999.950 → "1000k" reads wrong; move up a unit instead.
    if (tenths >= 10000 && i > 0) {
      final (up, upVi, upEn) = steps[i - 1];
      return '$sign${_tenths((a * 10 / up).round(), vi)}${vi ? upVi : upEn}';
    }
    return '$sign${_tenths(tenths, vi)}${vi ? viSuffix : enSuffix}';
  }
  return '$sign$a';
}

String _tenths(int tenths, bool vi) {
  final whole = tenths ~/ 10, frac = tenths % 10;
  return frac == 0 ? '$whole' : '$whole${vi ? ',' : '.'}$frac';
}

/// An amount as an input box shows it before editing: `120000` (VND),
/// `12.5` / `12` (USD). [parseMoneyInput] reads it back to the same value.
String moneyInputText(int amount, MoneyCurrency currency) {
  if (currency.decimals == 0) return '$amount';
  final sign = amount < 0 ? '-' : '';
  final a = amount.abs();
  final whole = a ~/ currency.minor, cents = a % currency.minor;
  if (cents == 0) return '$sign$whole';
  return '$sign$whole.${'$cents'.padLeft(currency.decimals, '0')}';
}
