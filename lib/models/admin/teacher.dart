class Teacher {
  final String id;
  final String name;
  final String phoneNumber;
  final DateTime createdAt;
  final bool isActive; // تحكم يدوي منك كأدمن
  final int totalStudents;
  final int subscriptionTotalStudents;
  final DateTime subscriptionEndTime;

  Teacher({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.createdAt,
    required this.isActive,
    required this.totalStudents,
    required this.subscriptionEndTime,
    required this.subscriptionTotalStudents,
  });

  bool get hasActiveSubscription =>
      isActive && subscriptionEndTime.isAfter(DateTime.now());

  factory Teacher.fromJson(Map<String, dynamic> json, String docId) {
    return Teacher(
      id: docId,
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      totalStudents: json['totalStudents'] ?? 0,
      subscriptionTotalStudents: json['subscriptionTotalStudents'] ?? 0,
      subscriptionEndTime: DateTime.parse(
          json['subscriptionEndTime'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'totalStudents': totalStudents,
      'subscriptionTotalStudents': subscriptionTotalStudents,
      'subscriptionEndTime': subscriptionEndTime.toIso8601String(),
    };
  }
}
