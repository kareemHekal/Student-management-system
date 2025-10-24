class SubscriptionFee {
  String id; // unique identifier for the subscription
  String subscriptionName; // name of the month or the payment
  double subscriptionAmount; // subscription amount

  SubscriptionFee({
    required this.id,
    required this.subscriptionName,
    required this.subscriptionAmount,
  });

  factory SubscriptionFee.fromJson(Map<String, dynamic> json) {
    return SubscriptionFee(
      id: json['id'] ?? '',
      subscriptionName: json['subscriptionName'] ?? '',
      subscriptionAmount: (json['subscriptionAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscriptionName': subscriptionName,
      'subscriptionAmount': subscriptionAmount,
    };
  }

  SubscriptionFee copyWith({
    String? id,
    String? subscriptionName,
    double? subscriptionAmount,
  }) {
    return SubscriptionFee(
      id: id ?? this.id,
      subscriptionName: subscriptionName ?? this.subscriptionName,
      subscriptionAmount: subscriptionAmount ?? this.subscriptionAmount,
    );
  }

  @override
  String toString() {
    return 'SubscriptionFee(id: $id, name: $subscriptionName, amount: $subscriptionAmount)';
  }
}
