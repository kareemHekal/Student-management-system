import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'package:student_management_system/theme/snack_bar.dart'; // Using your snack_bar logic

import '../loadingFile/loading_alert/run_with_loading.dart';

class RemoveFromGroupsListDialog extends StatelessWidget {
  final String title;
  final String content;
  final Future<void> Function() onConfirm;
  final String cancelButtonText;
  final String confirmButtonText;

  const RemoveFromGroupsListDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.cancelButtonText = "إلغاء",
    this.confirmButtonText = "تأكيد الحذف",
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
          color: AppColors.statusAbsent, // Red for warning/remove
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.group_remove_rounded,
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
                const Icon(Icons.info_outline_rounded,
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
            "تنبيه: سيتم إزالة العضو من هذه المجموعة فوراً.",
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
                  Navigator.pop(context); // Close dialog
                  await runWithLoading(context, () async {
                    await onConfirm();
                    // Optionally show success if context is still valid
                    // AppSnackBars.showSuccess(context, "تمت الإزالة بنجاح");
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