import 'package:equatable/equatable.dart';

abstract class ChildProfileEvent extends Equatable {
  const ChildProfileEvent();
  @override
  List<Object?> get props => [];
}

class ChildProfileStarted extends ChildProfileEvent {
  const ChildProfileStarted({required this.parentId, required this.childId});
  final String parentId;
  final String childId;
  @override
  List<Object?> get props => [parentId, childId];
}

class LinkRequestSubmitted extends ChildProfileEvent {
  const LinkRequestSubmitted({required this.therapistEmail});
  final String therapistEmail;
  @override
  List<Object?> get props => [therapistEmail];
}

class LinkRequestCancelled extends ChildProfileEvent {
  const LinkRequestCancelled({required this.requestId});
  final String requestId;
  @override
  List<Object?> get props => [requestId];
}

class TherapistAccessRevoked extends ChildProfileEvent {
  const TherapistAccessRevoked({
    required this.therapistId,
    required this.childId,
  });
  final String therapistId;
  final String childId;
  @override
  List<Object?> get props => [therapistId, childId];
}
