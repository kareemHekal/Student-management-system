import 'day_record.dart';

class StudentAbsencesModel {
  String monthName;
  List<DayRecord> attendedDays;
  List<DayRecord> absentDays;

  StudentAbsencesModel({
    required this.monthName,
    required this.attendedDays,
    required this.absentDays,
  });

  /// Convert a JSON map to AbsenceModel
  factory StudentAbsencesModel.fromJson(Map<String, dynamic> json) {
    return StudentAbsencesModel(
      monthName: json['monthName'] as String? ?? '',
      absentDays: (json['absentDays'] as List<dynamic>?)
              ?.map((e) => DayRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      attendedDays: (json['attendedDays'] as List<dynamic>?)
              ?.map((e) => DayRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  /// Convert AbsenceModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'monthName': monthName,
      'absentDays': absentDays.map((e) => e.toJson()).toList(),
      'attendedDays': attendedDays.map((e) => e.toJson()).toList(),
    };
  }

  /// Create a copy with optional new values
  StudentAbsencesModel copyWith({
    String? monthName,
    List<DayRecord>? attendedDays,
    List<DayRecord>? absentDays,
  }) {
    return StudentAbsencesModel(
      monthName: monthName ?? this.monthName,
      attendedDays: attendedDays ?? this.attendedDays,
      absentDays: absentDays ?? this.absentDays,
    );
  }

  @override
  String toString() {
    return 'AbsenceModel(monthName: $monthName, attendedDays: $attendedDays, absentDays: $absentDays)';
  }
}
