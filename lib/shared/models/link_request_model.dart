class LinkRequestModel {
  final String requestId;
  final String parentId;
  final String childId;
  final String therapistEmail;
  final String status; // "pending", "accepted", "rejected"
  final DateTime createdAt;

  LinkRequestModel({
    required this.requestId,
    required this.parentId,
    required this.childId,
    required this.therapistEmail,
    required this.status,
    required this.createdAt,
  });

  factory LinkRequestModel.fromMap(Map<String, dynamic> map, String requestId) {
    return LinkRequestModel(
      requestId: requestId,
      parentId: map['parentId'] ?? '',
      childId: map['childId'] ?? '',
      therapistEmail: map['therapistEmail'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'childId': childId,
      'therapistEmail': therapistEmail,
      'status': status,
      'createdAt': createdAt,
    };
  }
}