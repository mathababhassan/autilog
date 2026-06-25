/// Domain model for the therapist's notification preferences.
///
/// Persisted as a `notificationPrefs` map on the therapist's main document:
///   therapists/{uid}  →  notificationPrefs: { ... }
///
/// Keys MUST match `THERAPIST_PREF_GROUP` in `functions/notifications.js`,
/// which gates every push. The backend rule is `prefs[group] !== false`, so a
/// missing key (or anything other than an explicit `false`) defaults to ON.
///
///   patientRequests  → linkRequest
///   patientActivity  → logAdded, comment
///   sessionUpdates   → sessionReminder, sessionCancelled
///   weeklyAiInsights → aiInsight
///
/// High-severity incident alerts (`highSeverityIncident`) are ALWAYS sent and
/// are intentionally ungated — they have no field here.
class TherapistSettingsModel {
  const TherapistSettingsModel({
    this.patientRequests = true,
    this.patientActivity = true,
    this.sessionUpdates = true,
    this.weeklyAiInsights = true,
  });

  final bool patientRequests;
  final bool patientActivity;
  final bool sessionUpdates;
  final bool weeklyAiInsights;

  /// Reads from the `notificationPrefs` map. A missing key defaults to ON,
  /// matching the backend's `prefs[group] !== false` gating rule.
  factory TherapistSettingsModel.fromMap(Map<String, dynamic> map) {
    return TherapistSettingsModel(
      patientRequests: map['patientRequests'] as bool? ?? true,
      patientActivity: map['patientActivity'] as bool? ?? true,
      sessionUpdates: map['sessionUpdates'] as bool? ?? true,
      weeklyAiInsights: map['weeklyAiInsights'] as bool? ?? true,
    );
  }

  TherapistSettingsModel copyWith({
    bool? patientRequests,
    bool? patientActivity,
    bool? sessionUpdates,
    bool? weeklyAiInsights,
  }) =>
      TherapistSettingsModel(
        patientRequests: patientRequests ?? this.patientRequests,
        patientActivity: patientActivity ?? this.patientActivity,
        sessionUpdates: sessionUpdates ?? this.sessionUpdates,
        weeklyAiInsights: weeklyAiInsights ?? this.weeklyAiInsights,
      );

  /// The value written into `notificationPrefs`. High-severity is omitted by
  /// design (always-on, ungated).
  Map<String, dynamic> toMap() => {
        'patientRequests': patientRequests,
        'patientActivity': patientActivity,
        'sessionUpdates': sessionUpdates,
        'weeklyAiInsights': weeklyAiInsights,
      };
}
