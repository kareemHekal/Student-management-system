import 'dart:async';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Map<String, Studentmodel> _studentsCache = {};
  StreamSubscription? _absenceSubscription;

  bool isFirstLoadDone = false;
  bool _isProcessingAttendance = false;

  Future<void> handleIntent(AbsentIntent intent) async {
    if (isClosed) return;

    switch (intent.runtimeType) {
      case FetchAbsence:
        if (!isFirstLoadDone || _absenceSubscription == null) {
          await _fetchAbsenceStream();
        }
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

        final batch = FirebaseFirestore.instance.batch();

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
              secondary: null,
            ));
          }

          final studentRef = FirebaseFirestore.instance
              .doc(FirebaseFunctions.teacherPath)
              .collection(student.grade ?? "")
              .doc(student.id);
          batch.update(studentRef, student.toJson());
        }

// Create the AbsenceModel for this secondary group

        final newAbsenceModel = AbsenceModel(
          numberOfStudents: students.length,
          date: secondaryRecord.date,
          attendStudentIds: [],
          absentStudentIds: students.map((s) => s.id).toList(),
        );

        final absenceRef = FirebaseFirestore.instance
            .doc(FirebaseFunctions.teacherPath)
            .collection(secondaryRecord.day)
            .doc(secondaryRecord.magmo3aId)
            .collection('absences')
            .doc(secondaryRecord.date);
        batch.set(absenceRef, newAbsenceModel.toJson(), SetOptions(merge: true));

        await batch.commit();
      } else {
        print("secondary absence record already exists ✅✅");
      }

      emit(AttendanceStarted()); // Or AbsenceFetched
    } catch (e) {
      if (!isClosed) emit(AbsentError('Error fetching secondary students: $e'));
    }
  }

