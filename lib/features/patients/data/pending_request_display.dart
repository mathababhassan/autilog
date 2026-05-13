class PendingRequestDisplay {
  final String requestId;
  final String childId;
  final String childName;
  final String parentId;
  final String parentName;
  final String diagnosisType;
  final int severityLevel;
  final DateTime requestedAt;

  const PendingRequestDisplay({
    required this.requestId,
    required this.childId,
    required this.childName,
    required this.parentId,
    required this.parentName,
    required this.diagnosisType,
    required this.severityLevel,
    required this.requestedAt,
  });
}
