import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/firebase/auth_services.dart';
import 'package:student_management_system/models/admin/bill.dart';
import 'package:student_management_system/models/admin/teacher.dart';
import 'package:student_management_system/provider.dart';
import 'package:student_management_system/theme/colors_app.dart';
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/HomeScreen'),
        ),
        title: Text("لوحة التحكم والاشتراك",
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: teacher == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<int>>(
              // جلب الليمت الأساسي والإجمالي معاً لتفصيل العرض
              future: Future.wait([
                teacher.getBaseStudentLimit(),
                teacher.getTotalAllowedStudents(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final baseLimit = snapshot.data?[0] ?? 0;
                final totalAllowed = snapshot.data?[1] ?? 0;
                int current = teacher.currentStudentCount;
                bool isOverLimit = current > totalAllowed;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildTopHeader(
                          teacher, totalAllowed, current, isOverLimit),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isOverLimit)
                              _buildOverLimitWarning(current - totalAllowed),
                            const SizedBox(height: 20),
                            _buildSectionTitle("تفاصيل سعة الطلاب"),
                            _buildDetailedCapacityCard(
                                teacher, baseLimit, totalAllowed),
                            const SizedBox(height: 25),
                            _buildSectionTitle("حالة الصلاحية الزمنية"),
                            _buildTimelineCard(teacher),
                            const SizedBox(height: 25),
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
                );
              },
            ),
    );
  }

  Widget _buildTopHeader(
      Teacher teacher, int allowed, int current, bool isOverLimit) {
    double progress = allowed > 0 ? current / allowed : 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30, top: 10, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryMain,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacher.name,
                        style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    Text(teacher.phoneNumber,
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _buildUsageBar(current, allowed, progress, isOverLimit),
        ],
      ),
    );
  }

  Widget _buildUsageBar(
      int current, int allowed, double progress, bool isOverLimit) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("استهلاك السعة الكلية",
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
            Text("$current / $allowed طالب",
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress > 1 ? 1 : progress,
            minHeight: 8,
            backgroundColor: Colors.white24,
            color: isOverLimit
                ? Colors.redAccent
                : (progress > 0.85 ? Colors.orangeAccent : Colors.greenAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildOverLimitWarning(int extra) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "تنبيه: لديك $extra طالب فوق السعة المتاحة. لن تتمكن من إضافة طلاب جدد حالياً.",
              style: GoogleFonts.cairo(
                  fontSize: 11, color: Colors.red[900], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // الكارت الجديد الذي يفصل بين الليمت الأساسي والإجمالي
  Widget _buildDetailedCapacityCard(
      Teacher teacher, int baseLimit, int totalAllowed) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          _capacityItem("الحد الأساسي (الاشتراك الحالي)", "$baseLimit",
              Icons.assignment_rounded, Colors.blue),
          const SizedBox(height: 10),
          if (teacher.activeBoosts.isNotEmpty) ...[
            ...teacher.activeBoosts.map((boost) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _capacityItem("زيادة سعة (Boost)",
                      "+${boost.studentAmount}", Icons.bolt, Colors.amber),
                )),
            const Divider(height: 25),
          ],
          _capacityItem("إجمالي السعة المتاحة", "$totalAllowed",
              Icons.groups_rounded, AppColors.primaryMain,
              isBold: true),
        ],
      ),
    );
  }

  Widget _capacityItem(String title, String value, IconData icon, Color color,
      {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: isBold ? Colors.black : Colors.grey[700],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTimelineCard(Teacher teacher) {
    DateTime now = DateTime.now();
    int totalDays = teacher.subscriptionEndTime.difference(now).inDays;
    bool isExpired = totalDays <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isExpired
            ? const LinearGradient(colors: [Color(0xffFFF1F0), Colors.white])
            : const LinearGradient(colors: [Color(0xffF0F7FF), Colors.white]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isExpired ? Colors.red.shade100 : Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  color: isExpired ? Colors.red : AppColors.primaryMain),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("إجمالي صلاحية التطبيق",
                        style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(
                        isExpired
                            ? "متوقف حالياً"
                            : "ينتهي في ${DateFormat('yyyy/MM/dd').format(teacher.subscriptionEndTime)}",
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: isExpired ? Colors.red : AppColors.primaryMain,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(isExpired ? "منتهي" : "$totalDays يوم",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          _buildActiveBillsTimeline(teacher.id),
        ],
      ),
    );
  }

  Widget _buildActiveBillsTimeline(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('bills')
          .where('expiryDate', isGreaterThan: DateTime.now().toIso8601String())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final activeBills = snapshot.data!.docs
            .map((d) => Bill.fromJson(d.data() as Map<String, dynamic>, d.id))
            .toList();

        if (activeBills.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("الباقات الفعالة ومواعيد انتهائها:",
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...activeBills.map((bill) => Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bill.billType == 'basic'
                                  ? Colors.blue
                                  : Colors.amber)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bill.billType == 'basic'
                              ? "${bill.subscriptionName} (الأساسي: ${bill.baseStudentLimit} ط)"
                              : "${bill.subscriptionName} (زيادة: +${bill.boostAmount} ط)",
                          style: GoogleFonts.cairo(fontSize: 11),
                        ),
                      ),
                      Text(
                        "تنتهي: ${DateFormat('MM/dd').format(bill.expiryDate)}",
                        style: GoogleFonts.cairo(
                            fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _actionBtn("الدعم الفني", Icons.support_agent, Colors.green,
              _launchWhatsApp),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: _actionBtn("خروج", Icons.logout_rounded, Colors.redAccent,
              () => _handleLogout(context)),
        ),
      ],
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsList(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('bills')
          .orderBy('paidAt', descending: true)
          .limit(10)
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: bill.billType == 'basic'
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.amber.withOpacity(0.1),
              child: Icon(bill.billType == 'basic' ? Icons.star : Icons.bolt,
                  size: 18,
                  color:
                      bill.billType == 'basic' ? Colors.blue : Colors.amber)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.subscriptionName,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(DateFormat('yyyy-MM-dd').format(bill.paidAt),
                    style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Text("${bill.billAmount} ج.م",
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, color: AppColors.statusPresent)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primaryDark)));
  }

  Widget _buildEmptyState() => Center(
      child: Text("لا توجد فواتير سابقة",
          style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)));

  void _launchWhatsApp() async {
    final Uri url = Uri.parse(
        "https://wa.me/201019229461?text=${Uri.encodeComponent("السلام عليكم، أحتاج مساعدة في حسابي.")}");
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("تسجيل الخروج",
            style:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("هل أنت متأكد من رغبتك في الخروج؟",
            style: GoogleFonts.cairo(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("إلغاء", style: GoogleFonts.cairo(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
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