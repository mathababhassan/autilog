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
  final String mode;     // 'In-Person', 'Virtual'
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
    required this.mode,
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
      // Backward-compat for docs written before `mode` existed: infer from location.
      mode: map['mode'] as String? ??
          (map['location'] == 'Online' ? 'Virtual' : 'In-Person'),
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
      'mode': mode,
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
      mode: mode,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  /// Window during which the virtual call can be joined: from [joinLeadTime]
  /// before [scheduledAt] until [_joinGraceTime] after [endTime]. Public so the
  /// UI can describe the window ("opens N min before") without duplicating it.
  static const Duration joinLeadTime = Duration(minutes: 15);
  static const Duration _joinGraceTime = Duration(minutes: 30);

  /// Whether the call is joinable at [now]. Takes the clock as a parameter so
  /// it can be unit-tested without mocking `DateTime.now()`.
  ///
  /// True only for a Virtual, non-cancelled session inside the join window.
  bool isJoinableAt(DateTime now) {
    if (mode != 'Virtual' || status == 'cancelled') return false;
    final opens = scheduledAt.subtract(joinLeadTime);
    final closes = endTime.add(_joinGraceTime);
    return !now.isBefore(opens) && !now.isAfter(closes);
  }

  /// Convenience wrapper over [isJoinableAt] using the current time.
  bool get isJoinable => isJoinableAt(DateTime.now());

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