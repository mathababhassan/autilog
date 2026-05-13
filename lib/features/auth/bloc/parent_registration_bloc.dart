import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

import '../../../features/auth/data/auth_repository.dart';

part 'parent_registration_event.dart';
part 'parent_registration_state.dart';

class ParentRegistrationBloc
    extends Bloc<ParentRegistrationEvent, ParentRegistrationState> {
  ParentRegistrationBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const ParentRegistrationState()) {
    on<ParentRegistrationNameChanged>(_onNameChanged);
    on<ParentRegistrationEmailChanged>(_onEmailChanged);
    on<ParentRegistrationPasswordChanged>(_onPasswordChanged);
    on<ParentRegistrationGenderChanged>(_onGenderChanged);
    on<ParentRegistrationProfilePhotoChanged>(_onProfilePhotoChanged);
    on<ParentRegistrationTermsToggled>(_onTermsToggled);
    on<ParentRegistrationSubmitted>(_onSubmitted);
  }

  final AuthRepository _authRepository;

  // ── Field change handlers ─────────────────────────────────────────────────

  void _onNameChanged(
    ParentRegistrationNameChanged event,
    Emitter<ParentRegistrationState> emit,
  ) {
    emit(state.copyWith(name: event.name, clearNameError: true));
  }

  void _onEmailChanged(
    ParentRegistrationEmailChanged event,
    Emitter<ParentRegistrationState> emit,
  ) {
    emit(state.copyWith(email: event.email, clearEmailError: true));
  }

  void _onPasswordChanged(
    ParentRegistrationPasswordChanged event,
    Emitter<ParentRegistrationState> emit,
  ) {
    emit(state.copyWith(password: event.password, clearPasswordError: true));
  }

  void _onGenderChanged(
    ParentRegistrationGenderChanged event,
    Emitter<ParentRegistrationState> emit,
  ) {
    emit(state.copyWith(gender: event.gender));
  }

  void _onProfilePhotoChanged(
    ParentRegistrationProfilePhotoChanged event,
    Emitter<ParentRegistrationState> emit,
  ) {
    if (event.path == null) {
      emit(state.copyWith(clearProfilePhoto: true));
    } else {
      emit(state.copyWith(profilePhotoPath: event.path));
    }
  }

  void _onTermsToggled(
    ParentRegistrationTermsToggled event,
    Emitter<ParentRegistrationState> emit,
  ) {
    emit(state.copyWith(
      termsAccepted: !state.termsAccepted,
      clearTermsError: true,
    ));
  }

  // ── Submission ────────────────────────────────────────────────────────────

  Future<void> _onSubmitted(
    ParentRegistrationSubmitted event,
    Emitter<ParentRegistrationState> emit,
  ) async {
    final nameError = _validateName(state.name);
    final emailError = _validateEmail(state.email);
    final passwordError = _validatePassword(state.password);
    final termsError =
        state.termsAccepted ? null : 'You must accept the Terms of Service';

    final hasErrors = nameError != null ||
        emailError != null ||
        passwordError != null ||
        termsError != null;

    if (hasErrors) {
      emit(state.copyWith(
        nameError: nameError,
        emailError: emailError,
        passwordError: passwordError,
        termsError: termsError,
      ));
      return;
    }

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    try {
      await _authRepository.registerParent(
        email: state.email.trim(),
        password: state.password,
        name: state.name.trim(),
        gender: state.gender,
        profilePhotoBase64: state.profilePhotoPath,
      );
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        serverError: _mapError(e),
      ));
    }
  }

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'This field is required';
    if (value.trim().length < 2) return 'Must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String _mapError(Object e) {
    final message = e.toString();
    if (message.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('weak-password')) {
      return 'Password is too weak.';
    }
    if (message.contains('network-request-failed')) {
      return 'No internet connection. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}