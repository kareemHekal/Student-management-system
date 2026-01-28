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

  String _buildNotesForDate(Studentmodel student, String dateKey) {
    if (student.notes == null || student.notes!.isEmpty)
      return "لا توجد ملاحظات";
    for (var note in student.notes!) {
      if (note.containsKey(dateKey)) return note[dateKey] ?? "لا توجد";
    }
    return "لا توجد ملاحظات لتاريخ $dateKey";
  }

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    // Load Arabic font
    final fontData = await rootBundle.load("fonts/NotoKufiArabic-Regular.ttf");
    final pw.Font font = pw.Font.ttf(fontData);

    // Separate the lists (Assuming these are available in your widget/state)
    // If you are calling this from the Cubit, use cubit.attendStudents and cubit.absentStudents
    final attended = widget.cubit.attendStudents;
    final absent = widget.cubit.absentStudents;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // --- Report Header ---
          pw.Center(
            child: pw.Text(
                "تقرير الحضور والغياب - ${widget.cubit.magmo3aModel.grade}",
                style: pw.TextStyle(
                    font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("التاريخ: ${widget.cubit.selectedDateStr}",
                  style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Text("اليوم: ${widget.cubit.selectedDay}",
                  style: pw.TextStyle(font: font, fontSize: 12)),
            ],
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 15),

          // --- Attending Students Section ---
          _buildSectionHeader(
              "قائمة الحضور (${attended.length})", PdfColors.green900, font),
          pw.SizedBox(height: 10),
          attended.isEmpty
              ? pw.Text("لا يوجد طلاب حاضرون",
                  style: pw.TextStyle(font: font, fontSize: 10))
              : pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: attended
                      .map((s) =>
                          _buildPdfStudentCard(s, font, PdfColors.green50))
                      .toList(),
                ),

          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // --- Absent Students Section ---
          _buildSectionHeader(
              "قائمة الغياب (${absent.length})", PdfColors.red900, font),
          pw.SizedBox(height: 10),
          absent.isEmpty
              ? pw.Text("لا يوجد طلاب غائبون",
                  style: pw.TextStyle(font: font, fontSize: 10))
              : pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: absent
                      .map(
                          (s) => _buildPdfStudentCard(s, font, PdfColors.red50))
                      .toList(),
                ),
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

// Helper to build Section Headers
  pw.Widget _buildSectionHeader(String title, PdfColor color, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(color: color),
      child: pw.Text(title,
          style: pw.TextStyle(
              font: font,
              fontSize: 14,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold)),
    );
  }

