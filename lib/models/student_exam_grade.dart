class StudentExamGrade {
  final String studentGrade;
  final String examId;
  final String miniExamId;
  final String description;

  StudentExamGrade({
    required this.studentGrade,
    required this.examId,
    required this.miniExamId,
    required this.description,
  });

  // Convert to JSON for Firestore or other storage
  Map<String, dynamic> toJson() {
    return {
      'studentGrade': studentGrade,
      'examId': examId,
      'miniExamId': miniExamId,
      'description': description,
    };
  }

  // Create an instance from JSON
  factory StudentExamGrade.fromJson(Map<String, dynamic> json) {
    return StudentExamGrade(
      studentGrade: json['studentGrade'] as String,
      examId: json['examId'] as String,
      miniExamId: json['miniExamId'] as String,
      description: json['description'] as String,
    );
  }
}
