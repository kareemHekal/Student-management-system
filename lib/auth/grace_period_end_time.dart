import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';

class GracePeriodAlertScreen extends StatelessWidget {
  final DateTime graceEndDate;

  const GracePeriodAlertScreen({super.key, required this.graceEndDate});

  @override
  Widget build(BuildContext context) {
    // حساب الوقت المتبقي
    final timeLeft = graceEndDate.difference(DateTime.now());
    final days = timeLeft.inDays;
    final hours = timeLeft.inHours % 24;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // لون خلفية هادئ
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. الهيدر العلوي (نفس ستايل Register/Login)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primaryMain,
                    AppColors.primaryMain.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(50),
                ),
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset("assets/images/logo.png", height: 70),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "فترة سماح مؤقتة",
                    style: AppTextStyles.customText(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 2. كارت التنبيه (تداخل سلبي Transform)
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.orangeAccent,
                        size: 50,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "نعتذر عن الإزعاج",
                        style: AppTextStyles.customText(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "لقد انتهى اشتراكك أو تخطيت عدد الطلاب المسموح به. منحناك فترة سماح للمتابعة مؤقتاً.",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.customText(
                          fontSize: 14,
                          color: Colors.grey[600]!,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // صندوق الوقت المتبقي
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_outlined,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 10),
                            Text(
                              "متبقي: $days يوم و $hours ساعة",
                              style: AppTextStyles.customText(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // زرار الدخول
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryMain,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, '/HomeScreen');
                          },
                          child: Text(
                            "المتابعة للرئيسية حالياً",
                            style: AppTextStyles.customText(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. زرار التجديد السريع
            // 3. زرار التجديد السريع (المطور بأيقونة وشكل أوضح)
// نغلفه بـ Material عشان الـ InkWell يشتغل صح

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent, // شفاف عشان ميبوظش الـ UI
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  // لازم نفس ريديس الكونتينر
                  onTap: () {
                    // شلنا الـ replacement عشان يقدر يرجع
                    Navigator.pushNamed(context, "/subscriptionPlansPage");
                  },
                  // استخدمنا Ink بدل Container عشان الـ Splash يظهر فوق اللون
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 15),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMain.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: AppColors.primaryMain.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primaryMain,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          // حماية من الـ Overflow لو الخط كبير
                          child: RichText(
                            text: TextSpan(
                              text: "تريد الاستمرار بلا انقطاع؟ ",
                              style: AppTextStyles.customText(
                                color: Colors.grey[700]!,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "جدد اشتراكك الآن",
                                  style: AppTextStyles.customText(
                                    color: AppColors.primaryMain,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.primaryMain,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
