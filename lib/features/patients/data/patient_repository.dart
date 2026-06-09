import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/child_model.dart';
import 'pending_request_display.dart';

class PatientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Fetch pending requests ────────────────────────────────────────────────
  // Reads from therapists/{therapistId}/pendingRequests (written by Cloud Function)
  Future<List<PendingRequestDisplay>> fetchPendingRequests(String therapistEmail) async {
  final snapshot = await _firestore
      .collection('linkRequests')
      .where('therapistEmail', isEqualTo: therapistEmail)
      .where('status', isEqualTo: 'pending')
      .get();

  final enriched = await Future.wait(snapshot.docs.map((doc) async {
    final data = doc.data();
    final parentId = data['parentId'] as String? ?? '';
    final childId = data['childId'] as String? ?? '';

    // Prefer values denormalized onto the request by the parent — while the
    // request is pending, rules block the therapist from reading the child or
    // parent docs, so the direct lookups below only succeed post-link.
    int severityLevel = (data['severityLevel'] as num?)?.toInt() ?? 0;
    String childName = data['childName'] as String? ?? '';
    String parentName = data['parentName'] as String? ?? '';

    if (childName.isEmpty) {
      try {
        final childDoc = await _firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();
        final childData = childDoc.data();
        childName = childData?['name'] as String? ?? '';
        severityLevel = ChildModel.parseSeverity(
            childData?['severityLevel'] ?? childData?['asdSeverity']);
      } catch (_) {}
    }

    if (parentName.isEmpty) {
      try {
        final parentDoc = await _firestore.collection('parents').doc(parentId).get();
        parentName = parentDoc.data()?['name'] as String? ?? '';
      } catch (_) {}
    }

    if (childName.isEmpty) childName = 'Unknown Child';
    if (parentName.isEmpty) parentName = 'Unknown Parent';

    return PendingRequestDisplay(
      requestId: doc.id,
      childId: childId,
      childName: childName,
      parentId: parentId,
      parentName: parentName,
      diagnosisType: '',
      severityLevel: severityLevel,
      requestedAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }));

  return enriched;
}

  // ── Fetch accepted patients ───────────────────────────────────────────────
  // Reads from therapists/{therapistId}/patients (written by acceptLinkRequest Cloud Function)
  Future<List<ChildModel>> fetchAcceptedPatients(String therapistId) async {
    final snapshot = await _firestore
        .collection('therapists')
        .doc(therapistId)
        .collection('patients')
        .get();

    final children = await Future.wait(snapshot.docs.map((doc) async {
      final data = doc.data();
      final parentId = data['parentId'] as String? ?? '';
      final childId = doc.id;

      try {
        final childDoc = await _firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();

        if (childDoc.exists) {
          return ChildModel.fromMap(
            {...childDoc.data()!, 'parentId': parentId},
            childId,
          );
        }
      } catch (_) {}

      // Fallback to data stored in the patient doc
      return ChildModel.fromMap(
        {
          'name': data['childName'] ?? 'Unknown',
          'parentId': parentId,
          'age': 0,
          'asdSeverity': 'Level 1',
        },
        childId,
      );
    }));

    return children;
  }

  // ── Accept request ────────────────────────────────────────────────────────
  // Calls the acceptLinkRequest Cloud Function via Firestore directly
  Future<void> acceptLinkRequest({
  required String requestId,
  required String therapistId,
  required String parentId,
  required String childId,
}) async {
  final batch = _firestore.batch();

  batch.set(
    _firestore.collection('therapists').doc(therapistId).collection('patients').doc(childId),
    {
      'parentId': parentId,
      'linkedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    },
  );

  batch.set(
    _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('linkedTherapists')
        .doc(therapistId),
    {'linkedAt': FieldValue.serverTimestamp()},
  );

  batch.update(
    _firestore.collection('linkRequests').doc(requestId),
    {'status': 'accepted'},
  );

  await batch.commit();
}

  // ── Reject request ────────────────────────────────────────────────────────
  Future<void> rejectLinkRequest(String requestId) async {
  await _firestore.collection('linkRequests').doc(requestId).delete();
}

  // ── Remove patient ────────────────────────────────────────────────────────
  Future<void> removePatient({
    required String therapistId,
    required String parentId,
    required String childId,
  }) async {
    final batch = _firestore.batch();

    // Remove from therapists/{therapistId}/patients
    batch.delete(
      _firestore.collection('therapists').doc(therapistId).collection('patients').doc(childId),
    );

    // Remove from parents/{parentId}/children/{childId}/linkedTherapists
    batch.delete(
      _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('linkedTherapists')
          .doc(therapistId),
    );

    await batch.commit();
  }
}