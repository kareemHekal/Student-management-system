import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/Invoice.dart';
import '../../models/Studentmodel.dart';
import '../../models/absence_model.dart';
import '../../models/subscription_fee.dart';

bool _isArabic(String? text) {
  if (text == null || text.isEmpty) return false;
  final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
  return arabicRegex.hasMatch(text);
}

pw.Widget localizedText(String text, pw.Font font,
    {double size = 12, pw.FontWeight? fontWeight, PdfColor? color}) {
  return pw.Directionality(
    textDirection:
        _isArabic(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
      ),
    ),
  );
}

String getArabicWeekdayName(String englishDay) {
  switch (englishDay.toLowerCase()) {
    case 'monday':
      return 'الاثنين';
    case 'tuesday':
      return 'الثلاثاء';
    case 'wednesday':
      return 'الأربعاء';
    case 'thursday':
      return 'الخميس';
    case 'friday':
      return 'الجمعة';
    case 'saturday':
      return 'السبت';
    case 'sunday':
      return 'الأحد';
    default:
      return englishDay;
  }
}

String getArabicWeekday(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return "الاثنين";
    case DateTime.tuesday:
      return "الثلاثاء";
    case DateTime.wednesday:
      return "الأربعاء";
    case DateTime.thursday:
      return "الخميس";
    case DateTime.friday:
      return "الجمعة";
    case DateTime.saturday:
      return "السبت";
    case DateTime.sunday:
      return "الأحد";
    default:
      return "-";
  }
}

Future<Uint8List> generateFullStudentPdf({
  required Studentmodel student,
  required List<Invoice> invoices,
  required Map<String, SubscriptionFee> subscriptionFees,
}) async {
  final pdf = pw.Document();
  final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) {
        final List<pw.Widget> content = [];

        // ===== معلومات الطالب =====
        content.add(localizedText('معلومات الطالب', ttf,
            size: 20, fontWeight: pw.FontWeight.bold));
        content.add(pw.SizedBox(height: 10));
        content.add(localizedText('الاسم: ${student.name ?? "-"}', ttf));
        content.add(localizedText('الصف: ${student.grade ?? "-"}', ttf));
        content.add(localizedText('الجنس: ${student.gender ?? "-"}', ttf));
        content.add(
            localizedText('رقم الهاتف: ${student.phoneNumber ?? "-"}', ttf));
        content.add(
            localizedText('هاتف الأم: ${student.motherPhone ?? "-"}', ttf));
        content.add(
            localizedText('هاتف الأب: ${student.fatherPhone ?? "-"}', ttf));
        content.add(pw.SizedBox(height: 10));

        // ===== المجموعات =====
        content.add(localizedText('المجموعات', ttf,
            size: 18, fontWeight: pw.FontWeight.bold));
        if (student.hisGroups != null && student.hisGroups!.isNotEmpty) {
          for (var group in student.hisGroups!) {
            content.add(localizedText(
                'الصف: ${group.grade ?? "-"} - الأيام: ${group.days ?? "-"}',
                ttf));
          }
        } else {
          content.add(localizedText('لا توجد مجموعات', ttf));
        }
        content.add(pw.SizedBox(height: 10));

        // ===== الغياب والحضور =====
        content.add(localizedText('الغياب والحضور', ttf,
            size: 18, fontWeight: pw.FontWeight.bold));

        // إضافة "الشهر الحالي"
        final allMonths = <AbsenceModel>[
          AbsenceModel(
            monthName: "الشهر الحالي",
            attendedDays: student.countingAttendedDays ?? [],
            absentDays: student.countingAbsentDays ?? [],
          ),
        ];

        if (student.absencesNumbers != null) {
          allMonths.addAll(student.absencesNumbers!);
        }

        if (allMonths.isNotEmpty) {
          for (var month in allMonths) {
            content.add(localizedText(month.monthName, ttf,
                size: 16, fontWeight: pw.FontWeight.bold));
            final tableData = <List<pw.Widget>>[];

            tableData.add([
              localizedText('اليوم', ttf, fontWeight: pw.FontWeight.bold),
              localizedText('التاريخ', ttf, fontWeight: pw.FontWeight.bold),
              localizedText('الحالة', ttf, fontWeight: pw.FontWeight.bold),
            ]);

            for (var day in month.absentDays) {
              tableData.add([
                localizedText(getArabicWeekdayName(day.day), ttf),
                localizedText(day.date, ttf),
                localizedText('غياب', ttf, color: PdfColors.red),
              ]);
            }

            for (var day in month.attendedDays) {
              tableData.add([
                localizedText(getArabicWeekdayName(day.day), ttf),
                localizedText(day.date, ttf),
                localizedText('حضور', ttf, color: PdfColors.green),
              ]);
            }

            content.add(pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              cellAlignment: pw.Alignment.center,
              data: tableData
                  .map((row) => row.map((cell) => cell).toList())
                  .toList(),
            ));

            content.add(pw.SizedBox(height: 10));
          }
        } else {
          content.add(localizedText('لا توجد بيانات غياب وحضور', ttf));
        }

        // ===== الفواتير والمدفوعات =====
        content.add(localizedText('الفواتير والمدفوعات', ttf,
            size: 18, fontWeight: pw.FontWeight.bold));
        if (invoices.isNotEmpty) {
          final tableData = <List<pw.Widget>>[];

          // عناوين الأعمدة
          tableData.add([
            localizedText('التاريخ', ttf, fontWeight: pw.FontWeight.bold),
            localizedText('اليوم', ttf, fontWeight: pw.FontWeight.bold),
            localizedText('اسم الاشتراك', ttf, fontWeight: pw.FontWeight.bold),
            localizedText('السعر الأصلي', ttf, fontWeight: pw.FontWeight.bold),
            localizedText('المبلغ المدفوع', ttf,
                fontWeight: pw.FontWeight.bold),
          ]);

          for (var invoice in invoices) {
            final sub = subscriptionFees[invoice.subscriptionFeeID];
            tableData.add([
              localizedText(invoice.dateTime.toString().split(' ')[0], ttf),
              localizedText(getArabicWeekday(invoice.dateTime.weekday), ttf),
              localizedText(sub?.subscriptionName ?? "-", ttf),
              // اسم الاشتراك
              localizedText('${sub?.subscriptionAmount ?? "-"} ج', ttf),
              // السعر الأصلي
              localizedText('${invoice.amount} ج', ttf),
              // المبلغ المدفوع
            ]);
          }

          content.add(pw.Table.fromTextArray(
            border: pw.TableBorder.all(),
            cellAlignment: pw.Alignment.center,
            data: tableData
                .map((row) => row.map((cell) => cell).toList())
                .toList(),
          ));
        } else {
          content.add(localizedText('لا توجد فواتير', ttf));
        }

        return content;
      },
    ),
  );

  return pdf.save();
}
