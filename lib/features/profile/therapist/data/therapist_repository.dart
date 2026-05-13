import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/therapist_model.dart';
import '../../../../shared/models/user_model.dart';

class TherapistRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<({TherapistModel therapist, UserModel user})> fetchProfile(
      String uid) async {
    final results = await Future.wait([
      _firestore.collection('therapists').doc(uid).get(),
      _firestore.collection('users').doc(uid).get(),
    ]);

    final therapistDoc = results[0];
    final userDoc = results[1];

    if (!therapistDoc.exists || !userDoc.exists) {
      throw Exception('Profile not found for uid: $uid');
    }

    return (
      therapist: TherapistModel.fromMap(therapistDoc.data()!, uid),
      user: UserModel.fromMap(userDoc.data()!, uid),
    );
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {
    await _firestore.collection('therapists').doc(uid).update(fields);
  }

  // Cascading delete — client-side for Sprint 1.
  // Production approach would be a Cloud Function.
  Future<void> deleteProfile(String uid, String therapistEmail) async {
    final batch = _firestore.batch();

    batch.delete(_firestore.collection('therapists').doc(uid));
    batch.delete(_firestore.collection('users').doc(uid));

    // Remove link requests sent to this therapist
    final linkDocs = await _firestore
        .collection('linkRequests')
        .where('therapistEmail', isEqualTo: therapistEmail)
        .get();
    for (final doc in linkDocs.docs) {
      batch.delete(doc.reference);
    }

    // Unlink any children linked to this therapist
    final childDocs = await _firestore
        .collection('children')
        .where('linkedTherapistId', isEqualTo: uid)
        .get();
    for (final doc in childDocs.docs) {
      batch.update(doc.reference, {'linkedTherapistId': null});
    }

    await batch.commit();

    // Firebase Auth account must be deleted last — requires recent login.
    await _auth.currentUser!.delete();
  }
}
