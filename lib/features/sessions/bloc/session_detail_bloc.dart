import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/child_model.dart';
import '../data/session_repository.dart';
import 'session_detail_event.dart';
import 'session_detail_state.dart';

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({required this.repository})
      : super(const SessionDetailInitial()) {
    on<SessionDetailStarted>(_onStarted);
  }

  final SessionRepository repository;

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
}
