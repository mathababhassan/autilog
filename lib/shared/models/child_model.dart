class ChildModel {
  final String childId;
  final String parentId;
  final String name;
  final DateTime dateOfBirth;
  final String diagnosisType;
  final int severityLevel;
  final String? linkedTherapistId;

  ChildModel({
    required this.childId,
    required this.parentId,
    required this.name,
    required this.dateOfBirth,
    required this.diagnosisType,
    required this.severityLevel,
    this.linkedTherapistId,
  });

  factory ChildModel.fromMap(Map<String, dynamic> map, String childId) {
    return ChildModel(
      childId: childId,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      dateOfBirth: map['dateOfBirth']?.toDate() ?? DateTime.now(),
      diagnosisType: map['diagnosisType'] ?? '',
      severityLevel: map['severityLevel'] ?? 1,
      linkedTherapistId: map['linkedTherapistId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'diagnosisType': diagnosisType,
      'severityLevel': severityLevel,
      'linkedTherapistId': linkedTherapistId,
    };
  }
}