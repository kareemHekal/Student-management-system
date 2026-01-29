import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/firebase/auth_services.dart';
import 'package:student_management_system/models/admin/bill.dart';
import 'package:student_management_system/models/admin/teacher.dart';
import 'package:student_management_system/provider.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final teacher = Provider.of<TeacherProvider>(context).teacher;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA), // خلفية فاتحة هادية
      appBar: AppBar(
        backgroundColor: AppColors.primaryMain,
        elevation: 0,
        centerTitle: true,
        // زر الرجوع المخصص
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/HomeScreen'),
        ),
        title: Text("الملف الشخصي",
            style: AppTextStyles.customText(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: teacher == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildTopHeader(teacher),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 25),
                        _buildStatsRow(teacher),
                        const SizedBox(height: 20),
                        _buildSectionTitle("حالة الاشتراك الحالي"),
                        _buildSubscriptionCard(teacher),
                        const SizedBox(height: 20),
                        _buildActionButtons(context),
                        const SizedBox(height: 25),
                        _buildSectionTitle("سجل العمليات المادية"),
                        _buildBillsList(teacher.id),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- Header الـ Header مع تدرج ألوان ---
  Widget _buildTopHeader(Teacher teacher) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30, top: 10),
      decoration: const BoxDecoration(
        color: AppColors.primaryMain,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // استبدال الـ Avatar باللوجو
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage('assets/images/logo.png'),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(teacher.name,
                  style: AppTextStyles.customText(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(teacher.phoneNumber,
                  style: AppTextStyles.customText(
                      fontSize: 14, color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }

  // --- كروت الإحصائيات (الطلاب) ---
  Widget _buildStatsRow(Teacher teacher) {
    return Row(
      children: [
        _statCard("الطلاب الحاليين", "${teacher.totalStudents}", Icons.groups,
            AppColors.primaryMain),
        const SizedBox(width: 15),
        _statCard("سعة الباقة", "${teacher.subscriptionTotalStudents}",
            Icons.storage, AppColors.secondaryMain),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(value,
                style: AppTextStyles.customText(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label,
                style: AppTextStyles.customText(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // --- كارت الاشتراك الاحترافي ---
  Widget _buildSubscriptionCard(Teacher teacher) {
    int daysLeft =
        teacher.subscriptionEndTime.difference(DateTime.now()).inDays;
    bool isExpired = daysLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isExpired
            ? AppColors.statusAbsent.withOpacity(0.1)
            : AppColors.secondaryMain.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isExpired ? AppColors.statusAbsent : AppColors.secondaryMain,
            width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isExpired ? "اشتراك منتهي" : "تنتهي الصلاحية خلال:",
                    style: AppTextStyles.customText(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 5),
                Text(isExpired ? "برجاء التجديد" : "$daysLeft يوم",
                    style: AppTextStyles.customText(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isExpired
                            ? AppColors.statusAbsent
                            : AppColors.textPrimary)),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.calendar_today,
                  color: AppColors.textSecondary, size: 20),
              Text(DateFormat('yyyy/MM/dd').format(teacher.subscriptionEndTime),
                  style: AppTextStyles.customText(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  // --- زرار الواتساب (الدعم الفني) ---
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // زرار الواتساب (الدعم)
        Expanded(
          flex: 2,
          child: _buildSmallActionCard(
            onTap: _launchWhatsApp,
            icon: Icons.chat_bubble_outline,
            title: "الدعم الفني",
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        // زرار تسجيل الخروج
        Expanded(
          flex: 1,
          child: _buildSmallActionCard(
            onTap: () => _handleLogout(context),
            icon: Icons.logout,
            title: "خروج",
            color: AppColors.statusAbsent,
          ),
        ),
      ],
    );
  }

// ويدجت موحدة للأزرار عشان الكود يكون نضيف
  Widget _buildSmallActionCard({
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.customText(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- قائمة الفواتير ---
  Widget _buildBillsList(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('bills')
          .orderBy('paidAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        final bills = snapshot.data?.docs ?? [];
        if (bills.isEmpty) return _buildEmptyState();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = Bill.fromJson(
                bills[index].data() as Map<String, dynamic>, bills[index].id);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              // زيادة المسافة بين الكروت
              padding: const EdgeInsets.all(20),
              // تكبير الكارت من الداخل
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السطر الأول: الأيقونة + الاسم + المبلغ
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryMain.withOpacity(0.1),
                        child: const Icon(Icons.receipt_long,
                            color: AppColors.primaryMain, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bill.subscriptionName,
                          style: AppTextStyles.customText(
                            fontWeight: FontWeight.bold,
                            fontSize: 18, // تكبير الخط شوية
                          ),
                        ),
                      ),
                      Text(
                        "${bill.billAmount} ج.م",
                        style: AppTextStyles.customText(
                          color: AppColors.statusPresent,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 0.5), // خط فاصل خفيف
                  ),

                  // السطر الثاني: الوصف
                  if (bill.subscriptionDescription.isNotEmpty) ...[
                    Text(
                      "تفاصيل الاشتراك:",
                      style: AppTextStyles.customText(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.subscriptionDescription,
                      style: AppTextStyles.customText(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // السطر الأخير: التواريخ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDateInfo("تاريخ الدفع", bill.paidAt),
                      _buildDateInfo("تاريخ الانتهاء", bill.expiryDate),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// دالة مساعدة لعرض التواريخ بشكل صغير وأنيق
  Widget _buildDateInfo(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.customText(fontSize: 11, color: Colors.grey),
        ),
        Row(
          children: [
            const Icon(Icons.calendar_month,
                size: 14, color: AppColors.primaryMain),
            const SizedBox(width: 4),
            Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: AppTextStyles.customText(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title,
            style: AppTextStyles.customText(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Icon(Icons.history, size: 50, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        Text("لا يوجد سجل مدفوعات حتى الآن",
            style: AppTextStyles.customText(color: Colors.grey)),
      ],
    );
  }

  void _launchWhatsApp() async {
    const String phoneNumber = "201019229461"; // الرقم بصيغة دولية
    const String message =
        "السلام عليكم، أريد تجديد اشتراك نظام إدارة الطلاب الخاص بي.";
    final Uri url = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تسجيل الخروج",
            style: AppTextStyles.customText(fontWeight: FontWeight.bold)),
        content: Text("هل أنت متأكد أنك تريد تسجيل الخروج؟",
            style: AppTextStyles.customText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء",
                style:
                    AppTextStyles.customText(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusAbsent),
            onPressed: () async {
              await AuthService().signOut();
              Provider.of<TeacherProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            child: Text("خروج",
                style: AppTextStyles.customText(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