// ---------------------------------------------------------

  Future<void> _fetchAbsenceStream() async {
    await _absenceSubscription?.cancel();

    // أولاً: حمل كل طلبة المجموعة "مرة واحدة" وخزنهم في الـ Cache
    // ده بيخلي الـ Stream سريع جداً لأنه بيتعامل مع IDs بس
    try {
      final allStudentsSnapshot =
          await FirebaseFunctions.getStudentsByGroupIdOnce(
        magmo3aModel.grade ?? "",
        magmo3aModel.id,
      );
      for (var doc in allStudentsSnapshot.docs) {
        _studentsCache[doc.id] = doc.data();
      }
    } catch (e) {
      debugPrint("Cache Error: $e");
    }

    _absenceSubscription = FirebaseFunctions.getAbsenceByDateStream(
      selectedDay,
      magmo3aModel.id,
      selectedDateStr,
    ).listen((absenceRecord) async {
      if (isClosed) return;

      if (absenceRecord != null) {
        // بدلاً من Future.wait وطلبات DB، استخدم الـ Cache فوراً
        // ولو طالب مش موجود في الكاش (زي طالب جاي من مجموعة تانية) اطلبه لوحده

        List<Studentmodel> tempAbsent = [];
        List<Studentmodel> tempAttend = [];

        for (var id in absenceRecord.absentStudentIds) {
          if (_studentsCache.containsKey(id)) {
            tempAbsent.add(_studentsCache[id]!);
          } else {
            // طالب غريب (Guest) مش في المجموعة دي أصلاً
            final s = await FirebaseFunctions.getStudentById(
                magmo3aModel.grade ?? "", id);
            if (s != null) {
              _studentsCache[id] = s;
              tempAbsent.add(s);
            }
          }
        }

        for (var id in absenceRecord.attendStudentIds) {
          if (_studentsCache.containsKey(id)) {
            tempAttend.add(_studentsCache[id]!);
          } else {
            final s = await FirebaseFunctions.getStudentById(
                magmo3aModel.grade ?? "", id);
            if (s != null) {
              _studentsCache[id] = s;
              tempAttend.add(s);
            }
          }
        }

        absentStudents = tempAbsent;
        attendStudents = tempAttend;
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
    try {
      final snapshot = await FirebaseFunctions.getStudentsByGroupIdOnce(
        magmo3aModel.grade ?? "",
        magmo3aModel.id,
      );

      if (isClosed) return;

      absentStudents = snapshot.docs.map((doc) => doc.data()).toList();

      for (var student in absentStudents) {
        _studentsCache[student.id] = student;
      }
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
      final batch = FirebaseFirestore.instance.batch();

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
          _studentsCache[student.id] = student;
        }

        final studentRef = FirebaseFirestore.instance
            .doc(FirebaseFunctions.teacherPath)
            .collection(student.grade ?? "")
            .doc(student.id);
        batch.update(studentRef, student.toJson());
      }

      numberOfStudents = absentStudents.length;

      final absenceModel = AbsenceModel(
        numberOfStudents: numberOfStudents ?? 0,
        date: selectedDateStr,
        attendStudentIds: attendStudents.map((s) => s.id).toList(),
        absentStudentIds: absentStudents.map((s) => s.id).toList(),
      );

      final absenceRef = FirebaseFirestore.instance
          .doc(FirebaseFunctions.teacherPath)
          .collection(selectedDay)
          .doc(magmo3aModel.id)
          .collection('absences')
          .doc(selectedDateStr);
      batch.set(absenceRef, absenceModel.toJson(), SetOptions(merge: true));

      await batch.commit();

      isAttendanceStarted = true;

      emit(AttendanceStarted());
    } catch (e) {
      emit(AbsentError('Failed to start attendance: $e'));
    }
  }

  Future<void> _scanQrcode(BuildContext context) async {
    MobileScannerController _scannerController =
        MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
    Studentmodel? activeStudent;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BlocProvider.value(
        value: this,
        child: StatefulBuilder(
          builder: (context, setScannerState) {
            return AiBarcodeScanner(
              controller: _scannerController,
              onDispose: () => _scannerController.dispose(),
              bottomSheetBuilder: (context, controller) {
                if (activeStudent == null)
                  return Container(
                      height: 100,
                      color: Colors.white,
                      child: const Center(child: Text("يرجى مسح كود الطالب")));
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
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () {
                          setScannerState(() => activeStudent = null);
                          _scannerController.start();
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("الطالب التالي (فتح الكاميرا)",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Flexible(
                        child:
                            StudentPaymentBottomSheet(student: activeStudent!)),
                  ],
                );
              },
              onDetect: (BarcodeCapture capture) async {
                if (_isProcessingAttendance) return;
                final scannedValue = capture.barcodes.first.rawValue;
                if (scannedValue == null) return;

                // فحص الحضور المسبق
                if (attendStudents.any((s) => s.id == scannedValue)) {
                  AppSnackBars.showError(context, "⚠️ حاضر بالفعل");
                  return;
                }

                try {
                  _isProcessingAttendance = true;
                  await _scannerController
                      .stop(); // وقف الكاميرا مؤقتاً عشان ميسحبش كود تاني والديالوج مفتوح

                  await runWithLoading(context, () async {
                    // 1. البحث عن الطالب
                    Studentmodel? student = absentStudents
                        .cast<Studentmodel?>()
                        .firstWhere((s) => s?.id == scannedValue,
                            orElse: () => null);

                    student ??= await FirebaseFunctions.getStudentById(
                        magmo3aModel.grade ?? "", scannedValue);

                    if (student != null) {
                      // 2. طالب من المجموعة الأساسية
                      if (student.hisGroupsId?.contains(magmo3aModel.id) ==
                          true) {
                        await _addQrStudentToPresent(
                            student: student, originalSecondary: null);
                        setScannerState(() => activeStudent = student);
                      }
                      // 3. طالب ضيف (Guest)
                      else {
                        // *** التعديل هنا: مش هنعمل Navigator.pop(context) ***
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dCtx) => GroupSelectionWhileScanning(
                            currentDate: selectedDateStr,
                            studentGroups: student!.hisGroups ?? [],
                            studentName: student.name ?? "",
                            onConfirm: (selectedOriginalGroup) async {
                              await runWithLoading(dCtx, () async {
                                await _addQrStudentToPresent(
                                    student: student!,
                                    originalSecondary: selectedOriginalGroup);
                              });

                              // 3. نحدث الحالة عشان الـ BottomSheet يظهر والصفحة تفضل ثابتة
                              setScannerState(() {
                                activeStudent = student;
                              });
                            },
                          ),
                        );
                        // لو قفل الديالوج من غير ما يختار (لو ضفت زر إلغاء مثلاً)
                        if (activeStudent == null) _scannerController.start();
                      }
                    } else {
                      AppSnackBars.showError(context, "❌ الطالب غير مسجل");
                      _scannerController.start();
                    }
                  });
                } catch (e) {
                  debugPrint("QR scan error: $e");
                  if (context.mounted) {
                    AppSnackBars.showError(context, "حدث خطأ أثناء تسجيل الحضور");
                  }
                  _scannerController.start();
                } finally {
                  _isProcessingAttendance = false;
                }
              },
            );
          },
        ),
      ),
    ));
  }

  Future<void> _addQrStudentToPresent(
      {required Studentmodel student,
      SecondaryRecord? originalSecondary}) async {
    try {
      AbsenceModel? originalAbsenceToUpdate;

      if (originalSecondary != null) {
        // 1. تحديث المجموعة الأصلية (السيرفر)
        final originalAbsence = await FirebaseFunctions.getAbsenceByDateOnce(
            originalSecondary.day,
            originalSecondary.magmo3aId,
            originalSecondary.date);

        if (originalAbsence != null) {
          originalAbsence.absentStudentIds.remove(student.id);
          // نضمن إنه ميتكررش في الحضور هناك
          if (!originalAbsence.attendStudentIds.contains(student.id)) {
            // ملحوظة: عادة في الـ QR Guest بنشيله من غياب مجموعته بس،
            // لكن لو عايز تسجله حاضر هناك كمان (حسب نظامك) ضيفها هنا.
          }
          originalAbsenceToUpdate = originalAbsence;
        }

        // 2. تحديث سجل الطالب (محلياً)
        student.countingAttendedDays ??= [];
        bool isAlreadyAttended = student.countingAttendedDays!.any(
            (r) => r.magmo3aId == magmo3aModel.id && r.date == selectedDateStr);

        if (!isAlreadyAttended) {
          student.countingAttendedDays!.add(DayRecord(
            magmo3aId: magmo3aModel.id,
            date: selectedDateStr,
            day: selectedDay,
            time: magmo3aModel.time,
            secondary: originalSecondary,
          ));
        }

        // حذف أي سجل غياب للطالب مرتبط بالحصة دي
        student.countingAbsentDays?.removeWhere((d) =>
            d.magmo3aId == originalSecondary.magmo3aId &&
            d.date == originalSecondary.date);

        // 3. تحديث القوائم الحالية في الـ Cubit
        absentStudents.removeWhere((s) => s.id == student.id);
        if (!attendStudents.any((s) => s.id == student.id))
          attendStudents.add(student);
      } else {
        // حضور أساسي
        await _addBasicAttendance(student);
      }

      await _finalizeAttendanceUpdate(student,
          otherGroupAbs: originalAbsenceToUpdate,
          otherGroupInfo: originalSecondary);
    } catch (e) {
      emit(AbsentError('فشل حضور الـ QR: $e'));
    }
  }

  Future<void> _addBasicAttendance(Studentmodel student) async {
    absentStudents.removeWhere((s) => s.id == student.id);
    if (!attendStudents.any((s) => s.id == student.id))
      attendStudents.add(student);

    student.countingAttendedDays ??= [];
    if (!student.countingAttendedDays!.any(
        (r) => r.magmo3aId == magmo3aModel.id && r.date == selectedDateStr)) {
      student.countingAttendedDays!.add(DayRecord(
        magmo3aId: magmo3aModel.id,
        date: selectedDateStr,
        day: selectedDay,
        time: magmo3aModel.time,
        secondary: null,
      ));
    }
    student.countingAbsentDays?.removeWhere(
        (d) => d.magmo3aId == magmo3aModel.id && d.date == selectedDateStr);
  }

  Future<void> _addManualStudentToPresent(
      {required Studentmodel student, SecondaryRecord? targetSecondary}) async {
    if (_isProcessingAttendance) return;
    try {
      _isProcessingAttendance = true;
      AbsenceModel? targetAbsenceToUpdate;

      if (targetSecondary != null) {
        final String targetGrade = student.grade ?? magmo3aModel.grade ?? "";

        // 1. محاولة جلب سجل المجموعة المستهدفة
        var targetAbsence = await FirebaseFunctions.getAbsenceByDateOnce(
            targetSecondary.day,
            targetSecondary.magmo3aId,
            targetSecondary.date);

        // 2. السيناريو الأول: السجل غير موجود (يجب إنشاؤه)
        if (targetAbsence == null) {
          debugPrint("⚠️ Target absence record not found. Creating new one...");

          // أ. جلب كل طلاب المجموعة المستهدفة
          final snapshot = await FirebaseFunctions.getStudentsByGroupIdOnce(
              targetGrade, targetSecondary.magmo3aId);
          final allTargetStudents =
              snapshot.docs.map((doc) => doc.data()).toList();

          // ب. تجهيز قوائم الحضور والغياب للسجل الجديد
          List<String> newAbsentIds = [];
          List<String> newAttendIds = [student.id]; // الطالب بتاعنا حاضر

          // ج. تجهيز باتش لإنشاء غياب لباقي الطلاب
          var creationBatch = FirebaseFirestore.instance.batch();

          for (var otherStudent in allTargetStudents) {
            // تخطي الطالب الحالي (لأنه حاضر، ولأننا سنحدثه في نهاية الدالة)
            if (otherStudent.id == student.id) continue;

            otherStudent.countingAbsentDays ??= [];

            // التأكد من عدم التكرار
            bool exists = otherStudent.countingAbsentDays!.any((d) =>
                d.date == targetSecondary.date &&
                d.magmo3aId == targetSecondary.magmo3aId);

            if (!exists) {
              otherStudent.countingAbsentDays!.add(DayRecord(
                magmo3aId: targetSecondary.magmo3aId,
                date: targetSecondary.date,
                day: targetSecondary.day,
                time: targetSecondary.time,
                secondary: null, // غياب طبيعي في مجموعتهم
              ));

              // إضافة للباتش
              final otherRef = FirebaseFirestore.instance.doc(
                  '${FirebaseFunctions.teacherPath}/$targetGrade/${otherStudent.id}');
              creationBatch.update(otherRef, otherStudent.toJson());
            }
            newAbsentIds.add(otherStudent.id);
          }

          // د. إنشاء موديل الغياب الجديد
          final newAbsenceModel = AbsenceModel(
            numberOfStudents: allTargetStudents.length,
            date: targetSecondary.date,
            attendStudentIds: newAttendIds,
            absentStudentIds: newAbsentIds,
          );

          // هـ. حفظ السجل الجديد في الداتابيز
          final targetDocRef = FirebaseFirestore.instance.doc(
              '${FirebaseFunctions.teacherPath}/${targetSecondary.day}/${targetSecondary.magmo3aId}/absences/${targetSecondary.date}');
          creationBatch.set(targetDocRef, newAbsenceModel.toJson());

          await creationBatch.commit();

          // تعيين السجل للتحديث اللاحق (لضمان التناسق)
          targetAbsenceToUpdate = newAbsenceModel;
        } else {
          // 3. السيناريو الثاني: السجل موجود بالفعل
          if (!targetAbsence.attendStudentIds.contains(student.id)) {
            targetAbsence.attendStudentIds.add(student.id);
          }
          targetAbsence.absentStudentIds.remove(student.id);
          targetAbsenceToUpdate = targetAbsence;

          // ملحوظة: هنا مش محتاجين نعمل commit للسجل لسه، ممكن نضيفه للباتش النهائي بتاع الدالة الأصلية
          // أو لو الدالة دي منفصلة، نعمل تحديث هنا:
          final targetDocRef = FirebaseFirestore.instance.doc(
              '${FirebaseFunctions.teacherPath}/${targetSecondary.day}/${targetSecondary.magmo3aId}/absences/${targetSecondary.date}');
          await targetDocRef.set(
              targetAbsence.toJson(), SetOptions(merge: true));
        }

        // ============================================================
        // 4. تحديث بيانات الطالب نفسه (الجزء المحلي واللوجيك الخاص بك)
        // ============================================================

        // إزالة الطالب من قائمة الغائبين في الشاشة الحالية
        absentStudents.removeWhere((s) => s.id == student.id);

        // تهيئة قائمة الحضور
        student.countingAttendedDays ??= [];

        // إضافة سجل الحضور في المجموعة المستهدفة (Target Group)
        // مع وضع إشارة (Secondary) للمجموعة الحالية (Source Group)
        if (!student.countingAttendedDays!.any((r) =>
            r.magmo3aId == targetSecondary.magmo3aId &&
            r.date == targetSecondary.date)) {
          student.countingAttendedDays!.add(DayRecord(
            magmo3aId: targetSecondary.magmo3aId,
            date: targetSecondary.date,
            day: targetSecondary.day,
            time: targetSecondary.time,

            // ⚠️ هنا التريكاية: الـ Secondary بيشاور على المجموعة اللي إحنا واقفين فيها دلوقتي
            // عشان لما نيجي نعمل Restore يعرف يرجع فين
            secondary: SecondaryRecord(
                date: selectedDateStr, // تاريخ اليوم الحالي
                day: selectedDay, // يوم اليوم الحالي
                magmo3aId: magmo3aModel.id, // أيدي المجموعة الحالية
                time: magmo3aModel.time),
          ));
        }

        // تنظيف سجلات الغياب المتعارضة (Cleaning Conflicts)
        // بنمسح أي غياب مسجل لنفس تاريخ المجموعة الحالية أو المجموعة المستهدفة
        student.countingAbsentDays?.removeWhere((d) =>
            (d.date == selectedDateStr && d.magmo3aId == magmo3aModel.id) ||
            (d.date == targetSecondary.date &&
                d.magmo3aId == targetSecondary.magmo3aId));

        // 🔥 خطوة التزامن الهامة جداً (تحديث الكاش) 🔥
        _studentsCache[student.id] = student;
      } else {
        await _addBasicAttendance(student);
      }

      await _finalizeAttendanceUpdate(student,
          otherGroupAbs: targetAbsenceToUpdate,
          otherGroupInfo: targetSecondary);
    } catch (e) {
      emit(AbsentError('فشل الحضور اليدوي: $e'));
    } finally {
      _isProcessingAttendance = false;
    }
  }
  // --- عملية الاسترجاع (Restore) المحدثة ---
  Future<void> _restoreStudent({required Studentmodel student}) async {
    if (_isProcessingAttendance) return;
    _isProcessingAttendance = true;

    // 1. النسخ الاحتياطية (للتراجع في حالة الفشل)
    final backupStudentDays =
        List<DayRecord>.from(student.countingAttendedDays ?? []);
    final backupStudentAbsentDays =
        List<DayRecord>.from(student.countingAbsentDays ?? []);
    final backupAbsentList = List<Studentmodel>.from(absentStudents);
    final backupAttendList = List<Studentmodel>.from(attendStudents);

    try {
      // 2. تحديد السجل المراد حذفه
      final attendanceRecordIndex = student.countingAttendedDays?.indexWhere(
          (r) => (r.magmo3aId == magmo3aModel.id) && r.date == selectedDateStr);

      if (attendanceRecordIndex == null || attendanceRecordIndex == -1) {
        _isProcessingAttendance = false;
        return;
      }

      final attendanceRecord =
          student.countingAttendedDays![attendanceRecordIndex];
      final bool isGuest = attendanceRecord.secondary != null;

      // تحديد بيانات الحصة المستهدفة (الأصلية)
      final String targetMagmo3aId = isGuest
          ? attendanceRecord.secondary!.magmo3aId
          : attendanceRecord.magmo3aId;
      final String targetDate =
          isGuest ? attendanceRecord.secondary!.date : attendanceRecord.date;
      final String targetDay =
          isGuest ? attendanceRecord.secondary!.day : attendanceRecord.day;
      final TimeOfDay targetTime =
          isGuest ? attendanceRecord.secondary!.time : attendanceRecord.time;

      // 3. الحذف المحلي (مرحلة التنظيف)
      student.countingAttendedDays!.removeAt(attendanceRecordIndex);
      attendStudents.removeWhere((s) => s.id == student.id);

      // 4. الفحص الجوهري: هل الطالب لسه حاضر في مكان تاني لنفس الحصة؟
      bool isStillPresentElsewhere = student.countingAttendedDays!.any((r) {
        if (r.secondary == null) {
          return r.magmo3aId == targetMagmo3aId && r.date == targetDate;
        } else {
          return r.secondary!.magmo3aId == targetMagmo3aId &&
              r.secondary!.date == targetDate;
        }
      });

      AbsenceModel? originalAbsenceDocToUpdate;
      SecondaryRecord? originalGroupInfo;

      // 5. إذا لم يكن حاضراً في أي مكان آخر، نبدأ في إجراءات "تحويله لغائب"
      if (!isStillPresentElsewhere) {
        final originalAbsDoc = await FirebaseFunctions.getAbsenceByDateOnce(
            targetDay, targetMagmo3aId, targetDate);

        if (originalAbsDoc != null) {
          // أ- إضافة سجل غياب للطالب في الموديل الخاص به
          student.countingAbsentDays ??= [];
          if (!student.countingAbsentDays!.any(
              (d) => d.magmo3aId == targetMagmo3aId && d.date == targetDate)) {
            student.countingAbsentDays!.add(DayRecord(
              magmo3aId: targetMagmo3aId,
              date: targetDate,
              day: targetDay,
              time: targetTime,
              secondary: null,
            ));
          }

          // ب- تحديث قائمة الغياب للسيرفر
          if (!originalAbsDoc.absentStudentIds.contains(student.id)) {
            originalAbsDoc.absentStudentIds.add(student.id);
          }
          originalAbsDoc.attendStudentIds.remove(student.id);

          originalAbsenceDocToUpdate = originalAbsDoc;
          originalGroupInfo = SecondaryRecord(
              date: targetDate,
              day: targetDay,
              magmo3aId: targetMagmo3aId,
              time: targetTime);

          // ج- التحديث المحلي لقائمة الغياب (فقط لو كانت هي المجموعة الحالية)
          // هذا السطر هو الذي كان يسبب المشكلة عندك، وضعناه داخل الـ IF
          if (magmo3aModel.id == targetMagmo3aId && !isGuest) {
            if (!absentStudents.any((s) => s.id == student.id)) {
              absentStudents.add(student);
            }
          }
        }
      }

      // 6. الحفظ النهائي (Batch)
      // لاحظ: لو isStillPresentElsewhere بـ true، المتغيرات originalAbsenceDoc ستكون null
      // ولن يتم إضافة أي سجلات غياب، وهذا هو المطلوب.
      await _finalizeAttendanceUpdate(student,
          otherGroupAbs: originalAbsenceDocToUpdate,
          otherGroupInfo: originalGroupInfo);
    } catch (e) {
      // التراجع عن كل التغييرات المحلية في حالة فشل الاتصال بالإنترنت
      student.countingAttendedDays = backupStudentDays;
      student.countingAbsentDays = backupStudentAbsentDays;
      absentStudents = backupAbsentList;
      attendStudents = backupAttendList;
      _updateFilteredLists();
      emit(AbsentError('فشل الحفظ: $e'));
    } finally {
      _isProcessingAttendance = false;
    }
  }

  Future<void> _finalizeAttendanceUpdate(Studentmodel student,
      {AbsenceModel? otherGroupAbs, SecondaryRecord? otherGroupInfo}) async {
    // تحديث القوائم المحلية المفلترة (لليوزر يشوفها فوراً)
    _updateFilteredLists();

    final currentAbs = AbsenceModel(
        numberOfStudents: numberOfStudents ?? 0,
        date: selectedDateStr,
        attendStudentIds: attendStudents.map((s) => s.id).toSet().toList(),
        absentStudentIds: absentStudents.map((s) => s.id).toSet().toList());

    // إرسال البيانات للسيرفر ككتلة واحدة
    await FirebaseFunctions.runAttendanceTransaction(
      student: student,
      currentGroupAbsence: currentAbs,
      currentDay: selectedDay,
      currentMagmo3aId: magmo3aModel.id,
      currentDate: selectedDateStr,
      otherGroupAbsence: otherGroupAbs,
      otherGroupInfo: otherGroupInfo,
    );

    // تحديث الكاش
    _studentsCache[student.id] = student;
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

  @override
  Future<void> close() {
    _absenceSubscription?.cancel();
    searchController.dispose();
    return super.close();
  }
}
