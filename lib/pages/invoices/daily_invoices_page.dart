import 'package:flutter/material.dart';
import 'package:student_management_system/cards/invoices/daily_invoice_card.dart';
import 'package:student_management_system/theme/text_style.dart';
import '../../models/daily_invoice.dart';
import '../../theme/colors_app.dart';

class dailyInvoicesPage extends StatelessWidget {
  final String monthTitle;
  final List<DailyInvoice> invoices;

  const dailyInvoicesPage(
      {required this.monthTitle, required this.invoices, super.key});

  @override
  Widget build(BuildContext context) {
    // Sort so latest day is on top
    invoices.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              "فواتير $monthTitle",
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
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          return DailyInvoiceCard(invoice: invoices[index]);
        },
      ),
    );
  }
}