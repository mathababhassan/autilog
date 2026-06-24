import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for the parent's notification preferences.
///
/// Firestore path:  parents/{uid}/settings/notifications
///
/// Fields match the pref group keys read by the backend (notifications.js):
///   sessionReminders     → "sessionUpdates"
///   appointmentReminders → "sessionUpdates"  (therapist comments on sessions)
///   dailyLogReminders    → "dailyLogReminders"
///   weeklyAiInsights     → "weeklyAiInsights"
class ParentSettingsModel {
  const ParentSettingsModel({
    this.sessionReminders = true,
    this.appointmentReminders = true,
    this.dailyLogReminders = true,
    this.weeklyAiInsights = false,
  });

  final bool sessionReminders;
  final bool appointmentReminders;
  final bool dailyLogReminders;
  final bool weeklyAiInsights;

  factory ParentSettingsModel.fromMap(Map<String, dynamic> map) {
    return ParentSettingsModel(
      sessionReminders: map['sessionReminders'] as bool? ?? true,
      appointmentReminders: map['appointmentReminders'] as bool? ?? true,
      dailyLogReminders: map['dailyLogReminders'] as bool? ?? true,
      weeklyAiInsights: map['weeklyAiInsights'] as bool? ?? false,
    );
  }

  ParentSettingsModel copyWith({
    bool? sessionReminders,
    bool? appointmentReminders,
    bool? dailyLogReminders,
    bool? weeklyAiInsights,
  }) =>
      ParentSettingsModel(
        sessionReminders: sessionReminders ?? this.sessionReminders,
        appointmentReminders: appointmentReminders ?? this.appointmentReminders,
        dailyLogReminders: dailyLogReminders ?? this.dailyLogReminders,
        weeklyAiInsights: weeklyAiInsights ?? this.weeklyAiInsights,
      );

  Map<String, dynamic> toMap() => {
        'sessionReminders': sessionReminders,
        'appointmentReminders': appointmentReminders,
        'dailyLogReminders': dailyLogReminders,
        'weeklyAiInsights': weeklyAiInsights,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}