import 'package:flutter/material.dart';
import 'package:student_management_system/models/admin/subsription.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../../firebase/firebase_functions.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // 1. الهيدر المطور مع اللوجو وزر الرجوع
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryMain,
                  AppColors.primaryMain.withOpacity(0.8)
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // إضافة اللوجو هنا
                      Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 48), // لموازنة شكل الهيدر
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "خطط الاشتراك",
                  style: AppTextStyles.customText(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "اختر الباقة المناسبة لإدارة طلابك",
                  style: AppTextStyles.customText(
                      color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // 2. الـ TabBar بستايل Capsule
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: TabBar(
                controller: _tabController,
                indicatorPadding:
                    const EdgeInsets.symmetric(horizontal: -8, vertical: 4),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.primaryMain,
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: AppTextStyles.customText(
                    fontSize: 13, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "باقة أساسية"),
                  Tab(text: "زيادة طلاب (Boost)"),
                ],
              ),
            ),
          ),

          // 3. المحتوى
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubscriptionList(isBoost: false),
                _buildSubscriptionList(isBoost: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList({required bool isBoost}) {
    return StreamBuilder<List<Subscription>>(
      stream: isBoost
          ? FirebaseFunctions.getBoostSubscriptions()
          : FirebaseFunctions.getSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("لا توجد خطط متوفرة حالياً"));
        }

        List<Subscription> plans = snapshot.data!;
        // استبعاد باقة التجربة TzU5UZf5G11q08hSV0SU
        plans =
            plans.where((plan) => plan.id != 'TzU5UZf5G11q08hSV0SU').toList();
        plans.sort((a, b) => a.totalStudents.compareTo(b.totalStudents));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          itemCount: plans.length,
          itemBuilder: (context, index) =>
              _buildPlanCard(plans[index], isBoost),
        );
      },
    );
  }

  Widget _buildPlanCard(Subscription plan, bool isBoost) {
    // تمييز باقة الـ 600 طالب
    bool isPopular = plan.totalStudents == 600;

    // تحديد اللون الأساسي للكارت بناءً على نوع الباقة
    Color themeColor =
        isPopular ? AppColors.secondaryMain : AppColors.primaryMain;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: themeColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // الجزء العلوي (Header الكارت)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPopular)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryMain,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          "الأكثر مبيعاً",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    Text(
                      plan.name,
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${plan.price}",
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text("جنيه مصري",
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          // محتوى الكارت
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildFeatureRow(Icons.people_alt_rounded, "سعة الطلاب",
                    "${plan.totalStudents} طالب", themeColor),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.calendar_month_rounded, "مدة الصلاحية",
                    "${plan.durationInDays} يوم", themeColor),
                const SizedBox(height: 25),

                // زر الاشتراك
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: () => _confirmPurchase(plan, isBoost),
                    child: Text(
                      isPopular ? "اشتراك التميز" : "اختيار الخطة",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ودجت مساعد لصفوف المميزات
  Widget _buildFeatureRow(
      IconData icon, String title, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(title,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  void _confirmPurchase(Subscription plan, bool isBoost) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("تأكيد الاشتراك",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(
                "هل أنت متأكد من الاشتراك في خطة ${plan.name} بمبلغ ${plan.price} ج.م؟"),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("إلغاء"),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMain,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      AppSnackBars.showSuccess(
                          context, "منتظرين رد من Easy Cash 🩵🩵");
                      // _processPayment(plan, isBoost);
                    },
                    child: const Text("تأكيد ودفع",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

// void _processPayment(Subscription plan, bool isBoost) async {
//   showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(child: CircularProgressIndicator()));
//
//   try {
//     if (isBoost) {
//       await FirebaseFunctions.renewBoostSubscription(boostPlan: plan);
//     } else {
//       await FirebaseFunctions.renewBasicSubscription(plan: plan);
//     }
//
//     if (mounted) {
//       Navigator.pop(context); // إغلاق الـ Loading
//       _showSuccessDialog(); // دالة عرض النجاح
//     }
//   } catch (e) {
//     if (mounted) Navigator.pop(context); // إغلاق الـ Loading
//
//     if (e.toString().contains("AUTH_REQUIRED")) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("عفواً، يجب تسجيل الدخول أولاً لإتمام العملية"),
//           backgroundColor: Colors.red,
//         ),
//       );
//       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
// }
//
// void _showSuccessDialog() {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
//           const SizedBox(height: 20),
//           const Text("تم بنجاح!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 10),
//           const Text("تم تفعيل اشتراكك الجديد بنجاح، يمكنك الآن متابعة عملك.", textAlign: TextAlign.center),
//           const SizedBox(height: 30),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMain),
//               onPressed: () => Navigator.pushReplacementNamed(context, '/HomeScreen'),
//               child: const Text("العودة للرئيسية", style: TextStyle(color: Colors.white)),
//             ),
//           )
//         ],
//       ),
//     ),
//   );
// }
}
