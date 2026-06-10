import 'package:equatable/equatable.dart';
import '../../../shared/models/child_model.dart';
import '../data/pending_request_display.dart';

enum PatientListActionStatus { idle, inProgress, success, error }

abstract class PatientListState extends Equatable {
  const PatientListState();

  @override
  List<Object?> get props => [];
}

class PatientListInitial extends PatientListState {
  const PatientListInitial();
}

class PatientListLoading extends PatientListState {
  const PatientListLoading();
}

class PatientListLoaded extends PatientListState {
  const PatientListLoaded({
    required this.pendingRequests,
    required this.activePatients,
    this.actionStatus = PatientListActionStatus.idle,
    this.actionMessage,
  });

  final List<PendingRequestDisplay> pendingRequests;
  /// Each entry is (patient, parentName).
  final List<(ChildModel, String)> activePatients;
  final PatientListActionStatus actionStatus;
  final String? actionMessage;

  PatientListLoaded copyWith({
    List<PendingRequestDisplay>? pendingRequests,
    List<(ChildModel, String)>? activePatients,
    PatientListActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return PatientListLoaded(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activePatients: activePatients ?? this.activePatients,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props =>
      [pendingRequests, activePatients, actionStatus, actionMessage];
}

class PatientListError extends PatientListState {
  const PatientListError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
