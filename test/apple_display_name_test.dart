import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/services/auth_service.dart';

/// PF4 (pairing-funnel): the display name a new profile gets. Rules reject an
/// empty one, and Apple's hidden relay address must never become a name.
void main() {
  String name({String? firebaseName, String? email}) =>
      AuthService.profileDisplayName(firebaseName: firebaseName, email: email);
  final fallback = AppL10n.strings.defaultDisplayName;

  test('the name Firebase has wins', () {
    expect(name(firebaseName: '  Thảo Hà ', email: 'thao@gmail.com'), 'Thảo Hà');
  });

  test('no name → the part of a normal email before @', () {
    expect(name(email: 'Thao.Ha@gmail.com'), 'Thao.Ha');
    expect(name(firebaseName: '   ', email: 'tuan@icloud.com'), 'tuan');
  });

  test('never uses an Apple hidden relay address', () {
    expect(name(email: 'x7k2abcd9q@privaterelay.appleid.com'), fallback);
    expect(name(email: 'X7K2ABCD9Q@PrivateRelay.AppleID.com'), fallback);
  });

  test('nothing usable → the default name, never empty', () {
    expect(name(), fallback);
    expect(name(firebaseName: '', email: ''), fallback);
    expect(name(email: '@gmail.com'), fallback);
    expect(fallback, isNotEmpty);
  });
}
