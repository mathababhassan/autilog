import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/models/child_model.dart';
import '../../../../features/sessions/data/session_repository.dart';
import 'therapist_home_state.dart';

class TherapistHomeCubit extends Cubit<TherapistHomeState> {
  TherapistHomeCubit({
    required SessionRepository sessionRepository,
    FirebaseFirestore? firestore,
  })  : _sessionRepository = sessionRepository,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const TherapistHomeInitial());

  final SessionRepository _sessionRepository;
  final FirebaseFirestore _firestore;

  Future<void> load({
    required String therapistId,
    required List<ChildModel> patients,
  }) async {
    emit(const TherapistHomeLoading());

    try {
      final sessionsToday = await _sessionRepository.fetchSessionsToday(therapistId);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekAgo = now.subtract(const Duration(days: 7));

      int newLogsCount = 0;
      int urgentAlertsCount = 0;
      final needsAttention = <UrgentPatient>[];

      for (final patient in patients) {
        // New daily summaries logged today
        final logsSnap = await _firestore
            .collection('parents')
            .doc(patient.parentId)
            .collection('children')
            .doc(patient.childId)
            .collection('dailySummaries')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .get();
        newLogsCount += logsSnap.docs.length;

        // Urgent incidents in the last 7 days
        final incidentsSnap = await _firestore
            .collection('parents')
            .doc(patient.parentId)
            .collection('children')
            .doc(patient.childId)
            .collection('incidents')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
            .get();

        int maxSeverity = 0;
        for (final doc in incidentsSnap.docs) {
          final severity = (doc.data()['behaviorSeverity'] as num?)?.toInt() ?? 0;
          if (severity >= 4) {
            urgentAlertsCount++;
            if (severity > maxSeverity) maxSeverity = severity;
          }
        }

        if (maxSeverity >= 4 &&
            !needsAttention.any((p) => p.childId == patient.childId)) {
          needsAttention.add(UrgentPatient(
            childId: patient.childId,
            childName: patient.name,
            alertMessage: 'Severity $maxSeverity incident logged',
            severity: maxSeverity,
          ));
        }
      }

      needsAttention.sort((a, b) => b.severity.compareTo(a.severity));

      emit(TherapistHomeLoaded(
        sessionsToday: sessionsToday,
        newLogsCount: newLogsCount,
        urgentAlertsCount: urgentAlertsCount,
        needsAttention: needsAttention,
      ));
    } catch (e) {
      emit(TherapistHomeError(message: e.toString()));
    }
  }
}