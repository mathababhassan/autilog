import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/models/link_request_model.dart';
import 'pending_request_display.dart';

class PatientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PendingRequestDisplay>> fetchPendingRequests(
      String therapistEmail) async {
    final snapshot = await _firestore
        .collection('linkRequests')
        .where('therapistEmail', isEqualTo: therapistEmail)
        .where('status', isEqualTo: 'pending')
        .get();

    final requests = snapshot.docs
        .map((doc) => LinkRequestModel.fromMap(doc.data(), doc.id))
        .toList();

    final enriched = await Future.wait(requests.map((req) async {
      // Children live at parents/{parentId}/children/{childId}
      final childDoc = await _firestore
          .collection('parents')
          .doc(req.parentId)
          .collection('children')
          .doc(req.childId)
          .get();

      final parentDoc =
          await _firestore.collection('parents').doc(req.parentId).get();

      final childData = childDoc.data();
      return PendingRequestDisplay(
        requestId: req.requestId,
        childId: req.childId,
        childName: childData?['name'] as String? ?? 'Unknown Child',
        parentId: req.parentId,
        parentName: parentDoc.data()?['name'] as String? ?? 'Unknown Parent',
        diagnosisType: childData?['diagnosisType'] as String? ?? '',
        severityLevel: ChildModel.parseSeverity(
            childData?['severityLevel'] ?? childData?['asdSeverity']),
        requestedAt: req.createdAt,
      );
    }));

    return enriched;
  }

  // Uses collectionGroup to query children across all parents/{parentId}/children/
  Future<List<ChildModel>> fetchAcceptedPatients(String therapistId) async {
    final snapshot = await _firestore
        .collectionGroup('children')
        .where('linkedTherapistId', isEqualTo: therapistId)
        .get();

    return snapshot.docs
        .map((doc) => ChildModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> acceptLinkRequest({
    required String requestId,
    required String therapistId,
    required String parentId,
    required String childId,
  }) async {
    await _firestore
        .collection('linkRequests')
        .doc(requestId)
        .update({'status': 'accepted'});

    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'linkedTherapistId': therapistId,
      'therapists': FieldValue.arrayUnion([therapistId]),
    });
  }

  Future<void> rejectLinkRequest(String requestId) async {
    await _firestore
        .collection('linkRequests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  Future<void> removePatient({
    required String therapistId,
    required String parentId,
    required String childId,
  }) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'linkedTherapistId': null,
      'therapists': FieldValue.arrayRemove([therapistId]),
    });
  }
}
