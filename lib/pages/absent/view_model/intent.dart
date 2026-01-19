import 'package:flutter/material.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/models/absence_app/secondary_record.dart';

sealed class AbsentIntent {}

class FetchAbsence extends AbsentIntent {}

class StartTakingAttendance extends AbsentIntent {}

class AddStudentToPresent extends AbsentIntent {
  final Studentmodel student;
  final SecondaryRecord? secondaryRecord;

  AddStudentToPresent({
    required this.secondaryRecord,
    required this.student,
  });
}

class ScanQrIntent extends AbsentIntent {
  final BuildContext context;

  ScanQrIntent({required this.context});
}

class SearchStudent extends AbsentIntent {
  final String query;

  SearchStudent({required this.query});
}

class RestoreStudentToAbsent extends AbsentIntent {
  final Studentmodel student;

  RestoreStudentToAbsent({
    required this.student,
  });
}
