import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/services/invite_clipboard.dart';

// PF9 (feature pairing-funnel): only a dearembeiu.com/get link counts, never a
// bare 6-character string (that could be an OTP).
void main() {
  String? parse(String text) => InviteClipboard.parseInviteCode(text);

  test('full link', () {
    expect(parse('https://dearembeiu.com/get?code=A7K9Q2'), 'A7K9Q2');
  });

  test('www, no scheme, upper-case host', () {
    expect(parse('https://www.dearembeiu.com/get?code=A7K9Q2'), 'A7K9Q2');
    expect(parse('dearembeiu.com/get?code=A7K9Q2'), 'A7K9Q2');
    expect(parse('HTTPS://DearEmbeiu.COM/get?code=A7K9Q2'), 'A7K9Q2');
  });

  test('other query params before and after code', () {
    expect(
      parse('https://dearembeiu.com/get?lang=vi&utm=x&code=A7K9Q2&ref=zalo'),
      'A7K9Q2',
    );
  });

  test('lower-case code comes back upper-cased', () {
    expect(parse('https://dearembeiu.com/get?code=a7k9q2'), 'A7K9Q2');
  });

  test('code must be exactly 6 alphanumerics', () {
    expect(parse('https://dearembeiu.com/get?code=A7K9Q22'), isNull);
    expect(parse('https://dearembeiu.com/get?code=A7K9Q'), isNull);
    expect(parse('https://dearembeiu.com/get?xcode=A7K9Q2'), isNull);
  });

  test('foreign links and bare codes are ignored', () {
    expect(parse('https://example.com/get?code=A7K9Q2'), isNull);
    expect(parse('https://notdearembeiu.com/get?code=A7K9Q2'), isNull);
    expect(parse('https://dearembeiu.com/privacy-policy.html'), isNull);
    expect(parse('A7K9Q2'), isNull);
    expect(parse('Mã OTP của bạn là 482913'), isNull);
    expect(parse(''), isNull);
  });

  test('invite link nested inside another URL is ignored (BUG-5)', () {
    expect(
      parse('https://evil.com/?u=https://dearembeiu.com/get?code=ABC234'),
      isNull,
    );
    expect(parse('https://evil.com/dearembeiu.com/get?code=ABC234'), isNull);
  });

  test('brackets, quotes and whitespace before the link are fine', () {
    expect(parse('(https://dearembeiu.com/get?code=ABC234)'), 'ABC234');
    expect(parse('"https://dearembeiu.com/get?code=ABC234"'), 'ABC234');
    expect(parse('“https://dearembeiu.com/get?code=ABC234”'), 'ABC234');
    expect(
      parse('Tải app & nhập mã tại: https://dearembeiu.com/get?code=abc234'),
      'ABC234',
    );
  });

  test('finds the link inside the whole invite message', () {
    const message =
        'Mình muốn lưu giữ kỷ niệm cùng bạn trên Dear Embeiu 💞\n'
        'Nhập mã mời này để ghép đôi với mình nhé: A7K9Q2\n'
        'Tải app & nhập mã tại: https://dearembeiu.com/get?code=A7K9Q2';
    expect(parse(message), 'A7K9Q2');
  });
}
