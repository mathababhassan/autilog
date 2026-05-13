import 'package:equatable/equatable.dart';

abstract class TherapistProfileEvent extends Equatable {
  const TherapistProfileEvent();

  @override
  List<Object?> get props => [];
}

class TherapistProfileStarted extends TherapistProfileEvent {
  const TherapistProfileStarted();
}

class TherapistProfileUpdateRequested extends TherapistProfileEvent {
  const TherapistProfileUpdateRequested({required this.fields});

  final Map<String, dynamic> fields;

  @override
  List<Object?> get props => [fields];
}

class TherapistProfileDeleteRequested extends TherapistProfileEvent {
  const TherapistProfileDeleteRequested();
}

class TherapistProfileSignOutRequested extends TherapistProfileEvent {
  const TherapistProfileSignOutRequested();
}
