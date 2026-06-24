import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String childId;
  final String parentId;
  final String name;
  final DateTime? dateOfBirth;
  final int? ageYears; // from 'age' field when DOB is absent
  final String diagnosisType;
  final int severityLevel;
  final String? linkedTherapistId;

  ChildModel({
    required this.childId,
    required this.parentId,
    required this.name,
    this.dateOfBirth,
    this.ageYears,
    required this.diagnosisType,
    required this.severityLevel,
    this.linkedTherapistId,
  });

  /// Age in years — prefers computed from DOB, falls back to stored int.
  int get age {
    if (dateOfBirth != null) {
      final now = DateTime.now();
      int a = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month ||
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        a--;
      }
      return a;
    }
    return ageYears ?? 0;
  }

  factory ChildModel.fromMap(Map<String, dynamic> map, String childId) {
    final dobRaw = map['dateOfBirth'] ?? map['dob'];
    DateTime? dob;
    if (dobRaw != null) {
      try {
        dob = (dobRaw as Timestamp).toDate();
      } catch (_) {}
    }
    return ChildModel(
      childId: childId,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      dateOfBirth: dob,
      ageYears: (map['age'] as num?)?.toInt(),
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
      if (dateOfBirth != null) 'dob': Timestamp.fromDate(dateOfBirth!),
      'diagnosisType': diagnosisType,
      'severityLevel': severityLevel,
      'linkedTherapistId': linkedTherapistId,
    };
  }
}