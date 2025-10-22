import 'subscription_fee.dart';

class GradeSubscriptionsModel {
  String gradeName;
  List<SubscriptionFee> subscriptions;

  GradeSubscriptionsModel({
    required this.gradeName,
    required this.subscriptions,
  });

  // ✅ Convert from JSON to object
  factory GradeSubscriptionsModel.fromJson(Map<String, dynamic> json) {
    return GradeSubscriptionsModel(
      gradeName: json['gradeName'] ?? '',
      subscriptions: (json['subscriptions'] as List<dynamic>? ?? [])
          .map((e) => SubscriptionFee.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ✅ Convert from object to JSON
  Map<String, dynamic> toJson() {
    return {
      'gradeName': gradeName,
      'subscriptions': subscriptions.map((e) => e.toJson()).toList(),
    };
  }

  // ✅ Copy with modifications
  GradeSubscriptionsModel copyWith({
    String? gradeName,
    List<SubscriptionFee>? subscriptions,
  }) {
    return GradeSubscriptionsModel(
      gradeName: gradeName ?? this.gradeName,
      subscriptions: subscriptions ?? this.subscriptions,
    );
  }

  // ✅ For easier debugging / printing
  @override
  String toString() {
    return 'GradeSubscriptionsModel(gradeName: $gradeName, subscriptions: $subscriptions)';
  }
}
