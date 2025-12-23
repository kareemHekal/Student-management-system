import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_management_system/models/Invoice.dart';
import 'package:student_management_system/models/payment.dart';

import '../../models/big_invoice.dart';

class InvoicePdfGenerator {
  static Future<void> createDailyInvoicePDF(
      BigInvoice bigInvoice, BuildContext context) async {
    final pdf = pw.Document();

    // 🔤 Load Arabic Font
    final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final textStyle = pw.TextStyle(font: ttf, fontSize: 11);
    final headerStyle = pw.TextStyle(
      font: ttf,
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );

    // 🧱 Info Row
    pw.Widget buildInfoRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '$label: ',
              style: textStyle.copyWith(fontWeight: pw.FontWeight.bold),
            ),
            pw.Expanded(
              child: pw.Text(value, style: textStyle),
            ),
          ],
        ),
      );
    }

    String getArabicDayName(String dateStr) {
      try {
        final date = DateTime.parse(dateStr);
        const days = [
          'الاثنين',
          'الثلاثاء',
          'الأربعاء',
          'الخميس',
          'الجمعة',
          'السبت',
          'الأحد',
        ];
        return days[date.weekday - 1];
      } catch (_) {
        return dateStr;
      }
    }

    // =======================
    // 📄 1. SUMMARY PAGE
    // =======================
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf),
        build: (_) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('ملخص الفاتورة الشاملة', style: headerStyle),
                pw.SizedBox(height: 12),
                pw.Divider(),
                buildInfoRow('التاريخ', bigInvoice.date),
                buildInfoRow('اليوم', getArabicDayName(bigInvoice.date)),
                pw.Divider(),
              ],
            ),
          ),
        ),
      ),
    );

    // =======================
    // 💰 2. INCOME SECTION
    // =======================
    if (bigInvoice.invoices.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf),
          textDirection: pw.TextDirection.rtl,
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'الإيرادات (المبالغ المستلمة)',
                style: headerStyle,
              ),
              pw.Divider(),
            ],
          ),
          build: (_) => bigInvoice.invoices.map((inv) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildInfoRow('الطالب', inv.studentName ?? 'غير مسجل'),
                  buildInfoRow('المرحلة', inv.grade ?? 'غير محدد'),
                  buildInfoRow(
                      'المبلغ', '${inv.amount.toStringAsFixed(2)} ج.م'),
                  buildInfoRow('الوصف', inv.description ?? 'لا يوجد'),
                  buildInfoRow(
                      'التاريخ', inv.dateTime.toString().split(' ').first),
                  buildInfoRow('الوقت', formatTimeArabic(inv.dateTime)),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    // =======================
    // 💸 3. OUTCOME SECTION
    // =======================
    if (bigInvoice.payments.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf),
          textDirection: pw.TextDirection.rtl,
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('المصروفات', style: headerStyle),
              pw.Divider(),
            ],
          ),
          build: (_) => bigInvoice.payments.map((payment) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey300,
                  style: pw.BorderStyle.dashed,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildInfoRow(
                      'المبلغ', '${payment.amount.toStringAsFixed(2)} ج.م'),
                  buildInfoRow('الوصف', payment.description ?? 'لا يوجد'),
                  buildInfoRow(
                      'التاريخ', payment.dateTime.toString().split(' ').first),
                  buildInfoRow('الوقت', formatTimeArabic(payment.dateTime)),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
    );
  }

  // ⏰ Arabic Time Format
  static String formatTimeArabic(DateTime dateTime) {
    final period = dateTime.hour >= 12 ? 'م' : 'ص';
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;

    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  static Future<void> createMonthlyInvoicePDF(List<BigInvoice> monthlyInvoices,
      String monthName, BuildContext context) async {
    final pdf = pw.Document();

    // 🔤 Load Arabic Font
    final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final textStyle = pw.TextStyle(font: ttf, fontSize: 11);
    final headerStyle = pw.TextStyle(
      font: ttf,
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );

    // حساب الإجماليات للشهر بالكامل
    double totalMonthIncome = 0;
    double totalMonthOutcome = 0;

    for (var daily in monthlyInvoices) {
      for (var inv in daily.invoices) {
        totalMonthIncome += inv.amount;
      }
      for (var payment in daily.payments) {
        totalMonthOutcome += payment.amount;
      }
    }
    double totalMonthNet = totalMonthIncome - totalMonthOutcome;

    // 🧱 Info Row Helper
    pw.Widget buildSummaryRow(
      PdfColor? color,
      String label,
      String value,
    ) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(value,
                style: textStyle.copyWith(
                    color: color, fontWeight: pw.FontWeight.bold)),
            pw.Text('$label : ', style: textStyle),
          ],
        ),
      );
    }

    // =======================
    // 📄 1. MONTHLY SUMMARY PAGE
    // =======================
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf),
        build: (_) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Text('تقرير الحسابات الشهري', style: headerStyle)),
              pw.Center(
                  child: pw.Text(monthName,
                      style: textStyle.copyWith(fontSize: 14))),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  children: [
                    buildSummaryRow(PdfColors.green900, 'إجمالي إيرادات الشهر',
                        '${totalMonthIncome.toStringAsFixed(2)} ج.م'),
                    buildSummaryRow(PdfColors.red900, 'إجمالي مصروفات الشهر',
                        '${totalMonthOutcome.toStringAsFixed(2)} ج.م'),
                    pw.Divider(),
                    buildSummaryRow(
                      PdfColors.blue900,
                      'صافي الربح النهائي',
                      '${totalMonthNet.toStringAsFixed(2)} ج.م',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('تفاصيل الأيام المرفقة في التقرير:',
                  style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              // جدول بسيط للأيام
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
                    (dInc - dOut).toStringAsFixed(0),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey700),
                cellStyle: pw.TextStyle(font: ttf),
                cellAlignment: pw.Alignment.center,
              ),
            ],
          ),
        ),
      ),
    );

    // ==========================================
    // 💰 2. DETAILED INCOME (ALL MONTH)
    // ==========================================
    List<Invoice> allInvoices = [];
    for (var day in monthlyInvoices) {
      allInvoices.addAll(day.invoices);
    }

    if (allInvoices.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf),
          textDirection: pw.TextDirection.rtl,
          header: (context) => pw.Column(children: [
            pw.Text('تفاصيل جميع إيرادات الشهر', style: headerStyle),
            pw.Divider(),
          ]),
          build: (context) => allInvoices.map((inv) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('المبلغ: ${inv.amount} ج.م',
                              style: pw.TextStyle(
                                  color: PdfColors.green600,
                                  font: ttf,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              'الملاحظه: ${(inv.description == "") ? "لا يوجد" : inv.description}',
                              style: pw.TextStyle(font: ttf, fontSize: 9)),
                          pw.Text(
                            'التاريخ: ${inv.dateTime.toString().split(' ').first} - الوقت: ${formatTimeArabic(inv.dateTime)}',
                            style: textStyle,
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('الطالب: ${inv.studentName}',
                              style: textStyle),
                          pw.Text('الصف: ${inv.grade}',
                              style: pw.TextStyle(fontSize: 8)),
                          pw.Text('رقم الهاتف: ${inv.studentPhoneNumber}',
                              style: pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    // ==========================================
    // 💸 3. DETAILED OUTCOME (ALL MONTH)
    // ==========================================
    List<Payment> allPayments = [];
    for (var day in monthlyInvoices) {
      allPayments.addAll(day.payments);
    }

    if (allPayments.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf),
          textDirection: pw.TextDirection.rtl,
          header: (context) => pw.Column(children: [
            pw.Text('تفاصيل جميع مصروفات الشهر', style: headerStyle),
            pw.Divider(),
          ]),
          build: (context) => allPayments.map((payment) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColors.grey300, style: pw.BorderStyle.dashed),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('المبلغ: ${payment.amount} ج.م',
                          style: pw.TextStyle(
                              font: ttf,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red900)),
                      pw.Text(
                        'التاريخ: ${payment.dateTime.toString().split(' ').first} - الوقت: ${formatTimeArabic(payment.dateTime)}',
                        style: textStyle,
                      ),
                    ],
                  ),
                  pw.Text(
                      'الملاحظه: ${(payment.description == "") ? "لا يوجد" : payment.description}',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
