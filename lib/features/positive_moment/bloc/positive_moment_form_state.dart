import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PositiveMomentFormStatus {
  idle,
  videoUploading,
  saving,
  success,
  error,
}

class PositiveMomentFormState extends Equatable {
  final PositiveMomentFormStatus status;
  final DateTime date;
  final TimeOfDay time;
  final String antecedentDescription;
  final String? setting;
  final String behaviorDescription;
  final List<String> behaviorTypes;
  final int? positiveBehaviorRating;
  final String consequenceDescription;
  final int? effectiveness;
  final String? videoUrl;
  final String? videoThumbnailPath;
  final bool showErrors;
  final String? errorMessage;
  final String? savedMomentId;

  const PositiveMomentFormState({
    required this.status,
    required this.date,
    required this.time,
    required this.antecedentDescription,
    this.setting,
    required this.behaviorDescription,
    required this.behaviorTypes,
    this.positiveBehaviorRating,
    required this.consequenceDescription,
    this.effectiveness,
    this.videoUrl,
    this.videoThumbnailPath,
    required this.showErrors,
    this.errorMessage,
    this.savedMomentId,
  });

  factory PositiveMomentFormState.initial() {
    final now = DateTime.now();
    return PositiveMomentFormState(
      status: PositiveMomentFormStatus.idle,
      date: now,
      time: TimeOfDay.fromDateTime(now),
      antecedentDescription: '',
      behaviorDescription: '',
      behaviorTypes: const [],
      consequenceDescription: '',
      showErrors: false,
    );
  }

  PositiveMomentFormState copyWith({
    PositiveMomentFormStatus? status,
    DateTime? date,
    TimeOfDay? time,
    String? antecedentDescription,
    Object? setting = _clear,
    String? behaviorDescription,
    List<String>? behaviorTypes,
    Object? positiveBehaviorRating = _clear,
    String? consequenceDescription,
    Object? effectiveness = _clear,
    Object? videoUrl = _clear,
    Object? videoThumbnailPath = _clear,
    bool? showErrors,
    Object? errorMessage = _clear,
    Object? savedMomentId = _clear,
  }) {
    return PositiveMomentFormState(
      status: status ?? this.status,
      date: date ?? this.date,
      time: time ?? this.time,
      antecedentDescription:
          antecedentDescription ?? this.antecedentDescription,
      setting: identical(setting, _clear) ? this.setting : setting as String?,
      behaviorDescription: behaviorDescription ?? this.behaviorDescription,
      behaviorTypes: behaviorTypes ?? this.behaviorTypes,
      positiveBehaviorRating: identical(positiveBehaviorRating, _clear)
          ? this.positiveBehaviorRating
          : positiveBehaviorRating as int?,
      consequenceDescription:
          consequenceDescription ?? this.consequenceDescription,
      effectiveness: identical(effectiveness, _clear)
          ? this.effectiveness
          : effectiveness as int?,
      videoUrl: identical(videoUrl, _clear)
          ? this.videoUrl
          : videoUrl as String?,
      videoThumbnailPath: identical(videoThumbnailPath, _clear)
          ? this.videoThumbnailPath
          : videoThumbnailPath as String?,
      showErrors: showErrors ?? this.showErrors,
      errorMessage: identical(errorMessage, _clear)
          ? this.errorMessage
          : errorMessage as String?,
      savedMomentId: identical(savedMomentId, _clear)
          ? this.savedMomentId
          : savedMomentId as String?,
    );
  }

  static const _clear = Object();

  @override
  List<Object?> get props => [
        status,
        date,
        time,
        antecedentDescription,
        setting,
        behaviorDescription,
        behaviorTypes,
        positiveBehaviorRating,
        consequenceDescription,
        effectiveness,
        videoUrl,
        videoThumbnailPath,
        showErrors,
        errorMessage,
        savedMomentId,
      ];
}
