import 'dart:async';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:student_management_system/alert_dialogs/group_selection_while_scanning.dart';
import 'package:student_management_system/alert_dialogs/student_payment_bottom_sheet.dart';

import 'package:student_management_system/firebase/firebase_functions.dart';

import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';

import 'package:student_management_system/models/Magmo3aModel.dart';

import 'package:student_management_system/models/Student_model.dart';

import 'package:student_management_system/models/absence_app/absence_model.dart';

import 'package:student_management_system/models/absence_app/day_record.dart';

import 'package:student_management_system/models/absence_app/secondary_record.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';

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

  StreamSubscription? _absenceSubscription;

  bool isFirstLoadDone = false;

  Future<void> handleIntent(AbsentIntent intent) async {
    if (isClosed) return;

    switch (intent.runtimeType) {
      case FetchAbsence:
        await _fetchAbsenceStream();
        break;

      case StartTakingAttendance:
        await _startTakingAbsence();
        break;

      case AddStudentToPresent:
        final i = intent as AddStudentToPresent;

        await _addManualStudentToPresent(
            student: i.student, targetSecondary: i.secondaryRecord);

        break;

      case ScanQrIntent:
        await _scanQrcode((intent as ScanQrIntent).context);
        break;

      case SearchStudent:
        _searchAbsentStudents((intent as SearchStudent).query);
        break;

      case RestoreStudentToAbsent:
        await _restoreStudent(
            student: (intent as RestoreStudentToAbsent).student);
        break;
    }
  }

  /// ---------------------------------------------------------

  /// 🆕 NEW FUNCTION: Get Secondary Group Students & Initialize

  /// ---------------------------------------------------------

  Future<void> getSecondaryGroupStudents({
    required String grade,
    required SecondaryRecord secondaryRecord,
  }) async {
    try {
      emit(AbsentInitial()); // Loading state

// 1. Fetch Students Once using the existing function

      final snapshot = await FirebaseFunctions.getStudentsByGroupIdOnce(
          grade, secondaryRecord.magmo3aId);

      List<Studentmodel> students =
          snapshot.docs.map((doc) => doc.data()).toList();

// 2. Check if Absence Record exists for this secondary session

// (Assuming a method getAbsenceByDateOnce exists, otherwise we check the collection)

      final absenceRecord = await FirebaseFunctions.getAbsenceByDateOnce(
        secondaryRecord.day,
        secondaryRecord.magmo3aId,
        secondaryRecord.date,
      );

      if (absenceRecord == null) {
// --- START TAKING ABSENCE LOGIC FOR SECONDARY ---

        List<Future> batchOperations = [];

        for (var student in students) {
          student.countingAbsentDays ??= [];

// Check if this specific secondary day already exists to avoid duplicates

          bool exists = student.countingAbsentDays!.any((d) =>
              d.date == secondaryRecord.date &&
              d.day == secondaryRecord.day &&
              d.time.hour == secondaryRecord.time.hour &&
              d.time.minute == secondaryRecord.time.minute);

          if (!exists) {
// Add the DayRecord with the secondary object populated

            student.countingAbsentDays!.add(DayRecord(
              magmo3aId: secondaryRecord.magmo3aId,

              date: secondaryRecord.date,

              day: secondaryRecord.day,

              time: secondaryRecord.time,
              // Use the secondary time

              secondary: null,
            ));
          }

          batchOperations.add(
            FirebaseFunctions.updateStudentInCollection(
                student.grade ?? "", student.id, student),
          );
        }

// Create the AbsenceModel for this secondary group

        final newAbsenceModel = AbsenceModel(
          numberOfStudents: students.length,
          date: secondaryRecord.date,
          attendStudentIds: [],
          absentStudentIds: students.map((s) => s.id).toList(),
        );

        batchOperations.add(
            FirebaseFunctions.updateAbsenceByDateInSubcollection(
                secondaryRecord.day,
                secondaryRecord.magmo3aId,
                secondaryRecord.date,
                newAbsenceModel));

        await Future.wait(batchOperations);
      } else {
        print("secondary absence record already exists ✅✅");
      }

      emit(AttendanceStarted()); // Or AbsenceFetched
    } catch (e) {
      if (!isClosed) emit(AbsentError('Error fetching secondary students: $e'));
    }
  }

  Future<void> _addManualStudentToPresent(
      {required Studentmodel student, SecondaryRecord? targetSecondary}) async {
    try {
      List<Future> batchOperations = [];

      if (targetSecondary != null) {
        await getSecondaryGroupStudents(
            grade: student.grade ?? "", secondaryRecord: targetSecondary);

        final targetAbsence = await FirebaseFunctions.getAbsenceByDateOnce(
            targetSecondary.day,
            targetSecondary.magmo3aId,
            targetSecondary.date);

        if (targetAbsence != null) {
          if (!targetAbsence.attendStudentIds.contains(student.id))
            targetAbsence.attendStudentIds.add(student.id);

          targetAbsence.absentStudentIds.remove(student.id);

          batchOperations.add(
              FirebaseFunctions.updateAbsenceByDateInSubcollection(
                  targetSecondary.day,
                  targetSecondary.magmo3aId,
                  targetSecondary.date,
                  targetAbsence));
        }

        absentStudents.removeWhere((s) => s.id == student.id);

        student.countingAttendedDays ??= [];

        student.countingAttendedDays!.add(DayRecord(
          magmo3aId: targetSecondary.magmo3aId,
          date: targetSecondary.date,
          day: targetSecondary.day,
          time: targetSecondary.time,
          secondary: SecondaryRecord(
              date: selectedDateStr,
              day: selectedDay,
              magmo3aId: magmo3aModel.id,
              time: magmo3aModel.time),
        ));

        student.countingAbsentDays?.removeWhere((d) =>
            (d.date == selectedDateStr && d.magmo3aId == magmo3aModel.id) ||
            (d.date == targetSecondary.date &&
                d.magmo3aId == targetSecondary.magmo3aId));
      } else {
        await _addBasicAttendance(student, batchOperations);
      }

      await _finalizeAttendanceUpdate(student, batchOperations);
    } catch (e) {
      emit(AbsentError('Manual Attendance Failed: $e'));
    }
  }

