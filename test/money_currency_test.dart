import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/utils/money_currency.dart';
import 'package:dear_embeiu/utils/money_input.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/widgets/money/add_transaction_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

// Feature expenses D31 (currency per book) + keypad by language.
void main() {
  final usd = MoneyCurrency.of('USD');
  final jpy = MoneyCurrency.of('JPY');

  group('MoneyCurrency', () {
    test('unknown / missing code falls back to VND', () {
      expect(MoneyCurrency.of(null), MoneyCurrency.vnd);
      expect(MoneyCurrency.of('BTC'), MoneyCurrency.vnd);
      expect(usd.minor, 100);
      expect(jpy.minor, 1);
      expect(MoneyCurrency.vnd.roundStep, 1000);
      expect(usd.roundStep, 100);
    });

    test('codes match the rules list', () {
      expect(MoneyCurrency.codes, [
        'VND', 'USD', 'EUR', 'GBP', 'AUD', 'CAD', //
        'SGD', 'JPY', 'KRW', 'CNY', 'TWD', 'THB',
      ]);
    });

    test('MoneyMeta reads currency, missing = VND', () {
      expect(MoneyMeta.fromDoc({'currency': 'USD'}).currency, 'USD');
      expect(MoneyMeta.fromDoc({}).currency, 'VND');
      expect(MoneyMeta.fromDoc({'currency': 3}).currency, 'VND');
    });
  });

  group('parseMoneyInput', () {
    int? p(String s, MoneyCurrency c) => parseMoneyInput(s, currency: c).value;

    test('cents for USD', () {
      expect(p('12.5', usd), 1250);
      expect(p('12,50', usd), 1250);
      expect(p(r'$7.25', usd), 725);
      expect(p('7.25 usd', usd), 725);
      expect(p('5', usd), 500);
      expect(p('1.2k', usd), 120000);
      expect(p('1,234.56', usd), 123456);
      // Three digits after one mark still group thousands.
      expect(p('1.500', usd), 150000);
    });

    test('yen has no decimals', () {
      expect(p('500', jpy), 500);
      expect(p('1.5k', jpy), 1500);
      expect(parseMoneyInput('12.5', currency: jpy).ok, isFalse);
    });

    test('VND unchanged', () {
      expect(parseVndInput('50k').value, 50000);
      expect(parseVndInput('1tr2').value, 1200000);
      expect(parseVndInput('1 củ').value, 1000000);
      expect(parseVndInput('50K').value, 50000);
      expect(parseVndInput('2B').value, 2000000000);
    });

    test('cap is in the smallest unit', () {
      // 10 tỷ cents = $100,000,000.
      expect(
        parseMoneyInput('100000001', currency: usd).error,
        VndParseError.tooBig,
      );
      expect(parseMoneyInput('100000000', currency: usd).ok, isTrue);
    });
  });

  group('format', () {
    test('USD full and short', () {
      expect(formatMoney(1250, usd, locale: 'en'), r'$12.50');
      expect(formatMoney(-500, usd, locale: 'en'), '−\$5.00');
      expect(formatMoneyShort(120000, usd, locale: 'en'), r'$1.2K');
      expect(formatMoneyShort(500, usd, locale: 'en'), r'$5');
      expect(formatMoneyShort(1250, usd, locale: 'en'), r'$12.50');
    });

    test('VND keeps its shapes', () {
      expect(formatVnd(1250000, locale: 'vi'), '1.250.000 ₫');
      expect(formatVndShort(1200000, locale: 'vi'), '1,2tr');
      expect(formatVndShort(1200000, locale: 'en'), '1.2M');
    });

    test('moneyInputText round-trips', () {
      for (final v in [1, 99, 100, 1250, 120000]) {
        final text = moneyInputText(v, usd);
        expect(parseMoneyInput(text, currency: usd).value, v, reason: text);
      }
      expect(moneyInputText(120000, MoneyCurrency.vnd), '120000');
      expect(moneyInputText(1205, usd), '12.05');
    });
  });

  group('keypad', () {
    test('Vietnamese + VND keeps k · tr · củ', () {
      final i = MoneyAmountInput()..lang = 'vi';
      expect(i.keypadUnits, ['k', 'tr', 'củ']);
      expect(i.decimalKey, ',');
      expect(i.zerosKey, '000');
    });

    test('English shows K · M · B, never củ', () {
      final i = MoneyAmountInput()..lang = 'en';
      expect(i.keypadUnits, ['K', 'M', 'B']);
      expect(i.decimalKey, '.');
      for (final k in ['5', '0', 'K']) {
        i.press(k);
      }
      expect(i.parsed.value, 50000);
    });

    test('Vietnamese with USD uses K · M · B and 00', () {
      final i = MoneyAmountInput()
        ..lang = 'vi'
        ..currency = usd;
      expect(i.keypadUnits, ['K', 'M', 'B']);
      expect(i.zerosKey, '00');
    });

    test('USD: at most 2 digits after the mark', () {
      final i = MoneyAmountInput()
        ..lang = 'en'
        ..currency = usd;
      for (final k in ['1', '2', '.', '5', '0', '9']) {
        i.press(k);
      }
      expect(i.raw, '12.50');
      expect(i.parsed.value, 1250);
    });

    test('chips and setValue write major units', () {
      final i = MoneyAmountInput()..currency = usd;
      i.addChip(500);
      i.addChip(1000);
      expect(i.raw, '15');
      expect(i.parsed.value, 1500);
      i.setValue(1205);
      expect(i.raw, '12.05');
    });
  });

  test('perMonthNeeded rounds to the currency step', () {
    expect(MoneyMath.perMonthNeeded(1001, '2026-10-01', '2026-11-01'), 2000);
    expect(
      MoneyMath.perMonthNeeded(1001, '2026-10-01', '2026-11-01', step: 100),
      1100,
    );
  });
}
