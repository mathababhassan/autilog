import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

class ChildRegistrationState extends Equatable {
  final String name;
  final String? nameError;
  final String age;
  final String? ageError;
  final String asdSeverity;
  final String gender;
  final String therapistEmail;
  final FormzSubmissionStatus status;
  final String? serverError;

  const ChildRegistrationState({
    this.name = '',
    this.nameError,
    this.age = '',
    this.ageError,
    this.asdSeverity = 'Level 1',
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
    String? asdSeverity,
    String? gender,
    String? therapistEmail,
    FormzSubmissionStatus? status,
    String? serverError,
  }) {
    return ChildRegistrationState(
      name: name ?? this.name,
      nameError: nameError ?? this.nameError,
      age: age ?? this.age,
      ageError: ageError ?? this.ageError,
      asdSeverity: asdSeverity ?? this.asdSeverity,
      gender: gender ?? this.gender,
      therapistEmail: therapistEmail ?? this.therapistEmail,
      status: status ?? this.status,
      serverError: serverError ?? this.serverError,
    );
  }

  @override
  List<Object?> get props =>
      [name, nameError, age, ageError, asdSeverity, gender, therapistEmail, status, serverError];
}
