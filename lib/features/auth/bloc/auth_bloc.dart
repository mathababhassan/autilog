import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/user_model.dart';
import '../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  /// Subscribes to [AuthRepository.authStateChanges] for the lifetime
  /// of the bloc. Every time Firebase fires (login / logout / token refresh),
  /// this emits the matching [AuthAuthenticated] or [AuthUnauthenticated] state.
  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    await emit.forEach(
      _authRepository.authStateChanges,
      onData: (user) =>
          user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
      onError: (_, _) => const AuthUnauthenticated(),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    // authStateChanges stream will emit null → AuthUnauthenticated automatically.
  }
}
