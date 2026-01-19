import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart'; // Using your snack_bar.dart logic
import 'package:student_management_system/theme/text_style.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import 'verifiy_password.dart';

class DeleteSubscriptionDialog extends StatelessWidget {
  final String gradeName;
  final String id;

  const DeleteSubscriptionDialog({
    super.key,
    required this.gradeName,
    required this.id,
  });

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
            const Icon(Icons.money_off_rounded,
                color: AppColors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              "حذف الاشتراك",
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
              'هل أنت متأكد أنك تريد حذف هذا الاشتراك؟',
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
                color: AppColors.statusAbsent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: AppColors.statusAbsent.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.statusAbsent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'سيتم حذف اسم الاشتراك من جميع الفواتير المرتبطة به.',
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
                    'ملاحظة: ستظل مبالغ الفواتير المسجلة مسبقاً كما هي دون حذف، فقط يتم فك الارتباط بهذا المسمى.',
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
              'يتطلب هذا الإجراء تأكيد كلمة المرور.',
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
                  "تراجع",
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
                onPressed: () async {
                  showVerifyPasswordDialog(
                    context: context,
                    onVerified: () async {
                      await runWithLoading(context, () async {
                        await FirebaseFunctions.deleteSubscriptionFromGrade(
                          gradeName,
                          id,
                        );
                      });

                      if (context.mounted) {
                        Navigator.pop(context); // Close Delete Dialog
                        AppSnackBars.showSuccess(
                            context, "تم حذف الاشتراك بنجاح ✅");
                      }
                    },
                  );
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
  }
}