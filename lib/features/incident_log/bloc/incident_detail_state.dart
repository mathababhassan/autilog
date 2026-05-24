import 'package:equatable/equatable.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/models/incident_model.dart';

enum IncidentDetailActionStatus { idle, deleting, deleteSuccess, deleteError }

abstract class IncidentDetailState extends Equatable {
  const IncidentDetailState();

  @override
  List<Object?> get props => [];
}

class IncidentDetailInitial extends IncidentDetailState {
  const IncidentDetailInitial();
}

class IncidentDetailLoading extends IncidentDetailState {
  const IncidentDetailLoading();
}

class IncidentDetailLoaded extends IncidentDetailState {
  const IncidentDetailLoaded({
    required this.incident,
    required this.child,
    this.actionStatus = IncidentDetailActionStatus.idle,
    this.actionMessage,
  });

  final IncidentModel incident;
  final ChildModel child;
  final IncidentDetailActionStatus actionStatus;
  final String? actionMessage;

  IncidentDetailLoaded copyWith({
    IncidentModel? incident,
    ChildModel? child,
    IncidentDetailActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return IncidentDetailLoaded(
      incident: incident ?? this.incident,
      child: child ?? this.child,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [incident, child, actionStatus, actionMessage];
}

class IncidentDetailError extends IncidentDetailState {
  const IncidentDetailError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
