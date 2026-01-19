import 'package:flutter/material.dart';
import 'package:student_management_system/alert_dialogs/add_edit_subscription_for_grade.dart';
import 'package:student_management_system/alert_dialogs/delete_subscription.dart';

import '../models/subscription_fee.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart'; // استيراد ملف الستايلات الموحد

class SubscriptionCard extends StatelessWidget {
  final SubscriptionFee subscriptionFee;
  final String gradeName;

  const SubscriptionCard(
      {super.key, required this.subscriptionFee, required this.gradeName});

  // Helper method for the decorative background circles
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

  // Helper method for the icon buttons inside circles
  Widget _buildActionCircle({
    required IconData icon,
    required Color circleColor,
    required Color iconColor,
    required VoidCallback onPressed,
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
        icon: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryMain,
                  AppColors.secondaryMain,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMain.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Stack(
              children: [
                // ===== Decorative Circles =====
                Positioned(
                  top: -10,
                  right: -10,
                  child: _buildCircle(60, 0.1),
                ),
                Positioned(
                  bottom: -40,
                  left: -40,
                  child: _buildCircle(100, 0.15),
                ),

                // ===== Card Content =====
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_rounded,
                        size: 38,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 16),

                      // Text section (Subscription Name and Amount)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscriptionFee.subscriptionName,
                              style: AppTextStyles.customText(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${subscriptionFee.subscriptionAmount.toStringAsFixed(2)} ج.م',
                              // تم تغيير العملة للعربية لتناسب RTL
                              style: AppTextStyles.customText(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- ACTION BUTTONS (Edit and Delete) ---
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionCircle(
                            icon: Icons.edit,
                            circleColor: AppColors.white.withOpacity(0.2),
                            // تحسين لون الخلفية للزر
                            iconColor: AppColors.white,
                            onPressed: () {
                              showAddOrEditSubscriptionDialog(
                                context,
                                gradeName,
                                subscriptionFee: subscriptionFee,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildActionCircle(
                            icon: Icons.delete_forever,
                            circleColor: AppColors.statusAbsent
                                .withOpacity(0.8), // لون أحمر أوضح للحذف
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
                      ),
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
}