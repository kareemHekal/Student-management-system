import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../loadingFile/loading_alert/run_with_loading.dart';

class SelectRecipientDialogContent extends StatelessWidget {
  final Future<void> Function() sendMessageToFather;
  final Future<void> Function() sendMessageToMother;
  final Future<void> Function() sendMessageToStudent;

  const SelectRecipientDialogContent({
    super.key,
    required this.sendMessageToFather,
    required this.sendMessageToMother,
    required this.sendMessageToStudent,
  });

  @override
  Widget build(BuildContext context) {
    // This is just the inner body, so no AlertDialog wrapper here!
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        _buildRecipientTile(
          context: context,
          title: 'ولي الأمر (الأب)',
          icon: Icons.hail_rounded,
          color: AppColors.primaryMain,
          onTap: sendMessageToFather,
        ),
        const SizedBox(height: 12),
        _buildRecipientTile(
          context: context,
          title: 'ولي الأمر (الأم)',
          icon: Icons.person_3_rounded,
          color: Colors.pink.shade400,
          onTap: sendMessageToMother,
        ),
        const SizedBox(height: 12),
        _buildRecipientTile(
          context: context,
          title: 'الطالب',
          icon: Icons.school_rounded,
          color: AppColors.secondaryMain,
          onTap: sendMessageToStudent,
        ),
      ],
    );
  }

  Widget _buildRecipientTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.of(context).pop(); // Close the dialog
        await runWithLoading(context, () async {
          await onTap();
        });
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.15)),
          color: color.withOpacity(0.04),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 18,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.customText(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}