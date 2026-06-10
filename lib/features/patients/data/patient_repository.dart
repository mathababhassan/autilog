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
  // Returns (ChildModel, parentName) pairs.
  Future<List<(ChildModel, String)>> fetchAcceptedPatients(String therapistId) async {
    final snapshot = await _firestore
        .collection('therapists')
        .doc(therapistId)
        .collection('patients')
        .get();

    final results = await Future.wait(snapshot.docs.map((doc) async {
      final data = doc.data();
      final parentId  = data['parentId']   as String? ?? '';
      final childId   = doc.id;

      // parentName stored on the doc (new links) or fall back to linkRequests
      String parentName = data['parentName'] as String? ?? '';

      if (parentName.isEmpty) {
        try {
          // Security rules allow reading linkRequests filtered by therapistEmail
          final therapistEmail =
              FirebaseAuth.instance.currentUser?.email ?? '';
          final linkSnap = await _firestore
              .collection('linkRequests')
              .where('childId', isEqualTo: childId)
              .where('therapistEmail', isEqualTo: therapistEmail)
              .limit(1)
              .get();
          if (linkSnap.docs.isNotEmpty) {
            parentName =
                linkSnap.docs.first.data()['parentName'] as String? ?? '';
          }
        } catch (_) {}
      }

      // Fallback for old linkRequests that stored therapistId instead of therapistEmail
      if (parentName.isEmpty) {
        try {
          final linkSnap = await _firestore
              .collection('linkRequests')
              .where('childId', isEqualTo: childId)
              .where('therapistId', isEqualTo: therapistId)
              .limit(1)
              .get();
          if (linkSnap.docs.isNotEmpty) {
            parentName =
                linkSnap.docs.first.data()['parentName'] as String? ?? '';
          }
        } catch (_) {}
      }

      // Final fallback: read parent doc directly (therapists are allowed per security rules)
      if (parentName.isEmpty && parentId.isNotEmpty) {
        try {
          final parentDoc = await _firestore.collection('parents').doc(parentId).get();
          parentName = parentDoc.data()?['name'] as String? ?? '';
          // Patch the patients doc so future loads don't need this fallback
          if (parentName.isNotEmpty) {
            _firestore
                .collection('therapists')
                .doc(therapistId)
                .collection('patients')
                .doc(childId)
                .update({'parentName': parentName}).ignore();
          }
        } catch (_) {}
      }

      ChildModel child;
      try {
        final childDoc = await _firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();

        if (childDoc.exists) {
          child = ChildModel.fromMap(
            {...childDoc.data()!, 'parentId': parentId},
            childId,
          );
          return (child, parentName);
        }
      } catch (_) {}

      // Fallback to data stored in the patient doc
      child = ChildModel.fromMap(
        {
          'name':      data['childName'] ?? 'Unknown',
          'parentId':  parentId,
          'age':       0,
          'asdSeverity': 'Level 1',
        },
        childId,
      );
      return (child, parentName);
    }));

    return results;
  }

  // ── Accept request ────────────────────────────────────────────────────────
  // Calls the acceptLinkRequest Cloud Function via Firestore directly
  Future<void> acceptLinkRequest({
  required String requestId,
  required String therapistId,
  required String parentId,
  required String childId,
  String knownParentName = '',
  String knownChildName  = '',
}) async {
  // Read denormalized names from the linkRequest doc
  String parentName = knownParentName;
  String childName  = knownChildName;
  try {
    final reqDoc = await _firestore.collection('linkRequests').doc(requestId).get();
    final reqData = reqDoc.data() ?? {};
    if (parentName.isEmpty) parentName = reqData['parentName'] as String? ?? '';
    if (childName.isEmpty)  childName  = reqData['childName']  as String? ?? '';
  } catch (_) {}

  // Read therapist name + email to denormalize into linkedTherapists
  String therapistName  = '';
  String therapistEmail = '';
  try {
    final tDoc = await _firestore.collection('therapists').doc(therapistId).get();
    therapistName  = tDoc.data()?['name']  as String? ?? '';
    therapistEmail = tDoc.data()?['email'] as String? ?? '';
  } catch (_) {}

  final batch = _firestore.batch();

  // therapists/{therapistId}/patients/{childId}
  batch.set(
    _firestore.collection('therapists').doc(therapistId).collection('patients').doc(childId),
    {
      'parentId':   parentId,
      'parentName': parentName,
      'childName':  childName,
      'linkedAt':   FieldValue.serverTimestamp(),
      'status':     'active',
    },
  );

  // parents/{parentId}/children/{childId}/linkedTherapists/{therapistId}
  batch.set(
    _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('linkedTherapists')
        .doc(therapistId),
    {
      'linkedAt':       FieldValue.serverTimestamp(),
      'therapistName':  therapistName,
      'therapistEmail': therapistEmail,
      'parentName':     parentName,
    },
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