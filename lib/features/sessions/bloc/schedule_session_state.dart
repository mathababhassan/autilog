part of 'schedule_session_bloc.dart';

sealed class ScheduleSessionState {}

final class ScheduleSessionInitial extends ScheduleSessionState {}

final class ScheduleSessionReady extends ScheduleSessionState {
  final List<ChildModel> patients;
  final ChildModel? selectedPatient;
  final String? selectedType;
  final String selectedMode;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int? selectedDurationMinutes;
  final String parentNotes;
  final String privateNotes;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final String? serverError;

  ScheduleSessionReady({
    required this.patients,
    this.selectedPatient,
    this.selectedType,
    this.selectedMode = 'In-Person',
    this.selectedDate,
    this.selectedTime,
    this.selectedDurationMinutes,
    this.parentNotes = '',
    this.privateNotes = '',
    this.isSubmitting = false,
    this.fieldErrors = const {},
    this.serverError,
  });

  ScheduleSessionReady copyWith({
    List<ChildModel>? patients,
    ChildModel? selectedPatient,
    bool clearPatient = false,
    String? selectedType,
    String? selectedMode,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    int? selectedDurationMinutes,
    bool clearDuration = false,
    String? parentNotes,
    String? privateNotes,
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    String? serverError,
    bool clearServerError = false,
  }) {
    return ScheduleSessionReady(
      patients: patients ?? this.patients,
      selectedPatient: clearPatient ? null : (selectedPatient ?? this.selectedPatient),
      selectedType: selectedType ?? this.selectedType,
      selectedMode: selectedMode ?? this.selectedMode,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedDurationMinutes: clearDuration ? null : (selectedDurationMinutes ?? this.selectedDurationMinutes),
      parentNotes: parentNotes ?? this.parentNotes,
      privateNotes: privateNotes ?? this.privateNotes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      serverError: clearServerError ? null : (serverError ?? this.serverError),
    );
  }
}

final class ScheduleSessionSuccess extends ScheduleSessionState {}

final class ScheduleSessionLoadError extends ScheduleSessionState {
  final String message;
  ScheduleSessionLoadError(this.message);
}