// ---------------------------------------------------------

  Future<void> _fetchAbsenceStream() async {
    await _absenceSubscription?.cancel();

    _absenceSubscription = FirebaseFunctions.getAbsenceByDateStream(
      selectedDay,
      magmo3aModel.id,
      selectedDateStr,
    ).listen((absenceRecord) async {
      if (isClosed) return;

      try {
        if (absenceRecord != null) {
          final absentFutures = absenceRecord.absentStudentIds
              .map(
                (id) => FirebaseFunctions.getStudentById(
                    magmo3aModel.grade ?? "", id),
              )
              .toList();

          final attendFutures = absenceRecord.attendStudentIds
              .map(
                (id) => FirebaseFunctions.getStudentById(
                    magmo3aModel.grade ?? "", id),
              )
              .toList();

          final results = await Future.wait([
            Future.wait(absentFutures),
            Future.wait(attendFutures),
          ]);

          if (isClosed) return;

          absentStudents = results[0].whereType<Studentmodel>().toList();

          attendStudents = results[1].whereType<Studentmodel>().toList();

          numberOfStudents = absenceRecord.numberOfStudents;

          _updateFilteredLists();

          isAttendanceStarted = true;

          isFirstLoadDone = true;

          emit(AttendanceStarted());
        } else {
          await _fetchStudentsList();
        }
      } catch (e) {
        isFirstLoadDone = true;

        if (!isClosed) emit(AbsentError('Error: $e'));
      }
    });
  }

  Future<void> _fetchStudentsList() async {
    try {
      final snapshot = await FirebaseFunctions.getStudentsByGroupIdOnce(
        magmo3aModel.grade ?? "",
        magmo3aModel.id,
      );

      if (isClosed) return;

      absentStudents = snapshot.docs.map((doc) => doc.data()).toList();

      _updateFilteredLists();

      numberOfStudents = absentStudents.length;

      isAttendanceStarted = false;

      isFirstLoadDone = true;

      emit(AbsenceFetched());
    } catch (e) {
      isFirstLoadDone = true;

      if (!isClosed) emit(AbsentError("Error fetching students: $e"));
    }
  }

  Future<void> _startTakingAbsence() async {
    try {
      List<Future> batchOperations = [];

      for (var student in absentStudents) {
        student.countingAbsentDays ??= [];

        bool exists = student.countingAbsentDays!
            .any((d) => d.date == selectedDateStr && d.day == selectedDay);

        if (!exists) {
          student.countingAbsentDays!.add(DayRecord(
              date: selectedDateStr,
              magmo3aId: magmo3aModel.id,
              day: selectedDay,
              time: magmo3aModel.time,
              secondary: null));
        }

        batchOperations.add(
          FirebaseFunctions.updateStudentInCollection(
              student.grade ?? "", student.id, student),
        );
      }

      numberOfStudents = absentStudents.length;

      final absenceModel = AbsenceModel(
        numberOfStudents: numberOfStudents ?? 0,
        date: selectedDateStr,
        attendStudentIds: attendStudents.map((s) => s.id).toList(),
        absentStudentIds: absentStudents.map((s) => s.id).toList(),
      );

      batchOperations.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
          selectedDay, magmo3aModel.id, selectedDateStr, absenceModel));

      await Future.wait(batchOperations);

      isAttendanceStarted = true;

      emit(AttendanceStarted());
    } catch (e) {
      emit(AbsentError('Failed to start attendance: $e'));
    }
  }

  Future<void> _addQrStudentToPresent(
      {required Studentmodel student,
      SecondaryRecord? originalSecondary}) async {
    try {
      List<Future> batchOperations = [];

      if (originalSecondary != null) {
        final originalAbsence = await FirebaseFunctions.getAbsenceByDateOnce(
            originalSecondary.day,
            originalSecondary.magmo3aId,
            originalSecondary.date);

        if (originalAbsence != null) {
          originalAbsence.absentStudentIds.remove(student.id);

          batchOperations.add(
              FirebaseFunctions.updateAbsenceByDateInSubcollection(
                  originalSecondary.day,
                  originalSecondary.magmo3aId,
                  originalSecondary.date,
                  originalAbsence));
        }

        if (!attendStudents.any((s) => s.id == student.id))
          attendStudents.add(student);

        student.countingAttendedDays ??= [];

        student.countingAttendedDays!.add(DayRecord(
          magmo3aId: magmo3aModel.id,
          date: selectedDateStr,
          day: selectedDay,
          time: magmo3aModel.time,
          secondary: SecondaryRecord(
              date: originalSecondary.date,
              day: originalSecondary.day,
              magmo3aId: originalSecondary.magmo3aId,
              time: originalSecondary.time),
        ));

        student.countingAbsentDays?.removeWhere((d) =>
            (d.date == selectedDateStr && d.magmo3aId == magmo3aModel.id) ||
            (d.date == originalSecondary.date &&
                d.magmo3aId == originalSecondary.magmo3aId));
      } else {
        await _addBasicAttendance(student, batchOperations);
      }

      await _finalizeAttendanceUpdate(student, batchOperations);
    } catch (e) {
      emit(AbsentError('QR Attendance Failed: $e'));
    }
  }

