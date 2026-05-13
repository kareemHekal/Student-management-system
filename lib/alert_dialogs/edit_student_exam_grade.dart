import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart'; // Your custom snack_bar.dart
import 'package:student_management_system/theme/text_style.dart';

import '../firebase/exams_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import '../models/student_exam_grade.dart';

Future<void> showEditStudentExamGradeDialog({
  required BuildContext context,
  required String gradeName,
  required String studentId,
  required StudentExamGrade examGrade,
  required String examName,
  required String miniExamName,
  required double fullGrade,
}) async {
  final gradeController = TextEditingController(text: examGrade.studentGrade);
  final descController = TextEditingController(text: examGrade.description);

  String? errorText;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryMain,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.white),
                  const SizedBox(width: 12),
                  Text(
                    "تعديل درجة الطالب",
                    style: AppTextStyles.customText(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Exam Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMain.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: AppColors.primaryMain.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            Icons.book_outlined, "الامتحان", examName),
                        const SizedBox(height: 6),
                        _buildDetailRow(
                            Icons.assignment_outlined, "النموذج", miniExamName),
                        const SizedBox(height: 6),
                        _buildDetailRow(Icons.flag_outlined, "الدرجة الكاملة",
                            fullGrade.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Grade Input
                  _buildModernTextField(
                    controller: gradeController,
                    label: "درجة الطالب الجديدة",
                    hint: "0.0",
                    icon: Icons.score_outlined,
                    isNumber: true,
                    errorText: errorText,
                    onChanged: (val) {
                      if (errorText != null) setState(() => errorText = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Description Input
                  _buildModernTextField(
                    controller: descController,
                    label: "ملاحظات التعديل",
                    hint: "أضف ملاحظة (اختياري)...",
                    icon: Icons.description_outlined,
                    isMultiline: true,
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "إلغاء",
                        style: AppTextStyles.customText(
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMain,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final parentContext =
                            Navigator.of(context, rootNavigator: true).context;
                        final gradeValue =
                            double.tryParse(gradeController.text.trim()) ?? -1;

                        if (gradeValue < 0 || gradeValue > fullGrade) {
                          setState(() {
                            errorText = "الدرجة يجب أن تكون بين 0 و $fullGrade";
                          });
                          return;
                        }

                        final updated = StudentExamGrade(
                          studentGrade: gradeController.text.trim(),
                          examId: examGrade.examId,
                          miniExamId: examGrade.miniExamId,
                          description: descController.text.trim(),
                        );

                        await runWithLoading(context, () async {
                          await FirebaseExams.updateStudentExamGrade(
                            gradeName: gradeName,
                            studentId: studentId,
                            updatedGrade: updated,
                          );

                          if (context.mounted) {
                            AppSnackBars.showSuccess(
                                parentContext, "تم تعديل درجة الطالب بنجاح ✅");

                            Navigator.pushNamedAndRemoveUntil(
                              parentContext,
                              '/StudentsTab',
                              (route) => false,
                            );
                          }
                        });
                      },
                      child: Text(
                        "حفظ التعديل",
                        style: AppTextStyles.customText(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

// --- Internal UI Helpers ---

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 16, color: AppColors.primaryMain),
      const SizedBox(width: 8),
      Text(
        "$label: ",
        style: AppTextStyles.customText(
            fontSize: 13, color: AppColors.textSecondary),
      ),
      Expanded(
        child: Text(
          value,
          style: AppTextStyles.customText(
              fontSize: 13, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _buildModernTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  bool isNumber = false,
  bool isMultiline = false,
  String? errorText,
  Function(String)? onChanged,
}) {
  return TextFormField(
    controller: controller,
    onChanged: onChanged,
    keyboardType: isNumber
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    maxLines: isMultiline ? 2 : 1,
    style: AppTextStyles.customText(fontSize: 15),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: Icon(icon, color: AppColors.primaryMain, size: 22),
      filled: true,
      fillColor: Colors.grey[50],
      labelStyle: AppTextStyles.customText(
          color: AppColors.textSecondary, fontSize: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.primaryMain, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.statusAbsent, width: 1),
      ),
    ),
  );
}