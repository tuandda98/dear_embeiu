// DW-R2-1: decision texts are measured in UTF-16 units (= rules
// `string.size()`, checked on the emulator), never graphemes.
import 'package:dear_embeiu/models/decision.dart';
import 'package:dear_embeiu/utils/decision_suggester.dart';
import 'package:dear_embeiu/widgets/decision_parts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _v(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

String _type(DecisionLengthFormatter f, String input) {
  var value = _v('');
  for (final c in input.characters) {
    value = f.formatEditUpdate(value, _v(value.text + c));
  }
  return value.text;
}

void main() {
  const bowl = '🍜';
  const family = '👨‍👩‍👧'; // 3 emoji + 2 ZWJ = 8 units

  test('size = UTF-16 units: emoji 2, ZWJ family 8, Vietnamese 1/letter', () {
    expect(decisionTextSize(bowl), 2);
    expect(decisionTextSize(family), 8);
    expect(decisionTextSize('Bún chả'), 7);
  });

  test('typing 40 bowls stops at 20 (= 40 units, what rules allow)', () {
    const f = DecisionLengthFormatter(kDecisionResultMax);
    final out = _type(f, bowl * 40);
    expect(out, bowl * 20);
    expect(decisionTextSize(out), 40);
  });

  test('pasting past the cap cuts on a grapheme boundary', () {
    const f = DecisionLengthFormatter(kDecisionOptionMax);
    final out = f.formatEditUpdate(_v(''), _v(family * 6)).text; // 48 units
    expect(out, family * 5);
    final odd = f.formatEditUpdate(_v(''), _v('a${bowl * 20}')).text;
    expect(odd, 'a${bowl * 19}'); // no half surrogate pair at the end
    expect(decisionTextSize(odd), 39);
  });

  test('a full field drops the edit; 40 Vietnamese letters fit', () {
    const f = DecisionLengthFormatter(kDecisionResultMax);
    final full = _v('x' * 40);
    expect(f.formatEditUpdate(full, _v('${'x' * 40}$bowl')), full);
    const viet = 'Bún chả Hà Nội ngon tuyệt đỉnh của chópx';
    expect(viet.length, 40);
    expect(_type(f, viet), viet);
  });

  test('question cap is 60 units', () {
    const f = DecisionLengthFormatter(kDecisionQuestionMax);
    expect(_type(f, bowl * 40), bowl * 30);
  });

  test('validateCustomOptions counts the same way', () {
    expect(validateCustomOptions([bowl * 20, 'Em']), isNull);
    expect(
      validateCustomOptions([bowl * 21, 'Em']),
      CustomOptionsIssue.tooLong,
    );
    expect(
      validateCustomOptions([family * 5, 'Em']),
      isNull,
    );
  });
}
