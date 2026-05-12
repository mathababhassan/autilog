class TherapistModel {
  final String userId;
  final String name;
  final String licenceNumber;
  final String clinicName;
  final String specialisation;
  final String gender; 

  TherapistModel({
    required this.userId,
    required this.name,
    required this.licenceNumber,
    required this.clinicName,
    required this.specialisation,
    required this.gender, 
  });

  factory TherapistModel.fromMap(Map<String, dynamic> map, String userId) {
    return TherapistModel(
      userId: userId,
      name: map['name'] ?? '',
      licenceNumber: map['licenceNumber'] ?? '',
      clinicName: map['clinicName'] ?? '',
      specialisation: map['specialisation'] ?? '',
      gender: map['gender'] ?? '', 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'licenceNumber': licenceNumber,
      'clinicName': clinicName,
      'specialisation': specialisation,
      'gender': gender, 
    };
  }
}