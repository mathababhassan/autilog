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
