import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/alert_dialogs/ResetAbscenceMonthDialog.dart';
import 'package:student_management_system/alert_dialogs/Reset_Grade_student_subscriptions.dart';
import 'package:student_management_system/alert_dialogs/add_out_come.dart';
import 'package:student_management_system/alert_dialogs/change_password.dart';
import 'package:student_management_system/alert_dialogs/verifiy_password.dart';
import 'package:student_management_system/provider.dart';

import '../theme/colors_app.dart';
import '../theme/text_style.dart';
import 'allgrades.dart';
import 'invoices/monthly_invoices_page.dart';
import 'profile.dart';
import 'subscription_checker/PaymentCheckPage.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late String date;
  late String day;

  void getCurrentDate() {
    DateTime now = DateTime.now();
    date = now.toIso8601String().substring(0, 10);

    final days = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday'
    };
    day = days[now.weekday] ?? 'Unknown Day';
  }

  @override
  void initState() {
    super.initState();
    getCurrentDate();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _DrawerScrollBehavior(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),
          const Divider(color: AppColors.textOnDark, thickness: 0.5),
          _sectionTitle("الرئيسية"),
          _drawerTile(
            icon: Icons.people_alt_outlined,
            title: "كل الطلاب",
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/StudentsTab',
              (route) => false,
            ),
          ),
          _drawerTile(
            icon: Icons.receipt_long_outlined,
            title: "عرض جميع الفواتير",
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MonthlyReportsPage()),
              (route) => false,
            ),
          ),
          _drawerTile(
            icon: Icons.add_chart_outlined,
            title: "إضافة مصروف",
            onTap: () => showDialog(
              context: context,
              builder: (_) => AddExpenseDialog(
                date: date,
                day: day,
              ),
            ),
          ),
          _drawerTile(
            icon: Icons.school_outlined,
            title: "مراحل الدراسة",
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const Allgrades()),
              (route) => false,
            ),
          ),
          _drawerTile(
            icon: Icons.check_circle_outline,
            title: "مراجعة المدفوعات",
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const PaymentCheckPage()),
              (route) => false,
            ),
          ),
          const Divider(color: AppColors.textOnDark, thickness: 0.5),
          _sectionTitle("الإعدادات"),
          _drawerTile(
            icon: Icons.lock_outline,
            title: "تغيير كلمة المرور",
            onTap: () {
              showVerifyPasswordDialog(
                context: context,
                onVerified: () => showChangePasswordDialog(context),
              );
            },
          ),
          const Divider(color: AppColors.textOnDark, thickness: 0.5),
          _sectionTitle("إجراءات إعادة الضبط", danger: true),
          _drawerTile(
            icon: Icons.person,
            title: " الصفحه الشخصية",
            onTap: () async {
              await Provider.of<TeacherProvider>(context, listen: false)
                  .refreshTeacherData();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherProfilePage(),
                ),
                (route) => false,
              );
            },
          ),
          _drawerTile(
            icon: Icons.restore_page,
            title: "تصفير الغياب (بداية شهر)",
            onTap: () => showDialog(
              context: context,
              builder: (_) => StartNewMonthDialog(),
            ),
          ),
          _drawerTile(
            icon: Icons.restart_alt_outlined,
            title: "بدء ترم جديد",
            onTap: () => showDialog(
              context: context,
              builder: (_) => ResetGradeAndStudentSubscriptionsDialog(),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final teacher =
        Provider.of<TeacherProvider>(context, listen: false).teacher;

    // 1. حسابات الأيام
    int daysLeft = 0;
    if (teacher?.subscriptionEndTime != null) {
      daysLeft = teacher!.subscriptionEndTime.difference(DateTime.now()).inDays;
    }

    // 3. التحقق من وجود بيانات حقيقية (عشان مظهرش عدادات لـ "مدير النظام")
    bool hasRealData = teacher != null && teacher.name != "Studenizer";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // اللوجو
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2),
              ],
            ),
            child: Image.asset("assets/images/logo.png",
                height: 100, width: 100, fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),

          // اسم المدرس
          Text(
            teacher?.name ?? "Studenizer",
            style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: AppColors.primaryDark),
          ),

          // الفراغ والعدادات يظهروا فقط لو فيه بيانات مدرس حقيقية
          if (hasRealData) ...[
            const SizedBox(height: 15),
            // نستخدم FutureBuilder هنا
            FutureBuilder<int>(
              future: teacher.getTotalAllowedStudents(),
              builder: (context, snapshot) {
                int allowed = snapshot.data ?? 0;
                int current = teacher.currentStudentCount;
                double occupancyRatio = allowed > 0 ? current / allowed : 0;
                bool isNearLimit = occupancyRatio >= 0.9;
                bool isOverLimit = current > allowed;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      // كبسولة الأيام
                      _buildHeaderChip(
                        icon: Icons.timer_outlined,
                        label: daysLeft > 0
                            ? "متبقي $daysLeft يوم"
                            : "الاشتراك منتهي",
                        color: daysLeft > 7 ? AppColors.textOnDark : Colors.red,
                      ),

                      // كبسولة عدد الطلاب (ستظهر بعد انتهاء التحميل)
                      _buildHeaderChip(
                        icon: Icons.groups_outlined,
                        label:
                            snapshot.connectionState == ConnectionState.waiting
                                ? "جاري الحساب..."
                                : "الطلاب: $current / $allowed",
                        color: isOverLimit
                            ? Colors.red
                            : (isNearLimit
                                ? Colors.orange
                                : AppColors.textOnDark),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

// ويدجت مساعدة عشان شكل الكبسولات يكون موحد ونظيف
  Widget _buildHeaderChip(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  Widget _sectionTitle(String title, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTextStyles.customText(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: danger
              ? const Color(0xffd63a3a)
              : AppColors.textOnDark.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _drawerTile({
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required VoidCallback onTap,
  }) {
    final Color itemColor = AppColors.textOnDark;
    final Color iconColor = AppColors.secondaryMain;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: iconWidget ??
            (icon != null
                ? Icon(icon, color: iconColor, size: 24)
                : const SizedBox.shrink()),
        title: Text(
          title,
          style: AppTextStyles.customText(
            fontSize: 18,
            color: itemColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: itemColor.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _DrawerScrollBehavior extends ScrollBehavior {
  const _DrawerScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: AppColors.secondaryMain,
      child: child,
    );
  }
}
