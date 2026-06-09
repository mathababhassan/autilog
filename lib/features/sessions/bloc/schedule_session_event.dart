part of 'schedule_session_bloc.dart';

sealed class ScheduleSessionEvent {}

final class ScheduleSessionStarted extends ScheduleSessionEvent {}

final class ScheduleSessionPatientSelected extends ScheduleSessionEvent {
  final ChildModel patient;
  ScheduleSessionPatientSelected(this.patient);
}

final class ScheduleSessionTypeSelected extends ScheduleSessionEvent {
  final String type;
  ScheduleSessionTypeSelected(this.type);
}

final class ScheduleSessionModeSelected extends ScheduleSessionEvent {
  final String mode;
  ScheduleSessionModeSelected(this.mode);
}

final class ScheduleSessionDateSelected extends ScheduleSessionEvent {
  final DateTime date;
  ScheduleSessionDateSelected(this.date);
}

final class ScheduleSessionTimeSelected extends ScheduleSessionEvent {
  final TimeOfDay time;
  ScheduleSessionTimeSelected(this.time);
}

final class ScheduleSessionDurationSelected extends ScheduleSessionEvent {
  final int minutes;
  ScheduleSessionDurationSelected(this.minutes);
}

final class ScheduleSessionParentNotesChanged extends ScheduleSessionEvent {
  final String notes;
  ScheduleSessionParentNotesChanged(this.notes);
}

final class ScheduleSessionPrivateNotesChanged extends ScheduleSessionEvent {
  final String notes;
  ScheduleSessionPrivateNotesChanged(this.notes);
}

final class ScheduleSessionSubmitted extends ScheduleSessionEvent {}
