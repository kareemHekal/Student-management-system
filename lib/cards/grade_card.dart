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
    const int defaultActionAlpha = 51;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [AppColors.primaryMain, AppColors.secondaryMain],
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
          mainAxisSize: MainAxisSize.min, // لجعل الكرت مرن مع المحتوى
          children: [
            // 1. HEADER (School Icon + Grade Name)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              // توسيط الأيقونة مع النص
              children: [
                Icon(
                  Icons.school,
                  size: 30,
                  color: AppColors.white.withAlpha(204),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    gradeName,
                    // إزالة maxLines للسماح للنص بالتمدد إذا كان الخط كبيراً
                    style: AppTextStyles.customText(
                      fontSize: 18, // تصغير بسيط لضمان المساحة
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.white, thickness: 0.5, height: 1),
            ),

            // 2. ACTIONS ROW (استخدام Wrap بدل Row)
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  alignment: WrapAlignment.spaceAround, // توزيع متساوي
                  runSpacing: 15, // مسافة عمودية في حال نزل الأزرار لسطر جديد
                  spacing: 10, // مسافة أفقية بين الأزرار
                  children: [
                    _buildActionItem(
                      constraints,
                      icon: Icons.delete_forever,
                      label: 'حذف',
                      onPressed: onDelete,
                      color: AppColors.statusAbsent,
                    ),
                    _buildActionItem(
                      constraints,
                      icon: Icons.edit,
                      label: 'تعديل',
                      onPressed: onRename,
                      color: defaultActionColor.withAlpha(defaultActionAlpha),
                    ),
                    _buildActionItem(
                      constraints,
                      icon: Icons.assignment,
                      label: 'الامتحانات',
                      onPressed: onNavigateToExams,
                      color: defaultActionColor.withAlpha(defaultActionAlpha),
                    ),
                    _buildActionItem(
                      constraints,
                      icon: Icons.monetization_on,
                      label: 'الاشتراكات',
                      onPressed: onNavigateToSubscriptions,
                      color: defaultActionColor.withAlpha(defaultActionAlpha),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BoxConstraints constraints, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    // حساب عرض العنصر الواحد ليكون تقريباً ربع العرض المتاح في الحالة الطبيعية
    // ولكن مع حد أدنى لضمان عدم ضغط النصوص
    double itemWidth = (constraints.maxWidth - 30) / 4;
    if (itemWidth < 70) itemWidth = 75; // الحد الأدنى لعرض الزر

    return SizedBox(
      width: itemWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CardHelpers.buildActionCircle(
            icon: icon,
            tooltip: label,
            circleColor: color,
            iconColor: AppColors.textOnDark,
            onPressed: onPressed,
          ),
          const SizedBox(height: 6),
          // استخدام FittedBox هنا يضمن أن الكلمة الطويلة (مثل الاشتراكات)
          // لن تخرج عن حدود الزر بل سيصغر حجمها قليلاً
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.customText(
                fontSize: 11, // حجم خط مناسب للتجاوب
                color: AppColors.white.withAlpha(204),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}