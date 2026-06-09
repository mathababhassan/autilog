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
