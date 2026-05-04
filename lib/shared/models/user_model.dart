class UserModel {
  final String userId;
  final String email;
  final String role; // "parent" or "therapist"
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String userId) {
    return UserModel(
      userId: userId,
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }
}