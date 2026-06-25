class TherapistModel {
  final String userId;
  final String name;
  final String email;
  final String licenceNumber;
  final String clinicName;
  final String specialisation;
  final String gender;
  final String? experience;
  final String? profilePhotoBase64;

  TherapistModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.licenceNumber,
    required this.clinicName,
    required this.specialisation,
    required this.gender,
    this.experience,
    this.profilePhotoBase64,
  });

  factory TherapistModel.fromMap(Map<String, dynamic> map, String userId) {
    return TherapistModel(
      userId: userId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      licenceNumber: map['licenceNumber'] ?? '',
      clinicName: map['clinicName'] ?? '',
      specialisation: map['specialisation'] ?? '',
      gender: map['gender'] ?? '',
      experience: map['experience'] as String?,
      profilePhotoBase64: map['profilePhotoBase64'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'licenceNumber': licenceNumber,
      'clinicName': clinicName,
      'specialisation': specialisation,
      'gender': gender,
      if (experience != null) 'experience': experience,
    };
  }

  TherapistModel copyWith({
    String? name,
    String? clinicName,
    String? specialisation,
    String? experience,
    String? profilePhotoBase64,
  }) {
    return TherapistModel(
      userId: userId,
      name: name ?? this.name,
      email: email,
      licenceNumber: licenceNumber,
      clinicName: clinicName ?? this.clinicName,
      specialisation: specialisation ?? this.specialisation,
      gender: gender,
      experience: experience ?? this.experience,
      profilePhotoBase64: profilePhotoBase64 ?? this.profilePhotoBase64,
    );
  }
}