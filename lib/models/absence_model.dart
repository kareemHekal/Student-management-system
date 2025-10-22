class AbsenceModel {
  String monthName;
  int? absentDays;
  int? attendedDays;

  AbsenceModel({
    required this.monthName,
    required this.absentDays,
    required this.attendedDays,
  });

  // Convert a JSON map to AbsenceModel
  factory AbsenceModel.fromJson(Map<String, dynamic> json) {
    return AbsenceModel(
      monthName: json['monthName'] as String,
      absentDays: json['absentDays'] as int,
      attendedDays: json['attendedDays'] as int,
    );
  }

  // Convert AbsenceModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'monthName': monthName,
      'absentDays': absentDays,
      'attendedDays': attendedDays,
    };
  }
}
