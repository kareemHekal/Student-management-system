import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'package:student_management_system/theme/snack_bar.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import 'verifiy_password.dart';

class ResetGradeAndStudentSubscriptionsDialog extends StatelessWidget {
  const ResetGradeAndStudentSubscriptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Icon(Icons.warning_rounded, color: AppColors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'إعادة تعيين شاملة',
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
            Text(
              'هل أنت متأكد من حذف كافة البيانات؟',
              style: AppTextStyles.customText(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.statusAbsent,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusAbsent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: AppColors.statusAbsent.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildWarningItem('حذف جميع الاشتراكات المسجلة لكل مرحلة.'),
                  _buildWarningItem('حذف مبالغ التحصيل المالي لكل الطلاب.'),
                  _buildWarningItem('حذف سجلات الحضور والغياب بالكامل.'),
                  _buildWarningItem('حذف كافة الامتحانات ودرجات الطلاب.'),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يتطلب هذا الإجراء الحساس تأكيد كلمة المرور.',
                    style: AppTextStyles.customText(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
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
                  style:
                      AppTextStyles.customText(color: AppColors.textSecondary),
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
                onPressed: () {
                  final parentContext = context;

                  showVerifyPasswordDialog(
                    context: parentContext,
                    onVerified: () async {
                      await runWithLoading(parentContext, () async {
                        try {
                          List<String> fetchedGrades =
                              await FirebaseFunctions.getGradesList();

                          for (final grade in fetchedGrades) {
                            await FirebaseFunctions
                                .resetGradeSubscriptionsAndAbsences(grade);
                          }

                          if (parentContext.mounted) {
                            AppSnackBars.showSuccess(
                                parentContext, "تم تصفير كافة البيانات بنجاح");
                            Navigator.pushNamedAndRemoveUntil(
                                parentContext, "/HomeScreen", (_) => false);
                          }
                        } catch (e) {
                          if (parentContext.mounted) {
                            AppSnackBars.showError(
                                parentContext, "حدث خطأ: $e");
                          }
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
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ",
              style: TextStyle(
                  color: AppColors.statusAbsent, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style:
                  AppTextStyles.customText(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}