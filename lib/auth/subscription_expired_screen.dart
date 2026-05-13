import 'package:flutter/material.dart';
import 'package:student_management_system/firebase/auth_services.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'package:url_launcher/url_launcher.dart'; // تأكد من إضافة هذه المكتبة في pubspec.yaml

class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  // دالة لفتح الواتساب مباشرة
  void _launchWhatsApp() async {
    const String phoneNumber = "201019229461"; // الرقم بصيغة دولية
    const String message =
        "السلام عليكم، أريد تجديد اشتراك نظام إدارة الطلاب الخاص بي.";
    final Uri url = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // التعامل مع الخطأ إذا لم يكن الواتساب مثبتاً
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // خلفية علوية بسيطة لإعطاء شكل جمالي
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: AppColors.primaryMain.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // اللوجو في الأعلى بدلاً من أيقونة الحظر التقليدية
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, 10))
                      ],
                    ),
                    child: Image.asset("assets/images/logo.png",
                        height: 120, width: 120),
                  ),
                ),
                const SizedBox(height: 40),

                // حالة الحساب
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text("تنبيه: الحساب غير نشط",
                          style: AppTextStyles.customText(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  "عفواً، انتهت صلاحية الوصول",
                  style: AppTextStyles.customText(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMain),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Text(
                  "برجاء التواصل مع الدعم الفني لتجديد اشتراكك أو تفعيل حسابك الجديد لتتمكن من متابعة طلابك وإدارة بياناتك.",
                  style: AppTextStyles.customText(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),

                // أزرار التواصل
                _buildContactButton(
                    context,
                    "تواصل مع الإدارة عبر واتساب",
                    Icons.message,
                    AppColors.secondaryMain, // لون الواتساب الرسمي
                    _launchWhatsApp),

                const SizedBox(height: 20),

                // زر تسجيل الخروج
                TextButton.icon(
                  onPressed: () => AuthService().signOut().then((value) =>
                      Navigator.pushReplacementNamed(context, '/login')),
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.grey, size: 20),
                  label: Text("تسجيل الخروج والعودة لاحقاً",
                      style: AppTextStyles.customText(
                          color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(title,
            style: AppTextStyles.customText(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
      ),
    );
  }
}
