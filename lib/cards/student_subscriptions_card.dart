import 'package:flutter/material.dart';

import '../models/student_paid_subscription.dart';
import '../models/subscription_fee.dart';
import '../theme/colors_app.dart';

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

    // 🧩 The card defines its own width here:
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7, // responsive width
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppColors.secondaryMain, AppColors.secondaryMain],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryMain.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 🔵 Circle showing percentage paid
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.secondaryMain.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondaryMain),
                      strokeWidth: 6,
                    ),
                  ),
                  Text(
                    '${(ratio * 100).toInt()}%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryMain),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // 💵 Subscription info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      subscriptionFee.subscriptionName,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryMain),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'القيمة المطلوبة: ${total.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.primaryMain),
                        ),
                        Text(
                          'المدفوع: ${paid.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.primaryMain),
                        ),
                        Text(
                          'المتبقي: ${remaining.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.primaryMain),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 💰 Money icon
              Icon(
                Icons.monetization_on,
                size: 36,
                color: AppColors.secondaryMain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
