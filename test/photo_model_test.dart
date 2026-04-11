import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/photo.dart';

void main() {
  test('Photo serializes shared sync metadata correctly', () {
    final uploadDate = DateTime(2026, 4, 10, 10, 30);
    final updatedAt = DateTime(2026, 4, 10, 11, 0);

    final photo = Photo(
      id: 'photo-1',
      path: '/local/photo.jpg',
      remoteUrl: 'https://example.com/photo.jpg',
      storagePath: 'couple_photos/couple-1/photo-1.jpg',
      coupleId: 'couple-1',
      authorUserId: 'user-1',
      authorName: 'Tony',
      uploadDate: uploadDate,
      caption: 'Xin chào',
      updatedAt: updatedAt,
    );

    expect(photo.posterName, 'Tony');
    expect(photo.hasLocalPath, isTrue);
    expect(photo.hasRemoteUrl, isTrue);
    expect(photo.toFirestore()['path'], '');
    expect(photo.toJson()['path'], '/local/photo.jpg');
  });

  test('Photo.fromJson can restore remote-only photo metadata', () {
    final photo = Photo.fromJson({
      'id': 'photo-2',
      'path': '',
      'remoteUrl': 'https://example.com/2.jpg',
      'storagePath': 'couple_photos/couple-1/photo-2.jpg',
      'coupleId': 'couple-1',
      'authorUserId': 'user-2',
      'authorName': 'Em',
      'uploadDate': '2026-04-10T10:00:00.000',
      'caption': 'Ảnh sync',
      'updatedAt': '2026-04-10T10:05:00.000',
    });

    expect(photo.path, isEmpty);
    expect(photo.remoteUrl, isNotEmpty);
    expect(photo.posterName, 'Em');
    expect(photo.caption, 'Ảnh sync');
  });
}

