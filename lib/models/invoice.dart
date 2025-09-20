class Invoice {
  final String studentName;
  final String id;
  String studentId;
  final String studentPhoneNumber;
  final String momPhoneNumber;
  final String dadPhoneNumber;
  final String grade;
  final double amount;
  final String description;
  final DateTime dateTime;

  Invoice({
    required this.studentId,
    required this.id,
    required this.studentName,
    required this.studentPhoneNumber,
    required this.momPhoneNumber,
    required this.dadPhoneNumber,
    required this.grade,
    required this.amount,
    required this.description,
    required this.dateTime,
  });

  // From JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? "",
      // safe default
      studentId: json['studentId'] ?? "",
      // safe default
      studentName: json['studentName'] ?? "",
      studentPhoneNumber: json['studentPhoneNumber'] ?? "",
      momPhoneNumber: json['momPhoneNumber'] ?? "",
      dadPhoneNumber: json['dadPhoneNumber'] ?? "",
      grade: json['grade'] ?? "",
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
      'studentId': studentId,
      'studentPhoneNumber': studentPhoneNumber,
      'momPhoneNumber': momPhoneNumber,
      'dadPhoneNumber': dadPhoneNumber,
      'grade': grade,
      'amount': amount,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
    };
  }
}
