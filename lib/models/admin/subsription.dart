class Subscription {
  final String id;
  final String name;
  final String description;
  final int durationInDays; // أفضل من String عشان الحسابات
  final double price;

  Subscription({
    required this.id,
    required this.name,
    required this.description,
    required this.durationInDays,
    required this.price,
  });

  factory Subscription.fromJson(Map<String, dynamic> json, String docId) {
    return Subscription(
      id: docId,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      durationInDays: json['durationInDays'] ?? 30,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'durationInDays': durationInDays,
      'price': price,
    };
  }
}
