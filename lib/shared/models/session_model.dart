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
  final String type;     // 'Assessment', 'Behavioral Intervention', 'Follow-up', 'Parent Consultation'
  final String status;   // 'upcoming', 'completed', 'cancelled'
  final int durationMinutes;
  final String? preSessionParentNotes;
  final String? preSessionPrivateNotes;
  final String? notes;
  final String? privateNotes;
  final String? progress;
  final String? cancelReason;
  final DateTime? notesLastEditedAt;

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
    required this.type,
    required this.status,
    required this.durationMinutes,
    this.preSessionParentNotes,
    this.preSessionPrivateNotes,
    this.notes,
    this.privateNotes,
    this.progress,
    this.cancelReason,
    this.notesLastEditedAt,
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
      // Backward-compat for docs written before `type` existed: default to the
      // most common session type so the card's type line always renders.
      type: map['type'] as String? ?? 'Behavioral Intervention',
      status: map['status'] as String? ?? 'upcoming',
      // Backward-compat: old docs have no durationMinutes; derive from timestamps.
      durationMinutes: map['durationMinutes'] as int? ??
          ((map['endTime'] as dynamic)?.toDate() as DateTime? ?? DateTime.now())
              .difference(
                (map['scheduledAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
              )
              .inMinutes
              .abs(),
      preSessionParentNotes: map['preSessionParentNotes'] as String?,
      preSessionPrivateNotes: map['preSessionPrivateNotes'] as String?,
      notes: map['notes'] as String?,
      privateNotes: map['privateNotes'] as String?,
      progress: map['progress'] as String?,
      cancelReason: map['cancelReason'] as String?,
      notesLastEditedAt: (map['notesLastEditedAt'] as Timestamp?)?.toDate(),
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
      'type': type,
      'status': status,
      'durationMinutes': durationMinutes,
      if (preSessionParentNotes != null) 'preSessionParentNotes': preSessionParentNotes,
      if (preSessionPrivateNotes != null) 'preSessionPrivateNotes': preSessionPrivateNotes,
      if (notes != null) 'notes': notes,
      if (privateNotes != null) 'privateNotes': privateNotes,
      if (progress != null) 'progress': progress,
      if (cancelReason != null) 'cancelReason': cancelReason,
    };
  }

  SessionModel copyWith({
    String? status,
    DateTime? scheduledAt,
    DateTime? endTime,
    int? durationMinutes,
    String? preSessionParentNotes,
    String? preSessionPrivateNotes,
    String? notes,
    String? privateNotes,
    String? progress,
    String? cancelReason,
    DateTime? notesLastEditedAt,
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
      type: type,
      status: status ?? this.status,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      preSessionParentNotes: preSessionParentNotes ?? this.preSessionParentNotes,
      preSessionPrivateNotes: preSessionPrivateNotes ?? this.preSessionPrivateNotes,
      notes: notes ?? this.notes,
      privateNotes: privateNotes ?? this.privateNotes,
      progress: progress ?? this.progress,
      cancelReason: cancelReason ?? this.cancelReason,
      notesLastEditedAt: notesLastEditedAt ?? this.notesLastEditedAt,
    );
  }

  /// Window during which the virtual call can be joined: from [joinLeadTime]
  /// before [scheduledAt] until [_joinGraceTime] after [endTime]. Public so the
  /// UI can describe the window ("opens N min before") without duplicating it.
  static const Duration joinLeadTime = Duration(minutes: 10);

  /// Whether the call is joinable at [now]. Takes the clock as a parameter so
  /// it can be unit-tested without mocking `DateTime.now()`.
  ///
  /// True only for a Virtual, non-cancelled session inside the join window:
  /// from [joinLeadTime] before [scheduledAt] until [endTime].
  bool isJoinableAt(DateTime now) {
    if (mode != 'Virtual' || status == 'cancelled') return false;
    final opens = scheduledAt.subtract(joinLeadTime);
    return !now.isBefore(opens) && !now.isAfter(endTime);
  }

  /// Convenience wrapper over [isJoinableAt] using the current time.
  bool get isJoinable => isJoinableAt(DateTime.now());

  /// True when a still-`upcoming` session's scheduled end time has already
  /// passed. Drives the "Needs review" treatment (the therapist must mark it
  /// completed or cancel it). Display-only — `status` is never rewritten from
  /// the clock, since a past session may be a no-show, not a completion.
  bool get isPastDue =>
      status == 'upcoming' && endTime.isBefore(DateTime.now());

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

  /// e.g. "Mon, Jun 9"
  String get formattedDateShort {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[scheduledAt.weekday - 1]}, ${months[scheduledAt.month - 1]} ${scheduledAt.day}';
  }

}
