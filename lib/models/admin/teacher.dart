import 'package:cloud_firestore/cloud_firestore.dart';

import 'bill.dart';
import 'boost_subscription.dart';

class Teacher {
  final String id;
  final String name;
  final String phoneNumber;
  final DateTime createdAt;
  final bool isActive;
  final DateTime subscriptionEndTime;
  final List<ActiveBoost> activeBoosts;
  final int currentStudentCount;

  Teacher({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.createdAt,
    required this.isActive,
    required this.subscriptionEndTime,
    required this.activeBoosts,
    required this.currentStudentCount,
  });

  // --- الحسبة الذكية (Logic) ---

  Future<int> getBaseStudentLimit() async {
    final now = DateTime.now();

    // نستخدم "id" الخاص بالأوبجكت الحالي مباشرة
    var snapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(id)
        .collection('bills')
        .where('billType', isEqualTo: 'basic')
        .get();

    if (snapshot.docs.isEmpty) return 0;

    int highestLimit = 0;

    for (var doc in snapshot.docs) {
      final bill = Bill.fromJson(doc.data(), doc.id);

      // نتحقق أن الفاتورة سارية المفعول
      if (bill.expiryDate.isAfter(now)) {
        int limit = bill.baseStudentLimit ?? 0;
        if (limit > highestLimit) {
          highestLimit = limit;
        }
      }
    }
    return highestLimit;
  }

  /// دالة واحدة تجلب الحد الأقصى الكلي (الأساسي + البوستات) ديناميكياً
  Future<int> getTotalAllowedStudents() async {
    // 1. جلب الليمت الأساسي من الفواتير (نادينا الفانكشن اللي في نفس الكلاس)
    int baseLimit = await getBaseStudentLimit();

    int total = baseLimit;
    final now = DateTime.now();

    // 2. إضافة البوستات النشطة من القائمة الموجودة في الأوبجكت
    for (var boost in activeBoosts) {
      if (boost.expiryDate.isAfter(now)) {
        total += boost.studentAmount;
      }
    }

    return total;
  }

  bool get hasActiveSubscription =>
      isActive && subscriptionEndTime.isAfter(DateTime.now());

  // --- تحويل البيانات (Mapping) ---

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
      'currentStudentCount': currentStudentCount,
      'activeBoosts': activeBoosts.map((e) => e.toJson()).toList(),
    };
  }
}