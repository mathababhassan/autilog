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
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, user.uid);
    });
  }

  // ── Register parent ───────────────────────────────────────────────────────
  // Child info is NOT collected here — it is added separately via addChild()
  // after the parent completes the ChildRegistrationScreen.
  Future<UserModel> registerParent({
    required String email,
    required String password,
    required String name,
    String? gender,
    String? profilePhotoPath,
  }) async {
    // 1. Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final userId = credential.user!.uid;

    // 2. Build the shared UserModel (role = 'parent')
    final userModel = UserModel(
      userId: userId,
      email: email,
      role: 'parent',
      createdAt: DateTime.now(),
    );

    // 3. Batched Firestore write
    final batch = _firestore.batch();

    // /users/{uid} — shared auth document
    batch.set(
      _firestore.collection('users').doc(userId),
      userModel.toMap(),
    );

    // /parents/{uid} — parent profile
    batch.set(
      _firestore.collection('parents').doc(userId),
      {
        'name': name,
        'gender': gender,
        'profilePhotoPath': profilePhotoPath,
      },
    );

    await batch.commit();

    return userModel;
  }

  // ── Add child ─────────────────────────────────────────────────────────────
  // Called by ChildRegistrationBloc after parent registration is complete.
  Future<void> addChild({
    required String parentId,
    required String name,
    required int age,
    required String asdSeverity,
  }) async {
    final childRef = _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(); // auto-generated child ID

    await childRef.set({
      'childId': childRef.id,
      'parentId': parentId,
      'name': name,
      'age': age,
      'asdSeverity': asdSeverity, // 'Level 1' | 'Level 2' | 'Level 3'
      'therapists': [],            // populated later via link-therapist feature
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
      licenceNumber: licenceNumber,
      clinicName: clinicName,
      specialisation: specialisation,
      gender: gender,
    );

    await _firestore.collection('users').doc(userId).set(userModel.toMap());
    await _firestore.collection('therapists').doc(userId).set(therapistModel.toMap());

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
}