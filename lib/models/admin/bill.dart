class Bill {
  final String id;
  final String subscriptionId;
  final String teacherId;
  final double billAmount;
  final DateTime paidAt;
  final DateTime expiryDate;
  final String subscriptionName;
  final int subscriptionDurationInDays;
  final String subscriptionDescription;

  // تاريخ انتهاء الفاتورة دي

  Bill({
    required this.id,
    required this.subscriptionId,
    required this.teacherId,
    required this.billAmount,
    required this.paidAt,
    required this.expiryDate,
    required this.subscriptionName,
    required this.subscriptionDescription,
    required this.subscriptionDurationInDays,
  });

  factory Bill.fromJson(Map<String, dynamic> json, String docId) {
    return Bill(
      subscriptionDurationInDays: json['subscriptionDurationInDays'] ?? 0,
      subscriptionName: json['subscriptionName'] ?? '',
      subscriptionDescription: json['subscriptionDescription'] ?? '',
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
      'subscriptionName': subscriptionName,
      'subscriptionDescription': subscriptionDescription,
      'subscriptionId': subscriptionId,
      'subscriptionDurationInDays': subscriptionDurationInDays,
      'teacherId': teacherId,
      'billAmount': billAmount,
      'paidAt': paidAt.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }
}
