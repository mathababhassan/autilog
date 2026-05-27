import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/daily_summary_model.dart';
import 'package:autilog/shared/models/daily_summary_model.dart';

class DailySummaryRepository {
  final FirebaseFirestore _firestore;

  DailySummaryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveSummary(DailySummaryModel summary) async {
    final user = FirebaseAuth.instance.currentUser;
    print("Current user UID: ${user?.uid}");
    if (user == null) {
      print("No user logged in!");
      throw Exception("User not logged in");
    }
    
    final parentId = user.uid;
    print("Saving to parentId: $parentId");
    print("ChildId: ${summary.childId}");
    final docId = summary.date.toIso8601String();

    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(summary.childId)
          .collection('dailySummaries')
          .doc(docId)
          .set(summary.toJson(), SetOptions(merge: true));
      print("Save successful!");
    } catch (e) {
      print("Save failed: $e");
      throw Exception("Failed to save summary: $e");
    }
  }

  Future<List<DailySummaryModel>> getSummaries(String childId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    
    final parentId = user.uid;

    try {
      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('dailySummaries')
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    
    final parentId = user.uid;
    final docId = date.toIso8601String();

    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('dailySummaries')
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    
    final parentId = user.uid;
    final docId = date.toIso8601String();

    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('dailySummaries')
          .doc(docId)
          .set({"therapistComments": comments}, SetOptions(merge: true));
    } catch (e) {
      throw Exception("Failed to update therapist comments: $e");
    }
  }
}