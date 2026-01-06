import 'package:flutter/material.dart';
import 'package:student_management_system/models/Student_model.dart';

sealed class AbsentIntent {}

class FetchAbsence extends AbsentIntent {}

class StartTakingAttendance extends AbsentIntent {}

class AddStudentToPresent extends AbsentIntent {
  final Studentmodel student;
  final String realStudentId;

  AddStudentToPresent({
    required this.student,
    required this.realStudentId,
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

  RestoreStudentToAbsent(this.student);
}
