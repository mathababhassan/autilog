import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String therapistId;
  final String childId;
  final String childName;
  final String parentId;
  final DateTime scheduledAt;
  final DateTime endTime;
  final String location; // 'Clinic', 'Online', 'Home'
  final String status;   // 'upcoming', 'completed', 'cancelled'
  final String? notes;
  final String? cancelReason;

  const SessionModel({
    required this.id,
    required this.therapistId,
    required this.childId,
    required this.childName,
    required this.parentId,
    required this.scheduledAt,
    required this.endTime,
    required this.location,
    required this.status,
    this.notes,
    this.cancelReason,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionModel(
      id: id,
      therapistId: map['therapistId'] as String? ?? '',
      childId: map['childId'] as String? ?? '',
      childName: map['childName'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      scheduledAt: (map['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'] as String? ?? 'Clinic',
      status: map['status'] as String? ?? 'upcoming',
      notes: map['notes'] as String?,
      cancelReason: map['cancelReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'therapistId': therapistId,
      'childId': childId,
      'childName': childName,
      'parentId': parentId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'status': status,
      if (notes != null) 'notes': notes,
      if (cancelReason != null) 'cancelReason': cancelReason,
    };
  }

  SessionModel copyWith({
    String? status,
    DateTime? scheduledAt,
    DateTime? endTime,
    String? notes,
    String? cancelReason,
  }) {
    return SessionModel(
      id: id,
      therapistId: therapistId,
      childId: childId,
      childName: childName,
      parentId: parentId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      endTime: endTime ?? this.endTime,
      location: location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  /// e.g. "9:00 AM - 11:00 AM"
  String get formattedTimeRange {
    String fmt(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $period';
    }
    return '${fmt(scheduledAt)} - ${fmt(endTime)}';
  }
}