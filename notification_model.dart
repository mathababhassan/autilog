import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types that map to specific target screens.
enum NotificationTargetType { session, log, appointment, unknown }

NotificationTargetType _parseTargetType(String? raw) {
  switch (raw) {
    case 'session':
      return NotificationTargetType.session;
    case 'log':
      return NotificationTargetType.log;
    case 'appointment':
      return NotificationTargetType.appointment;
    default:
      return NotificationTargetType.unknown;
  }
}

/// Domain model for a single notification document stored in:
///   parents/{uid}/notifications/{id}
///   therapists/{uid}/notifications/{id}
///
/// Firestore field names:
///   title        – String
///   body         – String
///   type         – String  (e.g. "session_reminder", "new_comment", "high_severity", …)
///   read         – bool    (false until the user opens it)
///   createdAt    – Timestamp
///   targetType   – String? (e.g. "session", "log", "appointment")
///   targetId     – String? (document ID of the target)
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.targetType = NotificationTargetType.unknown,
    this.targetId,
  });

  final String id;
  final String title;
  final String body;

  /// Raw notification type string, e.g. "session_reminder", "new_comment".
  final String type;

  final bool isRead;
  final DateTime createdAt;

  final NotificationTargetType targetType;

  /// ID of the related document (session, log, etc.), if any.
  final String? targetId;

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? '',
      // Firestore field is `read`, not `isRead`.
      isRead: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetType: _parseTargetType(data['targetType'] as String?),
      targetId: data['targetId'] as String?,
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        targetType: targetType,
        targetId: targetId,
      );
}
