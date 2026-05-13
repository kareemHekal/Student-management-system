class AbsenceModel {
  final String date;
  final int numberOfStudents;
  final List<String> absentStudentIds;
  final List<String> attendStudentIds;

  AbsenceModel({
    required this.date,
    required this.numberOfStudents,
    required this.absentStudentIds,
    required this.attendStudentIds,
  });

  factory AbsenceModel.fromJson(Map<String, dynamic> json) {
    return AbsenceModel(
      date: json['date'] ?? '',
      numberOfStudents: json['numberOfStudents'] ?? 0,
      absentStudentIds: List<String>.from(json['absentStudentIds'] ?? []),
      attendStudentIds: List<String>.from(json['attendStudentIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'numberOfStudents': numberOfStudents,
      'absentStudentIds': absentStudentIds,
      'attendStudentIds': attendStudentIds,
    };
  }
}
