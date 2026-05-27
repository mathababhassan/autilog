import 'package:cloud_firestore/cloud_firestore.dart';

/// Denormalized activity entry written by Cloud Functions under
/// `parents/{parentId}/children/{childId}/activityLogs/{id}`.
class ActivityLogModel {
  final String id;
  final String type;
  final String sourceCollection;
  final String sourceId;
  final String title;
  final String summary;
  final String detail;
  final DateTime date;
  final int timeMinutes;
  final DateTime createdAt;

  const ActivityLogModel({
    required this.id,
    required this.type,
    required this.sourceCollection,
    required this.sourceId,
    required this.title,
    required this.summary,
    required this.detail,
    required this.date,
    required this.timeMinutes,
    required this.createdAt,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLogModel(
      id: id,
      type: map['type'] as String? ?? '',
      sourceCollection: map['sourceCollection'] as String? ?? '',
      sourceId: map['sourceId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      detail: map['detail'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeMinutes: (map['time'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isPositiveMoment => type == 'positiveMoment';
}
