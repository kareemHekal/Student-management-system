import 'package:flutter/material.dart';
import 'package:student_management_system/cards/invoices/weekly_invoices_card.dart';
import 'package:student_management_system/models/daily_invoice.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'daily_invoices_page.dart';

class WeeklyReportsPage extends StatelessWidget {
  final String monthTitle;
  final List<DailyInvoice> weeklyInvoices;

  const WeeklyReportsPage(
      {required this.monthTitle, required this.weeklyInvoices, super.key});

  @override
  Widget build(BuildContext context) {
    // 1. تجميع الفواتير في أسابيع
    Map<String, List<DailyInvoice>> weeklyGroups = {};

    for (var invoice in weeklyInvoices) {
      DateTime date = DateTime.parse(invoice.date);
      int weekNum = ((date.day - 1) / 7).floor() + 1;
      String weekKey = "الأسبوع $weekNum";

      if (weeklyGroups[weekKey] == null) {
        weeklyGroups[weekKey] = [];
      }
      weeklyGroups[weekKey]!.add(invoice);
    }

    // 2. ترتيب الأسابيع نفسها تنازلياً (الأسبوع 4 يظهر قبل الأسبوع 1)
    var sortedWeeks = weeklyGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              "تقارير أسابيع شهر: $monthTitle",
              style: AppTextStyles.customText(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white.withOpacity(0.9)),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30))),
        centerTitle: true,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.secondaryMain)),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset("assets/images/logo.png", height: 90, width: 80),
        toolbarHeight: 140,
      ),
      body: ListView.builder(
        itemCount: sortedWeeks.length,
        itemBuilder: (context, index) {
          String weekKey = sortedWeeks[index];

          List<DailyInvoice> currentWeekInvoices = weeklyGroups[weekKey]!;
          currentWeekInvoices.sort((a, b) => b.date.compareTo(a.date));
          // ------------------------------------------

          return WeeklyInvoiceCard(
            weekTitle: "$weekKey ($monthTitle)",
            dailyInvoices: currentWeekInvoices,
          );
        },
      ),
    );
  }
}
