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
        // التمييز بين التحضير "هنا" أو "هناك" يدوياً
        if (i.secondaryRecord != null) {
          await _processAttendanceThere(
              student: i.student, targetSecondary: i.secondaryRecord!);
        } else {
          await _processAttendanceHere(student: i.student);
        }
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
  /// 1️⃣ التحضير "هنا" (QR أو يدوي للمجموعة الحالية)
  /// ---------------------------------------------------------
  Future<void> _processAttendanceHere({
    required Studentmodel student,
    SecondaryRecord? originalHomeGroup,
  }) async {
    try {
      List<Future> batch = [];
      student.countingAttendedDays ??= [];
      student.countingAbsentDays ??= [];

      // 🔥 FIX 1: Safety Check
      // If the "Original Home" is actually "This Group", then he is NOT a visitor.
      // Force secondary to null so we don't save redundant data.
      if (originalHomeGroup?.magmo3aId == magmo3aModel.id) {
        originalHomeGroup = null;
      }

      // 1. Clean previous records for TODAY in THIS GROUP
      student.countingAttendedDays!.removeWhere(
          (r) => r.date == selectedDateStr && r.magmo3aId == magmo3aModel.id);
      student.countingAbsentDays!.removeWhere(
          (r) => r.date == selectedDateStr && r.magmo3aId == magmo3aModel.id);

      // 2. Handle Visitor Logic (Only if originalHomeGroup is DIFFERENT)
      if (originalHomeGroup != null) {
        // Logic to remove absence from the OTHER group because he attended HERE
        await getSecondaryGroupStudents(
            grade: student.grade ?? "", secondaryRecord: originalHomeGroup);
        final homeAbs = await FirebaseFunctions.getAbsenceByDateOnce(
            originalHomeGroup.day,
            originalHomeGroup.magmo3aId,
            originalHomeGroup.date);

        if (homeAbs != null) {
          homeAbs.absentStudentIds.remove(student.id);
          batch.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
              originalHomeGroup.day,
              originalHomeGroup.magmo3aId,
              originalHomeGroup.date,
              homeAbs));
        }

        // Remove any "Absent" record for his home group from his profile
        student.countingAbsentDays!.removeWhere((r) =>
            r.date == originalHomeGroup!.date &&
            r.magmo3aId == originalHomeGroup.magmo3aId);
      }

      // 3. Add DayRecord
      student.countingAttendedDays!.add(DayRecord(
        magmo3aId: magmo3aModel.id,
        // Attended HERE
        date: selectedDateStr,
        day: selectedDay,
        time: magmo3aModel.time,
        secondary:
            originalHomeGroup, // Will be NULL if he belongs here, populated if he is a visitor
      ));

      // 4. Update UI Lists
      if (!attendStudents.any((s) => s.id == student.id))
        attendStudents.add(student);
      absentStudents.removeWhere((s) => s.id == student.id);

      await _finalizeUpdate(student, batch);
    } catch (e) {
      emit(AbsentError('Attendance Failed: $e'));
    }
  }

  /// ---------------------------------------------------------
  /// 2️⃣ التحضير "هناك" (يدوي لمجموعة الطالب الأصلية)
  /// ---------------------------------------------------------
  Future<void> _processAttendanceThere({
    required Studentmodel student,
    required SecondaryRecord targetSecondary,
  }) async {
    try {
      List<Future> batch = [];
      student.countingAttendedDays ??= [];
      student.countingAbsentDays ??= [];

      // 1. Fetch Remote Group data
      await getSecondaryGroupStudents(
          grade: student.grade ?? "", secondaryRecord: targetSecondary);
      final remoteAbs = await FirebaseFunctions.getAbsenceByDateOnce(
          targetSecondary.day, targetSecondary.magmo3aId, targetSecondary.date);

      // 2. Remove him from Absent list THERE and add to Attend list THERE
      if (remoteAbs != null) {
        if (!remoteAbs.attendStudentIds.contains(student.id))
          remoteAbs.attendStudentIds.add(student.id);
        remoteAbs.absentStudentIds.remove(student.id);
        batch.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
            targetSecondary.day,
            targetSecondary.magmo3aId,
            targetSecondary.date,
            remoteAbs));
      }

      // 3. Remove Absence records from local profile
      // We remove absence from Current Group (because we processed him) AND Target Group (because he attended)
      student.countingAbsentDays?.removeWhere((d) =>
          (d.date == selectedDateStr && d.magmo3aId == magmo3aModel.id) ||
          (d.date == targetSecondary.date &&
              d.magmo3aId == targetSecondary.magmo3aId));

      // 4. Add DayRecord
      // 🔥 FIX 2: Do NOT set 'secondary'.
      // He is attending his HOME group (targetSecondary). He is not a visitor.
      student.countingAttendedDays!.add(DayRecord(
        magmo3aId: targetSecondary.magmo3aId,
        // The ID of the group he attended
        date: targetSecondary.date,
        day: targetSecondary.day,
        time: targetSecondary.time,
        secondary: null,
      ));

      // 5. Update UI
      // He is removed from "Absent" list locally, but NOT added to "Attend" locally
      // because he physically attended elsewhere.
      absentStudents.removeWhere((s) => s.id == student.id);

      await _finalizeUpdate(student, batch);
    } catch (e) {
      emit(AbsentError('Manual Remote Attendance Failed: $e'));
    }
  }

  /// ---------------------------------------------------------
  /// 🔄 دالة الاسترجاع (Undo/Restore)
  /// ---------------------------------------------------------
  Future<void> _restoreStudent({required Studentmodel student}) async {
    try {
      // البحث عن السجل المرتبط باليوم الحالي (سواء كان محضراً هنا أو محولاً لهناك)
      final recordIndex = student.countingAttendedDays?.indexWhere((r) {
            bool isDirect =
                (r.magmo3aId == magmo3aModel.id && r.date == selectedDateStr);
            bool isRemote = (r.secondary?.magmo3aId == magmo3aModel.id &&
                r.secondary?.date == selectedDateStr);
            return isDirect || isRemote;
          }) ??
          -1;

      if (recordIndex == -1) return;
      final record = student.countingAttendedDays![recordIndex];
      List<Future> batch = [];

      // الحالة أ: الطالب حضر فعلياً في مجموعة الكيوبت (مباشر أو ضيف QR)
      if (record.magmo3aId == magmo3aModel.id) {
        if (record.secondary != null) {
          // كان ضيف QR
          final sec = record.secondary!;
          final homeAbs = await FirebaseFunctions.getAbsenceByDateOnce(
              sec.day, sec.magmo3aId, sec.date);
          if (homeAbs != null) {
            homeAbs.absentStudentIds.add(student.id);
            batch.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
                sec.day, sec.magmo3aId, sec.date, homeAbs));
          }
          student.countingAbsentDays?.add(DayRecord(
              magmo3aId: sec.magmo3aId,
              date: sec.date,
              day: sec.day,
              time: sec.time));
        } else {
          // كان طالب أساسي حضر هنا
          if (!absentStudents.any((s) => s.id == student.id))
            absentStudents.add(student);
          student.countingAbsentDays?.add(DayRecord(
              magmo3aId: magmo3aModel.id,
              date: selectedDateStr,
              day: selectedDay,
              time: magmo3aModel.time));
        }
        attendStudents.removeWhere((s) => s.id == student.id);
      }
      // الحالة ب: تم تحضيره يدوياً في مجموعته الأصلية (عن بُعد)
      else if (record.secondary?.magmo3aId == magmo3aModel.id) {
        final remoteAbs = await FirebaseFunctions.getAbsenceByDateOnce(
            record.day, record.magmo3aId, record.date);
        if (remoteAbs != null) {
          remoteAbs.attendStudentIds.remove(student.id);
          remoteAbs.absentStudentIds.add(student.id); // نرجعه غايب هناك
          batch.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
              record.day, record.magmo3aId, record.date, remoteAbs));
        }
        // نرجعه غايب هنا أيضاً في مجموعة الكيوبت
        if (!absentStudents.any((s) => s.id == student.id))
          absentStudents.add(student);
        student.countingAbsentDays?.add(DayRecord(
            magmo3aId: magmo3aModel.id,
            date: selectedDateStr,
            day: selectedDay,
            time: magmo3aModel.time));
      }

      student.countingAttendedDays!.removeAt(recordIndex);
      await _finalizeUpdate(student, batch);
      emit(AbsenceFetched());
    } catch (e) {
      emit(AbsentError('Restore Failed: $e'));
    }
  }

  // --- دوال مساعدة ---

  Future<void> _finalizeUpdate(Studentmodel student, List<Future> batch) async {
    final currentAbs = AbsenceModel(
      numberOfStudents: numberOfStudents ?? 0,
      date: selectedDateStr,
      attendStudentIds: attendStudents.map((s) => s.id).toList(),
      absentStudentIds: absentStudents.map((s) => s.id).toList(),
    );
    batch.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
        selectedDay, magmo3aModel.id, selectedDateStr, currentAbs));
    batch.add(FirebaseFunctions.updateStudentInCollection(
        student.grade ?? "", student.id, student));
    await Future.wait(batch);
    _updateFilteredLists();
    emit(ScanSuccess(student));
  }

  Future<void> getSecondaryGroupStudents(
      {required String grade, required SecondaryRecord secondaryRecord}) async {
    try {
      final absenceRecord = await FirebaseFunctions.getAbsenceByDateOnce(
          secondaryRecord.day, secondaryRecord.magmo3aId, secondaryRecord.date);
      if (absenceRecord == null) {
        final snapshot = await FirebaseFunctions.getStudentsByGroupIdOnce(
            grade, secondaryRecord.magmo3aId);
        List<Studentmodel> students =
            snapshot.docs.map((doc) => doc.data()).toList();
        List<Future> batch = [];
        for (var s in students) {
          s.countingAbsentDays ??= [];
          if (!s.countingAbsentDays!.any((d) =>
              d.date == secondaryRecord.date &&
              d.magmo3aId == secondaryRecord.magmo3aId)) {
            s.countingAbsentDays!.add(DayRecord(
                magmo3aId: secondaryRecord.magmo3aId,
                date: secondaryRecord.date,
                day: secondaryRecord.day,
                time: secondaryRecord.time));
            batch.add(
                FirebaseFunctions.updateStudentInCollection(grade, s.id, s));
          }
        }
        final model = AbsenceModel(
            numberOfStudents: students.length,
            date: secondaryRecord.date,
            attendStudentIds: [],
            absentStudentIds: students.map((s) => s.id).toList());
        batch.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
            secondaryRecord.day,
            secondaryRecord.magmo3aId,
            secondaryRecord.date,
            model));
        await Future.wait(batch);
      }
    } catch (e) {
      debugPrint("Error initializing secondary group: $e");
    }
  }

  // --- Streams & UI ---

  Future<void> _fetchAbsenceStream() async {
    await _absenceSubscription?.cancel();
    _absenceSubscription = FirebaseFunctions.getAbsenceByDateStream(
            selectedDay, magmo3aModel.id, selectedDateStr)
        .listen((absenceRecord) async {
      if (isClosed) return;
      if (absenceRecord != null) {
        final results = await Future.wait([
          Future.wait(absenceRecord.absentStudentIds.map((id) =>
              FirebaseFunctions.getStudentById(magmo3aModel.grade ?? "", id))),
          Future.wait(absenceRecord.attendStudentIds.map((id) =>
              FirebaseFunctions.getStudentById(magmo3aModel.grade ?? "", id))),
        ]);
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
    });
  }

  Future<void> _fetchStudentsList() async {
    final snapshot = await FirebaseFunctions.getStudentsByGroupIdOnce(
        magmo3aModel.grade ?? "", magmo3aModel.id);
    absentStudents = snapshot.docs.map((doc) => doc.data()).toList();
    _updateFilteredLists();
    numberOfStudents = absentStudents.length;
    isAttendanceStarted = false;
    isFirstLoadDone = true;
    emit(AbsenceFetched());
  }

  Future<void> _startTakingAbsence() async {
    List<Future> batch = [];
    for (var s in absentStudents) {
      s.countingAbsentDays ??= [];
      if (!s.countingAbsentDays!.any(
          (d) => d.date == selectedDateStr && d.magmo3aId == magmo3aModel.id)) {
        s.countingAbsentDays!.add(DayRecord(
            date: selectedDateStr,
            magmo3aId: magmo3aModel.id,
            day: selectedDay,
            time: magmo3aModel.time));
        batch.add(FirebaseFunctions.updateStudentInCollection(
            s.grade ?? "", s.id, s));
      }
    }
    final model = AbsenceModel(
        numberOfStudents: absentStudents.length,
        date: selectedDateStr,
        attendStudentIds: [],
        absentStudentIds: absentStudents.map((s) => s.id).toList());
    batch.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
        selectedDay, magmo3aModel.id, selectedDateStr, model));
    await Future.wait(batch);
    isAttendanceStarted = true;
    emit(AttendanceStarted());
  }

  void _updateFilteredLists() {
    _searchAbsentStudents(searchController.text);
    searchAttendingStudents(searchController.text);
  }

  void _searchAbsentStudents(String query) {
    filteredAbsentStudentsList = query.isEmpty
        ? List.from(absentStudents)
        : absentStudents
            .where((s) =>
                (s.name ?? '').toLowerCase().contains(query.toLowerCase()))
            .toList();
    emit(SearchResultsUpdated(filteredAbsentStudentsList));
  }

  void searchAttendingStudents(String query) {
    filteredAttendStudentsList = query.isEmpty
        ? List.from(attendStudents)
        : attendStudents
            .where((s) =>
                (s.name ?? '').toLowerCase().contains(query.toLowerCase()))
            .toList();
    emit(SearchResultsUpdated(filteredAttendStudentsList));
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
              bottomSheetBuilder: (context, controller) {
                if (activeStudent == null) {
                  return Container(
                    height: 100,
                    color: Colors.white,
                    child: const Center(child: Text("يرجى مسح كود الطالب")),
                  );
                }

                // Wrap your payment sheet with a Column to add the "Next" button
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                        child:
                            StudentPaymentBottomSheet(student: activeStudent!)),
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
                          // Restart scanner and clear active student
                          setScannerState(() {
                            activeStudent = null;
                          });
                          _scannerController.start();
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("الطالب التالي (فتح الكاميرا)",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              },
              onDetect: (BarcodeCapture capture) async {
                final scannedValue = capture.barcodes.first.rawValue;
                if (scannedValue == null) return;

                // 1. Check if already attended
                if (attendStudents.any((s) => s.id == scannedValue)) {
                  AppSnackBars.showError(context, "⚠️ حاضر بالفعل");
                  return;
                }

                // 2. Pause scanner immediately to focus on this student
                await _scannerController.stop();

                await runWithLoading(context, () async {
                  // Fetch student
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
                      await _processAttendanceHere(student: student);
                    } else {
                      await showDialog(
                        context: context,
                        builder: (dCtx) => GroupSelectionWhileScanning(
                          currentDate: selectedDateStr,
                          studentGroups: student.hisGroups ?? [],
                          studentName: student.name ?? "",
                          onConfirm: (home) => _processAttendanceHere(
                              student: student, originalHomeGroup: home),
                        ),
                      );
                    }

                    // 4. Update UI to show payment sheet
                    setScannerState(() {
                      activeStudent = student;
                    });
                  } else {
                    // If student not found, restart camera so user can try again
                    AppSnackBars.showError(context, "الطالب غير موجود");
                    _scannerController.start();
                  }
                });
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