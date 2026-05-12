part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — auth status not yet known (app is starting up).
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A user is logged in. [user] contains their profile and role.
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// No user is logged in.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
