class ParentModel {
  final String userId;
  final String name;
  final String phone;

  ParentModel({
    required this.userId,
    required this.name,
    required this.phone,
  });

  factory ParentModel.fromMap(Map<String, dynamic> map, String userId) {
    return ParentModel(
      userId: userId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}