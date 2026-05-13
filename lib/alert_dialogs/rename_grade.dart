import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import 'verifiy_password.dart';

Future<void> renameGrade({
  required BuildContext context,
  required String oldGrade,
}) async {
  final TextEditingController gradeController =
      TextEditingController(text: oldGrade);
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              const Icon(Icons.edit_note_rounded,
                  color: AppColors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'تغيير اسم الصف',
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
                "أدخل الاسم الجديد للصف الدراسي أدناه:",
                style: AppTextStyles.customText(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: gradeController,
                  autofocus: true,
                  style: AppTextStyles.customText(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'اسم المرحلة الجديد',
                    hintText: 'مثال: الصف الثالث الثانوي',
                    prefixIcon: const Icon(Icons.school_outlined,
                        color: AppColors.primaryMain),
                    filled: true,
                    fillColor: Colors.grey[50],
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                          color: AppColors.primaryMain, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'من فضلك أدخل اسم المرحلة الجديد';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
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
                    'إلغاء',
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
                    if (formKey.currentState!.validate()) {
                      String newGrade = gradeController.text.trim();

                      // Get current grades to prevent duplicates
                      List<String> fetchedGrades =
                          await FirebaseFunctions.getGradesList();

                      if (fetchedGrades.contains(newGrade)) {
                        if (context.mounted) {
                          AppSnackBars.showError(
                              context, "هذا الصف موجود بالفعل!");
                        }
                        return;
                      }

                      // Proceed with password verification
                      if (context.mounted) {
                        final pageContext = context;
                        showVerifyPasswordDialog(
                          context: dialogContext,
                          onVerified: () async {
                            await runWithLoading(dialogContext, () async {
                              await FirebaseFunctions.renameGrade(
                                  oldGrade, newGrade);
                            });
                            if (pageContext.mounted) {
                              Navigator.pop(pageContext);
                              AppSnackBars.showSuccess(
                                  pageContext, "تم تغيير اسم الصف بنجاح ✅");
                            }
                          },
                        );
                      }
                    }
                  },
                  child: Text(
                    'تأكيد',
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