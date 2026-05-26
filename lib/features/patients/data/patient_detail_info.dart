import '../../../shared/models/child_model.dart';

class PatientDetailInfo {
  final ChildModel child;
  final String parentName;
  final String parentPhone;

  const PatientDetailInfo({
    required this.child,
    required this.parentName,
    required this.parentPhone,
  });

  int get age {
    final now = DateTime.now();
    var years = now.year - child.dateOfBirth.year;
    if (now.month < child.dateOfBirth.month ||
        (now.month == child.dateOfBirth.month &&
            now.day < child.dateOfBirth.day)) {
      years--;
    }
    return years.clamp(0, 120);
  }

  String get severityLabel => 'ASD - LEVEL ${child.severityLevel}';

  String get severitySubtitle => 'ASD Level ${child.severityLevel}';
}
