import 'dart:async';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/Magmo3aModel.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/models/absence_app/absence_model.dart';
import 'package:student_management_system/models/absence_app/day_record.dart';

import 'intent.dart';
import 'states.dart';

class AbsentCubit extends Cubit<AbsentState> {
  final Magmo3amodel magmo3aModel;
  final String selectedDateStr;
  final String selectedDay;

  AbsentCubit({
    required this.magmo3aModel,
    required this.selectedDateStr,
    required this.selectedDay,
  }) : super(AbsentInitial());

  final searchController = TextEditingController();

  List<Studentmodel> absentStudents = [];
  List<Studentmodel> attendStudents = [];
  List<Studentmodel> filteredAbsentStudentsList = [];
  List<Studentmodel> filteredAttendStudentsList = [];

  bool? isAttendanceStarted;
  int? numberOfStudents;

  // ------------------- HANDLE INTENT -------------------
  Future<void> handleIntent(AbsentIntent intent) async {
    switch (intent.runtimeType) {
      case FetchAbsence:
        await _fetchAbsence();
        break;

      case StartTakingAttendance:
        await _startTakingAbsence();
        break;

      case AddStudentToPresent:
        final i = intent as AddStudentToPresent;
        await _addStudentToPresent(i.student, i.realStudentId);
        break;

      case ScanQrIntent:
        final i = intent as ScanQrIntent;
        await _scanQrcode(i.context);
        break;

      case SearchStudent:
        final i = intent as SearchStudent;
        _searchAbsentStudents(i.query);
        break;

      case RestoreStudentToAbsent:
        final i = intent as RestoreStudentToAbsent;
        await _restoreStudent(i.student);
        break;
    }
  }

  // ------------------- FETCH ABSENCE -------------------
  Future<void> _fetchAbsence() async {
    emit(AbsentLoading());

    try {
      // Clear old data to avoid duplicates
      absentStudents.clear();
      attendStudents.clear();

      final absentRecord = await FirebaseFunctions.getAbsenceByDate(
        selectedDay,
        magmo3aModel.id,
        selectedDateStr,
      );

      if (absentRecord != null) {
        // 🔹 Fetch absent students in parallel
        final absentFutures = absentRecord.absentStudentIds.map(
          (String studentId) => FirebaseFunctions.getStudentById(
            magmo3aModel.grade ?? "",
            studentId,
          ),
        );

        final absentResults = await Future.wait(absentFutures);
        absentStudents.addAll(
          absentResults.whereType<Studentmodel>(),
        );

        // 🔹 Fetch attending students in parallel
        final attendFutures = absentRecord.attendStudentIds.map(
          (String studentId) => FirebaseFunctions.getStudentById(
            magmo3aModel.grade ?? "",
            studentId,
          ),
        );

        final attendResults = await Future.wait(attendFutures);
        attendStudents.addAll(
          attendResults.whereType<Studentmodel>(),
        );

        numberOfStudents = absentRecord.numberOfStudents ?? 0;
        filteredAbsentStudentsList = absentStudents;
        isAttendanceStarted = true;

        emit(AttendanceStarted());
      } else {
        await _fetchStudentsList();
      }
    } catch (e) {
      emit(AbsentError('Error fetching absence record: $e'));
    }
  }

  // ------------------- FETCH STUDENTS LIST -------------------
  Future<void> _fetchStudentsList() async {
    emit(AbsentLoading());
    try {
      final snapshot = await FirebaseFunctions.getStudentsByGroupIdOnce(
        magmo3aModel.grade ?? "",
        magmo3aModel.id,
      );

      absentStudents = snapshot.docs.map((doc) => doc.data()).toList();
      filteredAbsentStudentsList = absentStudents;
      numberOfStudents = absentStudents.length;
      isAttendanceStarted = false;
      emit(AbsenceFetched());

      emit(AbsenceFetched());
    } catch (e) {
      emit(AbsentError("Error fetching students: $e"));
    }
  }

  // ------------------- START ATTENDANCE -------------------
  Future<void> _startTakingAbsence() async {
    emit(AbsentLoading());

    for (var student in absentStudents) {
      student.countingAbsentDays ??= [];
      student.countingAbsentDays!
          .add(DayRecord(date: selectedDateStr, day: selectedDay));
      await FirebaseFunctions.updateStudentInCollection(
        student.grade ?? "",
        student.id,
        student,
      );
    }

    isAttendanceStarted = true;

    final absenceModel = AbsenceModel(
      numberOfStudents: absentStudents.length,
      date: selectedDateStr,
      attendStudentIds: attendStudents.map((s) => s.id).toList(),
      absentStudentIds: absentStudents.map((s) => s.id).toList(),
    );

    await FirebaseFunctions.updateAbsenceByDateInSubcollection(
      selectedDay,
      magmo3aModel.id,
      selectedDateStr,
      absenceModel,
    );

    emit(AttendanceStarted());
  }

