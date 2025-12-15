import 'package:flutter/material.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../theme/colors_app.dart';

// --- Card Helpers (Kept consistent with withAlpha usage) ---
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
    // Define the consistent color for non-delete actions (0.20 opacity -> Alpha 51)
    const Color defaultActionColor = AppColors.white;
    const int defaultActionAlpha = 51; // 0.20 opacity

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          // Dark Gradient Theme
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
              color: AppColors.primaryMain.withAlpha(102), // 0.4 opacity
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
                // School Icon
                Icon(
                  Icons.school,
                  size: 30,
                  color: AppColors.white.withAlpha(204),
                ),
                const SizedBox(width: 16),

                // Grade Name (Title)
                Expanded(
                  child: Text(
                    gradeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(color: AppColors.white, thickness: 0.5, height: 25),

            // 2. ACTIONS ROW (4 items, Delete on the right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Delete (Moved to the start/right in RTL)
                _buildActionItem(
                  icon: Icons.delete_forever,
                  label: 'حذف',
                  onPressed: onDelete,
                  color: AppColors.statusAbsent, // Red background
                ),

                // Edit (Rename Grade)
                _buildActionItem(
                  icon: Icons.edit,
                  label: 'تعديل',
                  onPressed: onRename,
                  color: defaultActionColor
                      .withAlpha(defaultActionAlpha), // Consistent background
                ),

                // Exams (Assignment Icon)
                _buildActionItem(
                  icon: Icons.assignment,
                  label: 'الامتحانات',
                  onPressed: onNavigateToExams,
                  color: defaultActionColor
                      .withAlpha(defaultActionAlpha), // Consistent background
                ),

                // Subscriptions (Monetization Icon)
                _buildActionItem(
                  icon: Icons.monetization_on,
                  label: 'الاشتراكات',
                  onPressed: onNavigateToSubscriptions,
                  color: defaultActionColor
                      .withAlpha(defaultActionAlpha), // Consistent background
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build a column for the action button and its label
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
          // Dark icon for contrast
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.customText(
              fontSize: 12,
              color: AppColors.white.withAlpha(204),
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}