// --- عملية الاسترجاع (Restore) ---

  Future<void> _restoreStudent({required Studentmodel student}) async {
    try {
      // 1. Find the attendance record for the current session
      DayRecord? attendanceRecord;
      if (student.countingAttendedDays != null) {
        attendanceRecord = student.countingAttendedDays!.firstWhere(
          (r) =>
              (r.magmo3aId == magmo3aModel.id ||
                  r.secondary?.magmo3aId == magmo3aModel.id) &&
              r.date == selectedDateStr,
          orElse: () => throw Exception("Record not found"),
        );
      }

      if (attendanceRecord == null) return;

      List<Future> batchOperations = [];
      final bool isGuest = attendanceRecord.secondary != null;

      // 2. Handle the "Local" state (Current group UI)
      attendStudents.removeWhere((s) => s.id == student.id);

      // 3. Logic for restoring to Absence
      if (!isGuest) {
        // NORMAL CASE: Student belongs to THIS group
        if (!absentStudents.any((s) => s.id == student.id)) {
          absentStudents.add(student);
        }

        // Since it's the current group, we know the record exists
        student.countingAbsentDays?.add(DayRecord(
          magmo3aId: magmo3aModel.id,
          date: selectedDateStr,
          day: selectedDay,
          time: magmo3aModel.time,
          secondary: null,
        ));
      } else {
        // GUEST CASE: Student belongs to a DIFFERENT group (Secondary)
        final homeGroup = attendanceRecord.secondary!;

        // Check if the home group's absence record still exists in Firebase
        final homeAbsenceDoc = await FirebaseFunctions.getAbsenceByDateOnce(
            homeGroup.day, homeGroup.magmo3aId, homeGroup.date);

        if (homeAbsenceDoc != null) {
          // ONLY if the record exists, we update it and add to student history
          if (!homeAbsenceDoc.absentStudentIds.contains(student.id)) {
            homeAbsenceDoc.absentStudentIds.add(student.id);
          }

          batchOperations.add(
              FirebaseFunctions.updateAbsenceByDateInSubcollection(
                  homeGroup.day,
                  homeGroup.magmo3aId,
                  homeGroup.date,
                  homeAbsenceDoc));

          // Add to student history ONLY because the record exists
          student.countingAbsentDays?.add(DayRecord(
            magmo3aId: homeGroup.magmo3aId,
            date: homeGroup.date,
            day: homeGroup.day,
            time: homeGroup.time,
            secondary: null,
          ));
        } else {
          // If homeAbsenceDoc is NULL, the record was deleted.
          // We do NOT add to countingAbsentDays here.
          debugPrint(
              "Skipping history update: Original absence record no longer exists.");
        }
      }

      // 4. Clean up: Remove the attendance record we are restoring from
      student.countingAttendedDays?.remove(attendanceRecord);

      // 5. Update the current group's Absence Doc (to remove them from "Attended")
      final currentAbsDoc = AbsenceModel(
          numberOfStudents: numberOfStudents ?? 0,
          date: selectedDateStr,
          attendStudentIds: attendStudents.map((s) => s.id).toList(),
          absentStudentIds: absentStudents.map((s) => s.id).toList());

      batchOperations.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
          selectedDay, magmo3aModel.id, selectedDateStr, currentAbsDoc));

      // 6. Save the student's modified object
      batchOperations.add(FirebaseFunctions.updateStudentInCollection(
          student.grade ?? "", student.id, student));

      await Future.wait(batchOperations);

      _updateFilteredLists();
      emit(AbsenceFetched());
    } catch (e) {
      emit(AbsentError('Restore Failed: $e'));
    }
  }

