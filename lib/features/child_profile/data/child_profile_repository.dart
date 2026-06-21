import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/models/link_request_model.dart';
import '../bloc/link_status.dart';

class ChildProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<(ChildModel, LinkStatus)> fetchChildWithLinkStatus({
    required String parentId,
    required String childId,
  }) async {
    final childDoc = await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .get();

    if (!childDoc.exists || childDoc.data() == null) {
      throw Exception('Child record not found.');
    }
    final child = ChildModel.fromMap(childDoc.data()!, childDoc.id);

    // An active link is recorded in parents/{parentId}/children/{childId}/
    // linkedTherapists/{therapistId} (written by the therapist's acceptLinkRequest
    // flow). The doc id is the therapist id. A child may have more than one;
    // order by linkedAt so the surfaced link is deterministic (most recent).
    final linkedSnap = await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('linkedTherapists')
        .orderBy('linkedAt', descending: true)
        .limit(1)
        .get();

    if (linkedSnap.docs.isNotEmpty) {
      final therapistId = linkedSnap.docs.first.id;
      String therapistName = 'Unknown Therapist';
      String clinicName = '';
      String specialisation = '';
      String? phone;
      try {
        final therapistDoc = await _firestore
            .collection('therapists')
            .doc(therapistId)
            .get();
        final data = therapistDoc.data();
        therapistName = data?['name'] as String? ?? 'Unknown Therapist';
        clinicName = data?['clinicName'] as String? ?? '';
        specialisation = data?['specialisation'] as String? ?? '';
        phone = data?['phone'] as String?;
      } catch (_) {
        // Therapist docs are readable only by their owner under current rules;
        // fall back to placeholders if the read is denied or the doc is gone.
      }
      return (
        child,
        ActiveLink(
          therapistId: therapistId,
          therapistName: therapistName,
          clinicName: clinicName,
          specialisation: specialisation,
          phone: phone,
        ) as LinkStatus,
      );
    }

    // Query by parentId so the security rule (resource.data.parentId == auth.uid)
    // can be satisfied at query-validation time. Filter childId + status in Dart.
    final pendingSnap = await _firestore
        .collection('linkRequests')
        .where('parentId', isEqualTo: parentId)
        .get();

    final pendingDoc = pendingSnap.docs
        .where((d) =>
            d.data()['childId'] == childId &&
            d.data()['status'] == 'pending')
        .firstOrNull;

    if (pendingDoc != null) {
      final req = LinkRequestModel.fromMap(pendingDoc.data(), pendingDoc.id);
      return (
        child,
        PendingLink(
          requestId: req.requestId,
          therapistEmail: req.therapistEmail,
        ) as LinkStatus,
      );
    }

    return (child, const NoLink() as LinkStatus);
  }

  Future<void> sendLinkRequest({
    required String parentId,
    required String childId,
    required String therapistEmail,
  }) async {
    final therapistSnap = await _firestore
        .collection('therapists')
        .where('email', isEqualTo: therapistEmail)
        .limit(1)
        .get();

    if (therapistSnap.docs.isEmpty) {
      throw Exception('No therapist found with that email address.');
    }

    final pendingSnap = await _firestore
        .collection('linkRequests')
        .where('parentId', isEqualTo: parentId)
        .get();

    final alreadyPending = pendingSnap.docs.any(
      (d) =>
          d.data()['childId'] == childId &&
          d.data()['status'] == 'pending',
    );

    if (alreadyPending) {
      throw Exception('A request is already pending for this child.');
    }

    // Enforce one therapist per child: block a new request if the child is
    // already linked to a therapist.
    final linkedSnap = await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('linkedTherapists')
        .limit(1)
        .get();
    if (linkedSnap.docs.isNotEmpty) {
      throw Exception('This child is already linked to a therapist.');
    }

    // Denormalize child/parent display info onto the request. While a request
    // is pending the therapist cannot read the child or parent docs (rules
    // only grant that once the link is accepted), so the pending-requests list
    // would otherwise show "Unknown". The parent owns these docs and can read
    // them here to stamp the values.
    final childDoc = await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .get();
    final childData = childDoc.data() ?? {};

    final parentDoc =
        await _firestore.collection('parents').doc(parentId).get();
    final parentData = parentDoc.data() ?? {};

    await _firestore.collection('linkRequests').add({
      'parentId': parentId,
      'childId': childId,
      'therapistEmail': therapistEmail,
      'status': 'pending',
      'childName': childData['name'] ?? '',
      'parentName': parentData['name'] ?? '',
      'severityLevel': ChildModel.parseSeverity(
          childData['severityLevel'] ?? childData['asdSeverity']),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelLinkRequest(String requestId) async {
    await _firestore.collection('linkRequests').doc(requestId).delete();
  }

  Future<void> revokeTherapistAccess({
    required String parentId,
    required String childId,
    required String therapistId,
  }) async {
    final patientRef = _firestore
        .collection('therapists')
        .doc(therapistId)
        .collection('patients')
        .doc(childId);

    // Stamp the actor + time BEFORE deleting so the onDelete notification trigger
    // can (a) tell a parent revocation from a therapist self-removal, and (b) make
    // the notification id unique per revocation (a re-link then re-revoke
    // re-notifies). Must be a separate commit — a same-batch update+delete hides
    // the field from the delete event.
    await patientRef.update({
      'removedBy': 'parent',
      'removedAt': FieldValue.serverTimestamp(),
    });

    // Mirror the therapist-side removePatient: drop both link records atomically.
    final batch = _firestore.batch();

    batch.delete(
      _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('linkedTherapists')
          .doc(therapistId),
    );

    batch.delete(patientRef);

    try {
      await batch.commit();
    } catch (e) {
      // Delete failed after the stamp — roll the marker back so the record isn't
      // left flagged while the therapist still has access. A retry then runs clean.
      try {
        await patientRef.update({
          'removedBy': FieldValue.delete(),
          'removedAt': FieldValue.delete(),
        });
      } catch (_) {
        // Best-effort rollback; surface the original failure regardless.
      }
      rethrow;
    }
  }
}
