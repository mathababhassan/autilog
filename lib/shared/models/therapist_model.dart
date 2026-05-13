class TherapistModel {
  final String userId;
  final String name;
  final String licenceNumber;
  final String clinicName;
  final String specialisation;
  final String gender;
  final String? phone;
  final String? experience;

  TherapistModel({
    required this.userId,
    required this.name,
    required this.licenceNumber,
    required this.clinicName,
    required this.specialisation,
    required this.gender,
    this.phone,
    this.experience,
  });

  factory TherapistModel.fromMap(Map<String, dynamic> map, String userId) {
    return TherapistModel(
      userId: userId,
      name: map['name'] ?? '',
      licenceNumber: map['licenceNumber'] ?? '',
      clinicName: map['clinicName'] ?? '',
      specialisation: map['specialisation'] ?? '',
      gender: map['gender'] ?? '',
      phone: map['phone'] as String?,
      experience: map['experience'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'licenceNumber': licenceNumber,
      'clinicName': clinicName,
      'specialisation': specialisation,
      'gender': gender,
      if (phone != null) 'phone': phone,
      if (experience != null) 'experience': experience,
    };
  }

  TherapistModel copyWith({
    String? name,
    String? clinicName,
    String? specialisation,
    String? phone,
    String? experience,
  }) {
    return TherapistModel(
      userId: userId,
      name: name ?? this.name,
      licenceNumber: licenceNumber,
      clinicName: clinicName ?? this.clinicName,
      specialisation: specialisation ?? this.specialisation,
      gender: gender,
      phone: phone ?? this.phone,
      experience: experience ?? this.experience,
    );
  }
}