import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../data/patient_repository.dart';
import 'patient_list_event.dart';
import 'patient_list_state.dart';

class PatientListBloc extends Bloc<PatientListEvent, PatientListState> {
  PatientListBloc({
    required PatientRepository patientRepository,
    required AuthRepository authRepository,
  })  : _patientRepository = patientRepository,
        _authRepository = authRepository,
        super(const PatientListInitial()) {
    on<PatientListStarted>(_onLoad);
    on<PatientListRefreshRequested>(_onLoad);
    on<PendingRequestAccepted>(_onPendingAccepted);
    on<PendingRequestRejected>(_onPendingRejected);
    on<ActivePatientRemoved>(_onPatientRemoved);
  }

  final PatientRepository _patientRepository;
  final AuthRepository _authRepository;

  Future<void> _onLoad(
    PatientListEvent event,
    Emitter<PatientListState> emit,
  ) async {
    emit(const PatientListLoading());
    try {
      final uid = _authRepository.currentUser!.uid;
      final email = _authRepository.currentUser!.email!;

      final pending = await _patientRepository.fetchPendingRequests(email);
      final active = await _patientRepository.fetchAcceptedPatients(uid);

      emit(PatientListLoaded(
        pendingRequests: pending,
        activePatients: active,
      ));
    } catch (e) {
      emit(PatientListError(message: e.toString()));
    }
  }

  Future<void> _onPendingAccepted(
    PendingRequestAccepted event,
    Emitter<PatientListState> emit,
  ) async {
    final current = state;
    if (current is! PatientListLoaded) return;

    emit(current.copyWith(actionStatus: PatientListActionStatus.inProgress));
    try {
      final uid = _authRepository.currentUser!.uid;
      final email = _authRepository.currentUser!.email!;

      await _patientRepository.acceptLinkRequest(
        requestId: event.requestId,
        therapistId: uid,
        parentId: event.parentId,
        childId: event.childId,
        knownParentName: event.parentName,
        knownChildName: event.childName,
      );

      final pending = await _patientRepository.fetchPendingRequests(email);
      final active = await _patientRepository.fetchAcceptedPatients(uid);

      emit(PatientListLoaded(
        pendingRequests: pending,
        activePatients: active,
        actionStatus: PatientListActionStatus.success,
        actionMessage: 'Patient accepted.',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: PatientListActionStatus.error,
        actionMessage: e.toString(),
      ));
    }
  }

  Future<void> _onPendingRejected(
    PendingRequestRejected event,
    Emitter<PatientListState> emit,
  ) async {
    final current = state;
    if (current is! PatientListLoaded) return;

    emit(current.copyWith(actionStatus: PatientListActionStatus.inProgress));
    try {
      final email = _authRepository.currentUser!.email!;
      final uid = _authRepository.currentUser!.uid;

      await _patientRepository.rejectLinkRequest(event.requestId);

      final pending = await _patientRepository.fetchPendingRequests(email);
      final active = await _patientRepository.fetchAcceptedPatients(uid);

      emit(PatientListLoaded(
        pendingRequests: pending,
        activePatients: active,
        actionStatus: PatientListActionStatus.success,
        actionMessage: 'Request rejected.',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: PatientListActionStatus.error,
        actionMessage: e.toString(),
      ));
    }
  }

  Future<void> _onPatientRemoved(
    ActivePatientRemoved event,
    Emitter<PatientListState> emit,
  ) async {
    final current = state;
    if (current is! PatientListLoaded) return;

    emit(current.copyWith(actionStatus: PatientListActionStatus.inProgress));
    try {
      final email = _authRepository.currentUser!.email!;
      final uid = _authRepository.currentUser!.uid;

      await _patientRepository.removePatient(
        therapistId: uid,
        parentId: event.parentId,
        childId: event.childId,
      );

      final pending = await _patientRepository.fetchPendingRequests(email);
      final active = await _patientRepository.fetchAcceptedPatients(uid);

      emit(PatientListLoaded(
        pendingRequests: pending,
        activePatients: active,
        actionStatus: PatientListActionStatus.success,
        actionMessage: 'Patient removed.',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: PatientListActionStatus.error,
        actionMessage: e.toString(),
      ));
    }
  }
}