  // ------------------- ADD STUDENT TO PRESENT -------------------
  Future<void> _addStudentToPresent(
      Studentmodel student, String realStudentId) async {
    // 1. Check if already present without using context
    if (attendStudents.any((s) => s.id == student.id)) {
      emit(AbsentError('⚠️ تم تسجيل حضوره من قبل.'));
      return;
    }

    try {
      // UI Update: Move to lists immediately for responsiveness
      attendStudents.add(student);
      absentStudents.removeWhere((s) => s.id == student.id);
      filteredAbsentStudentsList =
          List.from(absentStudents); // Create new list reference

      emit(AbsenceFetched()); // Update the list in UI

      final absenceModel = AbsenceModel(
        numberOfStudents: numberOfStudents ?? 0,
        date: selectedDateStr,
        attendStudentIds: attendStudents.map((s) => s.id).toList(),
        absentStudentIds: absentStudents.map((s) => s.id).toList(),
      );

      // Firebase updates
      await updateStudentAttendance(student, realStudentId);
      await FirebaseFunctions.updateAbsenceByDateInSubcollection(
        selectedDay,
        magmo3aModel.id,
        selectedDateStr,
        absenceModel,
      );

      isAttendanceStarted = true;
      emit(ScanSuccess(
          student)); // This will trigger the success snackbar in the UI
    } catch (e) {
      emit(AbsentError('❌ فشل في تحديث الحضور: $e'));
    }
  }

  Future<void> updateStudentAttendance(
      Studentmodel student, String studentId) async {
    student.countingAttendedDays ??= [];
    student.countingAttendedDays!
        .add(DayRecord(date: selectedDateStr, day: selectedDay));

    student.countingAbsentDays ??= [];
    student.countingAbsentDays!.removeWhere((dayRecord) =>
        dayRecord.date == selectedDateStr && dayRecord.day == selectedDay);

    await FirebaseFunctions.updateStudentInCollection(
      magmo3aModel.grade ?? "",
      studentId,
      student,
    );
  }

  // ------------------- SCAN QR -------------------
  Future<void> _scanQrcode(BuildContext context) async {
    MobileScannerController _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: this,
          child: AiBarcodeScanner(
            onDispose: () => debugPrint("Barcode scanner disposed!"),
            hideGalleryButton: false,
            controller: _scannerController,
            onDetect: (BarcodeCapture capture) async {
              _scannerController.stop();
              await runWithLoading(context, () async {
                final scannedValue = capture.barcodes.first.rawValue;
                if (scannedValue == null) return;

                scaffoldMessenger.clearSnackBars();

                final student = await FirebaseFunctions.getStudentById(
                  magmo3aModel.grade ?? "",
                  scannedValue,
                );

                if (student != null &&
                    student.hisGroupsId?.contains(magmo3aModel.id) == true) {
                  await _addStudentToPresent(student, scannedValue);
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        student == null
                            ? "لم يتم العثور على الطالب!"
                            : "الطالب ليس ضمن هذه المجموعة!",
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(milliseconds: 800),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
              _scannerController.start();
            },
          ),
        ),
      ),
    );
  }

  // ------------------- SEARCH STUDENT -------------------
  void _searchAbsentStudents(String query) {
    filteredAbsentStudentsList = query.isEmpty
        ? absentStudents
        : absentStudents
            .where((student) => (student.name ?? '')
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();

    emit(SearchResultsUpdated(filteredAbsentStudentsList));
  }

  Future<void> _restoreStudent(Studentmodel student) async {
    attendStudents.removeWhere((s) => s.id == student.id);
    absentStudents.add(student);

    student.countingAbsentDays ??= [];
    student.countingAbsentDays!
        .add(DayRecord(date: selectedDateStr, day: selectedDay));

    student.countingAttendedDays?.removeWhere(
      (d) => d.date == selectedDateStr && d.day == selectedDay,
    );

    final absenceModel = AbsenceModel(
      date: selectedDateStr,
      numberOfStudents: numberOfStudents ?? 0,
      attendStudentIds: attendStudents.map((s) => s.id).toList(),
      absentStudentIds: absentStudents.map((s) => s.id).toList(),
    );

    await FirebaseFunctions.updateStudentInCollection(
      magmo3aModel.grade ?? "",
      student.id,
      student,
    );

    await FirebaseFunctions.updateAbsenceByDateInSubcollection(
      selectedDay,
      magmo3aModel.id,
      selectedDateStr,
      absenceModel,
    );
    refreshAbsentFilteredList();

    emit(AbsenceFetched());
  }

  void searchAttendingStudents(String query) {
    filteredAttendStudentsList = query.isEmpty
        ? attendStudents
        : attendStudents
            .where((student) => (student.name ?? '')
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();

    emit(SearchResultsUpdated(filteredAttendStudentsList));
  }

  void refreshAbsentFilteredList() {
    filteredAbsentStudentsList = List.from(absentStudents);
    emit(SearchResultsUpdated(filteredAbsentStudentsList));
  }
}
