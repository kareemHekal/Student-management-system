import 'package:flutter/material.dart';
import 'package:student_management_system/alert_dialogs/add_edit_subscription_for_grade.dart';
import 'package:student_management_system/alert_dialogs/delete_subscription.dart';

import '../models/subscription_fee.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionFee subscriptionFee;
  final String gradeName;

  const SubscriptionCard({
    super.key,
    required this.subscriptionFee,
    required this.gradeName,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [AppColors.primaryMain, AppColors.secondaryMain],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMain.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // زخارف خلفية متجاوبة
                Positioned(
                  top: -15,
                  right: -15,
                  child: _buildCircle(
                      MediaQuery.of(context).size.width * 0.15, 0.1),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: _buildCircle(
                      MediaQuery.of(context).size.width * 0.25, 0.15),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      // أيقونة الدفع بحجم مرن
                      const Icon(
                        Icons.payments_outlined,
                        size: 32,
                        color: AppColors.white,
                      ),

                      const SizedBox(width: 14),

                      // قسم النصوص (الاسم والمبلغ) محمي بـ Expanded
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                subscriptionFee.subscriptionName,
                                style: AppTextStyles.customText(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${subscriptionFee.subscriptionAmount.toStringAsFixed(0)} ج.م',
                                style: AppTextStyles.customText(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textOnDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // أزرار التحكم
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionCircle(
          icon: Icons.edit_note_rounded,
          circleColor: AppColors.white.withOpacity(0.15),
          iconColor: AppColors.white,
          onPressed: () => showAddOrEditSubscriptionDialog(
            context,
            gradeName,
            subscriptionFee: subscriptionFee,
          ),
        ),
        const SizedBox(width: 8),
        _buildActionCircle(
          icon: Icons.delete_outline_rounded,
          circleColor: AppColors.statusAbsent.withOpacity(0.9),
          iconColor: AppColors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => DeleteSubscriptionDialog(
                gradeName: gradeName,
                id: subscriptionFee.id,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color circleColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}