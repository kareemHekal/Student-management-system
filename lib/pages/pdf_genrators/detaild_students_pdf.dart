import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_management_system/models/absence_app/day_record.dart';

import '../../models/Student_model.dart';

class StudentsPdfGenerator {
  static Future<void> generateStudentsDetailsPdf(
      List<Studentmodel> students) async {
    final pdf = pw.Document();

    // 🔤 Arabic Font
    final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    final titleStyle = pw.TextStyle(
      font: font,
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );

    final sectionStyle = pw.TextStyle(
      font: font,
      fontSize: 15,
      fontWeight: pw.FontWeight.bold,
    );

    final labelStyle = pw.TextStyle(
      font: font,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );

    final valueStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
    );

    final boys = students.where((s) => s.gender == 'ذكر').toList();
    final girls = students.where((s) => s.gender == 'أنثى').toList();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text('تقرير بيانات الطلاب', style: titleStyle),
          pw.SizedBox(height: 12),

          // ================= BOYS TABLE =================
          if (boys.isNotEmpty) ...[
            pw.Text('الطلاب الذكور', style: sectionStyle),
            pw.SizedBox(height: 6),
            _studentsTable(boys, labelStyle, valueStyle),
            pw.SizedBox(height: 20),
          ],

          // ================= GIRLS TABLE =================
          if (girls.isNotEmpty) ...[
            pw.Text('الطالبات الإناث', style: sectionStyle),
            pw.SizedBox(height: 6),
            _studentsTable(girls, labelStyle, valueStyle),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
    );
  }

  // ==================================================
  // 📊 Students Table
  // ==================================================
  static pw.Widget _studentsTable(
    List<Studentmodel> students,
    pw.TextStyle headerStyle,
    pw.TextStyle cellStyle,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
        5: pw.FlexColumnWidth(1.5),
        6: pw.FlexColumnWidth(1.5),
      },
      children: [
        // ---------- Header ----------
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _tableCell('الاسم', headerStyle),
            _tableCell('المرحلة', headerStyle),
            _tableCell('هاتف الطالب', headerStyle),
            _tableCell('هاتف الأب', headerStyle),
            _tableCell('هاتف الأم', headerStyle),
            _tableCell('آخر حضور', headerStyle),
            _tableCell('آخر غياب', headerStyle),
          ],
        ),

        // ---------- Rows ----------
        ...students.map(
          (s) => pw.TableRow(
            children: [
              _tableCell(s.name ?? 'غير مسجل', cellStyle),
              _tableCell(s.grade ?? '-', cellStyle),
              _tableCell(s.phoneNumber ?? '-', cellStyle),
              _tableCell(s.fatherPhone ?? '-', cellStyle),
              _tableCell(s.motherPhone ?? '-', cellStyle),
              _tableCell(
                _getLastDay(s.countingAttendedDays),
                cellStyle,
              ),
              _tableCell(
                _getLastDay(s.countingAbsentDays),
                cellStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================================================
  // 🔹 Table Cell
  // ==================================================
  static pw.Widget _tableCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: style,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ==================================================
  // 🔹 Helpers (UNCHANGED)
  // ==================================================
  static String _getLastDay(List<DayRecord>? records) {
    if (records == null || records.isEmpty) {
      return 'لا يوجد';
    }
    final last = records.last;
    return last.date;
  }

// دالة مساعدة لاختصار الرقم الطويل
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return "-";
    if (phone.length <= 11) return phone;
    // يأخذ أول 3 وأخر 3 ويضع بينهم نجوم
    return "${phone.substring(0, 3)}**${phone.substring(phone.length - 3)}";
  }

  static Future<void> generateQrCodesPdf(
      List<Studentmodel> students, String teacherName) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("fonts/NotoKufiArabic-Regular.ttf");
    final pw.Font arabicFont = pw.Font.ttf(fontData);

    const int cols = 4;
    const int rows = 9;
    const int cardsPerPage = cols * rows;

    void _addSection(List<Studentmodel> list, String title) {
      if (list.isEmpty) return;
      String gradeName =
          students.isNotEmpty ? (students.first.grade ?? "") : "";

      // صفحة الغلاف
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(fontSize: 40),
                  textDirection: pw.TextDirection.rtl),
              pw.Text("المدرس: $teacherName",
                  style: pw.TextStyle(fontSize: 25),
                  textDirection: pw.TextDirection.rtl),
              pw.Text("الصف الدراسي : $gradeName",
                  style: pw.TextStyle(fontSize: 25),
                  textDirection: pw.TextDirection.rtl),
              pw.Text("عدد الطلاب: ${list.length}",
                  style: pw.TextStyle(fontSize: 25),
                  textDirection: pw.TextDirection.rtl),
            ],
          ),
        ),
      ));

      for (var i = 0; i < list.length; i += cardsPerPage) {
        final chunk = list.sublist(
            i, i + cardsPerPage > list.length ? list.length : i + cardsPerPage);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
            build: (pw.Context context) {
              List<List<Studentmodel?>> tableRows = [];
              for (var j = 0; j < chunk.length; j += cols) {
                List<Studentmodel?> row = [];
                for (var k = 0; k < cols; k++) {
                  row.add((j + k < chunk.length) ? chunk[j + k] : null);
                }
                tableRows.add(row);
              }

              return pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Table(
                  columnWidths: {
                    0: const pw.FractionColumnWidth(0.25),
                    1: const pw.FractionColumnWidth(0.25),
                    2: const pw.FractionColumnWidth(0.25),
                    3: const pw.FractionColumnWidth(0.25),
                  },
                  children: tableRows.map((rowItems) {
                    return pw.TableRow(
                      children: rowItems.map((student) {
                        if (student == null) return pw.Container();

                        return pw.Container(
                          margin: const pw.EdgeInsets.all(4),
                          padding: const pw.EdgeInsets.all(5),
                          height: (PdfPageFormat.a4.height - 60) / rows,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                                color: PdfColors.grey400, width: 0.5),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.SizedBox(
                                height: 14,
                                child: pw.FittedBox(
                                  child: pw.Text(student.name ?? "",
                                      textDirection: pw.TextDirection.rtl,
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold)),
                                ),
                              ),
                              pw.Divider(thickness: 0.3, height: 2),
                              pw.Expanded(
                                child: pw.Row(
                                  children: [
                                    pw.Container(
                                      width: 35,
                                      height: 35,
                                      child: pw.BarcodeWidget(
                                        data: student.id ?? "0",
                                        barcode: pw.Barcode.qrCode(),
                                        drawText: false,
                                      ),
                                    ),
                                    pw.SizedBox(width: 4),
                                    pw.Expanded(
                                      child: pw.Column(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Directionality(
                                            textDirection: pw.TextDirection.ltr,
                                            child: pw.FittedBox(
                                              child: pw.Text(
                                                  // تم استدعاء دالة الفورمات هنا
                                                  "ت: ${formatPhone(student.phoneNumber)}",
                                                  style: const pw.TextStyle(
                                                      fontSize: 7)),
                                            ),
                                          ),
                                          pw.Divider(thickness: 0.2, height: 3),
                                          pw.SizedBox(
                                            height: 9,
                                            child: pw.FittedBox(
                                              child: pw.Text(
                                                  "ص: ${student.grade ?? ''}",
                                                  textDirection:
                                                      pw.TextDirection.rtl),
                                            ),
                                          ),
                                          pw.SizedBox(
                                            height: 9,
                                            child: pw.FittedBox(
                                              child: pw.Text("أ: $teacherName",
                                                  textDirection:
                                                      pw.TextDirection.rtl),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      }
    }

    final List<Studentmodel> boys =
        students.where((s) => s.gender == "ذكر").toList();
    final List<Studentmodel> girls =
        students.where((s) => s.gender == "أنثى").toList();

    _addSection(boys, "قسم البنين");
    _addSection(girls, "قسم البنات");

    String gradeName = students.isNotEmpty ? (students.first.grade ?? "") : "";

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      // هنا نحدد اسم الملف الافتراضي عند الحفظ
      name: 'Qr codes $gradeName',
    );
  }
}
