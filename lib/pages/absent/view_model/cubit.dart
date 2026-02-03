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
  final Map<String, Studentmodel> _studentsCache = {};
  StreamSubscription? _absenceSubscription;

  bool isFirstLoadDone = false;
  bool _isProcessingAttendance = false;

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
                if (_isProcessingAttendance) return;

                final scannedValue = capture.barcodes.first.rawValue;
                if (scannedValue == null) return;

                // 1. فحص محلي فوري (بدون Loading) عشان لو حاضر نطلع SnackBar بسرعة
                if (attendStudents.any((s) => s.id == scannedValue)) {
                  AppSnackBars.showError(context, "⚠️ حاضر بالفعل");
                  return;
                }

                try {
                  _isProcessingAttendance = true;
                  await _scannerController.stop();

                  // 2. تشغيل الـ Loading لعملية كاملة (Block UI)
                  await runWithLoading(context, () async {
                    // أ- البحث في الذاكرة أولاً (فائق السرعة)
                    Studentmodel? student = absentStudents
                        .cast<Studentmodel?>()
                        .firstWhere((s) => s?.id == scannedValue,
                            orElse: () => null);

                    // ب- لو مش في الذاكرة، نطلبه من Firebase (وأنت لسه جوه الـ Loading)
                    student ??= await FirebaseFunctions.getStudentById(
                        magmo3aModel.grade ?? "", scannedValue);

                    if (student != null) {
                      // ج- لو الطالب في مجموعته الأصلية، احفظ فوراً وأنت جوه الـ Loading
                      if (student.hisGroupsId?.contains(magmo3aModel.id) ==
                          true) {
                        await _addQrStudentToPresent(
                            student: student, originalSecondary: null);

                        // تحديث الـ Bottom Sheet بعد ما الـ Loading يخلص
                        setScannerState(() {
                          activeStudent = student;
                        });
                      } else {
                        // د- لو طالب مجموعة تانية، هنضطر نطلع من الـ Loading عشان يختار المجموعة
                        // لكن هنمرر البيانات للـ Dialog مباشرة
                        _isProcessingAttendance =
                            false; // نفتح القفل مؤقتاً للـ Dialog

                        // نغلق الـ Loading يدوياً هنا عشان نفتح الـ Dialog
                        if (Navigator.canPop(context)) Navigator.pop(context);

                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dCtx) => GroupSelectionWhileScanning(
                            currentDate: selectedDateStr,
                            studentGroups: student!.hisGroups ?? [],
                            studentName: student.name ?? "",
                            onConfirm: (selectedOriginalGroup) async {
                              // نرجع نعمل Loading تاني وقت الحفظ فقط
                              await runWithLoading(context, () async {
                                await _addQrStudentToPresent(
                                  student: student!,
                                  originalSecondary: selectedOriginalGroup,
                                );
                              });
                              Navigator.pop(dCtx);
                              setScannerState(() {
                                activeStudent = student;
                              });
                            },
                          ),
                        );
                      }
                    } else {
                      AppSnackBars.showError(context, "❌ الطالب غير مسجل");
                      _scannerController.start();
                    }
                  });
                } catch (e) {
                  debugPrint("❌ Scan Error: $e");
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

  Future<void> _addManualStudentToPresent(
      {required Studentmodel student, SecondaryRecord? targetSecondary}) async {
    if (_isProcessingAttendance) return;

    try {
      _isProcessingAttendance = true;
      List<Future> batchOperations = [];

      // ملاحظة: الـ runWithLoading يتم استدعاؤه من الـ UI (onConfirm) كما وضحت سابقاً

      if (targetSecondary != null) {
        // 1. التأكد من تهيئة سجل المجموعة البديلة (محلياً/سيرفر)
        await getSecondaryGroupStudents(
            grade: student.grade ?? "", secondaryRecord: targetSecondary);

        // 2. التزامن: جلب أحدث نسخة للسجل البديل لضمان عدم ضياع شغل سكرتيرة أخرى
        final targetAbsence = await FirebaseFunctions.getAbsenceByDateOnce(
            targetSecondary.day,
            targetSecondary.magmo3aId,
            targetSecondary.date);

        if (targetAbsence != null) {
          if (!targetAbsence.attendStudentIds.contains(student.id)) {
            targetAbsence.attendStudentIds.add(student.id);
          }
          targetAbsence.absentStudentIds.remove(student.id);

          batchOperations.add(
              FirebaseFunctions.updateAbsenceByDateInSubcollection(
                  targetSecondary.day,
                  targetSecondary.magmo3aId,
                  targetSecondary.date,
                  targetAbsence));
        }

        // تحديث الكائن المحلي للطالب (التعويض)
        absentStudents.removeWhere((s) => s.id == student.id);
        student.countingAttendedDays ??= [];

        bool isAlreadyAttended = student.countingAttendedDays!.any((r) =>
            r.magmo3aId == targetSecondary.magmo3aId &&
            r.date == targetSecondary.date);

        if (!isAlreadyAttended) {
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
        }

        student.countingAbsentDays?.removeWhere((d) =>
            (d.date == selectedDateStr && d.magmo3aId == magmo3aModel.id) ||
            (d.date == targetSecondary.date &&
                d.magmo3aId == targetSecondary.magmo3aId));
      } else {
        // الحضور العادي (يستخدم البحث المحلي داخل _addBasicAttendance)
        await _addBasicAttendance(student, batchOperations);
      }

      // 3. الحفظ النهائي (بيحدث سجل الحصة الحالية وسجل الطالب)
      await _finalizeAttendanceUpdate(student, batchOperations);
    } catch (e) {
      emit(AbsentError('Attendance Failed: $e'));
    } finally {
      _isProcessingAttendance = false;
    }
  }

  Future<void> _addQrStudentToPresent(
      {required Studentmodel student,
      SecondaryRecord? originalSecondary}) async {
    try {
      List<Future> batchOperations = [];

      if (originalSecondary != null) {
        // أ- تحديث سجل المجموعة الأصلية في الـ Firebase (إزالة من الغياب هناك)
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

        // ب- تحديث سجل الطالب (حضور تعويضي)
        student.countingAttendedDays ??= [];
        // التحقق من عدم تكرار "هذا التعويض" تحديداً
        bool isAlreadyAttended = student.countingAttendedDays!.any((r) =>
            r.magmo3aId == magmo3aModel.id &&
            r.date == selectedDateStr &&
            r.secondary?.magmo3aId == originalSecondary.magmo3aId);

        if (!isAlreadyAttended) {
          student.countingAttendedDays!.add(DayRecord(
            magmo3aId: magmo3aModel.id,
            date: selectedDateStr,
            day: selectedDay,
            time: magmo3aModel.time,
            secondary: originalSecondary,
          ));
        }

        // ج- التزامن: حذف الغياب للمجموعة "الأصلية" من سجل الطالب
        student.countingAbsentDays?.removeWhere((d) =>
            d.magmo3aId == originalSecondary.magmo3aId &&
            d.date == originalSecondary.date);

        if (!attendStudents.any((s) => s.id == student.id))
          attendStudents.add(student);
      } else {
        await _addBasicAttendance(student, batchOperations);
      }

      await _finalizeAttendanceUpdate(student, batchOperations);
    } catch (e) {
      emit(AbsentError('QR Attendance Failed: $e'));
    }
  }

  Future<void> _addBasicAttendance(
      Studentmodel student, List<Future> batch) async {
    // 1. التحديث المحلي
    absentStudents.removeWhere((s) => s.id == student.id);
    if (!attendStudents.any((s) => s.id == student.id))
      attendStudents.add(student);

    student.countingAttendedDays ??= [];

    // التحقق من وجود "هذا السجل المعين" (نفس المجموعة ونفس التاريخ)
    bool isAlreadyRecorded = student.countingAttendedDays!.any(
        (r) => r.magmo3aId == magmo3aModel.id && r.date == selectedDateStr);

    if (!isAlreadyRecorded) {
      student.countingAttendedDays!.add(DayRecord(
        magmo3aId: magmo3aModel.id,
        date: selectedDateStr,
        day: selectedDay,
        time: magmo3aModel.time,
        secondary: null,
      ));
    }

    // حذف الغياب "فقط" المرتبط بهذه الحصة المحددة
    student.countingAbsentDays?.removeWhere(
        (d) => d.magmo3aId == magmo3aModel.id && d.date == selectedDateStr);
  }

// --- عملية الاسترجاع (Restore) ---
  // --- عملية الاسترجاع (Restore) المحدثة ---
  Future<void> _restoreStudent({required Studentmodel student}) async {
    if (_isProcessingAttendance) return;

    try {
      _isProcessingAttendance = true;

      // 1. تحديد السجل الحالي المراد حذفه
      final attendanceRecordIndex = student.countingAttendedDays?.indexWhere(
          (r) => (r.magmo3aId == magmo3aModel.id) && r.date == selectedDateStr);

      if (attendanceRecordIndex == null || attendanceRecordIndex == -1) return;

      final attendanceRecord =
          student.countingAttendedDays![attendanceRecordIndex];
      final bool isGuest = attendanceRecord.secondary != null;

      // تحديد بيانات "الحصة الأصلية"
      final String targetMagmo3aId = isGuest
          ? attendanceRecord.secondary!.magmo3aId
          : attendanceRecord.magmo3aId;
      final String targetDate =
          isGuest ? attendanceRecord.secondary!.date : attendanceRecord.date;
      final String targetDay =
          isGuest ? attendanceRecord.secondary!.day : attendanceRecord.day;
      final TimeOfDay targetTime =
          isGuest ? attendanceRecord.secondary!.time : attendanceRecord.time;

      List<Future> batchOperations = [];

      // 2. الحذف المحلي من الحضور
      student.countingAttendedDays!.removeAt(attendanceRecordIndex);
      attendStudents.removeWhere((s) => s.id == student.id);

      // 3. فحص هل هو حاضر في أي مكان آخر لنفس الحصة الأصلية؟
      bool isStillPresentElsewhere = student.countingAttendedDays!.any((r) {
        if (r.secondary == null) {
          return r.magmo3aId == targetMagmo3aId && r.date == targetDate;
        } else {
          return r.secondary!.magmo3aId == targetMagmo3aId &&
              r.secondary!.date == targetDate;
        }
      });

      if (!isStillPresentElsewhere) {
        // -------------------------------------------------------
        // 🆕 التحقق من وجود AbsenceModel للمجموعة الأصلية قبل إضافة الغياب
        // -------------------------------------------------------
        final originalAbsDoc = await FirebaseFunctions.getAbsenceByDateOnce(
            targetDay, targetMagmo3aId, targetDate);

        if (originalAbsDoc != null) {
          // أ- إضافة سجل غياب للطالب محلياً
          student.countingAbsentDays ??= [];
          bool alreadyInAbsent = student.countingAbsentDays!.any(
              (d) => d.magmo3aId == targetMagmo3aId && d.date == targetDate);

          if (!alreadyInAbsent) {
            student.countingAbsentDays!.add(DayRecord(
              magmo3aId: targetMagmo3aId,
              date: targetDate,
              day: targetDay,
              time: targetTime,
              secondary: null,
            ));
          }

          // ب- تحديث قائمة الغياب في السجل البعيد (Firebase)
          if (!originalAbsDoc.absentStudentIds.contains(student.id)) {
            originalAbsDoc.absentStudentIds.add(student.id);
          }
          originalAbsDoc.attendStudentIds.remove(student.id);

          batchOperations.add(
              FirebaseFunctions.updateAbsenceByDateInSubcollection(
                  targetDay, targetMagmo3aId, targetDate, originalAbsDoc));

          // ج- لو كنا حالياً داخل المجموعة الأصلية، أضفه لقائمة الغياب لتحديث الـ Stream
          if (magmo3aModel.id == targetMagmo3aId && !isGuest) {
            if (!absentStudents.any((s) => s.id == student.id)) {
              absentStudents.add(student);
            }
          }
        } else {
          debugPrint(
              "Original Absence record doesn't exist yet. Student won't be marked absent.");
        }
      }

      // 4. الحفظ النهائي (تحديث سجل المجموعة الحالية وسجل الطالب)
      await _finalizeAttendanceUpdate(student, batchOperations);
    } catch (e) {
      emit(AbsentError('Restore Failed: $e'));
    } finally {
      _isProcessingAttendance = false;
    }
  }

  Future<void> _updateRemoteAbsenceRecord(
      String day, String magmo3aId, String date, String studentId,
      {required bool isAddingToAbsent}) async {
    final absDoc =
        await FirebaseFunctions.getAbsenceByDateOnce(day, magmo3aId, date);
    if (absDoc != null) {
      if (isAddingToAbsent) {
        if (!absDoc.absentStudentIds.contains(studentId))
          absDoc.absentStudentIds.add(studentId);
        absDoc.attendStudentIds.remove(studentId);
      } else {
        absDoc.absentStudentIds.remove(studentId);
        if (!absDoc.attendStudentIds.contains(studentId))
          absDoc.attendStudentIds.add(studentId);
      }
      await FirebaseFunctions.updateAbsenceByDateInSubcollection(
          day, magmo3aId, date, absDoc);
    }
  }


  Future<void> _finalizeAttendanceUpdate(
      Studentmodel student, List<Future> batch) async {
    // تحديث محلي للقوائم المفلترة
    _updateFilteredLists();

    // بناء الموديل للمجموعة الحالية من اللستة اللي اتحدثت فوق
    final currentAbs = AbsenceModel(
        numberOfStudents: numberOfStudents ?? 0,
        date: selectedDateStr,
        attendStudentIds: attendStudents.map((s) => s.id).toSet().toList(),
        absentStudentIds: absentStudents.map((s) => s.id).toSet().toList());

    // إضافة تحديث المجموعة الحالية والسجل للطالب
    batch.add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
        selectedDay, magmo3aModel.id, selectedDateStr, currentAbs));
    batch.add(FirebaseFunctions.updateStudentInCollection(
        student.grade ?? "", student.id, student));

    await Future.wait(batch);

    // تحديث الكاش عشان الـ Stream يقرأ من الميموري
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
