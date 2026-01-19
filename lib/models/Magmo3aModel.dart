import 'package:flutter/material.dart';

class Magmo3amodel {
  String? day;
  String? grade;
  TimeOfDay time;
  String id;

  Magmo3amodel({
    this.id = "",
    required this.grade,
    required this.day,
    required this.time,
  });

  factory Magmo3amodel.fromJson(Map<String, dynamic> json) {
    return Magmo3amodel(
      day: json["days"],
      id: json['id'] ?? "",
      grade: json["grade"],
      // Logic to handle the nested time map safely
      time: json["time"] != null
          ? TimeOfDay(
              hour: json["time"]["hour"] ?? 0,
              minute: json["time"]["minute"] ?? 0,
            )
          : const TimeOfDay(hour: 0, minute: 0), // Fallback if null in DB
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "days": day,
      "id": id,
      "grade": grade,
      // Removed null checks since 'time' is required
      "time": {
        "hour": time.hour,
        "minute": time.minute,
      },
    };
  }

  // Recommended: Add a copyWith to make state management easier
  Magmo3amodel copyWith({
    String? days,
    String? grade,
    TimeOfDay? time,
    String? id,
  }) {
    return Magmo3amodel(
      day: days ?? this.day,
      grade: grade ?? this.grade,
      time: time ?? this.time,
      id: id ?? this.id,
    );
  }
}