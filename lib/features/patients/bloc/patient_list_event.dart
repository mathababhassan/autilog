import 'package:equatable/equatable.dart';

abstract class PatientListEvent extends Equatable {
  const PatientListEvent();

  @override
  List<Object?> get props => [];
}

class PatientListStarted extends PatientListEvent {
  const PatientListStarted();
}

class PatientListRefreshRequested extends PatientListEvent {
  const PatientListRefreshRequested();
}

class PendingRequestAccepted extends PatientListEvent {
  const PendingRequestAccepted({
    required this.requestId,
    required this.parentId,
    required this.childId,
  });

  final String requestId;
  final String parentId;
  final String childId;

  @override
  List<Object?> get props => [requestId, parentId, childId];
}

class PendingRequestRejected extends PatientListEvent {
  const PendingRequestRejected({required this.requestId});

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

class ActivePatientRemoved extends PatientListEvent {
  const ActivePatientRemoved({
    required this.parentId,
    required this.childId,
  });

  final String parentId;
  final String childId;

  @override
  List<Object?> get props => [parentId, childId];
}
