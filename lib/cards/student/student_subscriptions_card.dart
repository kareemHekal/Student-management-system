import 'package:flutter/material.dart';

import '../../models/student_paid_subscription.dart';
import '../../models/subscription_fee.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart';

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

    // تحديد ألوان الحالة
    Color remainingColor =
        remaining > 0 ? AppColors.statusLate : AppColors.secondaryMain;
    Color progressRingColor =
        ratio >= 1.0 ? AppColors.secondaryMain : AppColors.statusLate;

    return SizedBox(
      // عرض الكارت بالنسبة للشاشة مع ضمان حد أدنى للارتفاع
      width: MediaQuery.of(context).size.width * 0.75,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              // إضافة زخرفة بسيطة ليتماشى مع روح التطبيق
              children: [
                Positioned(
                  top: -15,
                  left: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // 🔵 دائرة النسبة المئوية المتجاوبة
                      _buildProgressCircle(ratio, progressRingColor),

                      const SizedBox(width: 14),

                      // 💵 معلومات الاشتراك (مرنة)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                subscriptionFee.subscriptionName,
                                style: AppTextStyles.customText(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildAmountRow('المطلوب:', total),
                            _buildAmountRow('المدفوع:', paid),
                            _buildAmountRow('المتبقي:', remaining,
                                color: remainingColor, isBold: remaining > 0),
                          ],
                        ),
                      ),

                      // 💰 أيقونة العملة (تختفي في الشاشات الصغيرة جداً لتوفير مساحة)
                      if (MediaQuery.of(context).size.width > 340)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.monetization_on_outlined,
                            size: 28,
                            color: AppColors.white.withOpacity(0.6),
                          ),
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

  Widget _buildProgressCircle(double ratio, Color color) {
    return SizedBox(
      width: 55,
      height: 55,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 5,
          ),
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                '${(ratio * 100).toInt()}%',
                style: AppTextStyles.customText(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount,
      {Color? color, bool isBold = false}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$label ${amount.toStringAsFixed(0)} ج.م',
        style: AppTextStyles.customText(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColors.white.withOpacity(0.85),
        ),
      ),
    );
  }
}