import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types that map to specific target screens.
enum NotificationTargetType { session, log, appointment, unknown }

NotificationTargetType _parseTargetType(String? raw) {
  switch (raw) {
    case 'session':
      return NotificationTargetType.session;
    case 'log':
    case 'incident':
    case 'dailySummary':
    case 'positiveMoment':
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
    this.targetChildId,
    this.targetParentId,
    this.rawTargetKind,
  });

  final String id;
  final String title;
  final String body;

  /// Raw notification type string, e.g. "session_reminder", "new_comment".
  final String type;

  final bool isRead;
  final DateTime createdAt;

  final NotificationTargetType targetType;
  final String? targetId;
  final String? targetChildId;
  final String? targetParentId;
  final String? rawTargetKind;

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final target = data['target'] as Map<String, dynamic>?;
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? '',
      isRead: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetType: _parseTargetType(target?['kind'] as String? ?? data['targetType'] as String?),
      targetId: target?['id'] as String? ?? data['targetId'] as String?,
      targetChildId: target?['childId'] as String?,
      targetParentId: target?['parentId'] as String?,
      rawTargetKind: target?['kind'] as String?,
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
        targetChildId: targetChildId,
        targetParentId: targetParentId,
        rawTargetKind: rawTargetKind ?? this.rawTargetKind,
      );
}
