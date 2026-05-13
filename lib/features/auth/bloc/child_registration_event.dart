import 'package:equatable/equatable.dart';

abstract class ChildRegistrationEvent extends Equatable {
  const ChildRegistrationEvent();

  @override
  List<Object?> get props => [];
}

class ChildNameChanged extends ChildRegistrationEvent {
  final String name;
  const ChildNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

class ChildAgeChanged extends ChildRegistrationEvent {
  final String age;
  const ChildAgeChanged(this.age);

  @override
  List<Object?> get props => [age];
}

class ChildDobChanged extends ChildRegistrationEvent {
  final DateTime dob;
  const ChildDobChanged(this.dob);

  @override
  List<Object?> get props => [dob];
}

class ChildSeverityChanged extends ChildRegistrationEvent {
  final String severity;
  const ChildSeverityChanged(this.severity);

  @override
  List<Object?> get props => [severity];
}

class ChildGenderChanged extends ChildRegistrationEvent {
  final String gender;
  const ChildGenderChanged(this.gender);

  @override
  List<Object?> get props => [gender];
}

class ChildTherapistEmailChanged extends ChildRegistrationEvent {
  final String email;
  const ChildTherapistEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class ChildRegistrationSubmitted extends ChildRegistrationEvent {
  const ChildRegistrationSubmitted();
}