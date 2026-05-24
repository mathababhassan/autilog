import 'package:cloud_firestore/cloud_firestore.dart';

class TherapistFeedback {
  final String therapistName;
  final String comment;
  final DateTime createdAt;

  const TherapistFeedback({
    required this.therapistName,
    required this.comment,
    required this.createdAt,
  });

  factory TherapistFeedback.fromMap(Map<String, dynamic> map) {
    return TherapistFeedback(
      therapistName: map['therapistName'] as String? ?? '',
      comment: map['comment'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'therapistName': therapistName,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
