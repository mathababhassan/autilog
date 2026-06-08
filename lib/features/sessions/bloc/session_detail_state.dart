import 'package:equatable/equatable.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/models/session_model.dart';

abstract class SessionDetailState extends Equatable {
  const SessionDetailState();

  @override
  List<Object?> get props => [];
}

class SessionDetailInitial extends SessionDetailState {
  const SessionDetailInitial();
}

class SessionDetailLoading extends SessionDetailState {
  const SessionDetailLoading();
}

class SessionDetailLoaded extends SessionDetailState {
  const SessionDetailLoaded({required this.session, this.child});

  final SessionModel session;

  /// Nullable: the patient sub-line (diagnosis · age) is hidden if the
  /// child read fails, so a child error degrades gracefully instead of
  /// taking down the whole screen.
  final ChildModel? child;

  @override
  List<Object?> get props => [session, child];
}

class SessionDetailError extends SessionDetailState {
  const SessionDetailError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
