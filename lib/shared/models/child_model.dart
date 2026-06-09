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
      dateOfBirth: (map['dateOfBirth'] ?? map['dob'])?.toDate() ?? DateTime.now(),
      diagnosisType: map['diagnosisType'] ?? '',
      severityLevel: parseSeverity(map['severityLevel'] ?? map['asdSeverity']),
      linkedTherapistId: map['linkedTherapistId'],
    );
  }

  static int parseSeverity(dynamic value) {
    if (value is int) return value.clamp(1, 3).toInt();
    if (value is String) {
      final n = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
      return n != null ? n.clamp(1, 3).toInt() : 1;
    }
    return 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'name': name,
      'dob': dateOfBirth,
      'diagnosisType': diagnosisType,
      'severityLevel': severityLevel,
      'linkedTherapistId': linkedTherapistId,
    };
  }
}