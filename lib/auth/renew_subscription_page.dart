import 'package:flutter/material.dart';
import 'package:student_management_system/models/admin/subsription.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildModernHeader(),
          _buildCapsuleTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // تاب الباقات الأساسية
                _buildSubscriptionList(
                    stream: FirebaseFunctions.getSubscriptions()),
                // تاب زيادة الطلاب (Boost)
                _buildSubscriptionList(
                    stream: FirebaseFunctions.getBoostSubscriptions()),
                // تاب العروض الخاصة
                _buildSubscriptionList(
                    stream: FirebaseFunctions.getOffersSubscriptions()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primaryMain,
            AppColors.primaryMain.withOpacity(0.8)
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(45)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
                Image.asset('assets/images/logo.png',
                    height: 45, fit: BoxFit.contain),
                const SizedBox(width: 45),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("خطط الاشتراك",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("اختر ما يناسبك لإدارة طلابك باحترافية",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCapsuleTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      height: 55,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorPadding: EdgeInsetsGeometry.symmetric(horizontal: -8),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(colors: [
            AppColors.primaryMain,
            AppColors.primaryMain.withOpacity(0.7)
          ]),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.blueGrey[300],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: "أساسية"),
          Tab(text: "Boost"),
          Tab(text: "عروض"),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList({required Stream<List<Subscription>> stream}) {
    return StreamBuilder<List<Subscription>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        List<Subscription> plans = snapshot.data!;
        // ترتيب تصاعدي حسب عدد الطلاب
        plans.sort((a, b) => a.totalStudents.compareTo(b.totalStudents));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          itemCount: plans.length,
          itemBuilder: (context, index) => _buildPremiumPlanCard(plans[index]),
        );
      },
    );
  }

  Widget _buildPremiumPlanCard(Subscription plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              left: -20,
              top: -20,
              child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryMain.withOpacity(0.03)),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTypeBadge(plan),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${plan.price}",
                              style: TextStyle(
                                  color: AppColors.primaryMain,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          const Padding(
                              padding: EdgeInsets.only(bottom: 4, right: 4),
                              child: Text("ج.م",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(plan.name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text(plan.description,
                      style: TextStyle(
                          color: Colors.blueGrey[400],
                          fontSize: 13,
                          height: 1.4)),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFeatureIcon(
                          Icons.group_rounded, "${plan.totalStudents} طالب"),
                      _buildFeatureIcon(Icons.calendar_today_rounded,
                          "${plan.durationInDays} يوم"),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMain,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      onPressed: () => _confirmPurchase(plan),
                      child: const Text("اشترك الآن",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(Subscription plan) {
    // تحديد النوع بناءً على اسم الـ Collection أو الـ billType داخل الموديل
    String type = plan.subscriptionType.toString().toLowerCase();
    String text = "باقة أساسية";
    Color color = AppColors.primaryMain;

    if (type.contains('boost')) {
      text = "تزويد طلاب";
      color = Colors.orange;
    } else if (type.contains('offers')) {
      text = "عرض لفترة محدودة";
      color = AppColors.secondaryMain;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryMain.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
                fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("لا توجد خطط متوفرة حالياً",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmPurchase(Subscription plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Text("تأكيد طلب الاشتراك",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text("أنت على وشك الاشتراك في ${plan.name} بمبلغ ${plan.price} ج.م",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 15)),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                    child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("رجوع",
                            style: TextStyle(color: Colors.grey)))),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMain,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    onPressed: () {
                      Navigator.pop(context);
                      AppSnackBars.showSuccess(
                          context, "سيتم تحويلك للدفع... مع easy cash 🩵");
                    },
                    child: const Text("تأكيد",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
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
