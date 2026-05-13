import 'package:equatable/equatable.dart';
import '../../../../shared/models/therapist_model.dart';
import '../../../../shared/models/user_model.dart';

abstract class TherapistProfileState extends Equatable {
  const TherapistProfileState();

  @override
  List<Object?> get props => [];
}

class TherapistProfileInitial extends TherapistProfileState {
  const TherapistProfileInitial();
}

class TherapistProfileLoading extends TherapistProfileState {
  const TherapistProfileLoading();
}

class TherapistProfileLoaded extends TherapistProfileState {
  const TherapistProfileLoaded({
    required this.therapist,
    required this.user,
  });

  final TherapistModel therapist;
  final UserModel user;

  @override
  List<Object?> get props => [therapist, user];
}

class TherapistProfileUpdating extends TherapistProfileState {
  const TherapistProfileUpdating({
    required this.therapist,
    required this.user,
  });

  final TherapistModel therapist;
  final UserModel user;

  @override
  List<Object?> get props => [therapist, user];
}

class TherapistProfileUpdateSuccess extends TherapistProfileState {
  const TherapistProfileUpdateSuccess({
    required this.therapist,
    required this.user,
  });

  final TherapistModel therapist;
  final UserModel user;

  @override
  List<Object?> get props => [therapist, user];
}

class TherapistProfileDeleting extends TherapistProfileState {
  const TherapistProfileDeleting();
}

class TherapistProfileDeleted extends TherapistProfileState {
  const TherapistProfileDeleted();
}

class TherapistProfileSignedOut extends TherapistProfileState {
  const TherapistProfileSignedOut();
}

class TherapistProfileError extends TherapistProfileState {
  const TherapistProfileError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
