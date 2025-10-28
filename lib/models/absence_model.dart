import 'day_record.dart';

class AbsenceModel {
  String monthName;
  List<DayRecord> attendedDays;
  List<DayRecord> absentDays;

  AbsenceModel({
    required this.monthName,
    required this.attendedDays,
    required this.absentDays,
  });

  /// Convert a JSON map to AbsenceModel
  factory AbsenceModel.fromJson(Map<String, dynamic> json) {
    return AbsenceModel(
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
  AbsenceModel copyWith({
    String? monthName,
    List<DayRecord>? attendedDays,
    List<DayRecord>? absentDays,
  }) {
    return AbsenceModel(
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
