import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../shared/models/incident_model.dart';
import '../data/incident_repository.dart';
import 'incident_form_state.dart';

class IncidentFormCubit extends Cubit<IncidentFormState> {
  IncidentFormCubit({
    required IncidentRepository repository,
    required String childId,
  })  : _repository = repository,
        _childId = childId,
        super(IncidentFormState.initial());

  final IncidentRepository _repository;
  final String _childId;

  // ── Simple field updates ─────────────────────────────────────────────────

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));
  void timeChanged(TimeOfDay time) => emit(state.copyWith(time: time));

  void antecedentDescriptionChanged(String value) =>
      emit(state.copyWith(antecedentDescription: value));

  void antecedentTriggerToggled(String trigger) {
    final updated = List<String>.from(state.antecedentTriggers);
    updated.contains(trigger) ? updated.remove(trigger) : updated.add(trigger);
    emit(state.copyWith(antecedentTriggers: updated));
  }

  void antecedentSeverityChanged(int value) =>
      emit(state.copyWith(antecedentSeverity: value));

  void behaviorDescriptionChanged(String value) =>
      emit(state.copyWith(behaviorDescription: value));

  void behaviorTypeToggled(String type) {
    final updated = List<String>.from(state.behaviorTypes);
    updated.contains(type) ? updated.remove(type) : updated.add(type);
    emit(state.copyWith(behaviorTypes: updated));
  }

  void behaviorDurationChanged(Duration duration) =>
      emit(state.copyWith(behaviorDuration: duration));

  void behaviorSeverityChanged(int value) =>
      emit(state.copyWith(behaviorSeverity: value));

  void consequenceDescriptionChanged(String value) =>
      emit(state.copyWith(consequenceDescription: value));

  void strategyToggled(String strategy) {
    final updated = List<String>.from(state.strategies);
    updated.contains(strategy)
        ? updated.remove(strategy)
        : updated.add(strategy);
    emit(state.copyWith(strategies: updated));
  }

  void didItWorkChanged(bool value) => emit(state.copyWith(didItWork: value));

  void effectivenessChanged(int value) =>
      emit(state.copyWith(effectiveness: value));

  // ── Async operations ─────────────────────────────────────────────────────

  Future<void> videoSelected(XFile file) async {
    emit(state.copyWith(status: IncidentFormStatus.videoUploading));
    try {
      final parentId = FirebaseAuth.instance.currentUser!.uid;

      // Start both operations before awaiting either so they run in parallel.
      final uploadFuture = _repository.uploadVideo(
        parentId: parentId,
        childId: _childId,
        file: file,
      );
      // video_thumbnail uses native channels — not available on web.
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
        status: IncidentFormStatus.idle,
        videoUrl: url,
        videoThumbnailPath: thumbnailPath,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IncidentFormStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  Future<void> submit() async {
    if (!_isValid()) {
      emit(state.copyWith(showErrors: true));
      return;
    }

    emit(state.copyWith(status: IncidentFormStatus.saving));
    try {
      final parentId = FirebaseAuth.instance.currentUser!.uid;
      final incident = IncidentModel(
        id: '',
        date: state.date,
        time: state.time,
        antecedentDescription: state.antecedentDescription,
        antecedentTriggers: state.antecedentTriggers,
        antecedentSeverity: state.antecedentSeverity!,
        behaviorDescription: state.behaviorDescription,
        behaviorTypes: state.behaviorTypes,
        behaviorDuration: state.behaviorDuration,
        behaviorSeverity: state.behaviorSeverity!,
        consequenceDescription: state.consequenceDescription,
        strategies: state.strategies,
        didItWork: state.didItWork ?? false,
        effectiveness: state.effectiveness!,
        videoUrl: state.videoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.saveIncident(
        parentId: parentId,
        childId: _childId,
        incident: incident,
      );

      emit(state.copyWith(status: IncidentFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: IncidentFormStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  void reset() => emit(IncidentFormState.initial());

  // ── Private helpers ──────────────────────────────────────────────────────

  bool _isValid() =>
      state.antecedentDescription.trim().isNotEmpty &&
      state.antecedentTriggers.isNotEmpty &&
      (state.antecedentSeverity ?? 0) > 0 &&
      state.behaviorDescription.trim().isNotEmpty &&
      state.behaviorTypes.isNotEmpty &&
      state.behaviorDuration != Duration.zero &&
      (state.behaviorSeverity ?? 0) > 0 &&
      state.consequenceDescription.trim().isNotEmpty &&
      state.strategies.isNotEmpty &&
      state.didItWork != null &&
      (state.effectiveness ?? 0) > 0;

  String _friendlyError(Object e) {
    if (e is FirebaseException) {
      return 'Could not save the incident (${e.code}). Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
