import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'package:student_management_system/theme/snack_bar.dart'; // Using your snack_bar.dart

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import 'verifiy_password.dart';

void DeleteGradeDialog(BuildContext context, String gradeToDelete) {
  showDialog(
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
              const Icon(Icons.delete_forever,
                  color: AppColors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                "حذف الصف الدراسي",
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
            children: [
              const SizedBox(height: 15),
              Text(
                'هل أنت متأكد أنك تريد حذف الصف "$gradeToDelete"؟',
                textAlign: TextAlign.center,
                style: AppTextStyles.customText(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.statusAbsent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: AppColors.statusAbsent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.statusAbsent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سيتم حذف جميع الطلاب المنتمين لهذا الصف نهائيًا.',
                            style: AppTextStyles.customText(
                              color: AppColors.statusAbsent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '💡 نصيحة: إذا كنت تريد تغيير الاسم فقط، استخدم أيقونة التعديل ✏️ لتجنب فقدان البيانات.',
                      style: AppTextStyles.customText(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'هذا الإجراء لا يمكن التراجع عنه مطلقاً.',
                style: AppTextStyles.customText(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: 12,
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
                    showVerifyPasswordDialog(
                      context: context,
                      onVerified: () async {
                        await runWithLoading(context, () async {
                          await FirebaseFunctions.deleteGradeFromList(
                              gradeToDelete);
                        });

                        if (context.mounted) {
                          Navigator.pop(context); // Close Delete Dialog
                          AppSnackBars.showSuccess(
                              context, "تم حذف الصف الدراسي بنجاح");
                        }
                      },
                    );
                  },
                  child: Text(
                    "حذف نهائي",
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