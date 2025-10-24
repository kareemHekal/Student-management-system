class StudentPaidSubscriptions {
  final double paidAmount;
  final String subscriptionId;
  final String description;

  StudentPaidSubscriptions({
    required this.paidAmount,
    required this.subscriptionId,
    required this.description,
  });

  factory StudentPaidSubscriptions.fromJson(Map<String, dynamic> json) {
    return StudentPaidSubscriptions(
      description: json['description'] ?? '',
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      subscriptionId: json['subscriptionId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'paidAmount': paidAmount,
      'subscriptionId': subscriptionId,
    };
  }

  StudentPaidSubscriptions copyWith({
    double? paidAmount,
    String? description,
    String? subscriptionId,
  }) {
    return StudentPaidSubscriptions(
      description: description ?? this.description,
      paidAmount: paidAmount ?? this.paidAmount,
      subscriptionId: subscriptionId ?? this.subscriptionId,
    );
  }

  @override
  String toString() {
    return 'StudentPaidSubscription(paidAmount: $paidAmount, subscriptionId: $subscriptionId,description: $description)';
  }
}