// --- Helper Methods ---

  Future<void> _addBasicAttendance(
      Studentmodel student, List<Future> batch) async {
    absentStudents.removeWhere((s) => s.id == student.id);

    if (!attendStudents.any((s) => s.id == student.id))
      attendStudents.add(student);

    student.countingAttendedDays ??= [];

    student.countingAttendedDays!.add(DayRecord(
        magmo3aId: magmo3aModel.id,
        date: selectedDateStr,
        day: selectedDay,
        time: magmo3aModel.time,
        secondary: null));

    student.countingAbsentDays?.removeWhere(
        (d) => d.date == selectedDateStr && d.magmo3aId == magmo3aModel.id);
  }

  Future<void> _finalizeAttendanceUpdate(
      Studentmodel student, List<Future> batch) async {
    final currentAbs = AbsenceModel(
        numberOfStudents: numberOfStudents ?? 0,
        date: selectedDateStr,
        attendStudentIds: attendStudents.map((s) => s.id).toList(),
        absentStudentIds: absentStudents.map((s) => s.id).toList());

    batch.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
        selectedDay, magmo3aModel.id, selectedDateStr, currentAbs));

    batch.add(FirebaseFunctions.updateStudentInCollection(
        student.grade ?? "", student.id, student));

    await Future.wait(batch);

    _updateFilteredLists();

    emit(ScanSuccess(student));
  }

  void _updateFilteredLists() {
    if (searchController.text.isNotEmpty) {
      _searchAbsentStudents(searchController.text);

      searchAttendingStudents(searchController.text);
    } else {
      filteredAbsentStudentsList = List.from(absentStudents);

      filteredAttendStudentsList = List.from(attendStudents);
    }
  }

  void _searchAbsentStudents(String query) {
    filteredAbsentStudentsList = query.isEmpty
        ? List.from(absentStudents)
        : absentStudents
            .where((student) => (student.name ?? '')
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();

    emit(SearchResultsUpdated(filteredAbsentStudentsList));
  }

  void searchAttendingStudents(String query) {
    filteredAttendStudentsList = query.isEmpty
        ? List.from(attendStudents)
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

  Future<void> _scanQrcode(BuildContext context) async {
    MobileScannerController _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    Studentmodel? activeStudent;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BlocProvider.value(
        value: this,
        child: StatefulBuilder(
          builder: (context, setScannerState) {
            return AiBarcodeScanner(
              controller: _scannerController,
              onDispose: () => _scannerController.dispose(),
              // Using the bottomSheetBuilder logic from the first function
              bottomSheetBuilder: (context, controller) {
                if (activeStudent == null) {
                  return Container(
                    height: 100,
                    color: Colors.white,
                    child: const Center(child: Text("يرجى مسح كود الطالب")),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMain,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          // Reset state to scan next student
                          setScannerState(() {
                            activeStudent = null;
                          });
                          _scannerController.start();
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text(
                          "الطالب التالي (فتح الكاميرا)",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Flexible(
                      child: StudentPaymentBottomSheet(
                        student: activeStudent!,
                      ),
                    ),
                  ],
                );
              },
              onDetect: (BarcodeCapture capture) async {
                final scannedValue = capture.barcodes.first.rawValue;
                if (scannedValue == null) return;

                // 1. Check if already attended using AppSnackBars
                if (attendStudents.any((s) => s.id == scannedValue)) {
                  AppSnackBars.showError(context, "⚠️ حاضر بالفعل");
                  return;
                }

                // 2. Pause scanner to focus on the current student
                await _scannerController.stop();

                try {
                  await runWithLoading(context, () async {
                    // Fetch student logic
                    Studentmodel? student = absentStudents
                            .cast<Studentmodel?>()
                            .firstWhere((s) => s?.id == scannedValue,
                                orElse: () => null) ??
                        await FirebaseFunctions.getStudentById(
                            magmo3aModel.grade ?? "", scannedValue);

                    if (student != null) {
                      // 3. Process Attendance
                      if (student.hisGroupsId?.contains(magmo3aModel.id) ==
                          true) {
                        await _addQrStudentToPresent(
                            student: student, originalSecondary: null);
                      } else {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dCtx) => GroupSelectionWhileScanning(
                            currentDate: selectedDateStr,
                            studentGroups: student.hisGroups ?? [],
                            studentName: student.name ?? "",
                            onConfirm: (selectedOriginalGroup) async {
                              await runWithLoading(context, () async {
                                await _addQrStudentToPresent(
                                  student: student,
                                  originalSecondary: selectedOriginalGroup,
                                );
                              });
                            },
                          ),
                        );
                      }

                      // 4. Update UI to show the payment sheet (activeStudent)
                      setScannerState(() {
                        activeStudent = student;
                      });
                    } else {
                      // Student not found logic
                      AppSnackBars.showError(
                          context, "❌ الطالب غير مسجل في السيستم");
                      _scannerController.start();
                    }
                  });
                } catch (e) {
                  debugPrint("❌ Error during scan: $e");
                  _scannerController.start();
                }
              },
            );
          },
        ),
      ),
    ));
  }

  @override
  Future<void> close() {
    _absenceSubscription?.cancel();
    searchController.dispose();
    return super.close();
  }
}
