import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'package:student_management_system/theme/snack_bar.dart'; // Your custom snackbar logic

import '../firebase/exams_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';

Future<void> showDeleteStudentExamGradeDialog({
  required BuildContext context,
  required String gradeName,
  required String studentId,
  required String examId,
  required String miniExamId,
  required String examName,
  required String miniExamName,
}) async {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.statusAbsent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.delete_outline,
                  color: AppColors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                "حذف درجة الطالب",
                style: AppTextStyles.customText(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "هل أنت متأكد من حذف هذه الدرجة؟",
              style: AppTextStyles.customText(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.book_outlined, "الامتحان", examName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.assignment_outlined, "النموذج", miniExamName),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusAbsent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.statusAbsent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.statusAbsent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "سيتم إزالة الدرجة نهائيًا ولا يمكن التراجع عن هذا الإجراء.",
                      style: AppTextStyles.customText(
                        fontSize: 13,
                        color: AppColors.statusAbsent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                    backgroundColor: AppColors.statusAbsent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final parentContext =
                        Navigator.of(context, rootNavigator: true).context;

                    await runWithLoading(context, () async {
                      await FirebaseExams.deleteStudentExamGrade(
                        gradeName: gradeName,
                        studentId: studentId,
                        examId: examId,
                        miniExamId: miniExamId,
                      );

                      if (context.mounted) {
                        AppSnackBars.showSuccess(
                            parentContext, "تم حذف الدرجة بنجاح");

                        Navigator.pushNamedAndRemoveUntil(
                          parentContext,
                          '/StudentsTab',
                          (route) => false,
                        );
                      }
                    });
                  },
                  child: Text(
                    "تأكيد الحذف",
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
}

// Helper widget for clean info layout
Widget _buildInfoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primaryMain),
      const SizedBox(width: 8),
      Text(
        "$label: ",
        style: AppTextStyles.customText(
            fontSize: 14, color: AppColors.textSecondary),
      ),
      Expanded(
        child: Text(
          value,
          style: AppTextStyles.customText(
              fontSize: 14, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}