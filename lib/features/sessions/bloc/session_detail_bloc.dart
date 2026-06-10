import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/child_model.dart';
import '../data/jaas_repository.dart';
import '../data/session_repository.dart';
import 'session_detail_event.dart';
import 'session_detail_state.dart';

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required this.repository,
    JaasRepository? jaasRepository,
  })  : jaasRepository = jaasRepository ?? JaasRepository(),
        super(const SessionDetailInitial()) {
    on<SessionDetailStarted>(_onStarted);
    on<SessionJoinRequested>(_onJoinRequested);
    on<SessionDetailMarkCompleted>(_onMarkCompleted);
    on<SessionDetailRescheduleRequested>(_onRescheduleRequested);
    on<SessionDetailCancelRequested>(_onCancelRequested);
  }

  final SessionRepository repository;
  final JaasRepository jaasRepository;

  Future<void> _onStarted(
    SessionDetailStarted event,
    Emitter<SessionDetailState> emit,
  ) async {
    emit(const SessionDetailLoading());
    try {
      final session = await repository.fetchSessionById(event.sessionId);

      // The patient sub-line is secondary: if the child read fails, still
      // show the session with child = null rather than failing the screen.
      ChildModel? child;
      try {
        child = await repository.fetchChild(
          parentId: session.parentId,
          childId: session.childId,
        );
      } catch (_) {
        child = null;
      }

      emit(SessionDetailLoaded(session: session, child: child));
    } catch (_) {
      emit(const SessionDetailError(
        message: 'Could not load this session. Please try again.',
      ));
    }
  }

  Future<void> _onJoinRequested(
    SessionJoinRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final current = state;
    if (current is! SessionDetailLoaded) return;

    emit(current.copyWith(joinStatus: JoinStatus.loading));
    try {
      final result = await jaasRepository.fetchJoinToken(current.session.id);
      if (emit.isDone) return;
      emit(current.copyWith(
        joinStatus: JoinStatus.success,
        joinUrl: result.joinUrl,
      ));
    } catch (_) {
      if (emit.isDone) return;
      emit(current.copyWith(
        joinStatus: JoinStatus.failure,
        joinError: 'Could not start the call. Please try again.',
      ));
    }
  }

  Future<void> _onMarkCompleted(
    SessionDetailMarkCompleted event,
    Emitter<SessionDetailState> emit,
  ) async {
    final current = state;
    if (current is! SessionDetailLoaded) return;

    try {
      await repository.markSessionCompleted(event.sessionId);
      final session = await repository.fetchSessionById(event.sessionId);
      emit(SessionDetailLoaded(
        session: session,
        child: current.child,
        actionMessage: 'Session marked as completed.',
      ));
    } catch (_) {
      emit(SessionDetailLoaded(
        session: current.session,
        child: current.child,
        actionMessage: 'Could not update the session. Please try again.',
        actionIsError: true,
      ));
    }
  }

  Future<void> _onCancelRequested(
    SessionDetailCancelRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final current = state;
    if (current is! SessionDetailLoaded) return;

    try {
      await repository.cancelSession(event.sessionId);
      final session = await repository.fetchSessionById(event.sessionId);
      emit(SessionDetailLoaded(
        session: session,
        child: current.child,
        actionMessage: 'Session cancelled.',
      ));
    } catch (_) {
      emit(SessionDetailLoaded(
        session: current.session,
        child: current.child,
        actionMessage: 'Could not cancel. Please try again.',
        actionIsError: true,
      ));
    }
  }

  Future<void> _onRescheduleRequested(
    SessionDetailRescheduleRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final current = state;
    if (current is! SessionDetailLoaded) return;

    emit(current.copyWith(isRescheduling: true));
    try {
      await repository.rescheduleSession(
        sessionId: event.sessionId,
        newStart: event.newStart,
        newEnd: event.newEnd,
        mode: event.mode,
        location: event.location,
        durationMinutes: event.durationMinutes,
      );
      final session = await repository.fetchSessionById(event.sessionId);
      emit(SessionDetailLoaded(
        session: session,
        child: current.child,
        actionMessage: 'Session rescheduled.',
      ));
    } catch (_) {
      emit(SessionDetailLoaded(
        session: current.session,
        child: current.child,
        actionMessage: 'Could not reschedule. Please try again.',
        actionIsError: true,
      ));
    }
  }
}
