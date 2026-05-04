class TherapistModel {
  final String userId;
  final String name;
  final String licenceNumber;
  final String clinicName;
  final String specialisation;

  TherapistModel({
    required this.userId,
    required this.name,
    required this.licenceNumber,
    required this.clinicName,
    required this.specialisation,
  });

  factory TherapistModel.fromMap(Map<String, dynamic> map, String userId) {
    return TherapistModel(
      userId: userId,
      name: map['name'] ?? '',
      licenceNumber: map['licenceNumber'] ?? '',
      clinicName: map['clinicName'] ?? '',
      specialisation: map['specialisation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'licenceNumber': licenceNumber,
      'clinicName': clinicName,
      'specialisation': specialisation,
    };
  }
}