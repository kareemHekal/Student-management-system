class MiniExam {
  final String miniExamName;
  final String id;
  final double fullGrade;

  MiniExam({
    required this.miniExamName,
    required this.id,
    required this.fullGrade,
  });

  /// Create from JSON
  factory MiniExam.fromJson(Map<String, dynamic> json) {
    return MiniExam(
      id: json['id'] ?? '',
      miniExamName: json['miniExamName'] ?? '',
      fullGrade: (json['fullGrade'] ?? 0).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'miniExamName': miniExamName,
      'id': id,
      'fullGrade': fullGrade,
    };
  }

  /// Copy with new values
  MiniExam copyWith({
    String? miniExamName,
    double? fullGrade,
  }) {
    return MiniExam(
      id: id,
      miniExamName: miniExamName ?? this.miniExamName,
      fullGrade: fullGrade ?? this.fullGrade,
    );
  }

  @override
  String toString() {
    return 'MiniExam(miniExamName: $miniExamName, fullGrade: $fullGrade)';
  }
}
