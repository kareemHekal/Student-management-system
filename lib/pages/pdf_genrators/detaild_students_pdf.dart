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

  static Future<void> generateQrCodesPdf(
      List<Studentmodel> students, String teacherName) async {
    final pdf = pw.Document();

    // تحميل الخط العربي - تأكد من المسار الصحيح في pubspec.yaml
    final fontData = await rootBundle.load("fonts/NotoKufiArabic-Regular.ttf");
    final pw.Font arabicFont = pw.Font.ttf(fontData);

    final boys = students.where((s) => s.gender == "ذكر").toList();
    final girls = students.where((s) => s.gender == "أنثى").toList();

    Future<void> _addGenderSection(
        List<Studentmodel> list, String title) async {
      if (list.isEmpty) return;

      const int crossAxisCount = 6;
      const double spacing = 8;
      final pageWidth = PdfPageFormat.a4.landscape.width;
      final pageHeight = PdfPageFormat.a4.landscape.height;

      final cardWidth =
          (pageWidth - (crossAxisCount + 1) * spacing) / crossAxisCount;
      const double cardHeight = 105; // زدت الارتفاع قليلاً لضمان ظهور البيانات

      final maxRowsPerPage =
          ((pageHeight - 60) / (cardHeight + spacing)).floor();
      final totalCardsPerPage = crossAxisCount * maxRowsPerPage;
      final totalPages = (list.length / totalCardsPerPage).ceil();

      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(10),
            // إعداد السمة العامة للخط والاتجاه
            theme: pw.ThemeData.withFont(
              base: arabicFont,
              bold: arabicFont,
            ),
            build: (context) {
              return pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                // إجبار الاتجاه من اليمين لليسار
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Text(title,
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Column(
                      children: List.generate(maxRowsPerPage, (rowIndex) {
                        return pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: List.generate(crossAxisCount, (colIndex) {
                            final index = pageIndex * totalCardsPerPage +
                                rowIndex * crossAxisCount +
                                colIndex;
                            if (index >= list.length)
                              return pw.SizedBox(
                                  width: cardWidth, height: cardHeight);

                            final student = list[index];

                            return pw.Container(
                              width: cardWidth,
                              height: 90,
                              margin: const pw.EdgeInsets.all(spacing / 2),
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 4),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                    color: PdfColors.grey400, width: 0.5),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Column(
                                mainAxisSize: pw.MainAxisSize.min,
                                children: [
                                  // اسم الطالب
                                  pw.Text(
                                    student.name ?? "غير مسجل",
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold),
                                    maxLines: 1,
                                  ),
                                  pw.Divider(thickness: 0.5, height: 6),
                                  // تقليل مساحة الفاصل

                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      // الـ QR Code مع إضافة مسافات جانبية
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.only(
                                            top: 2, left: 4, right: 4),
                                        // مسافة من الأعلى واليسار واليمين
                                        child: pw.Container(
                                          width: 30,
                                          height: 30,
                                          child: pw.BarcodeWidget(
                                            data: student.id ?? "0",
                                            barcode: pw.Barcode.qrCode(),
                                            drawText:
                                                false, // لضمان عدم كتابة الرقم أسفل الكود إذا لم تحتاجه
                                          ),
                                        ),
                                      ),

                                      pw.SizedBox(width: 8),
                                      // زيادة المسافة الفاصلة بين الـ QR ومنطقة البيانات

                                      // البيانات
                                      pw.Expanded(
                                        child: pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.end,
                                          children: [
                                            pw.Text(
                                                "هاتف: ${student.phoneNumber ?? '-'}",
                                                style: const pw.TextStyle(
                                                    fontSize: 8)),
                                            pw.SizedBox(height: 2),
                                            pw.Text(
                                                "الصف: ${student.grade ?? '-'}",
                                                style: const pw.TextStyle(
                                                    fontSize: 8)),

                                            // مسافة عمودية قبل اسم المدرس
                                            pw.SizedBox(height: 8),

                                            pw.Text(
                                              teacherName,
                                              style: pw.TextStyle(
                                                fontSize: 7,
                                                color: PdfColors.grey700,
                                                fontWeight: pw.FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    }

    await _addGenderSection(boys, "الطلاب الذكور");
    await _addGenderSection(girls, "الطالبات الإناث");

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
