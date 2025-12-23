import 'package:flutter/material.dart';

import '../../models/student_paid_subscription.dart';
import '../../models/subscription_fee.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart'; // تأكد من استيراد ملف الستايلات الموحد

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

    // تحديد لون المتبقي بناءً على وجود مديونية
    Color remainingColor;
    if (remaining > 0) {
      remainingColor = AppColors.statusLate; // اللون الأصفر/الكهرماني للديون
    } else {
      remainingColor = AppColors.secondaryMain; // اللون الأخضر عند اكتمال الدفع
    }

    // لون حلقة التقدم
    Color progressRingColor =
        ratio >= 1.0 ? AppColors.secondaryMain : AppColors.statusLate;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                // 🔵 دائرة النسبة المئوية
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: ratio,
                        backgroundColor: AppColors.white.withOpacity(0.3),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressRingColor),
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '${(ratio * 100).toInt()}%',
                      style: AppTextStyles.customText(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // 💵 معلومات الاشتراك
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
                      const SizedBox(height: 8),
                      Text(
                        'القيمة المطلوبة: ${total.toStringAsFixed(2)} ج.م',
                        style: AppTextStyles.customText(
                          fontSize: 14,
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        'المدفوع: ${paid.toStringAsFixed(2)} ج.م',
                        style: AppTextStyles.customText(
                          fontSize: 14,
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        'المتبقي: ${remaining.toStringAsFixed(2)} ج.م',
                        style: AppTextStyles.customText(
                          fontSize: 14,
                          fontWeight: remaining > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: remainingColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // 💰 أيقونة العملة
                Icon(
                  Icons.monetization_on,
                  size: 36,
                  color: AppColors.white.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}