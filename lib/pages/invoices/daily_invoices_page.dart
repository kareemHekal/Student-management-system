import 'package:flutter/material.dart';
import 'package:student_management_system/cards/invoices/daily_invoice_card.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../../models/big_invoice.dart';
import '../../theme/colors_app.dart';

class dailyInvoicesPage extends StatelessWidget {
  final String monthTitle;
  final List<BigInvoice> invoices;

  const dailyInvoicesPage(
      {required this.monthTitle, required this.invoices, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // الحل: استخدام PreferredSize للسماح بوضع النص في الـ bottom
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30), // الارتفاع الإضافي للنص
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              "الفواتير اليومية لشهر : $monthTitle",
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
            Navigator.pop(context);
          },
          // قمت بتغيير اللون للأبيض ليظهر بوضوح فوق اللون الأساسي، أو اتركه كما تحب
          icon:
              const Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
        ),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset(
          "assets/images/logo.png",
          height: 90,
          width: 80,
        ),
        toolbarHeight:
            140, // زدت الارتفاع قليلاً ليستوعب اللوجو والنص معاً براحة
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
