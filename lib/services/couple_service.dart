import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_l10n.dart';
import '../models/account_invite.dart';
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
  const CoupleException(this.message, {this.code});

  final String message;

  /// Optional stable, locale-independent reason. Used by callers (e.g. the
  /// analytics layer) to bucket failures without parsing the localized
  /// [message]. Null for throws that predate this tagging.
  final CoupleErrorCode? code;

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
  // Default region (us-central1) matches the deployed couple callables.
  FirebaseFunctions get _functions => FirebaseFunctions.instance;

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
      // Robustness (app-robustness A5): bound the cold-start couple fetch so a
      // slow/offline Firestore can't freeze route resolution. On timeout fall
      // back to the locally cached couple (the realtime watcher in
      // CoupleProvider reconciles to the authoritative server copy once it's
      // reachable), so the user still lands on home immediately.
      try {
        await _ensureFirebaseSessionReady();
        final snapshot = await _couplesCollection
            .doc(coupleId)
            .get()
            .timeout(const Duration(seconds: 5));
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
      } on TimeoutException {
        final cached = await StorageService.loadCouple();
        return cached?.id == coupleId ? cached : null;
      }
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
      throw CoupleException(AppL10n.strings.coupleUserNotFoundForCreate);
    }

    // The couple `create` rule checks createdByUserId/memberIds[0] against
    // request.auth.uid, and the user write checks request.auth.uid == userId.
    // When using Firebase, build everything from the AUTHORITATIVE auth uid
    // (not the possibly-stale local user id) so those checks can't fail.
    final authUid = isUsingFirebase
        ? FirebaseAuth.instance.currentUser?.uid
        : currentUser.id;
    if (isUsingFirebase && (authUid == null || authUid.isEmpty)) {
      throw CoupleException(AppL10n.strings.coupleSessionNotReadyRelogin);
    }
    final memberId = authUid ?? currentUser.id;

    final now = DateTime.now();
    final coupleId = isUsingFirebase ? _couplesCollection.doc().id : _uuid.v4();
    // Generate a fresh couple-level entry code, distinct from the personal
    // inviteCode. This code is shared with the partner and allows both to
    // rejoin after leave without the personal code being reset or reused.
    final coupleCode = await _generateCoupleCode();
    final baseCouple = Couple(
      id: coupleId,
      person1Name: person1Name.trim(),
      person2Name: person2Name.trim(),
      anniversaryDate: anniversaryDate,
      inviteCode: currentUser.inviteCode,
      coupleCode: coupleCode,
      memberIds: [memberId],
      memberCount: 1,
      createdByUserId: memberId,
      status: 'waiting_partner',
      createdAt: now,
      updatedAt: now,
    );

    final updatedUser = currentUser.copyWith(
      id: memberId,
      coupleId: baseCouple.id,
      status: 'waiting_partner',
      updatedAt: now,
      lastSeenAt: now,
    );

    if (isUsingFirebase) {
      try {
        await _ensureFirebaseSessionReady();
        await _couplesCollection.doc(baseCouple.id).set(baseCouple.toFirestore());
        await _userService.updateCoupleMembership(updatedUser);
        // Write couple_codes entry so partner (or creator rejoining) can look
        // up the couple by the shared code instead of the personal inviteCode.
        // Best-effort: a couple_codes write failure must not roll back the couple.
        try {
          await _userService.createCoupleCodeEntry(coupleCode, coupleId);
        } catch (_) {
          // Ignore — couple already created; code entry will be missing but the
          // old invite_codes fallback in joinCoupleByCode still works.
        }
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
      await _runCoupleWriteWithRecovery(
        () async {
          await _ensureFirebaseSessionReady();
          // Profile edit (photo only): never re-send structural/immutable
          // fields — merge keeps the server's, so `isCoupleProfileEdit` passes.
          await _couplesCollection.doc(couple.id).set(
                couple.toPhotoEditPayload(),
                SetOptions(merge: true),
              );
        },
        coupleId: couple.id,
      );
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
      await _runCoupleWriteWithRecovery(
        () async {
          await _ensureFirebaseSessionReady();
          // Profile edit: send ONLY the user-editable fields. Omitting
          // memberIds/memberCount/status/inviteCode/createdByUserId/createdAt
          // lets merge preserve the server's, so the `isCoupleProfileEdit`
          // equality checks pass even if the local couple copy is stale.
          await _couplesCollection.doc(updatedCouple.id).set(
                updatedCouple.toProfileEditPayload(),
                SetOptions(merge: true),
              );
        },
        coupleId: updatedCouple.id,
      );
    }

    await StorageService.saveCouple(updatedCouple);

    return CoupleActionResult(
      couple: updatedCouple,
      updatedUser: currentUser.copyWith(updatedAt: now, lastSeenAt: now),
      message: AppL10n.strings.coupleUpdatedSuccess,
      warningMessage: photoAttempt.warningMessage,
    );
  }

  Future<CoupleActionResult> joinCoupleByCode({
    required AppUser currentUser,
    required String inviteCode,
  }) async {
    // Block only users who are actively paired with a partner
    if (currentUser.hasCouple && currentUser.status == 'in_couple') {
      throw CoupleException(
        AppL10n.strings.coupleAlreadyInCouple,
        code: CoupleErrorCode.alreadyHasCouple,
      );
    }

    final normalizedCode = inviteCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw CoupleException(AppL10n.strings.coupleEnterCodeFirst);
    }

    if (normalizedCode == currentUser.inviteCode.trim().toUpperCase()) {
      throw CoupleException(AppL10n.strings.coupleCannotUseOwnCode);
    }

    // If user already created a solo couple (waiting_partner), leave it first
    AppUser effectiveUser = currentUser;
    if (currentUser.hasCouple && currentUser.status == 'waiting_partner') {
      effectiveUser = await leaveCouple(currentUser: currentUser);
    }

    if (isUsingFirebase) {
      try {
        await _ensureFirebaseSessionReady();

        // The join transition rule checks request.auth.uid is in the NEW
        // memberIds, and the user write checks request.auth.uid == userId.
        // Use the authoritative auth uid for the joiner's member id and user
        // doc so a stale local id can't trip those checks.
        final authUid = FirebaseAuth.instance.currentUser?.uid;
        if (authUid == null || authUid.isEmpty) {
          throw CoupleException(AppL10n.strings.coupleSessionNotReadyRelogin);
        }

        // Double-lookup: try couple_codes first (new flow — no personal
        // ownership check needed since the code is couple-level). Fall back to
        // invite_codes for backward compatibility with couples created before
        // this feature was deployed.
        var isNewCoupleCodeFlow = false;
        AccountInvite? accountInvite;
        late final String targetCoupleId;

        final coupleCodeCoupleId =
            await _userService.fetchCoupleCodeEntry(normalizedCode);
        if (coupleCodeCoupleId != null &&
            coupleCodeCoupleId.trim().isNotEmpty) {
          targetCoupleId = coupleCodeCoupleId.trim();
          isNewCoupleCodeFlow = true;
        } else {
          // Backward compat: look up invite_codes (old personal-code couples).
          accountInvite =
              await _userService.fetchAccountInvite(normalizedCode);
          if (accountInvite == null) {
            throw CoupleException(
              AppL10n.strings.coupleInviteCodeInvalid,
              code: CoupleErrorCode.inviteNotFound,
            );
          }
          if (accountInvite.userId == authUid) {
            throw CoupleException(AppL10n.strings.coupleCannotUseOwnCode);
          }
          final rawCoupleId = accountInvite.coupleId?.trim() ?? '';
          if (rawCoupleId.isEmpty) {
            throw CoupleException(AppL10n.strings.couplePartnerHasNoSpace);
          }
          targetCoupleId = rawCoupleId;
        }

        final docRef = _couplesCollection.doc(targetCoupleId);
        late Couple updatedCouple;
        late AppUser updatedUser;

        // Auto-recovery: if the join transaction is rejected with
        // permission-denied (e.g. a stale ID token), refresh the token once and
        // re-run. The transaction re-reads the couple and re-checks every guard
        // on each attempt, so re-running is safe and idempotent; the boolean
        // guard caps it at a single retry (no loop / recursion).
        var joinRecovered = false;
        Future<void> runJoinTransaction() => _db.runTransaction((transaction) async {
          final coupleSnapshot = await transaction.get(docRef);
          final coupleData = coupleSnapshot.data();
          if (coupleData == null) {
            throw CoupleException(AppL10n.strings.coupleNotFoundForCode);
          }

          final currentCouple = Couple.fromJson({
            'id': coupleSnapshot.id,
            ...coupleData,
          });

          // For the old invite_codes flow, verify the creator is still a
          // member (guards against the code pointing to a stale couple after
          // the creator left). Skip this check for the new couple_codes flow
          // because there is no single "owner" to verify.
          if (!isNewCoupleCodeFlow &&
              accountInvite != null &&
              !currentCouple.memberIds.contains(accountInvite.userId)) {
            throw CoupleException(
              AppL10n.strings.coupleCodeNoLongerValid,
              code: CoupleErrorCode.inviteNotFound,
            );
          }

          if (currentCouple.memberIds.contains(authUid)) {
            throw CoupleException(
              AppL10n.strings.coupleAlreadyInThisCouple,
              code: CoupleErrorCode.alreadyInThis,
            );
          }

          if (currentCouple.memberCount >= 2) {
            throw CoupleException(AppL10n.strings.coupleFull);
          }

          // Guard against stale/incomplete couple docs that the security rules
          // would reject on write — e.g. an older doc missing `createdAt` (the
          // one field the join write omits and relies on merge to preserve) or
          // a doc whose memberCount/memberIds are inconsistent. Failing here
          // gives a clear, actionable message instead of a cryptic
          // permission-denied. The joiner can't repair the other account's
          // invite pointer, so we ask them to regenerate the code.
          final storedMemberIds = (coupleData['memberIds'] as List?) ?? const [];
          final targetIsJoinable = coupleData['createdAt'] != null &&
              (coupleData['memberCount'] as num?)?.toInt() == 1 &&
              storedMemberIds.length == 1 &&
              currentCouple.status == 'waiting_partner' &&
              currentCouple.createdByUserId.trim().isNotEmpty &&
              currentCouple.inviteCode.trim().isNotEmpty;
          if (!targetIsJoinable) {
            throw CoupleException(AppL10n.strings.coupleSpaceInvalidRegenerate);
          }

          final now = DateTime.now();
          final newMemberIds = [...currentCouple.memberIds, authUid];
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
            id: authUid,
            coupleId: currentCouple.id,
            status: 'in_couple',
            updatedAt: now,
            lastSeenAt: now,
          );

          // The couple write is a JOIN TRANSITION: it MUST change
          // memberIds/memberCount/status, so it keeps toFirestoreUpdate()
          // (rule isCoupleJoinTransition requires the new structural values).
          transaction.set(
            docRef,
            updatedCouple.toFirestoreUpdate(),
            SetOptions(merge: true),
          );
          // The user write is a membership change: send ONLY coupleId/status/
          // updatedAt/lastSeenAt so the immutable email/inviteCode equality
          // checks in canUpdateOwnUser pass via merge. Write to users/{authUid}.
          transaction.set(
            _db.collection('users').doc(authUid),
            updatedUser.toCoupleMembershipPayload(),
            SetOptions(merge: true),
          );
        });

        try {
          await runJoinTransaction();
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied' && !joinRecovered) {
            joinRecovered = true;
            try {
              await FirebaseAuth.instance.currentUser?.getIdToken(true);
            } catch (_) {
              // Token refresh failed; the retry re-evaluates as before.
            }
            await runJoinTransaction(); // single retry — guard prevents a loop
          } else {
            rethrow;
          }
        }

        // Keep the joiner's own invite_codes pointer consistent with their new
        // couple. The transaction writes the user doc directly (bypassing the
        // invite sync), so without this the joiner's code could linger pointing
        // at their old, now-deleted solo couple. Use the narrow membership
        // write (re-syncs the invite pointer without re-sending immutable
        // email/inviteCode). Best-effort: a successful join must not fail just
        // because this housekeeping write does.
        try {
          await _userService.updateCoupleMembership(updatedUser);
        } catch (_) {
          // Ignore — the pairing already succeeded; the pointer will be
          // re-synced on the next profile update.
        }

        await StorageService.saveCouple(updatedCouple);
        return CoupleActionResult(
          couple: updatedCouple,
          updatedUser: updatedUser,
          message: AppL10n.strings.setupSuccessConnected,
        );
      } on FirebaseException catch (e) {
        switch (e.code) {
          case 'permission-denied':
            throw CoupleException(AppL10n.strings.coupleJoinPermissionDenied);
          case 'unauthenticated':
            throw CoupleException(AppL10n.strings.coupleSessionExpiredJoin);
          case 'unavailable':
            throw CoupleException(AppL10n.strings.coupleFirebaseUnavailable);
          default:
            throw CoupleException(e.message ?? AppL10n.strings.coupleJoinGeneric);
        }
      }
    }

    final localCouple = await StorageService.loadCouple();
    if (localCouple == null || localCouple.inviteCode != normalizedCode) {
      throw CoupleException(
        AppL10n.strings.coupleCodeNotFoundLocal,
        code: CoupleErrorCode.inviteNotFound,
      );
    }

    if (localCouple.memberCount >= 2) {
      throw CoupleException(AppL10n.strings.coupleFullLocal);
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
      message: AppL10n.strings.coupleMatchedLocal,
    );
  }

  /// Clears a stale coupleId from the user doc when permission-denied is
  /// detected on couple load (user removed from couple, or couple deleted).
  /// Best-effort — callers must not fail if this throws.
  Future<void> clearStaleCoupleRef(AppUser user) async {
    if (!isUsingFirebase) return;
    final cleared = user.copyWith(
      coupleId: null,
      status: 'single',
      updatedAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );
    await _userService.updateCoupleMembership(cleared);
    await StorageService.clearCouple();
  }

  Future<AppUser> leaveCouple({required AppUser currentUser}) async {
    final now = DateTime.now();

    if (isUsingFirebase && currentUser.coupleId != null) {
      // The leave-transition rule requires the AUTH uid to be the one removed
      // from memberIds (!(request.auth.uid in request.resource.data.memberIds)).
      // Use the authoritative auth uid (not the possibly-stale local id) when
      // computing remaining members so the write can't be rejected.
      final authUid =
          FirebaseAuth.instance.currentUser?.uid ?? currentUser.id;
      try {
        await _runCoupleWriteWithRecovery(
          () async {
            await _ensureFirebaseSessionReady();
            final docRef = _couplesCollection.doc(currentUser.coupleId);
            // Re-read the authoritative couple before each (re)try so the
            // leave write is built from fresh server structural fields.
            final snapshot = await docRef.get();

            if (snapshot.exists && snapshot.data() != null) {
              final currentCouple = Couple.fromJson({
                'id': snapshot.id,
                ...snapshot.data()!,
              });
              final remainingMembers = currentCouple.memberIds
                  .where((memberId) => memberId != authUid)
                  .toList();

              if (remainingMembers.isEmpty) {
                // Sole member leaving → the couple is destroyed. Route through
                // the server-side callable so the admin SDK recursively deletes
                // EVERY subcollection (photos+reactions, notes, noteHistory,
                // dailyAnswers) + couple_codes with no orphans. The old client
                // cleanup could only reach photos + couple_codes.
                try {
                  await _functions
                      .httpsCallable('leaveCoupleCleanup')
                      .call<dynamic>(<String, dynamic>{'coupleId': currentCouple.id});
                } catch (_) {
                  // Fallback: callable unavailable (transient CF error). Do a
                  // best-effort client teardown so the user can still leave —
                  // may orphan notes/dailyAnswers, swept later by the next
                  // account-deletion teardown.
                  await _cleanupCoupleSharedData(currentCouple);
                  await docRef.delete();
                }
              } else {
                final updatedCouple = currentCouple.copyWith(
                  memberIds: remainingMembers,
                  memberCount: remainingMembers.length,
                  status: 'waiting_partner',
                  updatedAt: now,
                );
                // Leave TRANSITION: must change memberIds/memberCount/status,
                // so it keeps toFirestoreUpdate() (rule isCoupleLeaveTransition
                // requires the new structural values).
                await docRef.set(
                  updatedCouple.toFirestoreUpdate(),
                  SetOptions(merge: true),
                );
                // Bug fix: the remaining member's user doc still has
                // status='in_couple' because only the leaver's doc is updated
                // by updateCoupleMembership below. Reset the remaining member
                // to 'waiting_partner' so they can accept a new partner join.
                final remainingUid = remainingMembers.first;
                try {
                  await _db.collection('users').doc(remainingUid).set(
                    {
                      'status': 'waiting_partner',
                      'updatedAt': now,
                    },
                    SetOptions(merge: true),
                  );
                } catch (_) {
                  // Best-effort — the couple update already succeeded; the
                  // remaining member's status will correct itself on next login.
                }
              }
            }
          },
          coupleId: currentUser.coupleId,
        );
      } on CoupleException {
        rethrow;
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
      // Membership change: narrow write so immutable email/inviteCode checks
      // in canUpdateOwnUser pass via merge.
      await _userService.updateCoupleMembership(updatedUser);
    }

    await StorageService.clearCouple();
    return updatedUser;
  }

  Future<void> _cleanupCoupleSharedData(Couple couple) async {
    if (!isUsingFirebase || couple.id.trim().isEmpty) {
      return;
    }

    // Remove the couple_codes entry BEFORE deleting the couple doc: the
    // couple_codes delete rule verifies the couple still exists and that the
    // requester is a member, so the couple doc must be present at this point.
    if (couple.coupleCode != null && couple.coupleCode!.isNotEmpty) {
      await _userService.deleteCoupleCodeEntry(couple.coupleCode!);
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
      throw CoupleException(AppL10n.strings.coupleSessionNotReadyRelogin);
    }
    await currentUser.getIdToken();
  }

  /// Runs a couple write, and on a `permission-denied` FirebaseException tries
  /// to self-heal ONCE before surfacing the error:
  ///   1. force-refresh the auth ID token (covers a stale/expired token whose
  ///      claims the rules evaluated against);
  ///   2. re-fetch the authoritative couple doc from the server and reconcile
  ///      the local cache (so the next attempt builds its payload from fresh
  ///      structural fields instead of a stale local copy);
  ///   3. retry [action] exactly once.
  /// A boolean guard (`_recovered`) makes this strictly single-shot — there is
  /// no recursion and no loop, so the worst case is two attempts total. If the
  /// retry still fails (or the failure isn't permission-denied) the original
  /// `_mapFirebaseError` message is thrown, unchanged.
  ///
  /// [coupleId] is the doc to reconcile; pass null/empty to skip the re-fetch
  /// (e.g. createCouple, where the doc doesn't exist on the server yet).
  Future<T> _runCoupleWriteWithRecovery<T>(
    Future<T> Function() action, {
    String? coupleId,
  }) async {
    var recovered = false;
    while (true) {
      try {
        return await action();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied' && !recovered) {
          recovered = true;
          await _attemptPermissionRecovery(coupleId);
          continue; // single retry — guard prevents any further loop
        }
        throw CoupleException(_mapFirebaseError(e));
      }
    }
  }

  /// Best-effort self-heal before a single write retry: refresh the auth token
  /// and pull the authoritative couple from the server into the local cache.
  /// Any error here is swallowed — recovery is opportunistic and must not mask
  /// the original permission-denied if it can't help.
  Future<void> _attemptPermissionRecovery(String? coupleId) async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      // Token refresh failed; the retry will simply re-evaluate as before.
    }

    final id = coupleId?.trim();
    if (id == null || id.isEmpty) {
      return;
    }

    try {
      final snapshot = await _couplesCollection.doc(id).get();
      if (snapshot.exists && snapshot.data() != null) {
        final authoritative = Couple.fromJson({
          'id': snapshot.id,
          ...snapshot.data()!,
        });
        await StorageService.saveCouple(authoritative);
      }
    } catch (_) {
      // Re-fetch/reconcile failed; the retry uses whatever local state exists.
    }
  }

  String _mapFirebaseError(FirebaseException exception) {
    final l10n = AppL10n.strings;
    switch (exception.code) {
      case 'permission-denied':
        return l10n.coupleSavePermissionDenied;
      case 'unauthenticated':
        return l10n.coupleSessionInvalid;
      case 'unavailable':
        return l10n.coupleFirebaseUnavailable;
      default:
        return exception.message ?? l10n.coupleSaveGeneric;
    }
  }

  String _mapPhotoSyncError(FirebaseException exception) {
    final l10n = AppL10n.strings;
    switch (exception.code) {
      case 'unauthorized':
      case 'permission-denied':
        return l10n.couplePhotoUploadPermission;
      case 'unauthenticated':
        return l10n.couplePhotoUploadSessionInvalid;
      case 'unavailable':
        return l10n.couplePhotoUploadUnavailable;
      default:
        return exception.message ?? l10n.couplePhotoUploadGeneric;
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

  /// Generate a unique 6-character couple entry code (distinct from the
  /// personal inviteCode). Uses a secure random source and checks
  /// couple_codes for collisions on up to 10 attempts before giving up.
  Future<String> _generateCoupleCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    for (var attempt = 0; attempt < 10; attempt++) {
      final code = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
      if (isUsingFirebase) {
        final existing = await _db.collection('couple_codes').doc(code).get();
        if (!existing.exists) {
          return code;
        }
      } else {
        return code;
      }
    }
    // Fallback: return a final random code even if we can't verify uniqueness.
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
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

