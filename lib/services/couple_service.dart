import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/couple.dart';
import 'firebase_bootstrap_service.dart';
import 'storage_service.dart';
import 'user_service.dart';

class CoupleException implements Exception {
  final String message;

  const CoupleException(this.message);

  @override
  String toString() => message;
}

class CoupleActionResult {
  const CoupleActionResult({
    required this.couple,
    required this.updatedUser,
    this.message,
  });

  final Couple couple;
  final AppUser updatedUser;
  final String? message;
}

class CoupleService {
  CoupleService({
    FirebaseFirestore? firestore,
    UserService? userService,
  })  : _firestore = firestore,
        _userService = userService ?? UserService();

  final FirebaseFirestore? _firestore;
  final UserService _userService;
  final Uuid _uuid = const Uuid();
  final Random _random = Random.secure();

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _couplesCollection =>
      _db.collection('couples');

  Future<Couple?> fetchCouple(String coupleId) async {
    if (coupleId.trim().isEmpty) {
      return null;
    }

    if (isUsingFirebase) {
      final snapshot = await _couplesCollection.doc(coupleId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      final couple = Couple.fromJson({
        'id': snapshot.id,
        ...snapshot.data()!,
      });
      await StorageService.saveCouple(couple);
      return couple;
    }

    final localCouple = await StorageService.loadCouple();
    if (localCouple?.id == coupleId) {
      return localCouple;
    }
    return null;
  }

  Future<CoupleActionResult> createCouple({
    required AppUser currentUser,
    required String person1Name,
    required String person2Name,
    required DateTime anniversaryDate,
    String? photoPath,
  }) async {
    if (currentUser.id.trim().isEmpty) {
      throw const CoupleException('Không tìm thấy người dùng hiện tại để tạo cặp đôi.');
    }

    final now = DateTime.now();
    final savedPhotoPath = await _prepareLocalPhotoPath(photoPath);
    final inviteCode = await _generateUniqueInviteCode();

    final couple = Couple(
      id: isUsingFirebase ? _couplesCollection.doc().id : _uuid.v4(),
      person1Name: person1Name.trim(),
      person2Name: person2Name.trim(),
      anniversaryDate: anniversaryDate,
      couplePhotoPath: savedPhotoPath,
      inviteCode: inviteCode,
      memberIds: [currentUser.id],
      memberCount: 1,
      createdByUserId: currentUser.id,
      status: 'waiting_partner',
      createdAt: now,
      updatedAt: now,
    );

    final updatedUser = currentUser.copyWith(
      coupleId: couple.id,
      status: 'waiting_partner',
      updatedAt: now,
      lastSeenAt: now,
    );

    if (isUsingFirebase) {
      await _couplesCollection.doc(couple.id).set(couple.toFirestore());
      await _userService.updateUserProfile(updatedUser);
    }

    await StorageService.saveCouple(couple);

    return CoupleActionResult(
      couple: couple,
      updatedUser: updatedUser,
      message: 'Mã kết nối của hai bạn là ${couple.inviteCode}',
    );
  }

  Future<CoupleActionResult> updateCouple({
    required AppUser currentUser,
    required Couple existingCouple,
    required String person1Name,
    required String person2Name,
    required DateTime anniversaryDate,
    String? photoPath,
  }) async {
    final now = DateTime.now();
    final savedPhotoPath = await _prepareLocalPhotoPath(
      photoPath,
      fallbackPath: existingCouple.couplePhotoPath,
    );

    final updatedCouple = existingCouple.copyWith(
      person1Name: person1Name.trim(),
      person2Name: person2Name.trim(),
      anniversaryDate: anniversaryDate,
      couplePhotoPath: savedPhotoPath,
      updatedAt: now,
    );

    if (isUsingFirebase && updatedCouple.id.isNotEmpty) {
      await _couplesCollection.doc(updatedCouple.id).set(
            updatedCouple.toFirestore(),
            SetOptions(merge: true),
          );
    }

    await StorageService.saveCouple(updatedCouple);

    return CoupleActionResult(
      couple: updatedCouple,
      updatedUser: currentUser.copyWith(updatedAt: now, lastSeenAt: now),
      message: 'Đã cập nhật thông tin cặp đôi.',
    );
  }

  Future<CoupleActionResult> joinCoupleByCode({
    required AppUser currentUser,
    required String inviteCode,
  }) async {
    if (currentUser.hasCouple) {
      throw const CoupleException('Tài khoản này đã thuộc một cặp đôi rồi.');
    }

    final normalizedCode = inviteCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw const CoupleException('Bạn hãy nhập mã kết nối trước nhé.');
    }

    if (isUsingFirebase) {
      final querySnapshot = await _couplesCollection
          .where('inviteCode', isEqualTo: normalizedCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw const CoupleException('Mã kết nối không hợp lệ hoặc đã hết hiệu lực.');
      }

      final docRef = querySnapshot.docs.first.reference;
      late Couple updatedCouple;
      late AppUser updatedUser;

      await _db.runTransaction((transaction) async {
        final coupleSnapshot = await transaction.get(docRef);
        final coupleData = coupleSnapshot.data();
        if (coupleData == null) {
          throw const CoupleException('Không tìm thấy cặp đôi tương ứng với mã này.');
        }

        final currentCouple = Couple.fromJson({
          'id': coupleSnapshot.id,
          ...coupleData,
        });

        if (currentCouple.memberIds.contains(currentUser.id)) {
          throw const CoupleException('Bạn đã ở trong cặp đôi này rồi.');
        }

        if (currentCouple.memberCount >= 2) {
          throw const CoupleException('Cặp đôi này đã đủ 2 người rồi.');
        }

        final now = DateTime.now();
        final newMemberIds = [...currentCouple.memberIds, currentUser.id];
        updatedCouple = currentCouple.copyWith(
          memberIds: newMemberIds,
          memberCount: newMemberIds.length,
          status: newMemberIds.length >= 2 ? 'active' : 'waiting_partner',
          updatedAt: now,
          person2Name: currentCouple.person2Name.trim().isEmpty
              ? currentUser.displayName
              : currentCouple.person2Name,
        );
        updatedUser = currentUser.copyWith(
          coupleId: currentCouple.id,
          status: 'in_couple',
          updatedAt: now,
          lastSeenAt: now,
        );

        transaction.set(
          docRef,
          updatedCouple.toFirestore(),
          SetOptions(merge: true),
        );
        transaction.set(
          _db.collection('users').doc(currentUser.id),
          updatedUser.toFirestore(),
          SetOptions(merge: true),
        );
      });

      await StorageService.saveCouple(updatedCouple);
      return CoupleActionResult(
        couple: updatedCouple,
        updatedUser: updatedUser,
        message: 'Hai bạn đã kết nối thành công rồi 💞',
      );
    }

    final localCouple = await StorageService.loadCouple();
    if (localCouple == null || localCouple.inviteCode != normalizedCode) {
      throw const CoupleException('Không tìm thấy mã kết nối trong local fallback.');
    }

    if (localCouple.memberCount >= 2) {
      throw const CoupleException('Cặp đôi local này đã đủ 2 người rồi.');
    }

    final now = DateTime.now();
    final newMemberIds = [...localCouple.memberIds, currentUser.id];
    final updatedLocalCouple = localCouple.copyWith(
      memberIds: newMemberIds,
      memberCount: newMemberIds.length,
      status: newMemberIds.length >= 2 ? 'active' : 'waiting_partner',
      updatedAt: now,
    );

    await StorageService.saveCouple(updatedLocalCouple);

    return CoupleActionResult(
      couple: updatedLocalCouple,
      updatedUser: currentUser.copyWith(
        coupleId: updatedLocalCouple.id,
        status: 'in_couple',
        updatedAt: now,
        lastSeenAt: now,
      ),
      message: 'Đã ghép cặp trong local fallback mode.',
    );
  }

