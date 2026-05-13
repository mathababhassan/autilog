import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

class ChildRegistrationState extends Equatable {
  final String name;
  final String? nameError;
  final String age;
  final String? ageError;
  final DateTime? dob;
  final String asdSeverity;
  final String? asdSeverityError;
  final String gender;
  final String therapistEmail;
  final FormzSubmissionStatus status;
  final String? serverError;

  const ChildRegistrationState({
    this.name = '',
    this.nameError,
    this.age = '',
    this.ageError,
    this.dob,
    this.asdSeverity = '',
    this.asdSeverityError,
    this.gender = '',
    this.therapistEmail = '',
    this.status = FormzSubmissionStatus.initial,
    this.serverError,
  });

  ChildRegistrationState copyWith({
    String? name,
    String? nameError,
    String? age,
    String? ageError,
    DateTime? dob,
    String? asdSeverity,
    String? asdSeverityError,
    String? gender,
    String? therapistEmail,
    FormzSubmissionStatus? status,
    String? serverError,
    bool clearNameError = false,
    bool clearAgeError = false,
    bool clearAsdSeverityError = false,
    bool clearServerError = false,
  }) {
    return ChildRegistrationState(
      name: name ?? this.name,
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      age: age ?? this.age,
      ageError: clearAgeError ? null : (ageError ?? this.ageError),
      dob: dob ?? this.dob,
      asdSeverity: asdSeverity ?? this.asdSeverity,
      asdSeverityError: clearAsdSeverityError
          ? null
          : (asdSeverityError ?? this.asdSeverityError),
      gender: gender ?? this.gender,
      therapistEmail: therapistEmail ?? this.therapistEmail,
      status: status ?? this.status,
      serverError:
          clearServerError ? null : (serverError ?? this.serverError),
    );
  }

  @override
  List<Object?> get props => [
        name,
        nameError,
        age,
        ageError,
        dob,
        asdSeverity,
        asdSeverityError,
        gender,
        therapistEmail,
        status,
        serverError,
      ];
}