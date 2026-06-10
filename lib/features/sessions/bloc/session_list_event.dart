import 'package:equatable/equatable.dart';

abstract class SessionListEvent extends Equatable {
  const SessionListEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when the screen opens: loads the therapist's sessions and the
/// patient list used by the filter dropdown.
class SessionListStarted extends SessionListEvent {
  const SessionListStarted();
}

/// Re-runs the same load (e.g. pull-to-refresh or returning from scheduling).
class SessionListRefreshRequested extends SessionListEvent {
  const SessionListRefreshRequested();
}

/// Changes the active patient filter. A null [childId] means "All Patients".
/// Filtering happens in memory, so this never hits Firestore.
class SessionPatientFilterChanged extends SessionListEvent {
  const SessionPatientFilterChanged(this.childId);

  final String? childId;

  @override
  List<Object?> get props => [childId];
}

/// Marks an upcoming session as completed (therapist-confirmed). Writes the new
/// status, then reloads so the card moves from Upcoming to Past.
class SessionMarkedCompleted extends SessionListEvent {
  const SessionMarkedCompleted(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// Reschedules a session to a new date/time/duration/mode. Writes to Firestore,
/// then reloads so the card reflects the updated values.
class SessionRescheduleRequested extends SessionListEvent {
  const SessionRescheduleRequested({
    required this.sessionId,
    required this.newStart,
    required this.newEnd,
    required this.mode,
    required this.location,
    required this.durationMinutes,
  });

  final String sessionId;
  final DateTime newStart;
  final DateTime newEnd;
  final String mode;
  final String location;
  final int durationMinutes;

  @override
  List<Object?> get props =>
      [sessionId, newStart, newEnd, mode, location, durationMinutes];
}
