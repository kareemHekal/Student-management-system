import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_management_system/alert_dialogs/Delete%20Absence.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/absence_app/day_record.dart';
import 'package:student_management_system/pages/absent/students_attending_page.dart';
import 'package:student_management_system/pages/absent/view_model/cubit.dart';
import 'package:student_management_system/pages/absent/view_model/intent.dart';

import '../../absent_home_screen.dart';
import '../../firebase/firebase_functions.dart';
import '../../models/Student_model.dart';
import '../../theme/colors_app.dart';
import '../../theme/snack_bar.dart';
import '../../theme/text_style.dart';

class CustomBottomSheet extends StatefulWidget {
  final AbsentCubit cubit;

  const CustomBottomSheet({
    Key? key,
    required this.cubit,
  }) : super(key: key);

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  // Logic remains the same, UI updated to Premium Theme

  @override
  Widget build(BuildContext context) {
    final cubit = widget.cubit;

    return Container(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Handle
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.primaryMain.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModernActionButton(
                icon: Icons.print_rounded,
                label: "طباعة",
                color: AppColors.primaryMain,
                onPressed: () async {
                  await runWithLoading(context, () async {
                    await _generatePdf(context);
                  });
                },
              ),
              _buildModernActionButton(
                  icon: Icons.checklist_rtl_rounded,
                  label: "الحاضرون",
                  color: AppColors.secondaryMain,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: StudentsAttending(
                            cubit: cubit,
                            selectedDay: cubit.selectedDay,
                            magmo3aModel: cubit.magmo3aModel,
                          ),
                        ),
                      ),
                    );
                    cubit.searchController.clear();
                    cubit.handleIntent(SearchStudent(query: ''));
                  }),
              _buildModernActionButton(
                icon: Icons.delete_forever_rounded,
                label: "حذف",
                color: AppColors.statusAbsent,
                onPressed: _showDeleteAbsenceDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: AppTextStyles.customText(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showDeleteAbsenceDialog() {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialogContent(
        onConfirm: () async {
          await fixAttendanceCounts();
        },
      ),
    );
  }

  // --- PDF & Logic Methods ---


  Future<void> _generatePdf(BuildContext context) async {
    // 1. تجهيز البيانات بره خالص بعيد عن الـ UI Thread
    final String dateStr = widget.cubit.selectedDateStr;
    final String groupInfo =
        "${widget.cubit.magmo3aModel.grade}_${widget.cubit.magmo3aModel.day}";
    final attended = widget.cubit.attendStudents;
    final absent = widget.cubit.absentStudents;

    try {
      await Printing.layoutPdf(
        name: "Attendance_${groupInfo}_$dateStr"
            .replaceAll(RegExp(r'[^\w\s]+'), '_'),
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();
          final fontData =
              await rootBundle.load("fonts/NotoKufiArabic-Regular.ttf");
          final pw.Font font = pw.Font.ttf(fontData);

          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              textDirection: pw.TextDirection.rtl,
              margin: const pw.EdgeInsets.all(20),
              theme: pw.ThemeData.withFont(base: font, bold: font),
              build: (pw.Context context) {
                return [
                  // الهيدر
                  pw.Header(
                    level: 0,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("تقرير الحضور والغياب: $groupInfo",
                            style: pw.TextStyle(fontSize: 15)),
                        pw.Text("التاريخ: $dateStr",
                            style: pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),

                  // قسم الحضور
                  _buildFastSectionHeader(
                      "قائمة الحضور (${attended.length})", PdfColors.green900),
                  pw.SizedBox(height: 10),
                  _buildOptimizedGrid(attended, PdfColors.green50),

                  pw.SizedBox(height: 20),

                  // قسم الغياب
                  _buildFastSectionHeader(
                      "قائمة الغياب (${absent.length})", PdfColors.red900),
                  pw.SizedBox(height: 10),
                  _buildOptimizedGrid(absent, PdfColors.red50),
                ];
              },
            ),
          );
          return pdf.save();
        },
      );
    } catch (e) {
      debugPrint("PDF Error: $e");
    }
  }

