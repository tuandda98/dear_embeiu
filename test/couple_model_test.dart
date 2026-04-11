import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/couple.dart';

void main() {
  test('Couple serializes remote hero photo metadata without leaking local path to Firestore', () {
    final now = DateTime(2026, 4, 10, 12, 0);

    final couple = Couple(
      id: 'couple-1',
      person1Name: 'Tony',
      person2Name: 'Em',
      anniversaryDate: DateTime(2025, 4, 10),
      couplePhotoPath: '/local/couple.jpg',
      couplePhotoUrl: 'https://example.com/couple.jpg',
      couplePhotoStoragePath: 'couple_photos/couple-1/cover_couple-1.jpg',
      inviteCode: 'ABC123',
      memberIds: const ['user-1', 'user-2'],
      memberCount: 2,
      createdByUserId: 'user-1',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    expect(couple.toJson()['couplePhotoPath'], '/local/couple.jpg');
    expect(couple.toFirestore()['couplePhotoPath'], '');
    expect(couple.toFirestore()['couplePhotoUrl'], 'https://example.com/couple.jpg');
  });

  test('Couple.fromJson restores remote hero photo metadata', () {
    final couple = Couple.fromJson({
      'id': 'couple-2',
      'person1Name': 'A',
      'person2Name': 'B',
      'anniversaryDate': '2025-04-10T00:00:00.000',
      'couplePhotoPath': '',
      'couplePhotoUrl': 'https://example.com/remote.jpg',
      'couplePhotoStoragePath': 'couple_photos/couple-2/cover_couple-2.jpg',
      'inviteCode': 'XYZ789',
      'memberIds': const ['u1'],
      'memberCount': 1,
      'createdByUserId': 'u1',
      'status': 'waiting_partner',
      'createdAt': '2026-04-10T12:00:00.000',
      'updatedAt': '2026-04-10T12:05:00.000',
    });

    expect(couple.couplePhotoPath, isEmpty);
    expect(couple.couplePhotoUrl, 'https://example.com/remote.jpg');
    expect(couple.couplePhotoStoragePath, contains('couple-2'));
  });
}

