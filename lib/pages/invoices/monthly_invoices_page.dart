import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_management_system/cards/invoices/monthly_invoice_card.dart';
import 'package:student_management_system/home.dart';
import 'package:student_management_system/models/daily_invoice.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'weekly_invoices_page.dart';

class MonthlyReportsPage extends StatefulWidget {
  const MonthlyReportsPage({super.key});

  @override
  State<MonthlyReportsPage> createState() => _MonthlyReportsPageState();
}

class _MonthlyReportsPageState extends State<MonthlyReportsPage> {
  Map<String, List<DailyInvoice>> groupedInvoices = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndGroupInvoices();
  }

  Future<void> _fetchAndGroupInvoices() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('big_invoices').get();
      Map<String, List<DailyInvoice>> tempGroups = {};

      for (var doc in snapshot.docs) {
        DailyInvoice invoice = DailyInvoice.fromJson(doc.data());
        List<String> parts = invoice.date.split('-');

        if (parts.length >= 2) {
          String monthKey = "${parts[0]}-${parts[1]}";
          if (tempGroups[monthKey] == null) tempGroups[monthKey] = [];
          tempGroups[monthKey]!.add(invoice);
        }
      }

      setState(() {
        var sortedKeys = tempGroups.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        groupedInvoices = {for (var key in sortedKeys) key: tempGroups[key]!};
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, "كل الفواتير الشهرية"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: groupedInvoices.keys.length,
              itemBuilder: (context, index) {
                String monthKey = groupedInvoices.keys.elementAt(index);
                List<DailyInvoice> monthInvoices = groupedInvoices[monthKey]!;

                return GestureDetector(
                  child: MonthlyInvoiceCard(
                    monthKey: monthKey,
                    weeklyInvoices: monthInvoices,
                  ),
                );
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(title,
              style: AppTextStyles.customText(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white.withOpacity(0.9))),
        ),
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30))),
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Homescreen()),
            (route) => false),
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
      ),
      backgroundColor: AppColors.primaryMain,
      title: Image.asset("assets/images/logo.png", height: 100, width: 90),
      toolbarHeight: 130,
    );
  }
}