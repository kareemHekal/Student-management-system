import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/absence_model.dart';
import '../../models/day_record.dart';

bool _isArabic(String? text) {
  if (text == null || text.isEmpty) return false;
  final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
  return arabicRegex.hasMatch(text);
}

Future<Uint8List> generateAbsenceReportPdf({
  required String studentName,
  required List<AbsenceModel> absences,
  required List<DayRecord> currentAbsentDays,
  required List<DayRecord> currentAttendedDays,
}) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);
  final baseStyle = pw.TextStyle(font: ttf, fontSize: 12);

  pw.Widget localizedText(String text,
      {pw.TextStyle? style, double size = 12}) {
    return pw.Directionality(
      textDirection:
          _isArabic(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Text(
        text,
        style: (style ?? baseStyle).copyWith(fontSize: size),
      ),
    );
  }

  // إنشاء نموذج الشهر الحالي
  AbsenceModel currentMonth = AbsenceModel(
    monthName: "الشهر الحالي",
    attendedDays: currentAttendedDays,
    absentDays: currentAbsentDays,
  );

  final allMonths = [currentMonth, ...absences];

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) {
        List<pw.Widget> content = [];

        content.add(
          pw.Center(
            child: localizedText(
              "تقرير الغياب للطالب",
              style: pw.TextStyle(
                  font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
        );

        content.add(pw.SizedBox(height: 10));

        content.add(
          pw.Center(
            child: localizedText(
              studentName,
              style:
                  pw.TextStyle(font: ttf, fontSize: 20, color: PdfColors.blue),
            ),
          ),
        );

        content.add(pw.SizedBox(height: 20));

        for (var month in allMonths) {
          content.add(
            localizedText(
              month.monthName,
              style: pw.TextStyle(
                  font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          );

          content.add(pw.SizedBox(height: 5));

          final tableData = <List<pw.Widget>>[];

          // عنوان الجدول
          tableData.add([
            localizedText("اليوم",
                style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
            localizedText("التاريخ",
                style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
            localizedText("الحالة",
                style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
          ]);

          for (var day in month.absentDays) {
            tableData.add([
              localizedText(day.day, style: pw.TextStyle(font: ttf)),
              localizedText(day.date, style: pw.TextStyle(font: ttf)),
              localizedText("غياب",
                  style: pw.TextStyle(font: ttf, color: PdfColors.red)),
            ]);
          }

          for (var day in month.attendedDays) {
            tableData.add([
              localizedText(day.day, style: pw.TextStyle(font: ttf)),
              localizedText(day.date, style: pw.TextStyle(font: ttf)),
              localizedText("حضور",
                  style: pw.TextStyle(font: ttf, color: PdfColors.green)),
            ]);
          }

          content.add(
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              cellAlignment: pw.Alignment.center,
              data: tableData
                  .map((row) => row.map((cell) => cell).toList())
                  .toList(),
            ),
          );

          content.add(pw.SizedBox(height: 20));
        }

        return content;
      },
    ),
  );

  return pdf.save(); // Bytes فقط، بدون حفظ تلقائي
}
