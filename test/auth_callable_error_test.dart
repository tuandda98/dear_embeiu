import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/services/auth_service.dart';

void main() {
  String map(String code, String message) => AuthService.mapCallableError(
    FirebaseFunctionsException(code: code, message: message),
    'fallback',
  );

  test('our own localized message is shown as-is', () {
    expect(
      map('invalid-argument', 'Email không hợp lệ.'),
      'Email không hợp lệ.',
    );
    expect(
      map('invalid-argument', "That email isn't valid."),
      "That email isn't valid.",
    );
  });

  test('text the SDK or framework makes up never reaches the screen', () {
    expect(map('internal', 'INTERNAL'), 'fallback');
    expect(map('not-found', ''), 'fallback');
    expect(map('unavailable', 'UNAVAILABLE'), AppL10n.strings.authNetworkError);
    expect(
      map('unknown', 'The Internet connection appears to be offline.'),
      AppL10n.strings.authNetworkError,
    );
    // A stale token: firebase-functions answers a bare "Unauthenticated".
    expect(
      map('unauthenticated', 'Unauthenticated'),
      AppL10n.strings.authSessionNotReady,
    );
  });
}
