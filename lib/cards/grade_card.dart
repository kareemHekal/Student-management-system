import 'package:flutter/material.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../theme/colors_app.dart';

// --- Card Helpers ---
class _CardHelpers {
  static Widget buildCircle(double size, double opacity) {
    int alpha = (opacity * 255).round();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(alpha),
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget buildActionCircle({
    required IconData icon,
    required Color circleColor,
    required Color iconColor,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
// --- End Card Helpers ---

class GradeActionCard extends StatelessWidget {
  final String gradeName;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onNavigateToExams;
  final VoidCallback onNavigateToSubscriptions;

  const GradeActionCard({
    Key? key,
    required this.gradeName,
    required this.onRename,
    required this.onDelete,
    required this.onNavigateToExams,
    required this.onNavigateToSubscriptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color defaultActionColor = AppColors.white;
    const int defaultActionAlpha = 51; // 0.20 opacity

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              AppColors.primaryMain,
              AppColors.secondaryMain,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryMain.withAlpha(102),
              blurRadius: 14,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (School Icon + Grade Name)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.school,
                  size: 30,
                  color: AppColors.white.withAlpha(204),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    gradeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    // تم التعديل هنا لاستخدام الكلاس الخاص بك
                    style: AppTextStyles.customText(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(color: AppColors.white, thickness: 0.5, height: 25),

            // 2. ACTIONS ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionItem(
                  icon: Icons.delete_forever,
                  label: 'حذف',
                  onPressed: onDelete,
                  color: AppColors.statusAbsent,
                ),
                _buildActionItem(
                  icon: Icons.edit,
                  label: 'تعديل',
                  onPressed: onRename,
                  color: defaultActionColor.withAlpha(defaultActionAlpha),
                ),
                _buildActionItem(
                  icon: Icons.assignment,
                  label: 'الامتحانات',
                  onPressed: onNavigateToExams,
                  color: defaultActionColor.withAlpha(defaultActionAlpha),
                ),
                _buildActionItem(
                  icon: Icons.monetization_on,
                  label: 'الاشتراكات',
                  onPressed: onNavigateToSubscriptions,
                  color: defaultActionColor.withAlpha(defaultActionAlpha),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        _CardHelpers.buildActionCircle(
          icon: icon,
          tooltip: label,
          circleColor: color,
          iconColor: AppColors.textOnDark,
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.customText(
            fontSize: 12,
            color: AppColors.white.withAlpha(204),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}