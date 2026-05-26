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

    if (child.linkedTherapistId != null) {
      String therapistName = 'Unknown Therapist';
      String clinicName = '';
      String specialisation = '';
      String? phone;
      try {
        final therapistDoc = await _firestore
            .collection('therapists')
            .doc(child.linkedTherapistId)
            .get();
        final data = therapistDoc.data();
        therapistName = data?['name'] as String? ?? 'Unknown Therapist';
        clinicName = data?['clinicName'] as String? ?? '';
        specialisation = data?['specialisation'] as String? ?? '';
        phone = data?['phone'] as String?;
      } catch (_) {
        // Firestore rule not yet deployed or therapist deleted; use defaults.
      }
      return (
        child,
        ActiveLink(
          therapistId: child.linkedTherapistId!,
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

    await _firestore.collection('linkRequests').add({
      'parentId': parentId,
      'childId': childId,
      'therapistEmail': therapistEmail,
      'status': 'pending',
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
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'linkedTherapistId': null,
      'therapists': FieldValue.arrayRemove([therapistId]),
    });

    await _firestore
        .collection('therapists')
        .doc(therapistId)
        .collection('patients')
        .doc(childId)
        .delete();
  }
}
