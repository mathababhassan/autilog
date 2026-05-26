import '../../../shared/models/child_model.dart';

class PatientSummary {
  final ChildModel child;
  final int recentHighSeverityCount;
  final DateTime? lastIncidentDate;

  const PatientSummary({
    required this.child,
    required this.recentHighSeverityCount,
    this.lastIncidentDate,
  });
}
