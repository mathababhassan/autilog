import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for the parent's notification / reminder preferences.
///
/// Firestore path:  parents/{uid}/settings/notifications
///
/// Fields:
///   enableNotifications  – bool  (master toggle; default true)
///   sessionReminders     – bool  (default true)
///   appointmentReminders – bool  (default true)
///   reminderTimeHour     – int   (0–23, default 8)
///   reminderTimeMinute   – int   (0–59, default 0)
///   updatedAt            – Timestamp
class ParentSettingsModel {
  const ParentSettingsModel({
    this.enableNotifications = true,
    this.sessionReminders = true,
    this.appointmentReminders = true,
    this.dailyLogReminders = true,
    this.weeklyAiInsights = false,
    this.reminderTimeHour = 8,
    this.reminderTimeMinute = 0,
  });

  final bool enableNotifications;
  final bool sessionReminders;
  final bool appointmentReminders;
  final bool dailyLogReminders;
  final bool weeklyAiInsights;
  final int reminderTimeHour;
  final int reminderTimeMinute;

  // ─── Factory ────────────────────────────────────────────────────────────────

  factory ParentSettingsModel.fromMap(Map<String, dynamic> map) {
    return ParentSettingsModel(
      enableNotifications: map['enableNotifications'] as bool? ?? true,
      sessionReminders: map['sessionReminders'] as bool? ?? true,
      appointmentReminders: map['appointmentReminders'] as bool? ?? true,
      dailyLogReminders: map['dailyLogReminders'] as bool? ?? true,
      weeklyAiInsights: map['weeklyAiInsights'] as bool? ?? false,
      reminderTimeHour: map['reminderTimeHour'] as int? ?? 8,
      reminderTimeMinute: map['reminderTimeMinute'] as int? ?? 0,
    );
  }

  /// Returns a new model with only the changed fields replaced.
  ParentSettingsModel copyWith({
    bool? enableNotifications,
    bool? sessionReminders,
    bool? appointmentReminders,
    bool? dailyLogReminders,
    bool? weeklyAiInsights,
    int? reminderTimeHour,
    int? reminderTimeMinute,
  }) =>
      ParentSettingsModel(
        enableNotifications: enableNotifications ?? this.enableNotifications,
        sessionReminders: sessionReminders ?? this.sessionReminders,
        appointmentReminders: appointmentReminders ?? this.appointmentReminders,
        dailyLogReminders: dailyLogReminders ?? this.dailyLogReminders,
        weeklyAiInsights: weeklyAiInsights ?? this.weeklyAiInsights,
        reminderTimeHour: reminderTimeHour ?? this.reminderTimeHour,
        reminderTimeMinute: reminderTimeMinute ?? this.reminderTimeMinute,
      );

  // ─── Serialisation ───────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'enableNotifications': enableNotifications,
        'sessionReminders': sessionReminders,
        'appointmentReminders': appointmentReminders,
        'dailyLogReminders': dailyLogReminders,
        'weeklyAiInsights': weeklyAiInsights,
        'reminderTimeHour': reminderTimeHour,
        'reminderTimeMinute': reminderTimeMinute,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
