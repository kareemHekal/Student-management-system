import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colors_app.dart';
import '../theme/text_style.dart';
import '../Alert dialogs/ResetAbscenceMonthDialog.dart';
import '../Alert dialogs/Reset_Grade_student_subscriptions.dart';
import '../Alert dialogs/add_out_come.dart';
import '../Alert dialogs/change_password.dart';
import '../Alert dialogs/verifiy_password.dart';
import '../constants.dart';
import 'PaymentCheckPage.dart';
import 'allgrades.dart';
import 'invoices page.dart';

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
              MaterialPageRoute(builder: (_) => const Invoicespage()),
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
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Image.asset(
            "assets/images/logo.png",
            height: 110,
            width: 110,
            fit: BoxFit.cover,
          ),
          Text(
            Constants.teacherName,
            style: GoogleFonts.caveat(
              fontWeight: FontWeight.bold,
              fontSize: 50,
              color: AppColors.secondaryMain,
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
