import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/Student_model.dart';
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

Future<Uint8List> generateExamReportPdf(Map<String, dynamic> params) async {
  final ExamModel exam = params['exam'];
  final List<Studentmodel> students = params['students'];
  final String gradeName = params['gradeName'];
  final Uint8List fontData = params['fontData']; // استلم الخط كبيانات

  final pdf = pw.Document();
  final ttf = pw.Font.ttf(fontData.buffer.asByteData());

  // منطق تجهيز البيانات (زي ما هو سليم عندك)
  final Map<String, List<_PdfStudentRow>> byMini = {};
  final List<String> noRecordStudents = [];
  final miniExams = exam.miniExams ?? [];
  for (final m in miniExams) byMini[m.id] = [];

  for (final st in students) {
    final gradeList = st.studentExamsGrades ?? [];
    final matching = gradeList.where((g) => g.examId == exam.id).toList();
    if (matching.isEmpty) {
      noRecordStudents.add(st.name ?? "بدون اسم");
      continue;
    }
    for (final g in matching) {
      if (byMini.containsKey(g.miniExamId)) {
        byMini[g.miniExamId]!.add(_PdfStudentRow(
          name: st.name ?? "بدون اسم",
          score: double.tryParse(g.studentGrade),
        ));
      }
    }
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
      margin: const pw.EdgeInsets.all(30),
      build: (context) {
        final List<pw.Widget> widgets = [];

        // 1. العنوان الرئيسي
        widgets.add(pw.Center(
            child: pw.Text(exam.name,
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold))));
        widgets.add(pw.Center(
            child: pw.Text('تقرير الدرجات - صف: $gradeName',
                style: const pw.TextStyle(fontSize: 16))));
        widgets.add(pw.SizedBox(height: 20));
        widgets.add(pw.Divider(thickness: 2));

        // 2. عرض نماذج الامتحان
        for (final mini in miniExams) {
          final rows = byMini[mini.id] ?? [];

          // عنوان النموذج
          widgets.add(pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(5),
            color: PdfColors.grey300,
            child: pw.Text(
                "نموذج: ${mini.miniExamName} (الدرجة: ${mini.fullGrade})",
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          ));

          if (rows.isNotEmpty) {
            // بدلاً من الجدول.. سنستخدم Wrap يحتوي على "كروت" صغيرة أو قائمة نصوص
            // لضمان السرعة، هنعرضهم كقائمة نصوص بسيطة
            for (var i = 0; i < rows.length; i++) {
              widgets.add(pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey200, width: 0.5))),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(" ${rows[i].name}  -${i + 1} "),
                    pw.Text("${rows[i].score?.toStringAsFixed(1) ?? '-'} ",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ));
            }
          } else {
            widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text("لا يوجد طلاب")));
          }
          widgets.add(pw.SizedBox(height: 20));
        }

        // 3. قسم الغائبين (بشكل مبسط جداً)
        if (noRecordStudents.isNotEmpty) {
          widgets.add(pw.Divider(thickness: 2));
          widgets.add(pw.Text("الطلاب الذين لم يؤدوا الامتحان:",
              style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColors.red,
                  fontWeight: pw.FontWeight.bold)));
          widgets.add(pw.SizedBox(height: 10));

          widgets.add(pw.Wrap(
            spacing: 10,
            runSpacing: 5,
            children: noRecordStudents
                .map((name) => pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.red100),
                          borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text(name,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.red700)),
                    ))
                .toList(),
          ));
        }

        return widgets;
      },
    ),
  );

  return pdf.save();
}