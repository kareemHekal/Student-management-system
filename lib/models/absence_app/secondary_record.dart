import 'package:flutter/material.dart';

class SecondaryRecord {
  final String date;
  final String day;
  final String magmo3aId;
  final TimeOfDay time; // Required, no '?'

  SecondaryRecord({
    required this.date,
    required this.day,
    required this.magmo3aId,
    required this.time,
  });

  factory SecondaryRecord.fromJson(Map<String, dynamic> json) {
    return SecondaryRecord(
      date: json['date'] ?? '',
      magmo3aId: json['magmo3aId'] ?? '',
      day: json['day'] ?? '',
      time: json['time'] != null
          ? _parseTime(json['time'])
          : const TimeOfDay(hour: 0, minute: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'magmo3aId': magmo3aId,
      'day': day,
      'time': '${time.hour}:${time.minute}',
    };
  }

  static TimeOfDay _parseTime(String source) {
    final parts = source.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
