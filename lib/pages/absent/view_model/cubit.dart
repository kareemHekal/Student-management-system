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
  StreamSubscription? _absenceSubscription;

  // ✅ متغير جديد للتحكم في الحالة الأولية ومنع ظهور الزر قبل البيانات
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
          filteredAbsentStudentsList = List.from(absentStudents);
          filteredAttendStudentsList = List.from(attendStudents);
          isAttendanceStarted = true;

          // ✅ تم تحميل البيانات بنجاح
          isFirstLoadDone = true;
          emit(AttendanceStarted());
        } else {
          await _fetchStudentsList();
        }
      } catch (e) {
        isFirstLoadDone = true; // نغلق حالة الانتظار حتى لو حدث خطأ
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
      filteredAbsentStudentsList = List.from(absentStudents);
      numberOfStudents = absentStudents.length;
      isAttendanceStarted = false;

      // ✅ تم تحميل البيانات (يوم جديد)
      isFirstLoadDone = true;
      emit(AbsenceFetched());
    } catch (e) {
      isFirstLoadDone = true;
      if (!isClosed) emit(AbsentError("Error fetching students: $e"));
    }
  }

  // --- بقية الدوال كما هي (StartTakingAttendance, Scan, Search, etc.) ---
  // ... (نفس الكود الأصلي الذي أرفقته أنت في الـ Cubit)

  Future<void> _startTakingAbsence() async {
    try {
      List<Future> batchOperations = [];
      for (var student in absentStudents) {
        student.countingAbsentDays ??= [];
        bool exists = student.countingAbsentDays!
            .any((d) => d.date == selectedDateStr && d.day == selectedDay);
        if (!exists) {
          student.countingAbsentDays!
              .add(DayRecord(date: selectedDateStr, day: selectedDay));
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

  Future<void> _addStudentToPresent(
      Studentmodel student, String realStudentId) async {
    if (attendStudents.any((s) => s.id == student.id)) {
      emit(AbsentError('⚠️ تم تسجيل حضوره من قبل.'));
      return;
    }
    try {
      attendStudents.add(student);
      absentStudents.removeWhere((s) => s.id == student.id);
      _updateFilteredLists();
      emit(AbsenceFetched());

      student.countingAttendedDays ??= [];
      student.countingAttendedDays!
          .add(DayRecord(date: selectedDateStr, day: selectedDay));
      student.countingAbsentDays?.removeWhere((dayRecord) =>
          dayRecord.date == selectedDateStr && dayRecord.day == selectedDay);

      final absenceModel = AbsenceModel(
        numberOfStudents: numberOfStudents ?? 0,
        date: selectedDateStr,
        attendStudentIds: attendStudents.map((s) => s.id).toList(),
        absentStudentIds: absentStudents.map((s) => s.id).toList(),
      );

      await Future.wait([
        FirebaseFunctions.updateStudentInCollection(
            magmo3aModel.grade ?? "", realStudentId, student),
        FirebaseFunctions.updateAbsenceByDateInSubcollection(
            selectedDay, magmo3aModel.id, selectedDateStr, absenceModel),
      ]);
      isAttendanceStarted = true;
      emit(ScanSuccess(student));
    } catch (e) {
      attendStudents.removeWhere((s) => s.id == student.id);
      absentStudents.add(student);
      emit(AbsentError('❌ فشل في تحديث الحضور: $e'));
    }
  }

  Future<void> _restoreStudent(Studentmodel student) async {
    try {
      attendStudents.removeWhere((s) => s.id == student.id);
      absentStudents.add(student);
      _updateFilteredLists();
      emit(AbsenceFetched());

      student.countingAbsentDays ??= [];
      student.countingAbsentDays!
          .add(DayRecord(date: selectedDateStr, day: selectedDay));
      student.countingAttendedDays?.removeWhere(
          (d) => d.date == selectedDateStr && d.day == selectedDay);

      final absenceModel = AbsenceModel(
        date: selectedDateStr,
        numberOfStudents: numberOfStudents ?? 0,
        attendStudentIds: attendStudents.map((s) => s.id).toList(),
        absentStudentIds: absentStudents.map((s) => s.id).toList(),
      );

      await Future.wait([
        FirebaseFunctions.updateStudentInCollection(
            magmo3aModel.grade ?? "", student.id, student),
        FirebaseFunctions.updateAbsenceByDateInSubcollection(
            selectedDay, magmo3aModel.id, selectedDateStr, absenceModel)
      ]);
      refreshAbsentFilteredList();
    } catch (e) {
      emit(AbsentError('Error restoring student: $e'));
    }
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
    MobileScannerController _scannerController =
        MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
    ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => BlocProvider.value(
            value: this,
            child: AiBarcodeScanner(
              onDispose: () => debugPrint("Scanner disposed"),
              hideGalleryButton: false,
              controller: _scannerController,
              onDetect: (BarcodeCapture capture) async {
                _scannerController.stop();
                await runWithLoading(context, () async {
                  final scannedValue = capture.barcodes.first.rawValue;
                  if (scannedValue == null) return;
                  scaffoldMessenger.clearSnackBars();
                  Studentmodel? student = [...absentStudents, ...attendStudents]
                      .cast<Studentmodel?>()
                      .firstWhere((s) => s!.id == scannedValue,
                          orElse: () => null);
                  if (student == null) {
                    student = await FirebaseFunctions.getStudentById(
                        magmo3aModel.grade ?? "", scannedValue);
                  }
                  if (student != null &&
                      student.hisGroupsId?.contains(magmo3aModel.id) == true) {
                    await _addStudentToPresent(student, scannedValue);
                  } else {
                    scaffoldMessenger.showSnackBar(SnackBar(
                        content: Text(student == null
                            ? "لم يتم العثور على الطالب!"
                            : "الطالب ليس ضمن هذه المجموعة!"),
                        backgroundColor: Colors.red));
                  }
                });
                _scannerController.start();
              },
            ))));
  }

  @override
  Future<void> close() {
    _absenceSubscription?.cancel();
    searchController.dispose();
    return super.close();
  }
}