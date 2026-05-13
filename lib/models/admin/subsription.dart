enum SubscriptionType { basic, boost, adminSubscription, offers }

class Subscription {
  final String? id;
  final String name;
  final String description;
  final int durationInDays; // أفضل من String عشان الحسابات
  final double price;
  final int totalStudents;
  final SubscriptionType subscriptionType;

  Subscription({
    this.id,
    required this.name,
    required this.description,
    required this.durationInDays,
    required this.price,
    required this.subscriptionType,
    required this.totalStudents,
  });

  factory Subscription.fromJson(Map<String, dynamic> json, String docId) {
    return Subscription(
      id: docId,
      name: json['name'] ?? '',
      subscriptionType: SubscriptionType.values.firstWhere(
        (e) => e.name == json['subscriptionType'],
        orElse: () => SubscriptionType.basic,
      ),
      description: json['description'] ?? '',
      durationInDays: json['durationInDays'] ?? 30,
      totalStudents: json['totalStudents'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subscriptionType': subscriptionType.name,
      'description': description,
      'durationInDays': durationInDays,
      'totalStudents': totalStudents,
      'price': price,
    };
  }
}
