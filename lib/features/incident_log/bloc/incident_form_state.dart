import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum IncidentFormStatus { idle, videoUploading, saving, success, error }

class IncidentFormState extends Equatable {
  final IncidentFormStatus status;
  final String? errorMessage;
  final bool showErrors;

  final DateTime date;
  final TimeOfDay time;

  final String antecedentDescription;
  final List<String> antecedentTriggers;
  final int? antecedentSeverity; // null = not yet selected

  final String behaviorDescription;
  final List<String> behaviorTypes;
  final Duration behaviorDuration;
  final int? behaviorSeverity; // null = not yet selected

  final String consequenceDescription;
  final List<String> strategies;
  final bool? didItWork; // null = not yet selected
  final int? effectiveness; // null = not yet selected

  final String? videoUrl;
  final String? videoThumbnailPath;

  const IncidentFormState({
    required this.status,
    this.errorMessage,
    required this.showErrors,
    required this.date,
    required this.time,
    required this.antecedentDescription,
    required this.antecedentTriggers,
    this.antecedentSeverity,
    required this.behaviorDescription,
    required this.behaviorTypes,
    required this.behaviorDuration,
    this.behaviorSeverity,
    required this.consequenceDescription,
    required this.strategies,
    this.didItWork,
    this.effectiveness,
    this.videoUrl,
    this.videoThumbnailPath,
  });

  factory IncidentFormState.initial() {
    final now = DateTime.now();
    return IncidentFormState(
      status: IncidentFormStatus.idle,
      showErrors: false,
      date: now,
      time: TimeOfDay.fromDateTime(now),
      antecedentDescription: '',
      antecedentTriggers: const [],
      antecedentSeverity: null,
      behaviorDescription: '',
      behaviorTypes: const [],
      behaviorDuration: Duration.zero,
      behaviorSeverity: null,
      consequenceDescription: '',
      strategies: const [],
      didItWork: null,
      effectiveness: null,
    );
  }

  static const _clear = Object();

  IncidentFormState copyWith({
    IncidentFormStatus? status,
    Object? errorMessage = _clear,
    bool? showErrors,
    DateTime? date,
    TimeOfDay? time,
    String? antecedentDescription,
    List<String>? antecedentTriggers,
    Object? antecedentSeverity = _clear,
    String? behaviorDescription,
    List<String>? behaviorTypes,
    Duration? behaviorDuration,
    Object? behaviorSeverity = _clear,
    String? consequenceDescription,
    List<String>? strategies,
    bool? didItWork,
    Object? effectiveness = _clear,
    Object? videoUrl = _clear,
    Object? videoThumbnailPath = _clear,
  }) {
    return IncidentFormState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _clear)
          ? this.errorMessage
          : errorMessage as String?,
      showErrors: showErrors ?? this.showErrors,
      date: date ?? this.date,
      time: time ?? this.time,
      antecedentDescription:
          antecedentDescription ?? this.antecedentDescription,
      antecedentTriggers: antecedentTriggers ?? this.antecedentTriggers,
      antecedentSeverity: identical(antecedentSeverity, _clear)
          ? this.antecedentSeverity
          : antecedentSeverity as int?,
      behaviorDescription: behaviorDescription ?? this.behaviorDescription,
      behaviorTypes: behaviorTypes ?? this.behaviorTypes,
      behaviorDuration: behaviorDuration ?? this.behaviorDuration,
      behaviorSeverity: identical(behaviorSeverity, _clear)
          ? this.behaviorSeverity
          : behaviorSeverity as int?,
      consequenceDescription:
          consequenceDescription ?? this.consequenceDescription,
      strategies: strategies ?? this.strategies,
      didItWork: didItWork ?? this.didItWork,
      effectiveness: identical(effectiveness, _clear)
          ? this.effectiveness
          : effectiveness as int?,
      videoUrl: identical(videoUrl, _clear)
          ? this.videoUrl
          : videoUrl as String?,
      videoThumbnailPath: identical(videoThumbnailPath, _clear)
          ? this.videoThumbnailPath
          : videoThumbnailPath as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        showErrors,
        date,
        time,
        antecedentDescription,
        antecedentTriggers,
        antecedentSeverity,
        behaviorDescription,
        behaviorTypes,
        behaviorDuration,
        behaviorSeverity,
        consequenceDescription,
        strategies,
        didItWork,
        effectiveness,
        videoUrl,
        videoThumbnailPath,
      ];
}
