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
  final DateTime? gracePeriodEndTime;

  Teacher({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.createdAt,
    required this.isActive,
    required this.subscriptionEndTime,
    required this.activeBoosts,
    required this.currentStudentCount,
    this.gracePeriodEndTime,
  });

  // --- الحسبة الذكية (Logic) ---

  Future<int> getBaseStudentLimit() async {
    final now = DateTime.now();

    // تحسين: جلب الفواتير التي تاريخ انتهائها "أكبر من" الآن فقط
    // ملحوظة: مقارنة النصوص ISO8601 تعمل بشكل صحيح للتواريخ
    var snapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(id)
        .collection('bills')
        .where('billType', isEqualTo: 'basic')
        .where('expiryDate', isGreaterThan: now.toIso8601String())
        .get();

    if (snapshot.docs.isEmpty) return 0;

    int highestLimit = 0;

    for (var doc in snapshot.docs) {
      // مش محتاجين نتحقق من التاريخ هنا تاني، الـ Query عمل الواجب
      // بس زيادة تأكيد مش هتضر
      final bill = Bill.fromJson(doc.data(), doc.id);
      int limit = bill.baseStudentLimit ?? 0;

      if (limit > highestLimit) {
        highestLimit = limit;
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
      gracePeriodEndTime: json['gracePeriodEndTime'] != null
          ? DateTime.parse(json['gracePeriodEndTime'])
          : null,
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
      'gracePeriodEndTime': gracePeriodEndTime?.toIso8601String(),
      // ملاحظة: حذفنا baseStudentLimit من هنا لأنه أصبح يُحسب ديناميكياً من الفواتير
    };
  }
}