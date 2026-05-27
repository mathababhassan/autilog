import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/daily_summary_model.dart';
import 'package:autilog/shared/models/daily_summary_model.dart';

class DailySummaryRepository {
  final FirebaseFirestore _firestore;

  DailySummaryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveSummary(DailySummaryModel summary) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docId = summary.date.toIso8601String(); // unique per day

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(summary.childId)
          .collection('logs')
          .doc(docId)
          .set(summary.toJson(), SetOptions(merge: true)); 
          // 👈 merge ensures hadScreenTime & screenTimeHours are saved safely
    } catch (e) {
      throw Exception("Failed to save summary: $e");
    }
  }

  Future<List<DailySummaryModel>> getSummaries(String childId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .collection('logs')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DailySummaryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Failed to load summaries: $e");
    }
  }

  Future<void> deleteSummary({
    required String childId,
    required DateTime date,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docId = date.toIso8601String();

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .collection('logs')
          .doc(docId)
          .delete();
    } catch (e) {
      throw Exception("Failed to delete summary: $e");
    }
  }

  Future<void> updateTherapistComments({
    required String childId,
    required DateTime date,
    required String comments,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docId = date.toIso8601String();

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .collection('logs')
          .doc(docId)
          .set({"therapistComments": comments}, SetOptions(merge: true));
    } catch (e) {
      throw Exception("Failed to update therapist comments: $e");
    }
  }
}
