import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/couple.dart';
import 'firebase_bootstrap_service.dart';
import 'storage_service.dart';
import 'user_service.dart';

enum CoupleErrorCode {
  alreadyHasCouple,
  emptyInvite,
  ownInvite,
  inviteNotFound,
  inviteNoSpace,
  targetNotFound,
  invalidInviteLink,
  alreadyInThis,
  full,
  localNotFound,
  localFull,
  firestorePermissionRead,
  firestorePermissionWrite,
  unavailable,
  unauthenticated,
  sessionNotReady,
  saveGeneric,
  joinGeneric,
  noCurrentUser,
  noCoupleToUpdate,
  loadFailed,
  syncFailed,
  unknown,
}

enum CoupleResultCode {
  updated,
  joined,
  localFallbackJoined,
}

enum CouplePhotoSyncWarningCode {
  permissionDenied,
  unauthenticated,
  unavailable,
  generic,
}

class CoupleException implements Exception {
  const CoupleException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CoupleActionResult {
  const CoupleActionResult({
    required this.couple,
    required this.updatedUser,
    this.message,
    this.warningMessage,
  });

  final Couple couple;
  final AppUser updatedUser;
  final String? message;
  final String? warningMessage;
}

class CoupleService {
  CoupleService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    UserService? userService,
  })  : _firestore = firestore,
        _storage = storage,
        _userService = userService ?? UserService();

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;
  final UserService _userService;
  final Uuid _uuid = const Uuid();

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _bucket => _storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _couplesCollection =>
      _db.collection('couples');

  Stream<Couple?> watchCouple(String coupleId) {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return Stream<Couple?>.value(null);
    }

    return _couplesCollection.doc(coupleId).snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      final remoteCouple = Couple.fromJson({
        'id': snapshot.id,
        ...snapshot.data()!,
      });
      final mergedCouple = await _mergeWithLocalCouple(remoteCouple);
      await StorageService.saveCouple(mergedCouple);
      return mergedCouple;
    });
  }

  Future<Couple?> fetchCouple(String coupleId) async {
    if (coupleId.trim().isEmpty) {
      return null;
    }

    if (isUsingFirebase) {
      await _ensureFirebaseSessionReady();
      final snapshot = await _couplesCollection.doc(coupleId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      final remoteCouple = Couple.fromJson({
        'id': snapshot.id,
        ...snapshot.data()!,
      });
      final couple = await _mergeWithLocalCouple(remoteCouple);
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
    final coupleId = isUsingFirebase ? _couplesCollection.doc().id : _uuid.v4();
    final baseCouple = Couple(
      id: coupleId,
      person1Name: person1Name.trim(),
      person2Name: person2Name.trim(),
      anniversaryDate: anniversaryDate,
      inviteCode: currentUser.inviteCode,
      memberIds: [currentUser.id],
      memberCount: 1,
      createdByUserId: currentUser.id,
      status: 'waiting_partner',
      createdAt: now,
      updatedAt: now,
    );

    final updatedUser = currentUser.copyWith(
      coupleId: baseCouple.id,
      status: 'waiting_partner',
      updatedAt: now,
      lastSeenAt: now,
    );

    if (isUsingFirebase) {
      try {
        await _ensureFirebaseSessionReady();
        await _couplesCollection.doc(baseCouple.id).set(baseCouple.toFirestore());
        await _userService.updateUserProfile(updatedUser);
      } on FirebaseException catch (e) {
        throw CoupleException(_mapFirebaseError(e));
      }
    }

    final photoAttempt = await _syncCouplePhoto(
      coupleId: coupleId,
      sourcePath: photoPath,
      existingCouple: baseCouple,
    );

    final couple = baseCouple.copyWith(
      couplePhotoPath: photoAttempt.result.localPath,
      couplePhotoUrl: photoAttempt.result.remoteUrl,
      couplePhotoStoragePath: photoAttempt.result.storagePath,
      updatedAt: photoAttempt.warningMessage == null && photoPath?.trim().isNotEmpty == true
          ? DateTime.now()
          : baseCouple.updatedAt,
    );

    if (isUsingFirebase && _hasRemotePhotoChanges(baseCouple, couple)) {
      try {
        await _ensureFirebaseSessionReady();
        await _couplesCollection.doc(couple.id).set(
              couple.toFirestoreUpdate(),
              SetOptions(merge: true),
            );
      } on FirebaseException catch (e) {
        throw CoupleException(_mapFirebaseError(e));
      }
    }

    await StorageService.saveCouple(couple);

    return CoupleActionResult(
      couple: couple,
      updatedUser: updatedUser,
      warningMessage: photoAttempt.warningMessage,
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
    final photoAttempt = await _syncCouplePhoto(
      coupleId: existingCouple.id,
      sourcePath: photoPath,
      existingCouple: existingCouple,
    );

    final updatedCouple = existingCouple.copyWith(
      person1Name: person1Name.trim(),
      person2Name: person2Name.trim(),
      anniversaryDate: anniversaryDate,
      couplePhotoPath: photoAttempt.result.localPath,
      couplePhotoUrl: photoAttempt.result.remoteUrl,
      couplePhotoStoragePath: photoAttempt.result.storagePath,
      updatedAt: now,
    );

    if (isUsingFirebase && updatedCouple.id.isNotEmpty) {
      try {
        await _ensureFirebaseSessionReady();
        await _couplesCollection.doc(updatedCouple.id).set(
              updatedCouple.toFirestoreUpdate(),
              SetOptions(merge: true),
            );
      } on FirebaseException catch (e) {
        throw CoupleException(_mapFirebaseError(e));
      }
    }

    await StorageService.saveCouple(updatedCouple);

    return CoupleActionResult(
      couple: updatedCouple,
      updatedUser: currentUser.copyWith(updatedAt: now, lastSeenAt: now),
      message: 'Đã cập nhật thông tin cặp đôi.',
      warningMessage: photoAttempt.warningMessage,
    );
  }

  Future<CoupleActionResult> joinCoupleByCode({
    required AppUser currentUser,
    required String inviteCode,
  }) async {
    // Block only users who are actively paired with a partner
    if (currentUser.hasCouple && currentUser.status == 'in_couple') {
      throw const CoupleException('Tài khoản này đã thuộc một cặp đôi rồi.');
    }

    final normalizedCode = inviteCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw const CoupleException('Bạn hãy nhập mã kết nối trước nhé.');
    }

    if (normalizedCode == currentUser.inviteCode.trim().toUpperCase()) {
      throw const CoupleException('Bạn không thể nhập mã mời của chính mình.');
    }

    // If user already created a solo couple (waiting_partner), leave it first
    AppUser effectiveUser = currentUser;
    if (currentUser.hasCouple && currentUser.status == 'waiting_partner') {
      effectiveUser = await leaveCouple(currentUser: currentUser);
    }

    if (isUsingFirebase) {
      try {
        await _ensureFirebaseSessionReady();

        final accountInvite = await _userService.fetchAccountInvite(normalizedCode);
        if (accountInvite == null) {
          throw const CoupleException('Mã mời không hợp lệ hoặc không còn tồn tại.');
        }

        if (accountInvite.userId == effectiveUser.id) {
          throw const CoupleException('Bạn không thể dùng mã mời của chính mình.');
        }

        final targetCoupleId = accountInvite.coupleId?.trim() ?? '';
        if (targetCoupleId.isEmpty) {
          throw const CoupleException(
            'Người ấy đã có mã mời riêng nhưng chưa tạo không gian cặp đôi để bạn tham gia.',
          );
        }

        final docRef = _couplesCollection.doc(targetCoupleId);
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

          if (!currentCouple.memberIds.contains(accountInvite.userId)) {
            throw const CoupleException('Mã mời này không còn trỏ tới một cặp đôi hợp lệ nữa.');
          }

          if (currentCouple.memberIds.contains(effectiveUser.id)) {
            throw const CoupleException('Bạn đã ở trong cặp đôi này rồi.');
          }

          if (currentCouple.memberCount >= 2) {
            throw const CoupleException('Cặp đôi này đã đủ 2 người rồi.');
          }

          final now = DateTime.now();
          final newMemberIds = [...currentCouple.memberIds, effectiveUser.id];
          updatedCouple = currentCouple.copyWith(
            memberIds: newMemberIds,
            memberCount: newMemberIds.length,
            status: newMemberIds.length >= 2 ? 'active' : 'waiting_partner',
            updatedAt: now,
            person2Name: currentCouple.person2Name.trim().isEmpty
                ? effectiveUser.displayName
                : currentCouple.person2Name,
          );
          updatedUser = effectiveUser.copyWith(
            coupleId: currentCouple.id,
            status: 'in_couple',
            updatedAt: now,
            lastSeenAt: now,
          );

          transaction.set(
            docRef,
            updatedCouple.toFirestoreUpdate(),
            SetOptions(merge: true),
          );
          transaction.set(
            _db.collection('users').doc(currentUser.id),
            updatedUser.toFirestoreUpdate(),
            SetOptions(merge: true),
          );
        });

        await StorageService.saveCouple(updatedCouple);
        return CoupleActionResult(
          couple: updatedCouple,
          updatedUser: updatedUser,
          message: 'Hai bạn đã kết nối thành công rồi 💞',
        );
      } on FirebaseException catch (e) {
        switch (e.code) {
          case 'permission-denied':
            throw const CoupleException(
              'Firestore đang từ chối đọc mã mời. App này đang kết nối project Firebase `tonyembeiu`, nên bạn cần deploy `firestore.rules` lên đúng project đó rồi thử lại.',
            );
          case 'unavailable':
            throw const CoupleException(
              'Firestore hiện chưa khả dụng hoặc mạng chưa ổn định. Bạn thử lại sau ít phút nhé.',
            );
          default:
            throw CoupleException(e.message ?? 'Không thể kết nối bằng mã mời lúc này.');
        }
      }
    }

    final localCouple = await StorageService.loadCouple();
    if (localCouple == null || localCouple.inviteCode != normalizedCode) {
      throw const CoupleException('Không tìm thấy mã kết nối trong local fallback.');
    }

    if (localCouple.memberCount >= 2) {
      throw const CoupleException('Cặp đôi local này đã đủ 2 người rồi.');
    }

    final now = DateTime.now();
    final newMemberIds = [...localCouple.memberIds, effectiveUser.id];
    final updatedLocalCouple = localCouple.copyWith(
      memberIds: newMemberIds,
      memberCount: newMemberIds.length,
      status: newMemberIds.length >= 2 ? 'active' : 'waiting_partner',
      updatedAt: now,
    );

    await StorageService.saveCouple(updatedLocalCouple);

    return CoupleActionResult(
      couple: updatedLocalCouple,
      updatedUser: effectiveUser.copyWith(
        coupleId: updatedLocalCouple.id,
        status: 'in_couple',
        updatedAt: now,
        lastSeenAt: now,
      ),
      message: 'Đã ghép cặp trong local fallback mode.',
    );
  }

  Future<AppUser> leaveCouple({required AppUser currentUser}) async {
    final now = DateTime.now();

    if (isUsingFirebase && currentUser.coupleId != null) {
      try {
        await _ensureFirebaseSessionReady();
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
            await _cleanupCoupleSharedData(currentCouple);
            await docRef.delete();
          } else {
            final updatedCouple = currentCouple.copyWith(
              memberIds: remainingMembers,
              memberCount: remainingMembers.length,
              status: 'waiting_partner',
              updatedAt: now,
            );
            await docRef.set(updatedCouple.toFirestoreUpdate(), SetOptions(merge: true));
          }
        }
      } on FirebaseException catch (e) {
        throw CoupleException(_mapFirebaseError(e));
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

  Future<void> _cleanupCoupleSharedData(Couple couple) async {
    if (!isUsingFirebase || couple.id.trim().isEmpty) {
      return;
    }

    final photosSnapshot = await _couplesCollection
        .doc(couple.id)
        .collection('photos')
        .get();

    await Future.wait([
      _deleteStorageObjectIfNeeded(couple.couplePhotoStoragePath),
      for (final photoDoc in photosSnapshot.docs) ...[
        _deleteStorageObjectIfNeeded(
          (photoDoc.data()['storagePath'] as String?)?.trim(),
        ),
        photoDoc.reference.delete(),
      ],
    ]);
  }

  Future<void> _deleteStorageObjectIfNeeded(String? storagePath) async {
    final normalizedPath = storagePath?.trim();
    if (normalizedPath == null || normalizedPath.isEmpty) {
      return;
    }

    try {
      await _bucket.ref(normalizedPath).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  Future<CouplePhotoSyncAttempt> _syncCouplePhoto({
    required String coupleId,
    String? sourcePath,
    Couple? existingCouple,
  }) async {
    final trimmedPath = sourcePath?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return CouplePhotoSyncAttempt(
        result: CouplePhotoSyncResult(
          localPath: existingCouple?.couplePhotoPath,
          remoteUrl: existingCouple?.couplePhotoUrl,
          storagePath: existingCouple?.couplePhotoStoragePath,
        ),
      );
    }

    final file = File(trimmedPath);
    if (!await file.exists()) {
      return CouplePhotoSyncAttempt(
        result: CouplePhotoSyncResult(
          localPath: existingCouple?.couplePhotoPath ?? trimmedPath,
          remoteUrl: existingCouple?.couplePhotoUrl,
          storagePath: existingCouple?.couplePhotoStoragePath,
        ),
      );
    }

    final savedPath = await StorageService.savePhotoFile(trimmedPath);

    if (!isUsingFirebase) {
      return CouplePhotoSyncAttempt(
        result: CouplePhotoSyncResult(
          localPath: savedPath ?? existingCouple?.couplePhotoPath ?? trimmedPath,
          remoteUrl: existingCouple?.couplePhotoUrl,
          storagePath: existingCouple?.couplePhotoStoragePath,
        ),
      );
    }

    final shouldReuseRemote =
        existingCouple != null &&
        trimmedPath == existingCouple.couplePhotoPath &&
        existingCouple.couplePhotoUrl?.trim().isNotEmpty == true;
    if (shouldReuseRemote) {
      return CouplePhotoSyncAttempt(
        result: CouplePhotoSyncResult(
          localPath: savedPath ?? existingCouple.couplePhotoPath,
          remoteUrl: existingCouple.couplePhotoUrl,
          storagePath: existingCouple.couplePhotoStoragePath,
        ),
      );
    }

    final extension = _guessFileExtension(trimmedPath);
    final storagePath = 'couple_photos/$coupleId/cover_$coupleId$extension';
    try {
      final uploadTask = await _bucket.ref(storagePath).putFile(file);
      final remoteUrl = await uploadTask.ref.getDownloadURL();

      return CouplePhotoSyncAttempt(
        result: CouplePhotoSyncResult(
          localPath: savedPath ?? existingCouple?.couplePhotoPath ?? trimmedPath,
          remoteUrl: remoteUrl,
          storagePath: storagePath,
        ),
      );
    } on FirebaseException catch (e) {
      return CouplePhotoSyncAttempt(
        result: CouplePhotoSyncResult(
          localPath: savedPath ?? existingCouple?.couplePhotoPath ?? trimmedPath,
          remoteUrl: existingCouple?.couplePhotoUrl,
          storagePath: existingCouple?.couplePhotoStoragePath,
        ),
        warningMessage: _mapPhotoSyncError(e),
      );
    }
  }

  bool _hasRemotePhotoChanges(Couple previous, Couple next) {
    return previous.couplePhotoUrl != next.couplePhotoUrl ||
        previous.couplePhotoStoragePath != next.couplePhotoStoragePath;
  }

  Future<void> _ensureFirebaseSessionReady() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw const CoupleException(
        'Phiên đăng nhập Firebase chưa sẵn sàng. Bạn đăng xuất rồi đăng nhập lại giúp mình nhé.',
      );
    }
    await currentUser.getIdToken();
  }

  String _mapFirebaseError(FirebaseException exception) {
    switch (exception.code) {
      case 'permission-denied':
        return 'Firestore đang chặn thao tác với dữ liệu cặp đôi. App này đang kết nối project Firebase `tonyembeiu`, nên bạn cần kiểm tra/deploy lại `firestore.rules` của đúng project đó rồi thử lại.';
      case 'unauthenticated':
        return 'Phiên đăng nhập Firebase không còn hợp lệ. Bạn đăng nhập lại giúp mình nhé.';
      case 'unavailable':
        return 'Firebase hiện chưa khả dụng hoặc mạng chưa ổn định. Bạn thử lại sau ít phút nhé.';
      default:
        return exception.message ?? 'Không thể lưu thông tin cặp đôi lúc này.';
    }
  }

  String _mapPhotoSyncError(FirebaseException exception) {
    switch (exception.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Ảnh đôi chưa upload được lên Firebase Storage. Mình vẫn lưu thông tin cặp đôi trước, bạn deploy `storage.rules` rồi thử đổi ảnh lại sau nhé.';
      case 'unauthenticated':
        return 'Ảnh đôi chưa upload được vì phiên đăng nhập Firebase không còn hợp lệ.';
      case 'unavailable':
        return 'Ảnh đôi chưa upload được vì Firebase Storage hoặc mạng đang tạm thời không ổn định.';
      default:
        return exception.message ?? 'Ảnh đôi chưa upload được lên Firebase Storage.';
    }
  }

  Future<Couple> _mergeWithLocalCouple(Couple remoteCouple) async {
    final localCouple = await StorageService.loadCouple();
    if (localCouple == null || localCouple.id != remoteCouple.id) {
      return remoteCouple;
    }

    final shouldKeepLocalPath =
        remoteCouple.couplePhotoPath?.trim().isEmpty != false &&
        localCouple.couplePhotoPath?.trim().isNotEmpty == true;

    return remoteCouple.copyWith(
      couplePhotoPath: shouldKeepLocalPath
          ? localCouple.couplePhotoPath
          : remoteCouple.couplePhotoPath,
      couplePhotoUrl: remoteCouple.couplePhotoUrl?.trim().isNotEmpty == true
          ? remoteCouple.couplePhotoUrl
          : localCouple.couplePhotoUrl,
      couplePhotoStoragePath:
          remoteCouple.couplePhotoStoragePath?.trim().isNotEmpty == true
              ? remoteCouple.couplePhotoStoragePath
              : localCouple.couplePhotoStoragePath,
    );
  }

  String _guessFileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return '.jpg';
    }

    final extension = path.substring(dotIndex).toLowerCase();
    if (extension.length > 6) {
      return '.jpg';
    }

    return extension;
  }

}

class CouplePhotoSyncResult {
  const CouplePhotoSyncResult({
    this.localPath,
    this.remoteUrl,
    this.storagePath,
  });

  final String? localPath;
  final String? remoteUrl;
  final String? storagePath;
}

class CouplePhotoSyncAttempt {
  const CouplePhotoSyncAttempt({
    required this.result,
    this.warningMessage,
  });

  final CouplePhotoSyncResult result;
  final String? warningMessage;
}

