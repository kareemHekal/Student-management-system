import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/Studentmodel.dart';
import '../../models/exam_model.dart';

bool _isArabic(String? text) {
  if (text == null || text.isEmpty) return false;
  final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
  return arabicRegex.hasMatch(text);
}

class _PdfStudentRow {
  final String name;
  final double? score;

  _PdfStudentRow({required this.name, this.score});
}

Future<Uint8List> generateExamReportPdf({
  required ExamModel exam,
  required List<Studentmodel> students,
  required String gradeName,
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

  final Map<String, List<_PdfStudentRow>> byMini = {};
  final List<String> noRecordStudents = [];

  final miniExams = exam.miniExams ?? [];
  for (final m in miniExams) {
    byMini[m.id] = [];
  }

  for (final st in students) {
    final gradeList = st.studentExamsGrades ?? [];
    final matching = gradeList.where((g) => g.examId == exam.id).toList();

    if (matching.isEmpty) {
      noRecordStudents.add(st.name ?? st.id);
      continue;
    }

    for (final g in matching) {
      final name = st.name ?? st.id;
      final score = double.tryParse(g.studentGrade);
      if (!byMini.containsKey(g.miniExamId)) {
        byMini[g.miniExamId] = [];
      }
      byMini[g.miniExamId]!.add(_PdfStudentRow(name: name, score: score));
    }
  }

  for (final key in byMini.keys) {
    byMini[key]!.sort((a, b) {
      if (a.score == null && b.score == null) return 0;
      if (a.score == null) return 1;
      if (b.score == null) return -1;
      return b.score!.compareTo(a.score!);
    });
  }

  final pageTheme = pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(25),
  );

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pageTheme,
      build: (context) {
        final List<pw.Widget> widgets = [];

        // HEADER
        widgets.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              localizedText(
                exam.name,
                style: pw.TextStyle(
                    font: ttf, fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              localizedText(
                'الصف: $gradeName',
                style: pw.TextStyle(font: ttf, color: PdfColors.grey700),
              ),
              pw.Divider(),
            ],
          ),
        );

        // MINI EXAM TABLES
        for (final mini in miniExams) {
          final rows = byMini[mini.id] ?? [];

          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  localizedText(
                    mini.miniExamName,
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  localizedText(
                    'الدرجة الكاملة: ${mini.fullGrade.toStringAsFixed(0)}',
                    style: pw.TextStyle(font: ttf),
                  ),
                ],
              ),
            ),
          );

          if (rows.isEmpty) {
            widgets.add(localizedText(
              'لا توجد درجات لهذا النموذج',
              style: pw.TextStyle(font: ttf, color: PdfColors.grey600),
            ));
            widgets.add(pw.Divider());
            continue;
          }

          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: localizedText('اسم الطالب',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: localizedText('الدرجة',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...rows.map((r) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: localizedText(r.name,
                            style: pw.TextStyle(font: ttf, fontSize: 11)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: localizedText(
                            r.score == null ? '-' : r.score!.toStringAsFixed(1),
                            style: pw.TextStyle(font: ttf, fontSize: 11)),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Divider());
        }

        // NO EXAM STUDENTS
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
            child: localizedText(
              'الطلاب الذين لم يؤدوا الامتحان',
              style: pw.TextStyle(
                  font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
        );

        if (noRecordStudents.isEmpty) {
          widgets.add(localizedText(
            'لا يوجد. جميع الطلاب لهم درجات.',
            style: pw.TextStyle(font: ttf, color: PdfColors.grey700),
          ));
        } else {
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: localizedText('اسم الطالب',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: localizedText('الدرجة',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...noRecordStudents.map((n) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: localizedText(n,
                            style: pw.TextStyle(font: ttf, fontSize: 11)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: localizedText('-',
                            style: pw.TextStyle(font: ttf, fontSize: 11)),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          );
        }

        widgets.add(pw.SizedBox(height: 20));

        return widgets;
      },
    ),
  );

  return pdf.save();
}
