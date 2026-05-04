import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/link_request_model.dart';

class LinkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send link request to therapist
  Future<void> sendLinkRequest({
    required String parentId,
    required String childId,
    required String therapistEmail,
  }) async {
    final requestRef = _firestore.collection('linkRequests').doc();
    
    final request = LinkRequestModel(
      requestId: requestRef.id,
      parentId: parentId,
      childId: childId,
      therapistEmail: therapistEmail,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await requestRef.set(request.toMap());
  }

  // Get all link requests for a therapist
  Future<List<LinkRequestModel>> getTherapistRequests(String therapistEmail) async {
    final snapshot = await _firestore
        .collection('linkRequests')
        .where('therapistEmail', isEqualTo: therapistEmail)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs
        .map((doc) => LinkRequestModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Accept link request
  Future<void> acceptLinkRequest({
    required String requestId,
    required String therapistId,
    required String childId,
  }) async {
    // Update request status
    await _firestore.collection('linkRequests').doc(requestId).update({
      'status': 'accepted',
    });

    // Link therapist to child
    await _firestore.collection('children').doc(childId).update({
      'linkedTherapistId': therapistId,
    });
  }

  // Reject link request
  Future<void> rejectLinkRequest(String requestId) async {
    await _firestore.collection('linkRequests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  // Get all linked patients for a therapist
  Future<List<String>> getLinkedPatients(String therapistId) async {
    final snapshot = await _firestore
        .collection('children')
        .where('linkedTherapistId', isEqualTo: therapistId)
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }
}