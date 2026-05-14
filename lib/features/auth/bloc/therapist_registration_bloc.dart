import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

import '../../../core/utils/firebase_error_mapper.dart';
import '../../../core/utils/validators/validators.dart';
import '../data/auth_repository.dart';

part 'therapist_registration_event.dart';
part 'therapist_registration_state.dart';

class TherapistRegistrationBloc
    extends Bloc<TherapistRegistrationEvent, TherapistRegistrationState> {
  final AuthRepository _authRepository;

  TherapistRegistrationBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const TherapistRegistrationState()) {
    on<TherapistRegistrationNameChanged>(_onNameChanged);
    on<TherapistRegistrationEmailChanged>(_onEmailChanged);
    on<TherapistRegistrationPasswordChanged>(_onPasswordChanged);
    on<TherapistRegistrationLicenceChanged>(_onLicenceChanged);
    on<TherapistRegistrationClinicChanged>(_onClinicChanged);
    on<TherapistRegistrationSpecialisationChanged>(_onSpecialisationChanged);
    on<TherapistRegistrationGenderChanged>(_onGenderChanged);
    on<TherapistRegistrationSubmitted>(_onSubmitted);
  }

  void _onNameChanged(
    TherapistRegistrationNameChanged event,
    Emitter<TherapistRegistrationState> emit,
  ) =>
      emit(state.copyWith(name: event.name, nameError: null));

  void _onEmailChanged(
    TherapistRegistrationEmailChanged event,
    Emitter<TherapistRegistrationState> emit,
  ) =>
      emit(state.copyWith(email: event.email, emailError: null));

  void _onPasswordChanged(
    TherapistRegistrationPasswordChanged event,
    Emitter<TherapistRegistrationState> emit,
  ) =>
      emit(state.copyWith(password: event.password, passwordError: null));

  void _onLicenceChanged(
    TherapistRegistrationLicenceChanged event,
    Emitter<TherapistRegistrationState> emit,
  ) =>
      emit(state.copyWith(licence: event.licence, licenceError: null));

  void _onClinicChanged(
    TherapistRegistrationClinicChanged event,
    Emitter<TherapistRegistrationState> emit,
  ) =>
      emit(state.copyWith(clinic: event.clinic, clinicError: null));

  void _onSpecialisationChanged(
    TherapistRegistrationSpecialisationChanged event,
    Emitter<TherapistRegistrationState> emit,
  ) =>
      emit(state.copyWith(
        specialisation: event.specialisation,
        specialisationError: null,
      ));

  void _onGenderChanged(
    TherapistRegistrationGenderChanged event,
    Emitter<TherapistRegistrationState> emit,
  ) =>
      emit(state.copyWith(gender: event.gender));

  Future<void> _onSubmitted(
    TherapistRegistrationSubmitted event,
    Emitter<TherapistRegistrationState> emit,
  ) async {
    final nameInput = RequiredTextInput.dirty(state.name);
    final emailInput = EmailInput.dirty(state.email);
    final passwordInput = PasswordInput.dirty(state.password);
    final licenceInput = RequiredTextInput.dirty(state.licence);
    final clinicInput = RequiredTextInput.dirty(state.clinic);
    final specInput = RequiredTextInput.dirty(state.specialisation);

    final valid = Formz.validate(
      [nameInput, emailInput, passwordInput, licenceInput, clinicInput, specInput],
    );

    if (!valid) {
      emit(state.copyWith(
        nameError: nameInput.error?.fieldMessage('Full name'),
        emailError: emailInput.error?.message,
        passwordError: passwordInput.error?.message,
        licenceError: licenceInput.error?.fieldMessage('Licence number'),
        clinicError: clinicInput.error?.fieldMessage('Clinic name'),
        specialisationError: specInput.error?.fieldMessage('Specialisation'),
        serverError: null,
      ));
      return;
    }

    emit(state.copyWith(
      status: FormzSubmissionStatus.inProgress,
      serverError: null,
    ));

    try {
      await _authRepository.registerTherapist(
        email: state.email,
        password: state.password,
        name: state.name,
        licenceNumber: state.licence,
        clinicName: state.clinic,
        specialisation: state.specialisation,
        gender: state.gender ?? '',
      );
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        serverError: mapFirebaseAuthError(e.code),
      ));
    } catch (e) {
    emit(state.copyWith(
      status: FormzSubmissionStatus.failure,
      serverError: e.toString(),
    ));
  }
  }
}