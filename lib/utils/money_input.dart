import 'package:intl/intl.dart';

/// Typing and printing VND amounts (feature expenses, overview D10).
///
/// Money is always a whole number of đồng (`int`), never a double.

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

/// Reads what people actually type: "50k", "1tr", "1tr2" (1.200.000),
/// "1.5tr", "1.500k" (1.500.000), "2 triệu", "1 củ", "1 tỏi", "120000",
/// "1.200.000", "1,200,000".
/// Anything above [max] is [VndParseError.tooBig] (10 tỷ for an entry; pass
/// [kMoneyWalletMax] for a wallet balance).
VndParseResult parseVndInput(String? raw, {int max = kMoneyTxMax}) {
  var s = (raw ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceFirst(_currencyTail, '');
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
    final u = BigInt.from(unit);
    big = BigInt.parse(whole) * u;
    if (frac.isNotEmpty) {
      final den = BigInt.from(10).pow(frac.length);
      // Rounded to the nearest đồng.
      big += (BigInt.parse(frac) * u * BigInt.two + den) ~/ (den * BigInt.two);
    }
  } else {
    if (tail != null) {
      return const VndParseResult._(null, VndParseError.invalid, false);
    }
    if (!_grouped.hasMatch(number) && !_digits.hasMatch(number)) {
      return const VndParseResult._(null, VndParseError.invalid, false);
    }
    big = BigInt.parse(number.replaceAll(separators, ''));
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
String formatVnd(int amount, {String? locale}) {
  final vi = _isVi(locale);
  final digits = NumberFormat.decimalPattern(
    vi ? 'vi' : 'en',
  ).format(amount.abs());
  final sign = amount < 0 ? kMoneyMinus : '';
  return vi ? '$sign$digits ₫' : '$sign₫$digits';
}

/// Short amount for chips, chart axes and the balance line: `50k`, `1,2tr`,
/// `3,5 tỷ` (vi) / `50K`, `1.2M`, `3.5B` (en). Never for wallet balances or
/// month totals (D10).
String formatVndShort(int amount, {String? locale}) {
  final vi = _isVi(locale);
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
