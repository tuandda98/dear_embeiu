import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/services/couple_service.dart';
import 'package:dear_embeiu/services/user_service.dart';

// Feature pairing-funnel, audit 2026-10-12: PA3 (code of a full couple) and
// PA8 (the "New user" placeholder name).
void main() {
  final l10n = AppL10n.strings;
  FirebaseException firestore(String code) =>
      FirebaseException(plugin: 'cloud_firestore', code: code);

  group('PA3 join errors', () {
    test('code resolved, couple read refused by the rules → full', () {
      final e = CoupleService.joinFirebaseError(
        firestore('permission-denied'),
        coupleRead: false,
      );
      expect(e.message, l10n.coupleFull);
      expect(e.code, CoupleErrorCode.full);
    });

    test('refused before the transaction, or at commit → old copy', () {
      for (final read in [null, true]) {
        final e = CoupleService.joinFirebaseError(
          firestore('permission-denied'),
          coupleRead: read,
        );
        expect(e.message, l10n.coupleJoinPermissionDenied, reason: '$read');
      }
    });

    test('other codes keep their copy', () {
      String message(String code) => CoupleService.joinFirebaseError(
            firestore(code),
            coupleRead: false,
          ).message;
      expect(message('unauthenticated'), l10n.coupleSessionExpiredJoin);
      expect(message('unavailable'), l10n.coupleFirebaseUnavailable);
      expect(message('aborted'), l10n.coupleJoinGeneric);
    });
  });

  group('PA8 placeholder name', () {
    test('either app language, or empty, is a placeholder', () {
      expect(UserService.isPlaceholderDisplayName('Người dùng mới'), isTrue);
      expect(UserService.isPlaceholderDisplayName(' New user '), isTrue);
      expect(UserService.isPlaceholderDisplayName('  '), isTrue);
      expect(UserService.isPlaceholderDisplayName('Tuấn'), isFalse);
      expect(UserService.isPlaceholderDisplayName('dodaoanhtuan'), isFalse);
    });

    test('only a placeholder is replaced, only by a real name', () {
      String? adopt(String current, String candidate) =>
          UserService.adoptedDisplayName(
            current: current,
            candidate: candidate,
          );
      expect(adopt('Người dùng mới', ' Tuấn '), 'Tuấn');
      expect(adopt('New user', 'Em Bé Iu'), 'Em Bé Iu');
      expect(adopt('Tuấn', 'Anh'), isNull);
      expect(adopt('New user', ''), isNull);
      expect(adopt('New user', 'Người dùng mới'), isNull);
    });
  });
}
