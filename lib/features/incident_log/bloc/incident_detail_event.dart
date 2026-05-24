import 'package:equatable/equatable.dart';
import '../../../shared/models/child_model.dart';

abstract class IncidentDetailEvent extends Equatable {
  const IncidentDetailEvent();

  @override
  List<Object?> get props => [];
}

class IncidentDetailStarted extends IncidentDetailEvent {
  const IncidentDetailStarted({
    required this.parentId,
    required this.childId,
    required this.incidentId,
    required this.child,
  });

  final String parentId;
  final String childId;
  final String incidentId;
  final ChildModel child;

  @override
  List<Object?> get props => [parentId, childId, incidentId, child];
}

class IncidentDetailDeleteRequested extends IncidentDetailEvent {
  const IncidentDetailDeleteRequested();
}