// Enhanced Student Card for PDF
  pw.Widget _buildPdfStudentCard(
      Studentmodel student, pw.Font font, PdfColor bgColor) {
    String note = _buildNotesForDate(student, widget.cubit.selectedDateStr);
    return pw.Container(
      width: 240, // Fixed width helps the Wrap layout stay organized
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("الاسم: ${student.name}",
              style: pw.TextStyle(
                  font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text("رقم الطالب: ${student.phoneNumber}",
              style: pw.TextStyle(font: font, fontSize: 8)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("الأب: ${student.fatherPhone}",
                  style: pw.TextStyle(font: font, fontSize: 8)),
              pw.Text("الأم: ${student.motherPhone}",
                  style: pw.TextStyle(font: font, fontSize: 8)),
            ],
          ),
          if (note.isNotEmpty) ...[
            pw.Divider(thickness: 0.3),
            pw.Text("ملاحظة: $note",
                style: pw.TextStyle(
                    font: font, fontSize: 8, color: PdfColors.red700)),
          ],
        ],
      ),
    );
  }
  Future<void> fixAttendanceCounts() async {
    try {
      debugPrint("🚀 Starting Attendance Rollback...");

      List<Future> batchUpdates = [];

      // 1. معالجة الطلاب الحاضرين (Attend Students)
      // دول اللي ممكن يكون فيهم Secondary (ضيوف)
      for (var student in widget.cubit.attendStudents) {
        if (student.countingAttendedDays != null) {
          // البحث عن سجل اليوم الحالي
          // نستخدم try/catch أو firstWhere orElse للبحث بأمان

          DayRecord? recordToDelete;
          try {
            recordToDelete = student.countingAttendedDays!.firstWhere(
              (dr) => dr.date == widget.cubit.selectedDateStr,
              // بنبحث بتاريخ الكيوبت (المجموعة الحالية)
            );
          } catch (e) {
            recordToDelete = null;
          }

          if (recordToDelete != null) {
            // --- هل الطالب ده ضيف؟ (ليه Secondary) ---
            if (recordToDelete.secondary != null) {
              final secRecord = recordToDelete.secondary!;

              // أ. روح هات سجل غياب المجموعة الأصلية بتاعته
              final secAbsenceModel =
                  await FirebaseFunctions.getAbsenceByDateOnce(
                secRecord.day,
                secRecord.magmo3aId,
                secRecord.date,
              );

              // ب. لو السجل موجود، رجع الطالب ده غياب فيه
              if (secAbsenceModel != null) {
                if (!secAbsenceModel.absentStudentIds.contains(student.id)) {
                  secAbsenceModel.absentStudentIds.add(student.id);
                  // وتأكد إنه مش في الحضور هناك
                  secAbsenceModel.attendStudentIds.remove(student.id);

                  // ج. ضيف للطالب سجل غياب في مجموعته الأصلية (عشان عداد الغياب يظبط)
                  student.countingAbsentDays ??= [];
                  student.countingAbsentDays!.add(DayRecord(
                      magmo3aId: secRecord.magmo3aId,
                      date: secRecord.date,
                      day: secRecord.day,
                      time: secRecord.time,
                      secondary: null));
                  batchUpdates
                      .add(FirebaseFunctions.updateAbsenceByDateInSubcollection(
                    secRecord.day,
                    secRecord.magmo3aId,
                    secRecord.date,
                    secAbsenceModel,
                  ));
                }
              }
            }

            // د. احذف سجل الحضور من الطالب
            student.countingAttendedDays!.remove(recordToDelete);

            // هـ. ضيف الطالب للباتش عشان يتعمل update
            batchUpdates.add(FirebaseFunctions.updateStudentInCollection(
                widget.cubit.magmo3aModel.grade ?? "", student.id, student));
          }
        }
      }

      // 2. معالجة الطلاب الغائبين (Absent Students)
      // دول طلاب المجموعة الأصليين اللي اتسجلوا غياب، هنشيل الغياب عنهم بس
      for (var student in widget.cubit.absentStudents) {
        if (student.countingAbsentDays != null) {
          // احذف سجل الغياب اللي بيطابق تاريخ اليوم
          student.countingAbsentDays!
              .removeWhere((dr) => dr.date == widget.cubit.selectedDateStr);

          batchUpdates.add(FirebaseFunctions.updateStudentInCollection(
              widget.cubit.magmo3aModel.grade ?? "", student.id, student));
        }
      }

      // 3. حذف وثيقة غياب المجموعة الحالية نهائياً
      batchUpdates.add(FirebaseFunctions.deleteAbsenceFromSubcollection(
          widget.cubit.selectedDay,
          widget.cubit.magmo3aModel.id,
          widget.cubit.selectedDateStr));

      // 4. تنفيذ الكل
      await Future.wait(batchUpdates);

      debugPrint("✅ Rollback Complete!");

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AbsentHomePage()),
          (route) => false,
        );

        AppSnackBars.showSuccess(
            context, "تم حذف سجل الغياب وتصحيح العدادات بنجاح");
      }
    } catch (e) {
      debugPrint("❌ Error fixing counts: $e");
      if (mounted) {
        AppSnackBars.showError(context, "حدث خطأ أثناء الحذف: $e");
      }
    }
  }
}
