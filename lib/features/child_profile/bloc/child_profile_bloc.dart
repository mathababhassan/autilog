import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/child_profile_repository.dart';
import 'child_profile_event.dart';
import 'child_profile_state.dart';
import 'link_status.dart';

class ChildProfileBloc extends Bloc<ChildProfileEvent, ChildProfileState> {
  ChildProfileBloc({required this.repository})
      : super(const ChildProfileInitial()) {
    on<ChildProfileStarted>(_onStarted);
    on<LinkRequestSubmitted>(_onLinkRequestSubmitted);
    on<LinkRequestCancelled>(_onLinkRequestCancelled);
    on<TherapistAccessRevoked>(_onTherapistAccessRevoked);
  }

  final ChildProfileRepository repository;

  Future<void> _onStarted(
    ChildProfileStarted event,
    Emitter<ChildProfileState> emit,
  ) async {
    emit(const ChildProfileLoading());
    try {
      final (child, linkStatus) = await repository.fetchChildWithLinkStatus(
        parentId: event.parentId,
        childId: event.childId,
      );
      emit(ChildProfileLoaded(child: child, linkStatus: linkStatus));
    } catch (_) {
      emit(const ChildProfileError(
        message: 'Could not load child profile. Please try again.',
      ));
    }
  }

  Future<void> _onLinkRequestSubmitted(
    LinkRequestSubmitted event,
    Emitter<ChildProfileState> emit,
  ) async {
    final current = state;
    if (current is! ChildProfileLoaded) return;

    emit(current.copyWith(actionStatus: ActionStatus.inProgress));
    try {
      await repository.sendLinkRequest(
        parentId: current.child.parentId,
        childId: current.child.childId,
        therapistEmail: event.therapistEmail,
      );
      // Reload link status so the pending card appears immediately.
      final (child, linkStatus) = await repository.fetchChildWithLinkStatus(
        parentId: current.child.parentId,
        childId: current.child.childId,
      );
      emit(ChildProfileLoaded(
        child: child,
        linkStatus: linkStatus,
        actionStatus: ActionStatus.success,
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: ActionStatus.error,
        actionMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onLinkRequestCancelled(
    LinkRequestCancelled event,
    Emitter<ChildProfileState> emit,
  ) async {
    final current = state;
    if (current is! ChildProfileLoaded) return;

    emit(current.copyWith(actionStatus: ActionStatus.inProgress));
    try {
      await repository.cancelLinkRequest(event.requestId);
      emit(current.copyWith(
        linkStatus: const NoLink(),
        actionStatus: ActionStatus.idle,
      ));
    } catch (_) {
      emit(current.copyWith(
        actionStatus: ActionStatus.error,
        actionMessage: 'Could not cancel the request. Please try again.',
      ));
    }
  }

  Future<void> _onTherapistAccessRevoked(
    TherapistAccessRevoked event,
    Emitter<ChildProfileState> emit,
  ) async {
    final current = state;
    if (current is! ChildProfileLoaded) return;

    emit(current.copyWith(actionStatus: ActionStatus.inProgress));
    try {
      await repository.revokeTherapistAccess(
        parentId: current.child.parentId,
        childId: event.childId,
        therapistId: event.therapistId,
      );
      emit(current.copyWith(
        linkStatus: const NoLink(),
        actionStatus: ActionStatus.idle,
      ));
    } catch (_) {
      emit(current.copyWith(
        actionStatus: ActionStatus.error,
        actionMessage: 'Could not revoke access. Please try again.',
      ));
    }
  }
}
