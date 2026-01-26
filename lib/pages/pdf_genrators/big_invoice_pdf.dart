import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/models/Invoice.dart';
import 'package:student_management_system/models/payment.dart';

import '../../models/daily_invoice.dart';

class InvoicePdfGenerator {
  // 1. دالة مساعدة لجلب أسماء الاشتراكات دفعة واحدة لتحسين الأداء
  static Future<Map<String, String>> _fetchAllSubscriptionNames(
      List<Invoice> invoices) async {
    Map<String, String> subscriptionNames = {};
    await Future.wait(invoices.map((inv) async {
      try {
        final sub = await FirebaseFunctions.getSubscriptionById(
            inv.grade, inv.subscriptionFeeID);
        subscriptionNames[inv.id] = sub?.subscriptionName ?? "اشتراك عام";
      } catch (e) {
        subscriptionNames[inv.id] = "غير محدد";
      }
    }));
    return subscriptionNames;
  }

  // 2. تنسيق الوقت باللغة العربية
  static String formatTimeArabic(DateTime dateTime) {
    final period = dateTime.hour >= 12 ? 'م' : 'ص';
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  // 3. بناء صف ملخص مخصص (يستخدم في اليوم والشهر)
  static pw.Widget _buildSummaryBox(
      pw.Font font, String title, String income, String outcome, String net) {
    final textStyle = pw.TextStyle(font: font, fontSize: 12);
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(income,
                  style: textStyle.copyWith(
                      color: PdfColors.green900,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('إجمالي الإيرادات : ', style: textStyle),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(outcome,
                  style: textStyle.copyWith(
                      color: PdfColors.red900, fontWeight: pw.FontWeight.bold)),
              pw.Text('إجمالي المصروفات : ', style: textStyle),
            ],
          ),
          pw.Divider(thickness: 1),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(net,
                  style: textStyle.copyWith(
                      color: PdfColors.blue900,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('الصافي النهائي : ', style: textStyle),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📄 تقرير اليوم الواحد
  // ==========================================
  static Future<void> createDailyInvoicePDF(
      DailyInvoice bigInvoice, BuildContext context) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final subscriptionNames =
        await _fetchAllSubscriptionNames(bigInvoice.invoices);

    double totalInc =
        bigInvoice.invoices.fold(0, (sum, item) => sum + item.amount);
    double totalOut =
        bigInvoice.payments.fold(0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Center(
              child: pw.Text('ملخص الحسابات اليومي',
                  style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold))),
          pw.Center(
              child: pw.Text('${bigInvoice.day} | ${bigInvoice.date}',
                  style: pw.TextStyle(font: ttf, fontSize: 14))),
          pw.SizedBox(height: 20),
          _buildSummaryBox(
              ttf,
              "",
              "${totalInc.toStringAsFixed(2)} ج.م",
              "${totalOut.toStringAsFixed(2)} ج.م",
              "${(totalInc - totalOut).toStringAsFixed(2)} ج.م"),
          pw.SizedBox(height: 20),
          pw.Text('تفاصيل الإيرادات:',
              style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
          ...bigInvoice.invoices.map(
              (inv) => _buildInvoiceItem(inv, ttf, subscriptionNames[inv.id]!)),
          if (bigInvoice.payments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('تفاصيل المصروفات:',
                style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
            ...bigInvoice.payments.map((p) => _buildPaymentItem(p, ttf)),
          ]
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ==========================================
  // 📄 تقرير الشهر الكامل
  // ==========================================
  static Future<void> createMonthlyInvoicePDF(
      List<DailyInvoice> monthlyInvoices,
      String monthName,
      BuildContext context) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    List<Invoice> allInvoices = [];
    double totalMonthOut = 0;
    for (var day in monthlyInvoices) {
      allInvoices.addAll(day.invoices);
      totalMonthOut += day.payments.fold(0, (sum, p) => sum + p.amount);
    }

    final subscriptionNames = await _fetchAllSubscriptionNames(allInvoices);
    double totalMonthInc =
        allInvoices.fold(0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Center(
              child: pw.Text('تقرير الحسابات الشهري الشامل',
                  style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold))),
          pw.Center(
              child: pw.Text(monthName,
                  style: pw.TextStyle(font: ttf, fontSize: 14))),
          pw.SizedBox(height: 20),
          _buildSummaryBox(
              ttf,
              "",
              "${totalMonthInc.toStringAsFixed(2)} ج.م",
              "${totalMonthOut.toStringAsFixed(2)} ج.م",
              "${(totalMonthInc - totalMonthOut).toStringAsFixed(2)} ج.م"),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['التاريخ', 'الإيراد', 'المصروف', 'الصافي'],
            data: monthlyInvoices.map((day) {
              double dInc =
                  day.invoices.fold(0, (sum, item) => sum + item.amount);
              double dOut =
                  day.payments.fold(0, (sum, item) => sum + item.amount);
              return [
                day.date,
                dInc.toStringAsFixed(0),
                dOut.toStringAsFixed(0),
                (dInc - dOut).toStringAsFixed(0)
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                font: ttf,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
            cellStyle: pw.TextStyle(font: ttf),
            cellAlignment: pw.Alignment.center,
          ),
          pw.SizedBox(height: 20),
          pw.Text('تفاصيل الإيرادات الشهري:',
              style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
          ...allInvoices.map(
              (inv) => _buildInvoiceItem(inv, ttf, subscriptionNames[inv.id]!)),
          pw.SizedBox(height: 20),
          pw.Text('تفاصيل المصروفات الشهري:',
              style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
          ...monthlyInvoices
              .expand((day) => day.payments)
              .map((p) => _buildPaymentItem(p, ttf)),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // دالة بناء عنصر الفاتورة (للتكرار ومنع تكرار الكود)
  static pw.Widget _buildInvoiceItem(Invoice inv, pw.Font ttf, String subName) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(5)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('المبلغ: ${inv.amount} ج.م',
                  style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700)),
              pw.Text('اسم الاشتراك: $subName',
                  style: pw.TextStyle(
                      font: ttf, fontSize: 9, color: PdfColors.blueGrey800)),
              pw.Text(
                  'الملاحظة: ${inv.description.isEmpty ? "لا يوجد" : inv.description}',
                  style: pw.TextStyle(font: ttf, fontSize: 8)),
              pw.Text(
                  'التاريخ: ${inv.dateTime.toString().split(' ').first} - ${formatTimeArabic(inv.dateTime)}',
                  style: pw.TextStyle(font: ttf, fontSize: 8)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('الطالب: ${inv.studentName}',
                  style: pw.TextStyle(
                      font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('الصف: ${inv.grade}',
                  style: pw.TextStyle(font: ttf, fontSize: 8)),
              pw.Text('الهاتف: ${inv.studentPhoneNumber}',
                  style: pw.TextStyle(font: ttf, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  // دالة بناء عنصر المصروف
  static pw.Widget _buildPaymentItem(Payment p, pw.Font ttf) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(
              color: PdfColors.grey300, style: pw.BorderStyle.dashed)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('المبلغ: ${p.amount} ج.م',
                  style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900)),
              pw.Text('البيان: ${p.description}',
                  style: pw.TextStyle(font: ttf, fontSize: 9)),
            ],
          ),
          pw.Text(
              '${p.dateTime.toString().split(' ').first} - ${formatTimeArabic(p.dateTime)}',
              style: pw.TextStyle(font: ttf, fontSize: 9)),
        ],
      ),
    );
  }

  // ==========================================
  // 📄 تقرير الأسبوع
  // ==========================================
  static Future<void> createWeeklyInvoicePDF(List<DailyInvoice> weeklyInvoices,
      String weekTitle, BuildContext context) async {
    final pdf = pw.Document();

    // تحميل الخط العربي
    final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // تجميع كل الفواتير والمصروفات الخاصة بالأسبوع للحسابات
    List<Invoice> allWeeklyInvoices = [];
    double totalWeekOut = 0;

    for (var day in weeklyInvoices) {
      allWeeklyInvoices.addAll(day.invoices);
      totalWeekOut += day.payments.fold(0, (sum, p) => sum + p.amount);
    }

    // جلب أسماء الاشتراكات
    final subscriptionNames =
        await _fetchAllSubscriptionNames(allWeeklyInvoices);
    double totalWeekInc =
        allWeeklyInvoices.fold(0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // العنوان الرئيسي
          pw.Center(
              child: pw.Text('تقرير الحسابات الأسبوعي',
                  style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold))),
          pw.Center(
              child: pw.Text(weekTitle,
                  style: pw.TextStyle(font: ttf, fontSize: 14))),
          pw.SizedBox(height: 20),

          // صندوق الملخص (إيراد - مصروف - صافي)
          _buildSummaryBox(
              ttf,
              "",
              "${totalWeekInc.toStringAsFixed(2)} ج.م",
              "${totalWeekOut.toStringAsFixed(2)} ج.م",
              "${(totalWeekInc - totalWeekOut).toStringAsFixed(2)} ج.م"),
          pw.SizedBox(height: 20),

          // جدول ملخص الأيام في الأسبوع
          pw.Text('ملخص أيام الأسبوع:',
              style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['اليوم', 'التاريخ', 'الإيراد', 'المصروف', 'الصافي'],
            data: weeklyInvoices.map((day) {
              double dInc =
                  day.invoices.fold(0, (sum, item) => sum + item.amount);
              double dOut =
                  day.payments.fold(0, (sum, item) => sum + item.amount);
              return [
                day.day, // اسم اليوم (السبت، الأحد..)
                day.date,
                dInc.toStringAsFixed(0),
                dOut.toStringAsFixed(0),
                (dInc - dOut).toStringAsFixed(0)
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                font: ttf,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
            cellAlignment: pw.Alignment.center,
          ),

          pw.SizedBox(height: 25),

          // تفاصيل الإيرادات
          pw.Text('تفاصيل فواتير الأسبوع:',
              style: pw.TextStyle(
                  font: ttf,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900)),
          pw.Divider(color: PdfColors.green900),
          ...allWeeklyInvoices.map((inv) => _buildInvoiceItem(
              inv, ttf, subscriptionNames[inv.id] ?? "اشتراك")),

          pw.SizedBox(height: 20),

          // تفاصيل المصروفات
          if (totalWeekOut > 0) ...[
            pw.Text('تفاصيل مصروفات الأسبوع:',
                style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900)),
            pw.Divider(color: PdfColors.red900),
            ...weeklyInvoices
                .expand((day) => day.payments)
                .map((p) => _buildPaymentItem(p, ttf)),
          ],
        ],
      ),
    );

    // عرض معاينة الطباعة أو الحفظ
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}