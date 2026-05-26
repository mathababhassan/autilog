import 'package:equatable/equatable.dart';
import '../../../shared/models/child_model.dart';
import 'link_status.dart';

enum ActionStatus { idle, inProgress, success, error }

abstract class ChildProfileState extends Equatable {
  const ChildProfileState();
  @override
  List<Object?> get props => [];
}

class ChildProfileInitial extends ChildProfileState {
  const ChildProfileInitial();
}

class ChildProfileLoading extends ChildProfileState {
  const ChildProfileLoading();
}

class ChildProfileLoaded extends ChildProfileState {
  const ChildProfileLoaded({
    required this.child,
    required this.linkStatus,
    this.actionStatus = ActionStatus.idle,
    this.actionMessage,
  });

  final ChildModel child;
  final LinkStatus linkStatus;
  final ActionStatus actionStatus;
  final String? actionMessage;

  ChildProfileLoaded copyWith({
    ChildModel? child,
    LinkStatus? linkStatus,
    ActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return ChildProfileLoaded(
      child: child ?? this.child,
      linkStatus: linkStatus ?? this.linkStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [child, linkStatus, actionStatus, actionMessage];
}

class ChildProfileError extends ChildProfileState {
  const ChildProfileError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}
