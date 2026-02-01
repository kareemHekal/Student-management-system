class ActiveBoost {
  final String id; // عشان نعرف نمسحها لو عملنا undo
  final int studentAmount; // الكمية: 50, 100
  final DateTime expiryDate; // تاريخ انتهاء البوست ده تحديداً
  final DateTime purchasedAt;

  ActiveBoost(
      {required this.id,
      required this.studentAmount,
      required this.expiryDate,
      required this.purchasedAt});

  // تحويل لـ Map عشان Firestore
  Map<String, dynamic> toJson() => {
        'id': id,
        'studentAmount': studentAmount,
        'expiryDate': expiryDate.toIso8601String(),
        'purchasedAt': purchasedAt.toIso8601String(),
      };

  factory ActiveBoost.fromJson(Map<String, dynamic> json) {
    return ActiveBoost(
      id: json['id'],
      studentAmount: json['studentAmount'],
      expiryDate: DateTime.parse(json['expiryDate']),
      purchasedAt: DateTime.parse(json['purchasedAt']),
    );
  }
}
