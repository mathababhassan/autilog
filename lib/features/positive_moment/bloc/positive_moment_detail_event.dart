import 'package:equatable/equatable.dart';

abstract class PositiveMomentDetailEvent extends Equatable {
  const PositiveMomentDetailEvent();

  @override
  List<Object?> get props => [];
}

class PositiveMomentDetailStarted extends PositiveMomentDetailEvent {
  const PositiveMomentDetailStarted({
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.momentId,
  });

  final String parentId;
  final String childId;
  final String childName;
  final String momentId;

  @override
  List<Object?> get props => [parentId, childId, childName, momentId];
}

class PositiveMomentDetailDeleteRequested extends PositiveMomentDetailEvent {
  const PositiveMomentDetailDeleteRequested();
}
