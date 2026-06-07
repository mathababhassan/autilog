import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<List<SessionModel>> fetchSessionsForChild(String childId) async {
    final snap = await _firestore
        .collection('sessions')
        .where('childId', isEqualTo: childId)
        .where('status', whereIn: ['upcoming', 'completed', 'cancelled'])
        .orderBy('scheduledAt', descending: true)
        .get();

    return snap.docs.map((doc) => SessionModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<String> addSession(SessionModel session) async {
    final ref = await _firestore.collection('sessions').add(session.toMap());
    return ref.id;
  }

  Future<void> cancelSession(String sessionId, {String? reason}) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'cancelled',
      if (reason != null && reason.isNotEmpty) 'cancelReason': reason,
    });
  }

  Future<void> rescheduleSession({
    required String sessionId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'scheduledAt': Timestamp.fromDate(newStart),
      'endTime': Timestamp.fromDate(newEnd),
      'status': 'upcoming',
    });
  }

  Future<void> saveNotes(String sessionId, String notes) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'notes': notes,
    });
  }
}