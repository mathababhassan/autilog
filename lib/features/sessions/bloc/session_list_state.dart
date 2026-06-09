import 'package:equatable/equatable.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/models/session_model.dart';

enum SessionListActionStatus { idle, success, error }

abstract class SessionListState extends Equatable {
  const SessionListState();

  @override
  List<Object?> get props => [];
}

class SessionListInitial extends SessionListState {
  const SessionListInitial();
}

class SessionListLoading extends SessionListState {
  const SessionListLoading();
}

/// The one data-bearing state. Holds every session for the therapist plus the
/// patient list, and remembers which patient is selected in the filter. The
/// Upcoming / Past splits are derived on demand so the filter can change
/// without another fetch.
class SessionListLoaded extends SessionListState {
  const SessionListLoaded({
    required this.allSessions,
    required this.patients,
    this.selectedChildId,
    this.actionStatus = SessionListActionStatus.idle,
    this.actionMessage,
  });

  final List<SessionModel> allSessions;
  final List<ChildModel> patients;

  /// null = "All Patients".
  final String? selectedChildId;

  /// One-shot feedback for an action (e.g. marking a session completed).
  /// Reset to idle on the next [copyWith] so a snackbar only fires once.
  final SessionListActionStatus actionStatus;
  final String? actionMessage;

  bool get isFiltered => selectedChildId != null;

  /// True when the therapist has no sessions at all (drives the full-screen
  /// "No sessions yet" empty state). Independent of the active filter.
  bool get hasAnySessions => allSessions.isNotEmpty;

  List<SessionModel> get _filtered => selectedChildId == null
      ? allSessions
      : allSessions.where((s) => s.childId == selectedChildId).toList();

  /// Upcoming = still `upcoming` AND not yet past its end time, soonest first.
  /// Time decides the *bucket* only; we never rewrite `status` from the clock.
  List<SessionModel> get upcoming {
    final list = _filtered
        .where((s) => s.status == 'upcoming' && !s.isPastDue)
        .toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  /// Past = completed + cancelled, **plus** past-due `upcoming` sessions
  /// (these surface as "Needs review" so the therapist resolves them).
  /// Most recent first.
  List<SessionModel> get past {
    final list = _filtered
        .where((s) =>
            s.status == 'completed' || s.status == 'cancelled' || s.isPastDue)
        .toList();
    list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return list;
  }

  /// The patient currently selected in the filter, or null for "All Patients".
  ChildModel? get selectedPatient {
    if (selectedChildId == null) return null;
    for (final p in patients) {
      if (p.childId == selectedChildId) return p;
    }
    return null;
  }

  /// Note: [actionStatus]/[actionMessage] default back to idle/null on every
  /// call, so action feedback is intentionally one-shot — only the copyWith
  /// that completes an action carries a success/error message.
  SessionListLoaded copyWith({
    List<SessionModel>? allSessions,
    List<ChildModel>? patients,
    String? selectedChildId,
    bool clearFilter = false,
    SessionListActionStatus actionStatus = SessionListActionStatus.idle,
    String? actionMessage,
  }) {
    return SessionListLoaded(
      allSessions: allSessions ?? this.allSessions,
      patients: patients ?? this.patients,
      selectedChildId:
          clearFilter ? null : (selectedChildId ?? this.selectedChildId),
      actionStatus: actionStatus,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props =>
      [allSessions, patients, selectedChildId, actionStatus, actionMessage];
}

class SessionListError extends SessionListState {
  const SessionListError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
