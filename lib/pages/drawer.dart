import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/alert_dialogs/ResetAbscenceMonthDialog.dart';
import 'package:student_management_system/alert_dialogs/Reset_Grade_student_subscriptions.dart';
import 'package:student_management_system/alert_dialogs/add_out_come.dart';
import 'package:student_management_system/alert_dialogs/change_password.dart';
import 'package:student_management_system/alert_dialogs/verifiy_password.dart';
import 'package:student_management_system/firebase/auth_services.dart';
import 'package:student_management_system/provider.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart';
import 'allgrades.dart';
import 'invoices/monthly_invoices_page.dart';
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
          _drawerTile(
            icon: Icons.logout_rounded,
            title: "تسجيل الخروج",
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final teacher =
        Provider.of<TeacherProvider>(context, listen: false).teacher;

    // منطق حساب الأيام المتبقية
    int daysLeft = 0;
    if (teacher?.subscriptionEndTime != null) {
      daysLeft = teacher!.subscriptionEndTime.difference(DateTime.now()).inDays;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // اللوجو مع تأثير بسيط
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              "assets/images/logo.png",
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          // اسم المدرس
          Text(
            teacher?.name ?? "مدير النظام",
            style: GoogleFonts.amiri(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 15),
          // عرض مدة الاشتراك
          if (teacher?.subscriptionEndTime != null)
            Container(
              // حددنا عرض أقصى للـ Container عشان يجبر اللي جواه يلف وينزل سطر جديد
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: daysLeft > 7
                    ? AppColors.primaryDark.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: daysLeft > 7 ? AppColors.primaryDark : Colors.red,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                // بيخلي الصف على قد المحتوى
                crossAxisAlignment: CrossAxisAlignment.center,
                // بيسنتر الأيقونة مع النص
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: daysLeft > 7 ? AppColors.primaryDark : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  // الحل السحري هنا: الـ Flexible بيجبر النص يلتزم بالمساحة المتبقية وينزل لتحت
                  Flexible(
                    child: Text(
                      daysLeft > 0
                          ? "متبقي $daysLeft يوم على انتهاء الاشتراك"
                          : "الاشتراك منتهي",
                      textAlign: TextAlign.start,
                      softWrap: true,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color:
                            daysLeft > 7 ? AppColors.primaryDark : Colors.red,
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
