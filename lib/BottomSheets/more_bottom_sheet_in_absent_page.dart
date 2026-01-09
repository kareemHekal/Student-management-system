import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_management_system/pages/absent/students_attending_page.dart';
import 'package:student_management_system/pages/absent/view_model/cubit.dart';

import '../../Alert dialogs/Delete Absence.dart';
import '../../absent_home_screen.dart';
import '../../firebase/firebase_functions.dart';
import '../../loadingFile/loading_alert/run_with_loading.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/Student_model.dart';
import '../../theme/colors_app.dart';
import '../../theme/snack_bar.dart';
import '../../theme/text_style.dart';

class CustomBottomSheet extends StatefulWidget {
  final AbsentCubit cubit;
  final List<Studentmodel> filteredStudentsList;
  final String selectedDay;
  final Magmo3amodel magmo3aModel;
  final String date;
  final int numberOfStudents;
  final List<Studentmodel> absentStudent;
  final List<Studentmodel> attendStudent;

  const CustomBottomSheet({
    Key? key,
    required this.cubit,
    required this.filteredStudentsList,
    required this.date,
    required this.numberOfStudents,
    required this.absentStudent,
    required this.attendStudent,
    required this.magmo3aModel,
    required this.selectedDay,
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
                  if (widget.filteredStudentsList.isNotEmpty) {
                    await _generatePdf(context);
                  } else {
                    _showNoStudentsDialog();
                  }
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

  void _showNoStudentsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: _buildDialogHeader(
            Icons.warning_amber_rounded, "تنبيه", AppColors.statusLate),
        content: Text(
          "لا يوجد طلاب غائبين للتصدير.",
          style: AppTextStyles.customText(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("موافق",
                style: AppTextStyles.customText(color: AppColors.primaryMain)),
          ),
        ],
      ),
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

  Widget _buildDialogHeader(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white),
          const SizedBox(width: 12),
          Text(title,
              style: AppTextStyles.customText(
                  color: AppColors.white, fontWeight: FontWeight.bold)),
        ],
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
    // Font loading logic stays the same...
    final fontData = await rootBundle.load("fonts/NotoKufiArabic-Regular.ttf");
    final pw.Font font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Center(
              child: pw.Text("تقرير الغياب - ${widget.magmo3aModel.grade}",
                  style: pw.TextStyle(
                      font: font,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold)),
            ),
          ),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10)),
          pw.Text("التاريخ: ${widget.date} | اليوم: ${widget.selectedDay}",
              style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Divider(),
          pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 0.6,
            children: widget.filteredStudentsList
                .map((student) => _buildPdfStudentCard(student, font))
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _buildPdfStudentCard(Studentmodel student, pw.Font font) {
    String note = _buildNotesForDate(student, widget.date);
    return pw.Container(
      margin: const pw.EdgeInsets.all(5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("الاسم: ${student.name}",
              style: pw.TextStyle(
                  font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text("الموبايل: ${student.phoneNumber}",
              style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text("الأب: ${student.fatherPhone}",
              style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text("الأم: ${student.motherPhone}",
              style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Divider(thickness: 0.5),
          pw.Text("الملاحظة: $note",
              style: pw.TextStyle(
                  font: font, fontSize: 9, color: PdfColors.red900)),
        ],
      ),
    );
  }

  Future<void> fixAttendanceCounts() async {
    await runWithLoading(context, () async {
      try {
        debugPrint("🚀 Starting Attendance Rollback...");

        List<Future> batchUpdates = [];

        for (var student in widget.absentStudent) {
          if (student.countingAbsentDays != null) {
            student.countingAbsentDays!
                .removeWhere((dr) => dr.date == widget.date);

            batchUpdates.add(FirebaseFunctions.updateStudentInCollection(
                widget.magmo3aModel.grade ?? "", student.id, student));
          }
        }

        for (var student in widget.attendStudent) {
          if (student.countingAttendedDays != null) {
            student.countingAttendedDays!
                .removeWhere((dr) => dr.date == widget.date);

            batchUpdates.add(FirebaseFunctions.updateStudentInCollection(
                widget.magmo3aModel.grade ?? "", student.id, student));
          }
        }

        batchUpdates.add(FirebaseFunctions.deleteAbsenceFromSubcollection(
            widget.selectedDay, // e.g., "Saturday"
            widget.magmo3aModel.id,
            widget.date // e.g., "12-10-2023"
            ));

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
    });
  }
}