// دالة بناء الشبكة محسنة جداً للأداء
  pw.Widget _buildOptimizedGrid(List<Studentmodel> students, PdfColor bgColor) {
    return pw.Wrap(
      spacing: 5,
      runSpacing: 5,
      children: students
          .map((s) => pw.Container(
                width: 170, // تصغير العرض عشان يجي 3 في السطر ويقلل عدد الصفحات
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  color: bgColor,
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(s.name ?? "",
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold),
                        maxLines: 1),
                    pw.Text("ت: ${s.phoneNumber}",
                        style: const pw.TextStyle(fontSize: 7)),
                    if (s.note != null && s.note!.isNotEmpty)
                      pw.Text("ملاحظة: ${s.note}",
                          style: pw.TextStyle(
                              fontSize: 6, color: PdfColors.red700),
                          maxLines: 1),
                  ],
                ),
              ))
          .toList(),
    );
  }

  pw.Widget _buildFastSectionHeader(String title, PdfColor color) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
          color: color, borderRadius: pw.BorderRadius.circular(2)),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  Future<void> fixAttendanceCounts() async {
    try {
      debugPrint("🚀 Starting Synced Attendance Rollback...");

      var batch = FirebaseFirestore.instance.batch();
      int operationCount = 0;
      final String grade = widget.cubit.magmo3aModel.grade ?? "";
      final String rootPath = FirebaseFunctions.teacherPath;

      // دالة مساعدة لعمل commit للباتش
      Future<void> checkAndCommitBatch() async {
        operationCount++;
        if (operationCount >= 450) {
          // رقم آمن قبل الـ 500
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          operationCount = 0;
        }
      }

      // ============================================================
      // 1. معالجة الطلاب الحاضرين (Logic التزامن الجديد)
      // ============================================================
      for (var student in widget.cubit.attendStudents) {
        if (student.countingAttendedDays != null) {
          // البحث عن السجل المطابق للتاريخ الحالي
          final recordIndex = student.countingAttendedDays!.indexWhere(
            (dr) => dr.date == widget.cubit.selectedDateStr,
          );

          if (recordIndex != -1) {
            final recordToDelete = student.countingAttendedDays![recordIndex];

            // هل هو ضيف (عنده Secondary) ولا طالب أساسي؟
            final bool isGuest = recordToDelete.secondary != null;

            // أ) حذف السجل من قائمة الحضور محلياً
            student.countingAttendedDays!.removeAt(recordIndex);

            // ب) التعامل حسب نوع الطالب
            if (!isGuest) {
              // --- الحالة الأولى: طالب أساسي (Owner) ---
              // المطلوب: حذف الحضور فقط، وعدم إضافة أي غياب.
              // (لأننا بنحذف الحصة دي أصلاً، فمفيش داعي نسجله غياب فيها)
            } else {
              // --- الحالة الثانية: طالب ضيف (Guest) ---
              // استخراج بيانات المجموعة الأصلية من الـ Secondary
              final secRecord = recordToDelete.secondary!;
              final String originalGroupDate = secRecord.date;
              final String originalGroupDay = secRecord.day;
              final String originalGroupId = secRecord.magmo3aId;
              final TimeOfDay originalTime = secRecord.time;

              // 1. هل الطالب لسه حاضر لنفس الحصة الأصلية دي في مكان تاني؟
              bool isStillPresentElsewhere =
                  student.countingAttendedDays!.any((r) {
                // فحص لو هو حاضر في مجموعته الأصلية
                if (r.secondary == null) {
                  return r.magmo3aId == originalGroupId &&
                      r.date == originalGroupDate;
                }
                // فحص لو هو معوضها في مجموعة تانية (غير اللي بتتمسح دي)
                else {
                  return r.secondary!.magmo3aId == originalGroupId &&
                      r.secondary!.date == originalGroupDate;
                }
              });

              // 2. لو مش حاضر في حته تانية، لازم نتأكد إن سجل الغياب الأصلي "موجود"
              if (!isStillPresentElsewhere) {
                // بنروح نسأل السيرفر: هل وثيقة الغياب للمجموعة الأصلية دي لسه موجودة؟
                final originalAbsenceModel =
                    await FirebaseFunctions.getAbsenceByDateOnce(
                  originalGroupDay,
                  originalGroupId,
                  originalGroupDate,
                );

                // الشرط الجوهري: لو السجل موجود -> رجعه غياب، لو مش موجود -> متعملش حاجة
                if (originalAbsenceModel != null) {
                  // إضافة الطالب لقائمة الغائبين في السيرفر (AbsenceModel)
                  if (!originalAbsenceModel.absentStudentIds
                      .contains(student.id)) {
                    originalAbsenceModel.absentStudentIds.add(student.id);
                    // لو كان مكتوب حاضر بالغلط هناك نشيله
                    originalAbsenceModel.attendStudentIds.remove(student.id);

                    // تحديث وثيقة الغياب الأصلية في الباتش
                    final otherAbsRef = FirebaseFirestore.instance.doc(
                        '$rootPath/$originalGroupDay/$originalGroupId/absences/$originalGroupDate');
                    batch.set(otherAbsRef, originalAbsenceModel.toJson(),
                        SetOptions(merge: true));
                    await checkAndCommitBatch();
                  }

                  // إضافة سجل الغياب في ملف الطالب (countingAbsentDays)
                  // بنستخدم بيانات الـ Secondary عشان نكريت DayRecord جديد للغياب
                  student.countingAbsentDays ??= [];
                  // نتأكد إنه مش مضاف قبل كده
                  if (!student.countingAbsentDays!.any((d) =>
                      d.magmo3aId == originalGroupId &&
                      d.date == originalGroupDate)) {
                    student.countingAbsentDays!.add(DayRecord(
                      magmo3aId: originalGroupId,
                      date: originalGroupDate,
                      day: originalGroupDay,
                      time: originalTime,
                      secondary:
                          null, // في الغياب الـ secondary بيكون null لأنه رجع لأصله
                    ));
                  }
                }
              }
            }

            // ج) تحديث بيانات الطالب النهائية في الباتش
            final studentRef = FirebaseFirestore.instance
                .doc('$rootPath/$grade/${student.id}');
            batch.update(studentRef, student.toJson());
            await checkAndCommitBatch();
          }
        }
      }

      // ============================================================
      // 2. معالجة الطلاب الغائبين (تنظيف كامل)
      // ============================================================
      for (var student in widget.cubit.absentStudents) {
        if (student.countingAbsentDays != null) {
          int initialLength = student.countingAbsentDays!.length;

          // مسح سجل اليوم ده من قائمة غياب الطالب لأنه الحصة بتتلغى
          student.countingAbsentDays!
              .removeWhere((dr) => dr.date == widget.cubit.selectedDateStr);

          // لو حصل تغيير في الـ List نبعت تحديث
          if (student.countingAbsentDays!.length != initialLength) {
            final studentRef = FirebaseFirestore.instance
                .doc('$rootPath/$grade/${student.id}');
            batch.update(studentRef, student.toJson());
            await checkAndCommitBatch();
          }
        }
      }

      // ============================================================
      // 3. حذف وثيقة الحصة الحالية نهائياً
      // ============================================================
      final currentAbsRef = FirebaseFirestore.instance.doc(
          '$rootPath/${widget.cubit.selectedDay}/${widget.cubit.magmo3aModel.id}/absences/${widget.cubit.selectedDateStr}');
      batch.delete(currentAbsRef);
      await checkAndCommitBatch();

      // ============================================================
      // 4. التنفيذ
      // ============================================================
      if (operationCount > 0) await batch.commit();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AbsentHomePage()),
            (route) => false);
        AppSnackBars.showSuccess(context, "تم حذف السجل وتزامن البيانات بنجاح");
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      if (mounted) AppSnackBars.showError(context, "حدث خطأ: $e");
    }
  }
}
