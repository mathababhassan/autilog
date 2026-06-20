import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/models/session_model.dart';

class SessionRepository {
  final FirebaseFirestore _firestore;

  SessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<SessionModel>> fetchSessionsToday(String therapistId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _firestore
        .collection('sessions')
        .where('therapistId', isEqualTo: therapistId)
        .where('status', whereIn: ['upcoming', 'completed'])
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('scheduledAt')
        .get();

    return snap.docs.map((doc) => SessionModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<SessionModel>> fetchUpcomingSessions(String therapistId) async {
    final now = DateTime.now();

    final snap = await _firestore
        .collection('sessions')
        .where('therapistId', isEqualTo: therapistId)
        .where('status', isEqualTo: 'upcoming')
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('scheduledAt')
        .get();

    return snap.docs.map((doc) => SessionModel.fromMap(doc.data(), doc.id)).toList();
  }

  /// All sessions belonging to a therapist, regardless of status.
  ///
  /// Uses a single equality filter (no `orderBy`) so it needs no composite
  /// Firestore index. The Session List BLoC partitions these into Upcoming /
  /// Past and sorts them in memory, and also filters by patient client-side.
  Future<List<SessionModel>> fetchSessionsForTherapist(String therapistId) async {
    final snap = await _firestore
        .collection('sessions')
        .where('therapistId', isEqualTo: therapistId)
        .get();

    return snap.docs.map((doc) => SessionModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<SessionModel>> fetchSessionsForChild(String childId) async {
    final snap = await _firestore
        .collection('sessions')
        .where('childId', isEqualTo: childId)
        .where('status', whereIn: ['upcoming', 'completed', 'cancelled'])
        .orderBy('scheduledAt', descending: true)
        .get();

    return snap.docs.map((doc) => SessionModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<SessionModel> fetchSessionById(String id) async {
    final doc = await _firestore.collection('sessions').doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw Exception('Session $id not found');
    }
    return SessionModel.fromMap(data, doc.id);
  }

  /// Reads the patient doc at parents/{parentId}/children/{childId} for the
  /// session's Patient card (diagnosis · severity · age). Same path the
  /// therapist home cubit uses.
  Future<ChildModel> fetchChild({
    required String parentId,
    required String childId,
  }) async {
    final doc = await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw Exception('Child $childId not found');
    }
    return ChildModel.fromMap(data, doc.id);
  }

  Future<String> addSession(SessionModel session) async {
    final ref = await _firestore.collection('sessions').add(session.toMap());
    return ref.id;
  }

  /// Marks an upcoming session as completed. The therapist confirms the
  /// session happened; we never derive this from the clock (a past-dated
  /// session may be a no-show, not a completion).
  Future<void> markSessionCompleted(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'completed',
    });
  }

  Future<void> cancelSession(String sessionId, {String? reason}) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'cancelled',
      // Records who cancelled so the notification trigger can route the alert to
      // the other party (therapist cancel → notify parent, and vice versa).
      'cancelledByUid': FirebaseAuth.instance.currentUser?.uid,
      if (reason != null && reason.isNotEmpty) 'cancelReason': reason,
    });
  }

  Future<void> rescheduleSession({
    required String sessionId,
    required DateTime newStart,
    required DateTime newEnd,
    required String mode,
    required String location,
    required int durationMinutes,
  }) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'scheduledAt': Timestamp.fromDate(newStart),
      'endTime': Timestamp.fromDate(newEnd),
      'status': 'upcoming',
      'mode': mode,
      'location': location,
      'durationMinutes': durationMinutes,
    });
  }

  Future<void> saveNotes(String sessionId, String notes) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'notes': notes,
    });
  }

  // ── T-29 / T-30: Session Notes ──────────────────────────────────────────────

  Future<void> saveSessionNotes({
    required String sessionId,
    String? progress,
    String? privateNotes,
    String? parentNotes,
  }) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      if (progress != null) 'progress': progress,
      if (privateNotes != null) 'privateNotes': privateNotes,
      if (parentNotes != null) 'notes': parentNotes,
      'notesLastEditedAt': FieldValue.serverTimestamp(),
    });
  }
}