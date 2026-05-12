part of 'therapist_registration_bloc.dart';

abstract class TherapistRegistrationEvent extends Equatable {
  const TherapistRegistrationEvent();

  @override
  List<Object> get props => [];
}

class TherapistRegistrationNameChanged extends TherapistRegistrationEvent {
  final String name;
  const TherapistRegistrationNameChanged(this.name);

  @override
  List<Object> get props => [name];
}

class TherapistRegistrationEmailChanged extends TherapistRegistrationEvent {
  final String email;
  const TherapistRegistrationEmailChanged(this.email);

  @override
  List<Object> get props => [email];
}

class TherapistRegistrationPasswordChanged extends TherapistRegistrationEvent {
  final String password;
  const TherapistRegistrationPasswordChanged(this.password);

  @override
  List<Object> get props => [password];
}

class TherapistRegistrationLicenceChanged extends TherapistRegistrationEvent {
  final String licence;
  const TherapistRegistrationLicenceChanged(this.licence);

  @override
  List<Object> get props => [licence];
}

class TherapistRegistrationClinicChanged extends TherapistRegistrationEvent {
  final String clinic;
  const TherapistRegistrationClinicChanged(this.clinic);

  @override
  List<Object> get props => [clinic];
}

class TherapistRegistrationSpecialisationChanged
    extends TherapistRegistrationEvent {
  final String specialisation;
  const TherapistRegistrationSpecialisationChanged(this.specialisation);

  @override
  List<Object> get props => [specialisation];
}

class TherapistRegistrationGenderChanged extends TherapistRegistrationEvent {
  final String gender;
  const TherapistRegistrationGenderChanged(this.gender);

  @override
  List<Object> get props => [gender];
}

class TherapistRegistrationSubmitted extends TherapistRegistrationEvent {
  const TherapistRegistrationSubmitted();
}