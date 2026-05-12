part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on app start — begins listening to the auth stream.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Fired when the user taps "Log out".
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
