import 'package:equatable/equatable.dart';

abstract class SessionDetailEvent extends Equatable {
  const SessionDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when the screen opens. Carries the id to fetch.
class SessionDetailStarted extends SessionDetailEvent {
  const SessionDetailStarted({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// Fired when the therapist taps "Join Meeting" on a Virtual session.
/// Triggers minting a JaaS token and (on success) opening the call URL.
class SessionJoinRequested extends SessionDetailEvent {
  const SessionJoinRequested();
}

/// Marks the session as completed (therapist-confirmed), then reloads so the
/// status pill and available actions update.
class SessionDetailMarkCompleted extends SessionDetailEvent {
  const SessionDetailMarkCompleted({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// Reschedules the session to a new date/time/duration/mode, then reloads.
class SessionDetailRescheduleRequested extends SessionDetailEvent {
  const SessionDetailRescheduleRequested({
    required this.sessionId,
    required this.newStart,
    required this.newEnd,
    required this.mode,
    required this.location,
  });

  final String sessionId;
  final DateTime newStart;
  final DateTime newEnd;
  final String mode;
  final String location;

  @override
  List<Object?> get props => [sessionId, newStart, newEnd, mode, location];
}
