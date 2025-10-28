import 'mini_exam.dart';

class ExamModel {
  final String? id;
  final String name;
  List<MiniExam>? miniExams; // nullable list of mini exams

  ExamModel({
    required this.id,
    required this.name,
    this.miniExams,
  });

  /// Create from JSON
  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'],
      name: json['name'] ?? '',
      miniExams: (json['miniExams'] as List<dynamic>?)
          ?.map((e) => MiniExam.fromJson(e))
          .toList(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'miniExams': miniExams?.map((e) => e.toJson()).toList(),
    };
  }

  /// Copy with new values
  ExamModel copyWith({
    String? id,
    String? name,
    double? examGrade,
    double? studentGrade,
    String? description,
    List<MiniExam>? miniExams,
  }) {
    return ExamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      miniExams: miniExams ?? this.miniExams,
    );
  }

  @override
  String toString() {
    return 'ExamModel(id: $id, name: $name, miniExams: ${miniExams?.length ?? 0})';
  }
}
