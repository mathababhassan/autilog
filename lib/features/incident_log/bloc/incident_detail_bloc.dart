import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/incident_repository.dart';
import 'incident_detail_event.dart';
import 'incident_detail_state.dart';

class IncidentDetailBloc extends Bloc<IncidentDetailEvent, IncidentDetailState> {
  IncidentDetailBloc({required this.repository})
      : super(const IncidentDetailInitial()) {
    on<IncidentDetailStarted>(_onStarted);
    on<IncidentDetailDeleteRequested>(_onDeleteRequested);
  }

  final IncidentRepository repository;

  Future<void> _onStarted(
    IncidentDetailStarted event,
    Emitter<IncidentDetailState> emit,
  ) async {
    emit(const IncidentDetailLoading());
    try {
      final incident = await repository.fetchIncident(
        parentId: event.parentId,
        childId: event.childId,
        incidentId: event.incidentId,
      );
      emit(IncidentDetailLoaded(incident: incident, child: event.child));
    } catch (e) {
      emit(const IncidentDetailError(message: 'Could not load the incident. Please try again.'));
    }
  }

  Future<void> _onDeleteRequested(
    IncidentDetailDeleteRequested event,
    Emitter<IncidentDetailState> emit,
  ) async {
    final current = state;
    if (current is! IncidentDetailLoaded) return;

    emit(current.copyWith(actionStatus: IncidentDetailActionStatus.deleting));
    try {
      await repository.deleteIncident(
        parentId: current.child.parentId,
        childId: current.child.childId,
        incidentId: current.incident.id,
      );
      emit(current.copyWith(actionStatus: IncidentDetailActionStatus.deleteSuccess));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: IncidentDetailActionStatus.deleteError,
        actionMessage: 'Could not delete the incident. Please try again.',
      ));
    }
  }
}
