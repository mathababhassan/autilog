import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../shared/models/positive_moment_model.dart';
import '../data/positive_moment_repository.dart';
import 'positive_moment_form_state.dart';

class PositiveMomentFormCubit extends Cubit<PositiveMomentFormState> {
  PositiveMomentFormCubit({
    required PositiveMomentRepository repository,
    required String childId,
  })  : _repository = repository,
        _childId = childId,
        super(PositiveMomentFormState.initial());

  final PositiveMomentRepository _repository;
  final String _childId;

  void timeChanged(TimeOfDay time) => emit(state.copyWith(time: time));

  void antecedentDescriptionChanged(String value) =>
      emit(state.copyWith(antecedentDescription: value));

  void settingChanged(String setting) =>
      emit(state.copyWith(setting: setting));

  void behaviorDescriptionChanged(String value) =>
      emit(state.copyWith(behaviorDescription: value));

  void behaviorTypeToggled(String type) {
    final updated = List<String>.from(state.behaviorTypes);
    updated.contains(type) ? updated.remove(type) : updated.add(type);
    emit(state.copyWith(behaviorTypes: updated));
  }

  void positiveBehaviorRatingChanged(int value) =>
      emit(state.copyWith(positiveBehaviorRating: value));

  void consequenceDescriptionChanged(String value) =>
      emit(state.copyWith(consequenceDescription: value));

  void effectivenessChanged(int value) =>
      emit(state.copyWith(effectiveness: value));

  Future<void> videoSelected(XFile file) async {
    emit(state.copyWith(status: PositiveMomentFormStatus.videoUploading));
    try {
      final parentId = FirebaseAuth.instance.currentUser!.uid;
      final uploadFuture = _repository.uploadVideo(
        parentId: parentId,
        childId: _childId,
        file: file,
      );
      final thumbnailFuture = kIsWeb
          ? Future<String?>.value(null)
          : VideoThumbnail.thumbnailFile(
              video: file.path,
              imageFormat: ImageFormat.JPEG,
              quality: 75,
            );

      final url = await uploadFuture;
      final thumbnailPath = await thumbnailFuture;

      emit(state.copyWith(
        status: PositiveMomentFormStatus.idle,
        videoUrl: url,
        videoThumbnailPath: thumbnailPath,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PositiveMomentFormStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  Future<void> submit() async {
    if (!_isValid()) {
      emit(state.copyWith(showErrors: true));
      return;
    }

    emit(state.copyWith(status: PositiveMomentFormStatus.saving));
    try {
      final parentId = FirebaseAuth.instance.currentUser!.uid;
      final moment = PositiveMomentModel(
        id: '',
        date: state.date,
        time: state.time,
        antecedentDescription: state.antecedentDescription,
        setting: state.setting!,
        behaviorDescription: state.behaviorDescription,
        behaviorTypes: state.behaviorTypes,
        positiveBehaviorRating: state.positiveBehaviorRating!,
        consequenceDescription: state.consequenceDescription,
        effectiveness: state.effectiveness!,
        videoUrl: state.videoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final momentId = await _repository.savePositiveMoment(
        parentId: parentId,
        childId: _childId,
        moment: moment,
      );

      emit(state.copyWith(
        status: PositiveMomentFormStatus.success,
        savedMomentId: momentId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PositiveMomentFormStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  void reset() => emit(PositiveMomentFormState.initial());

  bool _isValid() =>
      state.antecedentDescription.trim().isNotEmpty &&
      state.setting != null &&
      state.setting!.isNotEmpty &&
      state.behaviorDescription.trim().isNotEmpty &&
      state.behaviorTypes.isNotEmpty &&
      (state.positiveBehaviorRating ?? 0) > 0 &&
      state.consequenceDescription.trim().isNotEmpty &&
      (state.effectiveness ?? 0) > 0;

  String _friendlyError(Object e) {
    if (e is FirebaseException) {
      return 'Could not save the positive moment (${e.code}). Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
