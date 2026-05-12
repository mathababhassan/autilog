part of 'parent_registration_bloc.dart';

abstract class ParentRegistrationEvent extends Equatable {
  const ParentRegistrationEvent();

  @override
  List<Object?> get props => [];
}

class ParentRegistrationNameChanged extends ParentRegistrationEvent {
  final String name;
  const ParentRegistrationNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

class ParentRegistrationEmailChanged extends ParentRegistrationEvent {
  final String email;
  const ParentRegistrationEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class ParentRegistrationPasswordChanged extends ParentRegistrationEvent {
  final String password;
  const ParentRegistrationPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class ParentRegistrationGenderChanged extends ParentRegistrationEvent {
  final String gender;
  const ParentRegistrationGenderChanged(this.gender);

  @override
  List<Object?> get props => [gender];
}

class ParentRegistrationProfilePhotoChanged extends ParentRegistrationEvent {
  final String? path;
  const ParentRegistrationProfilePhotoChanged(this.path);

  @override
  List<Object?> get props => [path];
}

class ParentRegistrationChildNameChanged extends ParentRegistrationEvent {
  final String childName;
  const ParentRegistrationChildNameChanged(this.childName);

  @override
  List<Object?> get props => [childName];
}

class ParentRegistrationChildAgeChanged extends ParentRegistrationEvent {
  final String childAge;
  const ParentRegistrationChildAgeChanged(this.childAge);

  @override
  List<Object?> get props => [childAge];
}

class ParentRegistrationAsdSeverityChanged extends ParentRegistrationEvent {
  final String severity;
  const ParentRegistrationAsdSeverityChanged(this.severity);

  @override
  List<Object?> get props => [severity];
}

class ParentRegistrationTermsToggled extends ParentRegistrationEvent {
  final bool termsAccepted; // Add this field
  const ParentRegistrationTermsToggled(this.termsAccepted); // Add this constructor

  @override
  List<Object?> get props => [termsAccepted]; // Add it to props for equality checks
}

class ParentRegistrationSubmitted extends ParentRegistrationEvent {
  const ParentRegistrationSubmitted();
}
