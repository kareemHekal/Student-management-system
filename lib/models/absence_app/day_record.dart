import 'package:flutter/material.dart';

import 'secondary_record.dart';

class DayRecord {
  final String date;
  final String day;
  final TimeOfDay time;
  final String magmo3aId;
  final SecondaryRecord? secondary;

  DayRecord({
    required this.magmo3aId,
    required this.date,
    required this.day,
    required this.time, // Required in constructor
    this.secondary,
  });

  factory DayRecord.fromJson(Map<String, dynamic> json) {
    return DayRecord(
      magmo3aId: json['magmo3aId'] ?? '',
      date: json['date'] ?? '',
      day: json['day'] ?? '',
      // If time is null in JSON, we provide a default TimeOfDay
      time: json['time'] != null
          ? _parseTime(json['time'])
          : const TimeOfDay(hour: 0, minute: 0),
      secondary: json['secondary'] != null
          ? SecondaryRecord.fromJson(json['secondary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'magmo3aId': magmo3aId,
      'day': day,
      'time': '${time.hour}:${time.minute}', // No null check needed
      'secondary': secondary?.toJson(),
    };
  }

  static TimeOfDay _parseTime(String source) {
    final parts = source.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}