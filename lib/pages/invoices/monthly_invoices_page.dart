import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_management_system/cards/invoices/monthly_invoice_card.dart';
import 'package:student_management_system/home.dart';
import 'package:student_management_system/models/daily_invoice.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';

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
        // تحويل البيانات من Firebase إلى Model
        DailyInvoice invoice = DailyInvoice.fromJson(doc.data());

        // تغيير الـ split ليكون بناءً على '-' بدلاً من '_'
        List<String> parts = invoice.date.split('-');

        if (parts.length >= 2) {
          // إنشاء مفتاح الشهر (السنة - الشهر) مثل: "2025-11"
          String monthKey = "${parts[0]}-${parts[1]}";

          if (tempGroups[monthKey] == null) {
            tempGroups[monthKey] = [];
          }
          tempGroups[monthKey]!.add(invoice);
        }
      }

      setState(() {
        // تحويل الـ Map إلى قائمة مرتبة تنازلياً (الأحدث أولاً)
        var sortedKeys = tempGroups.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        // إعادة بناء Map مرتبة
        groupedInvoices = {for (var key in sortedKeys) key: tempGroups[key]!};
        isLoading = false;
      });
    } catch (e) {
      print("خطأ في جلب البيانات: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30), // الارتفاع الإضافي للنص
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              "كل الفواتير الشهريه ",
              style: AppTextStyles.customText(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const Homescreen(),
              ),
              (route) => false,
            );
          },
          icon:
              const Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
        ),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset(
          "assets/images/logo.png",
          height: 100,
          width: 90,
        ),
        toolbarHeight: 130,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: groupedInvoices.keys.length,
              itemBuilder: (context, index) {
                String monthKey = groupedInvoices.keys.elementAt(index);
                return MonthlyInvoiceCard(
                  monthKey: monthKey,
                  dailyInvoices: groupedInvoices[monthKey]!,
                );
              },
            ),
    );
  }
}
