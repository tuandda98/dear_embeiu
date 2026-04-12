import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/account_invite.dart';
import '../models/app_user.dart';

class UserService {
  UserService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  final Random _random = Random.secure();

  bool get isEnabled => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      (_firestore ?? FirebaseFirestore.instance).collection('users');

  CollectionReference<Map<String, dynamic>> get _inviteCodesCollection =>
      (_firestore ?? FirebaseFirestore.instance).collection('invite_codes');

  CollectionReference<Map<String, dynamic>> _devicesCollection(String userId) =>
      _usersCollection.doc(userId).collection('devices');

  Future<AppUser?> fetchUserProfile(String uid) async {
    if (!isEnabled) {
      return null;
    }

    final snapshot = await _usersCollection.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AppUser.fromJson({
      'id': snapshot.id,
      ...snapshot.data()!,
    });
  }

  Future<AccountInvite?> fetchAccountInvite(String inviteCode) async {
    if (!isEnabled || inviteCode.trim().isEmpty) {
      return null;
    }

    final normalizedCode = inviteCode.trim().toUpperCase();
    final snapshot = await _inviteCodesCollection.doc(normalizedCode).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AccountInvite.fromJson(snapshot.id, snapshot.data()!);
  }

  Future<String> generateUniqueInviteCode() async {
    if (!isEnabled) {
      return _generateInviteCode();
    }

    for (var attempt = 0; attempt < 12; attempt++) {
      final candidate = _generateInviteCode();
      final existing = await _inviteCodesCollection.doc(candidate).get();
      if (!existing.exists) {
        return candidate;
      }
    }

    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'invite-code-unavailable',
      message: 'Không thể tạo mã mời mới vào lúc này.',
    );
  }

  Future<void> saveUserProfile(AppUser user) async {
    if (!isEnabled) {
      return;
    }

    await _usersCollection.doc(user.id).set(user.toFirestore());
    await _syncInviteCode(user);
  }

  Future<void> updateUserProfile(AppUser user) async {
    if (!isEnabled) {
      return;
    }

    await _usersCollection.doc(user.id).set(user.toFirestore(), SetOptions(merge: true));
    await _syncInviteCode(user);
  }

  Future<void> saveDeviceRegistration({
    required String userId,
    required String deviceId,
    required String token,
    required String platform,
    required bool notificationsEnabled,
  }) async {
    if (!isEnabled || userId.trim().isEmpty || deviceId.trim().isEmpty) {
      return;
    }

    await _devicesCollection(userId).doc(deviceId).set({
      'token': token.trim(),
      'platform': platform.trim(),
      'notificationsEnabled': notificationsEnabled,
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
  }

  Future<void> removeDeviceRegistration({
    required String userId,
    required String deviceId,
  }) async {
    if (!isEnabled || userId.trim().isEmpty || deviceId.trim().isEmpty) {
      return;
    }

    await _devicesCollection(userId).doc(deviceId).delete();
  }

  Future<void> _syncInviteCode(AppUser user) async {
    final normalizedCode = user.inviteCode.trim().toUpperCase();
    if (!isEnabled || normalizedCode.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final existing = await _inviteCodesCollection.doc(normalizedCode).get();
    final existingData = existing.data();
    final createdAt = existingData == null
        ? now
        : AccountInvite.fromJson(normalizedCode, existingData).createdAt;

    await _inviteCodesCollection.doc(normalizedCode).set({
      'userId': user.id,
      'displayName': user.displayName,
      'coupleId': user.coupleId,
      'createdAt': createdAt,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}

