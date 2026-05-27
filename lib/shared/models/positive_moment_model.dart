import 'package:cloud_firestore/cloud_firestore.dart';
import 'therapist_feedback_model.dart';

class PositiveMomentModel {
  final String id;
  final DateTime date;
  final int timeMinutes;
  final String antecedentDescription;
  final String setting;
  final String behaviorDescription;
  final List<String> behaviorTypes;
  final int positiveBehaviorRating;
  final String consequenceDescription;
  final int effectiveness;
  final String? videoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TherapistFeedback? therapistFeedback;

  const PositiveMomentModel({
    required this.id,
    required this.date,
    required this.timeMinutes,
    required this.antecedentDescription,
    required this.setting,
    required this.behaviorDescription,
    required this.behaviorTypes,
    required this.positiveBehaviorRating,
    required this.consequenceDescription,
    required this.effectiveness,
    this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.therapistFeedback,
  });

  bool get isLocked =>
      DateTime.now().difference(createdAt) >= const Duration(hours: 24);

  factory PositiveMomentModel.fromMap(Map<String, dynamic> map, String id) {
    final timeMinutes = (map['time'] as num?)?.toInt() ?? 0;
    return PositiveMomentModel(
      id: id,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeMinutes: timeMinutes,
      antecedentDescription: map['antecedentDescription'] as String? ?? '',
      setting: map['setting'] as String? ?? '',
      behaviorDescription: map['behaviorDescription'] as String? ?? '',
      behaviorTypes: List<String>.from(map['behaviorTypes'] ?? []),
      positiveBehaviorRating:
          (map['positiveBehaviorRating'] as num?)?.toInt() ?? 0,
      consequenceDescription: map['consequenceDescription'] as String? ?? '',
      effectiveness: (map['effectiveness'] as num?)?.toInt() ?? 0,
      videoUrl: map['videoUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      therapistFeedback: map['therapistFeedback'] != null
          ? TherapistFeedback.fromMap(
              map['therapistFeedback'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'positiveMoment',
      'date': Timestamp.fromDate(date),
      'time': timeMinutes,
      'antecedentDescription': antecedentDescription,
      'setting': setting,
      'behaviorDescription': behaviorDescription,
      'behaviorTypes': behaviorTypes,
      'positiveBehaviorRating': positiveBehaviorRating,
      'consequenceDescription': consequenceDescription,
      'effectiveness': effectiveness,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (therapistFeedback != null)
        'therapistFeedback': therapistFeedback!.toMap(),
    };
  }
}
