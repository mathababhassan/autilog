import 'package:equatable/equatable.dart';

import '../../../shared/models/positive_moment_model.dart';

enum PositiveMomentDetailActionStatus {
  idle,
  deleting,
  deleteSuccess,
  deleteError,
}

abstract class PositiveMomentDetailState extends Equatable {
  const PositiveMomentDetailState();

  @override
  List<Object?> get props => [];
}

class PositiveMomentDetailInitial extends PositiveMomentDetailState {
  const PositiveMomentDetailInitial();
}

class PositiveMomentDetailLoading extends PositiveMomentDetailState {
  const PositiveMomentDetailLoading();
}

class PositiveMomentDetailLoaded extends PositiveMomentDetailState {
  const PositiveMomentDetailLoaded({
    required this.moment,
    required this.childName,
    required this.linkedTherapistId,
    this.actionStatus = PositiveMomentDetailActionStatus.idle,
    this.actionMessage,
  });

  final PositiveMomentModel moment;
  final String childName;
  final String? linkedTherapistId;
  final PositiveMomentDetailActionStatus actionStatus;
  final String? actionMessage;

  PositiveMomentDetailLoaded copyWith({
    PositiveMomentModel? moment,
    String? childName,
    String? linkedTherapistId,
    PositiveMomentDetailActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return PositiveMomentDetailLoaded(
      moment: moment ?? this.moment,
      childName: childName ?? this.childName,
      linkedTherapistId: linkedTherapistId ?? this.linkedTherapistId,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props =>
      [moment, childName, linkedTherapistId, actionStatus, actionMessage];
}

class PositiveMomentDetailError extends PositiveMomentDetailState {
  const PositiveMomentDetailError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
