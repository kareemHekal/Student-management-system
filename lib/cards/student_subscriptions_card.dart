import 'package:flutter/material.dart';

import '../models/student_paid_subscription.dart';
import '../models/subscription_fee.dart';
import '../theme/colors_app.dart';

// Assuming _CardHelpers is available for visual consistency,
// though not strictly needed here as we use explicit styling.

class StudentSubscriptionsCard extends StatelessWidget {
  final StudentPaidSubscriptions? studentPaidSubscription;
  final SubscriptionFee subscriptionFee;

  const StudentSubscriptionsCard({
    Key? key,
    required this.studentPaidSubscription,
    required this.subscriptionFee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double paid = studentPaidSubscription?.paidAmount ?? 0;
    final double total = subscriptionFee.subscriptionAmount;
    final double ratio = total == 0 ? 0 : paid / total;
    final double remaining = (total - paid).clamp(0, double.infinity);

    // Dynamic color for the remaining amount based on payment status
    Color remainingColor;
    if (remaining > 0) {
      remainingColor = AppColors.statusLate; // Yellow/Amber for debt
    } else {
      remainingColor = AppColors.secondaryMain; // Green/Success for fully paid
    }

    // Dynamic color for the progress ring
    Color progressRingColor =
        ratio >= 1.0 ? AppColors.secondaryMain : AppColors.statusLate;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Directionality(
        textDirection: TextDirection.rtl, // Ensure RTL compatibility
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22), // Consistent radius
            // Standard Dark Gradient Theme
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
                color: AppColors.primaryMain.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 🔵 Circle showing percentage paid (Themed)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: ratio,
                        backgroundColor: AppColors.white.withOpacity(0.3),
                        // Light background for contrast
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressRingColor),
                        // Dynamic color
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '${(ratio * 100).toInt()}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white), // White text
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // 💵 Subscription info (Themed)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Align to RTL start (right)
                    children: [
                      Text(
                        subscriptionFee.subscriptionName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white), // White text
                      ),
                      const SizedBox(height: 8),
                      // Info details aligned to start
                      Text(
                        'القيمة المطلوبة: ${total.toStringAsFixed(2)} ج.م',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white.withOpacity(0.8)),
                      ),
                      Text(
                        'المدفوع: ${paid.toStringAsFixed(2)} ج.م',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white.withOpacity(0.8)),
                      ),
                      Text(
                        'المتبقي: ${remaining.toStringAsFixed(2)} ج.م',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: remaining > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: remainingColor), // Highlight remaining
                      ),
                    ],
                  ),
                ),

                // 💰 Money icon (Themed)
                Icon(
                  Icons.monetization_on,
                  size: 36,
                  color: AppColors.white.withOpacity(0.8), // Light icon color
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}