import 'boost_subscription.dart';

class Teacher {
  final String id;
  final String name;
  final String phoneNumber;
  final DateTime createdAt;
  final bool isActive;
  final DateTime subscriptionEndTime;

  // الحقول الجديدة للسيستم المطور
  final int baseStudentLimit; // الليمت الأساسي (مثلاً 600)
  final List<ActiveBoost> activeBoosts; // لستة البوستات النشطة
  final int currentStudentCount; // عدد الطلاب اللي عند المدرس فعلياً حالياً

  Teacher({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.createdAt,
    required this.isActive,
    required this.subscriptionEndTime,
    required this.baseStudentLimit,
    required this.activeBoosts,
    required this.currentStudentCount,
  });

  // الحسبة الذكية: ليمت أساسي + أي بوست لسه مخلصش
  int get totalAllowedStudents {
    int total = baseStudentLimit;
    final now = DateTime.now();
    for (var boost in activeBoosts) {
      if (boost.expiryDate.isAfter(now)) {
        total += boost.studentAmount;
      }
    }
    return total;
  }

  bool get hasActiveSubscription =>
      isActive && subscriptionEndTime.isAfter(DateTime.now());

  factory Teacher.fromJson(Map<String, dynamic> json, String docId) {
    var boostsFromJson = json['activeBoosts'] as List? ?? [];
    List<ActiveBoost> listBoosts = boostsFromJson
        .map((boostJson) => ActiveBoost.fromJson(boostJson))
        .toList();

    return Teacher(
      id: docId,
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      subscriptionEndTime: DateTime.parse(
          json['subscriptionEndTime'] ?? DateTime.now().toIso8601String()),
      baseStudentLimit: json['baseStudentLimit'] ?? 0,
      currentStudentCount: json['currentStudentCount'] ?? 0,
      activeBoosts: listBoosts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'subscriptionEndTime': subscriptionEndTime.toIso8601String(),
      'baseStudentLimit': baseStudentLimit,
      'currentStudentCount': currentStudentCount,
      'activeBoosts': activeBoosts.map((e) => e.toJson()).toList(),
    };
  }
}