import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart'; // Your custom import
import 'package:student_management_system/theme/text_style.dart';

import '../firebase/exams_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import 'verifiy_password.dart'; // Import this for safety

Future<void> showDeleteExamDialog({
  required BuildContext context,
  required String gradeName,
  required String examId,
  required String examName,
}) async {
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.statusAbsent, // Using Red for delete
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'تأكيد الحذف',
                style: AppTextStyles.customText(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'هل أنت متأكد من حذف امتحان:',
                textAlign: TextAlign.center,
                style: AppTextStyles.customText(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                '"$examName"',
                textAlign: TextAlign.center,
                style: AppTextStyles.customText(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.statusAbsent,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusAbsent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⚠️ تنبيه: سيتم حذف هذا الامتحان وجميع درجات الطلاب المرتبطة به بشكل نهائي.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.customText(
                    fontSize: 13,
                    color: AppColors.statusAbsent,
                  ),
                ),
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
                    'تراجع',
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
                    // Safety first: Verify password before permanent deletion
                    await showVerifyPasswordDialog(
                      context: context,
                      onVerified: () async {
                        await runWithLoading(context, () async {
                          await FirebaseExams.deleteExam(gradeName, examId);

                          if (context.mounted) {
                            AppSnackBars.showSuccess(
                                context, "تم حذف الامتحان بنجاح");
                            Navigator.pop(context); // Close the Delete Dialog
                          }
                        });
                      },
                    );
                  },
                  child: Text(
                    'تأكيد الحذف',
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