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

  // حقول التحكم الجديدة
  final String billType; // 'basic' أو 'boost'
  final int? previousBaseLimit; // بنحتاجه في undo الـ basic
  final int? boostAmount; // بنحتاجه في undo الـ boost

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
    required this.billType,
    this.previousBaseLimit,
    this.boostAmount,
  });

  factory Bill.fromJson(Map<String, dynamic> json, String docId) {
    return Bill(
      id: docId,
      subscriptionId: json['subscriptionId'] ?? '',
      teacherId: json['teacherId'] ?? '',
      billAmount: (json['billAmount'] ?? 0).toDouble(),
      paidAt: DateTime.parse(json['paidAt']),
      expiryDate: DateTime.parse(json['expiryDate']),
      subscriptionName: json['subscriptionName'] ?? '',
      subscriptionDescription: json['subscriptionDescription'] ?? '',
      subscriptionDurationInDays: json['subscriptionDurationInDays'] ?? 0,
      billType: json['billType'] ?? 'basic',
      previousBaseLimit: json['previousBaseLimit'],
      boostAmount: json['boostAmount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'teacherId': teacherId,
      'billAmount': billAmount,
      'paidAt': paidAt.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'subscriptionName': subscriptionName,
      'subscriptionDescription': subscriptionDescription,
      'subscriptionDurationInDays': subscriptionDurationInDays,
      'billType': billType,
      'previousBaseLimit': previousBaseLimit,
      'boostAmount': boostAmount,
    };
  }
}