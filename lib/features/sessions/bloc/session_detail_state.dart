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

/// Sub-status of the "Join Meeting" action, layered on top of the loaded
/// session so the screen stays put while a join is in flight.
enum JoinStatus { idle, loading, success, failure }

class SessionDetailLoaded extends SessionDetailState {
  const SessionDetailLoaded({
    required this.session,
    this.child,
    this.joinStatus = JoinStatus.idle,
    this.joinUrl,
    this.joinError,
  });

  final SessionModel session;

  /// Nullable: the patient sub-line (diagnosis · age) is hidden if the
  /// child read fails, so a child error degrades gracefully instead of
  /// taking down the whole screen.
  final ChildModel? child;

  /// Join-action lifecycle. The button spins on [JoinStatus.loading]; the UI
  /// launches [joinUrl] on [JoinStatus.success] and shows [joinError] on
  /// [JoinStatus.failure].
  final JoinStatus joinStatus;

  /// Set only on [JoinStatus.success] — the 8x8 URL to open.
  final Uri? joinUrl;

  /// Set only on [JoinStatus.failure] — a user-friendly message.
  final String? joinError;

  SessionDetailLoaded copyWith({
    JoinStatus? joinStatus,
    Uri? joinUrl,
    String? joinError,
  }) {
    return SessionDetailLoaded(
      session: session,
      child: child,
      joinStatus: joinStatus ?? this.joinStatus,
      joinUrl: joinUrl,
      joinError: joinError,
    );
  }

  @override
  List<Object?> get props => [session, child, joinStatus, joinUrl, joinError];
}

class SessionDetailError extends SessionDetailState {
  const SessionDetailError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
