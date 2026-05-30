import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../l10n/app_l10n.dart';
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
      message: AppL10n.strings.authInviteCodeUnavailable,
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

    await _usersCollection.doc(user.id).set(user.toFirestoreUpdate(), SetOptions(merge: true));
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

  /// Keep the user's device list tidy so registrations don't pile up across
  /// reinstalls (each install gets a fresh deviceId). Removes docs older than
  /// [maxAge] and caps the list to the [keepMostRecent] newest. The current
  /// device ([keepDeviceId]) is always preserved.
  ///
  /// Dead-*token* removal is handled server-side when a notification send
  /// fails; this prunes abandoned/duplicate registrations.
  Future<void> pruneStaleDevices({
    required String userId,
    String? keepDeviceId,
    Duration maxAge = const Duration(days: 60),
    int keepMostRecent = 8,
  }) async {
    if (!isEnabled || userId.trim().isEmpty) {
      return;
    }

    final snapshot = await _devicesCollection(userId).get();
    if (snapshot.docs.length <= 1) {
      return;
    }

    final now = DateTime.now();
    final docs = snapshot.docs.toList()
      ..sort((a, b) => _deviceUpdatedAt(b.data()).compareTo(_deviceUpdatedAt(a.data())));

    for (var i = 0; i < docs.length; i++) {
      final doc = docs[i];
      if (doc.id == keepDeviceId) {
        continue;
      }
      final tooOld = now.difference(_deviceUpdatedAt(doc.data())) > maxAge;
      final overCap = i >= keepMostRecent;
      if (tooOld || overCap) {
        await doc.reference.delete();
      }
    }
  }

  DateTime _deviceUpdatedAt(Map<String, dynamic> data) {
    final value = data['updatedAt'];
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> deleteUserData(AppUser user) async {
    if (!isEnabled || user.id.trim().isEmpty) {
      return;
    }

    final devicesSnapshot = await _devicesCollection(user.id).get();
    for (final doc in devicesSnapshot.docs) {
      await doc.reference.delete();
    }

    final normalizedCode = user.inviteCode.trim().toUpperCase();
    if (normalizedCode.isNotEmpty) {
      await _inviteCodesCollection.doc(normalizedCode).delete();
    }

    await _usersCollection.doc(user.id).delete();
  }

  Future<void> _syncInviteCode(AppUser user) async {
    final normalizedCode = user.inviteCode.trim().toUpperCase();
    if (!isEnabled || normalizedCode.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final existing = await _inviteCodesCollection.doc(normalizedCode).get();

    // Only send `createdAt` when creating the doc. On update, omit it so the
    // immutable-`createdAt` rule check passes — merge keeps the stored value
    // and avoids the iOS DateTime→Timestamp nanosecond drift.
    final data = <String, dynamic>{
      'userId': user.id,
      'displayName': user.displayName,
      'coupleId': user.coupleId,
      'updatedAt': now,
    };
    if (!existing.exists) {
      data['createdAt'] = now;
    }

    await _inviteCodesCollection.doc(normalizedCode).set(data, SetOptions(merge: true));
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}

