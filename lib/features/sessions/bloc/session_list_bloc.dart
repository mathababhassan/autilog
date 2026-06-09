import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../patients/data/patient_repository.dart';
import '../data/session_repository.dart';
import 'session_list_event.dart';
import 'session_list_state.dart';

class SessionListBloc extends Bloc<SessionListEvent, SessionListState> {
  SessionListBloc({
    required SessionRepository sessionRepository,
    required PatientRepository patientRepository,
    required AuthRepository authRepository,
  })  : _sessionRepository = sessionRepository,
        _patientRepository = patientRepository,
        _authRepository = authRepository,
        super(const SessionListInitial()) {
    on<SessionListStarted>(_onLoad);
    on<SessionListRefreshRequested>(_onLoad);
    on<SessionPatientFilterChanged>(_onFilterChanged);
    on<SessionMarkedCompleted>(_onMarkCompleted);
  }

  final SessionRepository _sessionRepository;
  final PatientRepository _patientRepository;
  final AuthRepository _authRepository;

  Future<void> _onLoad(
    SessionListEvent event,
    Emitter<SessionListState> emit,
  ) async {
    emit(const SessionListLoading());
    try {
      final uid = _authRepository.currentUser!.uid;
    
      // Run both fetches at the same time
      final results = await Future.wait([
        _sessionRepository.fetchSessionsForTherapist(uid),
        _patientRepository.fetchAcceptedPatients(uid),
      ]);
    
      final sessions = results[0] as List<SessionModel>;
      final patients = results[1]; // The type depends on what fetchAcceptedPatients returns
    
      emit(SessionListLoaded(
        allSessions: sessions,
        patients: patients,
      ));
    } catch (_) {
      emit(const SessionListError(
        message: 'Could not load your sessions. Please try again.',
      ));
    }
  }

  /// Pure in-memory: just remembers the selected patient on the loaded state.
  void _onFilterChanged(
    SessionPatientFilterChanged event,
    Emitter<SessionListState> emit,
  ) {
    final current = state;
    if (current is! SessionListLoaded) return;

    if (event.childId == null) {
      emit(current.copyWith(clearFilter: true));
    } else {
      emit(current.copyWith(selectedChildId: event.childId));
    }
  }

  /// Writes the completed status, then re-fetches so the card moves to Past.
  /// Keeps the current patient filter so the view doesn't jump back to "All".
  Future<void> _onMarkCompleted(
    SessionMarkedCompleted event,
    Emitter<SessionListState> emit,
  ) async {
    final current = state;
    if (current is! SessionListLoaded) return;

    try {
      await _sessionRepository.markSessionCompleted(event.sessionId);

      final uid = _authRepository.currentUser!.uid;
      final sessions = await _sessionRepository.fetchSessionsForTherapist(uid);

      emit(current.copyWith(
        allSessions: sessions,
        actionStatus: SessionListActionStatus.success,
        actionMessage: 'Session marked as completed.',
      ));
    } catch (_) {
      emit(current.copyWith(
        actionStatus: SessionListActionStatus.error,
        actionMessage: 'Could not update the session. Please try again.',
      ));
    }
  }
}
