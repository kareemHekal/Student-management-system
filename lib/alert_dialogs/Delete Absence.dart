import 'package:flutter/material.dart';

import '../../loadingFile/loading_alert/run_with_loading.dart';
import '../../theme/colors_app.dart';
import '../../theme/snack_bar.dart';
import '../../theme/text_style.dart';

class DeleteConfirmationDialogContent extends StatefulWidget {
  final Future<void> Function() onConfirm;

  const DeleteConfirmationDialogContent({
    super.key,
    required this.onConfirm,
  });

  @override
  State<DeleteConfirmationDialogContent> createState() =>
      _DeleteConfirmationDialogContentState();
}

class _DeleteConfirmationDialogContentState
    extends State<DeleteConfirmationDialogContent> {
  bool isProcessing = false;

  Future<void> _handleDelete() async {
    setState(() {
      isProcessing = true;
    });

    try {
      await widget.onConfirm();

      if (mounted) {
        AppSnackBars.showSuccess(context, "تم حذف الغياب بنجاح!");
      }
    } catch (e) {
      if (mounted) {
        AppSnackBars.showError(context, "فشل في عملية الحذف");
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titlePadding: EdgeInsets.zero,

      // ===== Header =====
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
            const Icon(Icons.delete_sweep_rounded, color: AppColors.white),
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

      // ===== Content =====
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Icon(
            Icons.warning_amber_rounded,
            size: 50,
            color: AppColors.statusAbsent.withOpacity(0.8),
          ),
          const SizedBox(height: 15),
          Text(
            "هل أنت متأكد من حذف هذا الغياب؟",
            textAlign: TextAlign.center,
            style: AppTextStyles.customText(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "لا يمكن التراجع عن هذه الخطوة بعد التنفيذ.",
            textAlign: TextAlign.center,
            style: AppTextStyles.customText(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),

      // ===== Actions =====
      actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      actions: [
        Row(
          children: [
            // Cancel
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style: AppTextStyles.customText(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Delete
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusAbsent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        await runWithLoading(
                          context,
                          () async => await _handleDelete(),
                        );
                      },
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'حذف الآن',
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
