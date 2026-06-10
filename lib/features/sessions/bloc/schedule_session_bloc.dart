import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/data/auth_repository.dart';
import '../../../features/patients/data/patient_repository.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/models/session_model.dart';
import '../data/session_repository.dart';

part 'schedule_session_event.dart';
part 'schedule_session_state.dart';

class ScheduleSessionBloc
    extends Bloc<ScheduleSessionEvent, ScheduleSessionState> {
  ScheduleSessionBloc({
    required SessionRepository sessionRepository,
    required PatientRepository patientRepository,
    required AuthRepository authRepository,
  })  : _sessionRepository = sessionRepository,
        _patientRepository = patientRepository,
        _authRepository = authRepository,
        super(ScheduleSessionInitial()) {
    on<ScheduleSessionStarted>(_onStarted);
    on<ScheduleSessionPatientSelected>(_onPatientSelected);
    on<ScheduleSessionTypeSelected>(_onTypeSelected);
    on<ScheduleSessionModeSelected>(_onModeSelected);
    on<ScheduleSessionDateSelected>(_onDateSelected);
    on<ScheduleSessionTimeSelected>(_onTimeSelected);
    on<ScheduleSessionDurationSelected>(_onDurationSelected);
    on<ScheduleSessionParentNotesChanged>(_onParentNotesChanged);
    on<ScheduleSessionPrivateNotesChanged>(_onPrivateNotesChanged);
    on<ScheduleSessionSubmitted>(_onSubmitted);
  }

  final SessionRepository _sessionRepository;
  final PatientRepository _patientRepository;
  final AuthRepository _authRepository;

  Future<void> _onStarted(
    ScheduleSessionStarted event,
    Emitter<ScheduleSessionState> emit,
  ) async {
    try {
      final uid = _authRepository.currentUser!.uid;
      final pairs = await _patientRepository.fetchAcceptedPatients(uid);
      final patients = pairs.map((p) => p.$1).toList();
      emit(ScheduleSessionReady(patients: patients));
    } catch (_) {
      emit(ScheduleSessionLoadError(
        'Could not load your patients. Please try again.',
      ));
    }
  }

  void _onPatientSelected(
    ScheduleSessionPatientSelected event,
    Emitter<ScheduleSessionState> emit,
  ) {
    final s = state;
    if (s is! ScheduleSessionReady) return;
    emit(s.copyWith(selectedPatient: event.patient, fieldErrors: const {}));
  }

  void _onTypeSelected(
    ScheduleSessionTypeSelected event,
    Emitter<ScheduleSessionState> emit,
  ) {
    final s = state;
    if (s is! ScheduleSessionReady) return;
    emit(s.copyWith(selectedType: event.type));
  }

  void _onModeSelected(
    ScheduleSessionModeSelected event,
    Emitter<ScheduleSessionState> emit,
  ) {
    final s = state;
    if (s is! ScheduleSessionReady) return;
    emit(s.copyWith(selectedMode: event.mode));
  }

  void _onDateSelected(
    ScheduleSessionDateSelected event,
    Emitter<ScheduleSessionState> emit,
  ) {
    final s = state;
    if (s is! ScheduleSessionReady) return;
    emit(s.copyWith(selectedDate: event.date));
  }

  void _onTimeSelected(
    ScheduleSessionTimeSelected event,
    Emitter<ScheduleSessionState> emit,
  ) {
    final s = state;
    if (s is! ScheduleSessionReady) return;
    emit(s.copyWith(selectedTime: event.time));
  }

  void _onDurationSelected(
    ScheduleSessionDurationSelected event,
    Emitter<ScheduleSessionState> emit,
  ) {
    final s = state;
    if (s is! ScheduleSessionReady) return;
    emit(s.copyWith(selectedDurationMinutes: event.minutes));
  }

  void _onParentNotesChanged(
    ScheduleSessionParentNotesChanged event,
    Emitter<ScheduleSessionState> emit,
  ) {
    final s = state;
    if (s is! ScheduleSessionReady) return;
    emit(s.copyWith(parentNotes: event.notes));
  }

  void _onPrivateNotesChanged(
    ScheduleSessionPrivateNotesChanged event,
    Emitter<ScheduleSessionState> emit,
  ) {
    final s = state;
    if (s is! ScheduleSessionReady) return;
    emit(s.copyWith(privateNotes: event.notes));
  }

  Future<void> _onSubmitted(
    ScheduleSessionSubmitted event,
    Emitter<ScheduleSessionState> emit,
  ) async {
    final s = state;
    if (s is! ScheduleSessionReady) return;

    final errors = <String, String>{};
    if (s.selectedPatient == null) errors['patient'] = 'Please select a patient.';
    if (s.selectedType == null) errors['type'] = 'Please select a session type.';
    if (s.selectedDate == null) errors['date'] = 'Please select a date.';
    if (s.selectedTime == null) errors['time'] = 'Please select a time.';
    if (s.selectedDurationMinutes == null) errors['duration'] = 'Please select a duration.';

    if (errors.isNotEmpty) {
      emit(s.copyWith(fieldErrors: errors));
      return;
    }

    final submitting = s.copyWith(isSubmitting: true, fieldErrors: const {});
    emit(submitting);

    try {
      final uid = _authRepository.currentUser!.uid;
      final date = s.selectedDate!;
      final time = s.selectedTime!;
      final scheduledAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
      final duration = s.selectedDurationMinutes!;
      final endTime = scheduledAt.add(Duration(minutes: duration));
      final patient = s.selectedPatient!;
      final mode = s.selectedMode;

      final session = SessionModel(
        id: '',
        therapistId: uid,
        childId: patient.childId,
        childName: patient.name,
        parentId: patient.parentId,
        scheduledAt: scheduledAt,
        endTime: endTime,
        location: mode == 'Virtual' ? 'Online' : 'Clinic',
        mode: mode,
        type: s.selectedType!,
        status: 'upcoming',
        durationMinutes: duration,
        preSessionParentNotes:
            s.parentNotes.trim().isEmpty ? null : s.parentNotes.trim(),
        preSessionPrivateNotes:
            s.privateNotes.trim().isEmpty ? null : s.privateNotes.trim(),
      );

      await _sessionRepository.addSession(session);
      emit(ScheduleSessionSuccess());
    } catch (_) {
      emit(submitting.copyWith(
        isSubmitting: false,
        serverError: 'Could not schedule the session. Please try again.',
      ));
    }
  }
}
