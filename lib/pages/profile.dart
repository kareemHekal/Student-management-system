import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/firebase/auth_services.dart';
import 'package:student_management_system/models/admin/bill.dart';
import 'package:student_management_system/models/admin/boost_subscription.dart';
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
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryMain,
        elevation: 0,
        centerTitle: true,
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
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildTopHeader(teacher),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 25),
                        _buildStatsRow(context, teacher),
                        const SizedBox(height: 25),
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

  // --- Header المطور (Responsive) ---
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
              const SizedBox(width: 15),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacher.name,
                        style: GoogleFonts.cairo(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    Text(teacher.phoneNumber,
                        style: GoogleFonts.cairo(
                            fontSize: 14, color: Colors.white70)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // --- كروت الإحصائيات (Responsive Wrap) ---
  Widget _buildStatsRow(BuildContext context, Teacher teacher) {
    int allowed = teacher.totalAllowedStudents;
    int current = teacher.currentStudentCount;
    bool isOverLimit = current > allowed;

    return Column(
      children: [
        Wrap(
          spacing: 15,
          runSpacing: 15,
          alignment: WrapAlignment.center,
          children: [
            _statCard(
                context,
                "الطلاب الحاليين",
                "$current",
                Icons.groups_rounded,
                isOverLimit ? Colors.red : AppColors.primaryMain),
            _statCard(context, "إجمالي سعة الطلاب", "$allowed",
                Icons.pie_chart_rounded, AppColors.secondaryMain),
          ],
        ),
        if (isOverLimit) _buildOverLimitWarning(current - allowed),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    double screenWidth = MediaQuery.of(context).size.width;
    // إذا كان الخط كبيراً جداً، كل كرت يأخذ سطر كامل
    double width =
        screenWidth > 450 ? (screenWidth - 55) / 2 : screenWidth - 40;

    return Container(
      width: width,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildOverLimitWarning(int extra) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "تنبيه: لديك $extra طالب فوق السعة المتاحة. لن تتمكن من إضافة طلاب جدد حتى تجديد الاشتراك.",
              style: GoogleFonts.cairo(
                  fontSize: 12, color: Colors.red[900], height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // --- قسم الاشتراك (Flexible) ---
  Widget _buildSubscriptionCard(Teacher teacher) {
    int daysLeft =
        teacher.subscriptionEndTime.difference(DateTime.now()).inDays;
    bool isExpired = daysLeft <= 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isExpired ? Colors.red[50] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isExpired ? Colors.red : Colors.grey.shade200,
                width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium,
                  color: isExpired ? Colors.red : Colors.blue, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("الاشتراك الأساسي (سعة: ${teacher.baseStudentLimit})",
                        style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(
                        isExpired
                            ? "منتهي - يرجى التجديد"
                            : "صلاحية التطبيق: $daysLeft يوم",
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isExpired ? Colors.red : Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (teacher.activeBoosts.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...teacher.activeBoosts
              .map((boost) => _buildActiveBoostItem(boost))
              .toList(),
        ],
      ],
    );
  }

  Widget _buildActiveBoostItem(ActiveBoost boost) {
    int daysLeft = boost.expiryDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("زيادة سعة: +${boost.studentAmount} طالب",
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text(
                    "تنتهي في: ${DateFormat('yyyy/MM/dd').format(boost.expiryDate)}",
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.grey[700])),
              ],
            ),
          ),
          FittedBox(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.amber, borderRadius: BorderRadius.circular(8)),
              child: Text("$daysLeft يوم",
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- أزرار العمليات (Responsive Wrap) ---
  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width > 380
              ? (MediaQuery.of(context).size.width - 52) * 0.6
              : double.infinity,
          child: _buildSmallActionCard(
            onTap: _launchWhatsApp,
            icon: Icons.chat_bubble_outline,
            title: "الدعم الفني",
            color: Colors.green,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width > 380
              ? (MediaQuery.of(context).size.width - 52) * 0.35
              : double.infinity,
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

  Widget _buildSmallActionCard(
      {required VoidCallback onTap,
      required IconData icon,
      required String title,
      required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
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
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final bills = snapshot.data?.docs ?? [];
        if (bills.isEmpty) return _buildEmptyState();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = Bill.fromJson(
                bills[index].data() as Map<String, dynamic>, bills[index].id);
            return _buildBillCard(bill);
          },
        );
      },
    );
  }

  Widget _buildBillCard(Bill bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                  backgroundColor: AppColors.primaryMain.withOpacity(0.1),
                  child: const Icon(Icons.receipt_long,
                      color: AppColors.primaryMain)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(bill.subscriptionName,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 16))),
              Text("${bill.billAmount} ج.م",
                  style: GoogleFonts.cairo(
                      color: AppColors.statusPresent,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 25),
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
  }

  Widget _buildDateInfo(String label, DateTime date) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
          Text(DateFormat('yyyy-MM-dd').format(date),
              style:
                  GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title,
            style:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text("لا يوجد سجل مدفوعات حتى الآن",
          style: GoogleFonts.cairo(color: Colors.grey)),
    );
  }

  void _launchWhatsApp() async {
    const String phoneNumber = "201019229461";
    final Uri url = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent("السلام عليكم، أريد الاستفسار عن اشتراك النظام.")}");
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text("خروج", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text("هل تريد تسجيل الخروج؟", style: GoogleFonts.cairo()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await AuthService().signOut();
              Provider.of<TeacherProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            child: const Text("خروج", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}