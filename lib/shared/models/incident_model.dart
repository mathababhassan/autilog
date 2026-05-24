import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'therapist_feedback_model.dart';

class IncidentModel {
  final String id;
  final DateTime date;
  final TimeOfDay time;
  final String antecedentDescription;
  final List<String> antecedentTriggers;
  final int antecedentSeverity;
  final String behaviorDescription;
  final List<String> behaviorTypes;
  final Duration behaviorDuration;
  final int behaviorSeverity;
  final String consequenceDescription;
  final List<String> strategies;
  final bool didItWork;
  final int effectiveness;
  final String? videoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TherapistFeedback? therapistFeedback;

  const IncidentModel({
    required this.id,
    required this.date,
    required this.time,
    required this.antecedentDescription,
    required this.antecedentTriggers,
    required this.antecedentSeverity,
    required this.behaviorDescription,
    required this.behaviorTypes,
    required this.behaviorDuration,
    required this.behaviorSeverity,
    required this.consequenceDescription,
    required this.strategies,
    required this.didItWork,
    required this.effectiveness,
    this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.therapistFeedback,
  });

  factory IncidentModel.fromMap(Map<String, dynamic> map, String id) {
    final timeMinutes = (map['time'] as num?)?.toInt() ?? 0;
    final durationSeconds = (map['behaviorDuration'] as num?)?.toInt() ?? 0;
    return IncidentModel(
      id: id,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: TimeOfDay(hour: timeMinutes ~/ 60, minute: timeMinutes % 60),
      antecedentDescription: map['antecedentDescription'] as String? ?? '',
      antecedentTriggers: List<String>.from(map['antecedentTriggers'] ?? []),
      antecedentSeverity: (map['antecedentSeverity'] as num?)?.toInt() ?? 0,
      behaviorDescription: map['behaviorDescription'] as String? ?? '',
      behaviorTypes: List<String>.from(map['behaviorTypes'] ?? []),
      behaviorDuration: Duration(seconds: durationSeconds),
      behaviorSeverity: (map['behaviorSeverity'] as num?)?.toInt() ?? 0,
      consequenceDescription: map['consequenceDescription'] as String? ?? '',
      strategies: List<String>.from(map['strategies'] ?? []),
      didItWork: map['didItWork'] as bool? ?? false,
      effectiveness: (map['effectiveness'] as num?)?.toInt() ?? 0,
      videoUrl: map['videoUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      therapistFeedback: map['therapistFeedback'] != null
          ? TherapistFeedback.fromMap(
              map['therapistFeedback'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'time': time.hour * 60 + time.minute,
      'antecedentDescription': antecedentDescription,
      'antecedentTriggers': antecedentTriggers,
      'antecedentSeverity': antecedentSeverity,
      'behaviorDescription': behaviorDescription,
      'behaviorTypes': behaviorTypes,
      'behaviorDuration': behaviorDuration.inSeconds,
      'behaviorSeverity': behaviorSeverity,
      'consequenceDescription': consequenceDescription,
      'strategies': strategies,
      'didItWork': didItWork,
      'effectiveness': effectiveness,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (therapistFeedback != null)
        'therapistFeedback': therapistFeedback!.toMap(),
    };
  }
}
