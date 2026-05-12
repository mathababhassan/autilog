part of 'therapist_registration_bloc.dart';

// Sentinel used by copyWith to distinguish "not passed" from "explicitly null"
// for nullable error fields.
const _absent = Object();

class TherapistRegistrationState extends Equatable {
  final String name;
  final String email;
  final String password;
  final String licence;
  final String clinic;
  final String specialisation;
  final String? gender;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? licenceError;
  final String? clinicError;
  final String? specialisationError;
  final FormzSubmissionStatus status;
  final String? serverError;

  const TherapistRegistrationState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.licence = '',
    this.clinic = '',
    this.specialisation = '',
    this.gender,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.licenceError,
    this.clinicError,
    this.specialisationError,
    this.status = FormzSubmissionStatus.initial,
    this.serverError,
  });

  TherapistRegistrationState copyWith({
    String? name,
    String? email,
    String? password,
    String? licence,
    String? clinic,
    String? specialisation,
    Object? gender = _absent,
    Object? nameError = _absent,
    Object? emailError = _absent,
    Object? passwordError = _absent,
    Object? licenceError = _absent,
    Object? clinicError = _absent,
    Object? specialisationError = _absent,
    FormzSubmissionStatus? status,
    Object? serverError = _absent,
  }) {
    return TherapistRegistrationState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      licence: licence ?? this.licence,
      clinic: clinic ?? this.clinic,
      specialisation: specialisation ?? this.specialisation,
      gender: gender == _absent ? this.gender : gender as String?,
      nameError:
          nameError == _absent ? this.nameError : nameError as String?,
      emailError:
          emailError == _absent ? this.emailError : emailError as String?,
      passwordError:
          passwordError == _absent ? this.passwordError : passwordError as String?,
      licenceError:
          licenceError == _absent ? this.licenceError : licenceError as String?,
      clinicError:
          clinicError == _absent ? this.clinicError : clinicError as String?,
      specialisationError: specialisationError == _absent
          ? this.specialisationError
          : specialisationError as String?,
      status: status ?? this.status,
      serverError:
          serverError == _absent ? this.serverError : serverError as String?,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        licence,
        clinic,
        specialisation,
        gender,
        nameError,
        emailError,
        passwordError,
        licenceError,
        clinicError,
        specialisationError,
        status,
        serverError,
      ];
}