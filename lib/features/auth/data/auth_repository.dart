import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Register parent
  Future<UserModel> registerParent({
    required String email,
    required String password,
    required String name,
    required String phone,
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

    await _firestore.collection('users').doc(userId).set(userModel.toMap());
    await _firestore.collection('parents').doc(userId).set({
      'name': name,
      'phone': phone,
    });

    return userModel;
  }

  // Register therapist
  Future<UserModel> registerTherapist({
    required String email,
    required String password,
    required String name,
    required String licenceNumber,
    required String clinicName,
    required String specialisation,
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

    await _firestore.collection('users').doc(userId).set(userModel.toMap());
    await _firestore.collection('therapists').doc(userId).set({
      'name': name,
      'licenceNumber': licenceNumber,
      'clinicName': clinicName,
      'specialisation': specialisation,
    });

    return userModel;
  }

  // Login
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

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Forgot password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get user role
  Future<String> getUserRole(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['role'] ?? '';
  }
}