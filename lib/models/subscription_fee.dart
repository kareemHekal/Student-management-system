class SubscriptionFee {
  String subscriptionName; // name of the month or the payment
  double subscriptionAmount;

  SubscriptionFee({
    required this.subscriptionName,
    required this.subscriptionAmount,
  });

  factory SubscriptionFee.fromJson(Map<String, dynamic> json) {
    return SubscriptionFee(
      subscriptionName: json['subscriptionName'] ?? '',
      subscriptionAmount: (json['subscriptionAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionName': subscriptionName,
      'subscriptionAmount': subscriptionAmount,
    };
  }

  SubscriptionFee copyWith({
    String? subscriptionName,
    double? subscriptionAmount,
  }) {
    return SubscriptionFee(
      subscriptionName: subscriptionName ?? this.subscriptionName,
      subscriptionAmount: subscriptionAmount ?? this.subscriptionAmount,
    );
  }

  @override
  String toString() {
    return 'SubscriptionFee(name: $subscriptionName, amount: $subscriptionAmount)';
  }
}
