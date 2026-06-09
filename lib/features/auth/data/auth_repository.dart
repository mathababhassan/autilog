import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/therapist_model.dart';
import '../../../shared/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Emits the current [UserModel] when logged in, or null when logged out.
  /// AuthBloc listens to this stream to keep the session state up to date.
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return null;
      }
      return UserModel.fromMap(doc.data()!, user.uid);
    });
  }

  // ── Register parent ───────────────────────────────────────────────────────
  Future<UserModel> registerParent({
    required String email,
    required String password,
    required String name,
    String? gender,
    String? profilePhotoBase64,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final userId = credential.user!.uid;

    final userModel = UserModel(
      userId: userId,
      email: email,
      role: 'parent',
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    batch.set(
      _firestore.collection('users').doc(userId),
      userModel.toMap(),
    );

    batch.set(
      _firestore.collection('parents').doc(userId),
      {
        'name': name,
        'gender': gender,
        'profilePhotoBase64': profilePhotoBase64,
      },
    );

    await batch.commit();

    return userModel;
  }

  // ── Add child ─────────────────────────────────────────────────────────────
  Future<String> addChild({
    required String parentId,
    required String name,
    required int age,
    required String asdSeverity,
  }) async {
    final childRef = _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc();

    await childRef.set({
    'childId': childRef.id,
    'parentId': parentId,
    'name': name,
    'age': age,
    'asdSeverity': asdSeverity,
    'therapists': [],
    'createdAt': FieldValue.serverTimestamp(),
  });

  return childRef.id;
}

  Future<void> sendLinkRequest({
    required String parentId,
    required String childId,
    required String therapistEmail,
  }) async {
    await _firestore.collection('linkRequests').add({
      'parentId': parentId,
      'childId': childId,
      'therapistEmail': therapistEmail.trim().toLowerCase(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Register therapist ────────────────────────────────────────────────────
  Future<UserModel> registerTherapist({
  required String email,
  required String password,
  required String name,
  required String licenceNumber,
  required String clinicName,
  required String specialisation,
  required String gender,
}) async {
  final credential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  final userId = credential.user!.uid;

  final userModel = UserModel(
    userId: userId,
    email: email,
    role: 'therapist',
    createdAt: DateTime.now(),
  );

  final therapistModel = TherapistModel(
    userId: userId,
    name: name,
    email: email,
    licenceNumber: licenceNumber,
    clinicName: clinicName,
    specialisation: specialisation,
    gender: gender,
  );

  // Write to Firestore first before auth state fires
  final batch = _firestore.batch();
  batch.set(_firestore.collection('users').doc(userId), userModel.toMap());
  batch.set(_firestore.collection('therapists').doc(userId), therapistModel.toMap());
  await batch.commit();

  // Send verification email after Firestore is ready
  await credential.user!.sendEmailVerification();

  return userModel;
}
  // ── Login ─────────────────────────────────────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final userId = credential.user!.uid;

    final doc = await _firestore.collection('users').doc(userId).get();
    return UserModel.fromMap(doc.data()!, userId);
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Get user role ─────────────────────────────────────────────────────────
  Future<String> getUserRole(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['role'] ?? '';
  }

  // ── Update parent profile photo (base64) ──────────────────────────────────
  Future<void> updateParentProfilePhoto({
    required String userId,
    required String base64Image,
  }) async {
    await _firestore.collection('parents').doc(userId).update({
      'profilePhotoBase64': base64Image,
    });
  }

  // ── Update child profile photo (base64) ───────────────────────────────────
  Future<void> updateChildProfilePhoto({
    required String parentId,
    required String childId,
    required String base64Image,
  }) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'profilePhotoBase64': base64Image,
    });
  }
}
