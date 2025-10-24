

class Invoice {
  final String studentName;
  final String id;
  String studentId;
  final String studentPhoneNumber;
  final String momPhoneNumber;
  final String dadPhoneNumber;
  final double amount;
  final String description;
  final String grade;
  final String subscriptionFeeID;
  final DateTime dateTime;

  Invoice({
    required this.grade,
    required this.subscriptionFeeID,
    required this.studentId,
    required this.id,
    required this.studentName,
    required this.studentPhoneNumber,
    required this.momPhoneNumber,
    required this.dadPhoneNumber,
    required this.amount,
    required this.description,
    required this.dateTime,
  });

  // From JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      grade: json['grade'] ?? "",
      id: json['id'] ?? "",
      // safe default
      studentId: json['studentId'] ?? "",
      subscriptionFeeID: json['subscriptionFeeID'] ?? "",
      studentName: json['studentName'] ?? "",
      studentPhoneNumber: json['studentPhoneNumber'] ?? "",
      momPhoneNumber: json['momPhoneNumber'] ?? "",
      dadPhoneNumber: json['dadPhoneNumber'] ?? "",
      amount: (json['amount'] ?? 0).toDouble(),
      // handles int or null
      description: json['description'] ?? "",
      dateTime: json['dateTime'] != null
          ? DateTime.tryParse(json['dateTime']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'subscriptionFeeID': subscriptionFeeID,
      'studentId': studentId,
      'grade': grade,
      'studentPhoneNumber': studentPhoneNumber,
      'momPhoneNumber': momPhoneNumber,
      'dadPhoneNumber': dadPhoneNumber,
      'amount': amount,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
    };
  }
}