  Future<AppUser> resetCouple({required AppUser currentUser}) async {
    final now = DateTime.now();

    if (isUsingFirebase && currentUser.coupleId != null) {
      final docRef = _couplesCollection.doc(currentUser.coupleId);
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        final currentCouple = Couple.fromJson({
          'id': snapshot.id,
          ...snapshot.data()!,
        });
        final remainingMembers = currentCouple.memberIds
            .where((memberId) => memberId != currentUser.id)
            .toList();

        if (remainingMembers.isEmpty) {
          await docRef.delete();
        } else {
          final updatedCouple = currentCouple.copyWith(
            memberIds: remainingMembers,
            memberCount: remainingMembers.length,
            status: 'waiting_partner',
            updatedAt: now,
          );
          await docRef.set(updatedCouple.toFirestore(), SetOptions(merge: true));
        }
      }
    }

    final updatedUser = currentUser.copyWith(
      coupleId: null,
      status: 'single',
      updatedAt: now,
      lastSeenAt: now,
    );

    if (isUsingFirebase) {
      await _userService.updateUserProfile(updatedUser);
    }

    await StorageService.clearCouple();
    return updatedUser;
  }

  Future<String?> _prepareLocalPhotoPath(
    String? sourcePath, {
    String? fallbackPath,
  }) async {
    final trimmedPath = sourcePath?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return fallbackPath;
    }

    final file = File(trimmedPath);
    if (!await file.exists()) {
      return fallbackPath ?? trimmedPath;
    }

    final savedPath = await StorageService.savePhotoFile(trimmedPath);
    return savedPath ?? fallbackPath ?? trimmedPath;
  }

  Future<String> _generateUniqueInviteCode() async {
    if (!isUsingFirebase) {
      return _generateInviteCode();
    }

    for (var attempt = 0; attempt < 10; attempt++) {
      final candidate = _generateInviteCode();
      final existing = await _couplesCollection
          .where('inviteCode', isEqualTo: candidate)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        return candidate;
      }
    }

    throw const CoupleException('Không thể tạo mã kết nối mới, bạn thử lại nhé.');
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}

