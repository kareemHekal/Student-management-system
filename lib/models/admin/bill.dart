class Bill {
  final String id;
  final String subscriptionId;
  final String teacherId;
  final double billAmount;
  final DateTime paidAt;
  final DateTime expiryDate; // تاريخ انتهاء الفاتورة دي

  Bill({
    required this.id,
    required this.subscriptionId,
    required this.teacherId,
    required this.billAmount,
    required this.paidAt,
    required this.expiryDate,
  });

  factory Bill.fromJson(Map<String, dynamic> json, String docId) {
    return Bill(
      id: docId,
      subscriptionId: json['subscriptionId'] ?? '',
      teacherId: json['teacherId'] ?? '',
      billAmount: (json['billAmount'] ?? 0).toDouble(),
      paidAt: DateTime.parse(json['paidAt']),
      expiryDate: DateTime.parse(json['expiryDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'teacherId': teacherId,
      'billAmount': billAmount,
      'paidAt': paidAt.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }
}
