import 'package:equatable/equatable.dart';
import '../../../../shared/models/session_model.dart';

class UrgentPatient extends Equatable {
  final String childId;
  final String childName;
  final String alertMessage;
  final int severity;

  const UrgentPatient({
    required this.childId,
    required this.childName,
    required this.alertMessage,
    required this.severity,
  });

  @override
  List<Object?> get props => [childId, severity];
}

abstract class TherapistHomeState extends Equatable {
  const TherapistHomeState();

  @override
  List<Object?> get props => [];
}

class TherapistHomeInitial extends TherapistHomeState {
  const TherapistHomeInitial();
}

class TherapistHomeLoading extends TherapistHomeState {
  const TherapistHomeLoading();
}

class TherapistHomeLoaded extends TherapistHomeState {
  final List<SessionModel> sessionsToday;
  final int newLogsCount;
  final int urgentAlertsCount;
  final List<UrgentPatient> needsAttention;

  const TherapistHomeLoaded({
    required this.sessionsToday,
    required this.newLogsCount,
    required this.urgentAlertsCount,
    required this.needsAttention,
  });

  @override
  List<Object?> get props =>
      [sessionsToday, newLogsCount, urgentAlertsCount, needsAttention];
}

class TherapistHomeError extends TherapistHomeState {
  final String message;

  const TherapistHomeError({required this.message});

  @override
  List<Object?> get props => [message];
}