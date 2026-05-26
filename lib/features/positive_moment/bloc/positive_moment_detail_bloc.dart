import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/positive_moment_repository.dart';
import 'positive_moment_detail_event.dart';
import 'positive_moment_detail_state.dart';

class PositiveMomentDetailBloc
    extends Bloc<PositiveMomentDetailEvent, PositiveMomentDetailState> {
  PositiveMomentDetailBloc({
    required this.repository,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const PositiveMomentDetailInitial()) {
    on<PositiveMomentDetailStarted>(_onStarted);
    on<PositiveMomentDetailDeleteRequested>(_onDeleteRequested);
  }

  final PositiveMomentRepository repository;
  final FirebaseFirestore _firestore;

  String? _parentId;
  String? _childId;

  Future<void> _onStarted(
    PositiveMomentDetailStarted event,
    Emitter<PositiveMomentDetailState> emit,
  ) async {
    _parentId = event.parentId;
    _childId = event.childId;

    emit(const PositiveMomentDetailLoading());
    try {
      final moment = await repository.fetchPositiveMoment(
        parentId: event.parentId,
        childId: event.childId,
        momentId: event.momentId,
      );

      String? linkedTherapistId;
      final childSnap = await _firestore
          .collection('parents')
          .doc(event.parentId)
          .collection('children')
          .doc(event.childId)
          .get();
      if (childSnap.exists) {
        linkedTherapistId =
            childSnap.data()?['linkedTherapistId'] as String?;
      }

      emit(PositiveMomentDetailLoaded(
        moment: moment,
        childName: event.childName,
        linkedTherapistId: linkedTherapistId,
      ));
    } catch (_) {
      emit(const PositiveMomentDetailError(
        message: 'Could not load this positive moment. Please try again.',
      ));
    }
  }

  Future<void> _onDeleteRequested(
    PositiveMomentDetailDeleteRequested event,
    Emitter<PositiveMomentDetailState> emit,
  ) async {
    final current = state;
    if (current is! PositiveMomentDetailLoaded) return;
    if (_parentId == null || _childId == null) return;

    emit(current.copyWith(
      actionStatus: PositiveMomentDetailActionStatus.deleting,
    ));

    try {
      await repository.deletePositiveMoment(
        parentId: _parentId!,
        childId: _childId!,
        momentId: current.moment.id,
      );
      emit(current.copyWith(
        actionStatus: PositiveMomentDetailActionStatus.deleteSuccess,
      ));
    } catch (_) {
      emit(current.copyWith(
        actionStatus: PositiveMomentDetailActionStatus.deleteError,
        actionMessage: 'Could not delete this positive moment. Please try again.',
      ));
    }
  }
}
