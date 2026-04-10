import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_user.dart';

class UserService {
  UserService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isEnabled => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      (_firestore ?? FirebaseFirestore.instance).collection('users');

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

  Future<void> saveUserProfile(AppUser user) async {
    if (!isEnabled) {
      return;
    }

    await _usersCollection.doc(user.id).set(user.toFirestore());
  }

  Future<void> updateUserProfile(AppUser user) async {
    if (!isEnabled) {
      return;
    }

    await _usersCollection.doc(user.id).set(user.toFirestore(), SetOptions(merge: true));
  }
}

