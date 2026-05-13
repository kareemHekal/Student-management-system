import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart'; // Using your custom snackbar logic
import 'package:student_management_system/theme/text_style.dart';

import '../loadingFile/loading_alert/run_with_loading.dart';

class DeleteIncomeBillDialog extends StatelessWidget {
  final String title;
  final String content;
  final Future<void> Function() onConfirm;
  final String cancelButtonText;
  final String confirmButtonText;

  const DeleteIncomeBillDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.cancelButtonText = "إلغاء",
    this.confirmButtonText = "حذف نهائي",
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
            const Icon(Icons.receipt_long_outlined,
                color: AppColors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
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
        children: [
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.statusAbsent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
              border:
                  Border.all(color: AppColors.statusAbsent.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.statusAbsent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content,
                    style: AppTextStyles.customText(
                      color: AppColors.statusAbsent,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "تنبيه: لا يمكن استعادة هذه البيانات بعد الحذف.",
            style: AppTextStyles.customText(
              fontSize: 12,
              color: AppColors.textSecondary.withOpacity(0.7),
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
                  cancelButtonText,
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
                  await runWithLoading(context, () async {
                    await onConfirm();

                    if (context.mounted) {
                      AppSnackBars.showSuccess(context, "تم الحذف بنجاح");
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/HomeScreen",
                        (route) => false,
                      );
                    }
                  });
                },
                child: Text(
                  confirmButtonText,
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