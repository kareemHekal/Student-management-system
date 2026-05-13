import 'dart:typed_data';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/absence_app/day_record.dart';
import '../../models/absence_app/student_absence_model.dart';

// دالة تنسيق الوقت
String _formatTime(TimeOfDay time) {
  final hour =
      time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
  final period = time.hour >= 12 ? 'م' : 'ص';
  final minute = time.minute.toString().padLeft(2, '0');
  return "$hour:$minute $period";
}

Future<Uint8List> generateAbsenceReportPdf({
  required String studentName,
  required List<StudentAbsencesModel> absences,
  required List<DayRecord> currentAbsentDays,
  required List<DayRecord> currentAttendedDays,
}) async {
  final pdf = pw.Document();
  final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);
  final DateTime now = DateTime.now();

  // فلتر منع التواريخ المستقبلية للـ DayRecord الأساسي
  bool _isFuture(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime today = DateTime(now.year, now.month, now.day);
      return date.isAfter(today);
    } catch (e) {
      return false;
    }
  }

  // أنماط الخطوط
  final headerStyle = pw.TextStyle(
      font: ttf,
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue900);
  final subHeaderStyle =
      pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold);
  final boldStyle =
      pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold);
  final normalStyle = pw.TextStyle(font: ttf, fontSize: 10);
  final smallStyle = pw.TextStyle(font: ttf, fontSize: 9);
  final strikeStyle = pw.TextStyle(
      font: ttf,
      fontSize: 9,
      color: PdfColors.red700,
      decoration: pw.TextDecoration.lineThrough);

  pw.Widget localizedText(String text, {pw.TextStyle? style}) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(text, style: style ?? normalStyle),
    );
  }

  List<DayRecord> filterPast(List<DayRecord> list) =>
      list.where((d) => !_isFuture(d.date)).toList();

  final List<StudentAbsencesModel> allMonths = [
    StudentAbsencesModel(
      monthName: "الشهر الحالي",
      attendedDays: filterPast(currentAttendedDays),
      absentDays: filterPast(currentAbsentDays),
    ),
    ...absences.map((m) => m.copyWith(
          attendedDays: filterPast(m.attendedDays),
          absentDays: filterPast(m.absentDays),
        ))
  ];

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      footer: (pw.Context context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            localizedText("نظام إدارة الحضور والغياب الذكي", style: smallStyle),
            pw.Text("Page ${context.pageNumber} of ${context.pagesCount}",
                style: smallStyle),
          ],
        ),
      ),
      build: (pw.Context context) => [
        pw.Header(
          level: 0,
          child: pw.Column(
            children: [
              pw.Center(
                  child: localizedText("تقرير سجل المتابعة التفصيلي",
                      style: headerStyle)),
              pw.SizedBox(height: 5),
              pw.Center(
                  child: localizedText("الطالب: $studentName",
                      style:
                          subHeaderStyle.copyWith(color: PdfColors.blue800))),
              pw.Divider(thickness: 1, color: PdfColors.blueGrey),
            ],
          ),
        ),
        for (var month in allMonths) ...[
          if (month.attendedDays.isNotEmpty || month.absentDays.isNotEmpty) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: localizedText(month.monthName, style: subHeaderStyle),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5), // تاريخ السجل
                1: const pw.FlexColumnWidth(4), // التفاصيل الكاملة
                2: const pw.FlexColumnWidth(1), // الحالة النهائية
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Center(
                            child: localizedText("التاريخ", style: boldStyle))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Center(
                            child: localizedText(
                                "بيانات المجموعات (الموعد الأصلي والبديل)",
                                style: boldStyle))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Center(
                            child: localizedText("الحالة", style: boldStyle))),
                  ],
                ),

                // الغياب
                for (var day in month.absentDays)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Center(
                              child: localizedText("${day.day}\n${day.date}",
                                  style: normalStyle))),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: localizedText(
                            "غائب عن موعد مجموعته: الساعة ${_formatTime(day.time)}",
                            style: normalStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Center(
                            child: localizedText("غياب",
                                style: boldStyle.copyWith(
                                    color: PdfColors.red800))),
                      ),
                    ],
                  ),

                // الحضور (تم إظهار كل البيانات هنا)
                for (var day in month.attendedDays)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Center(
                              child: localizedText("${day.day}\n${day.date}",
                                  style: normalStyle))),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: day.secondary == null
                            ? pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  localizedText("حضور في موعد مجموعته الأساسي",
                                      style: normalStyle),
                                  localizedText(
                                      "الوقت الفعلي: ${_formatTime(day.time)}",
                                      style: boldStyle.copyWith(
                                          color: PdfColors.green800)),
                                ],
                              )
                            : pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  localizedText("حضور (تعويض لموعد سابق)",
                                      style: boldStyle.copyWith(
                                          color: PdfColors.orange900)),
                                  pw.SizedBox(height: 2),
                                  // بيانات الموعد اللي حضر فيه فعلاً
                                  localizedText(
                                      "• حضر اليوم فعلياً الساعة: ${_formatTime(day.time)}",
                                      style: normalStyle),
                                  // بيانات الموعد القديم بالكامل (يوم وتاريخ ووقت)
                                  localizedText(
                                      "• الموعد الأصلي الفائت: ${day.secondary!.day} بتاريخ (${day.secondary!.date}) الساعة ${_formatTime(day.secondary!.time)}",
                                      style: strikeStyle),
                                ],
                              ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Center(
                          child: localizedText(
                            day.secondary == null ? "حضور" : "تعويض",
                            style: boldStyle.copyWith(
                                color: day.secondary == null
                                    ? PdfColors.green800
                                    : PdfColors.orange800),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
          ],
        ],
      ],
    ),
  );

  return pdf.save();
}