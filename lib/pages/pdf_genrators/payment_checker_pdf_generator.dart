import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_management_system/models/student_paid_subscription.dart';
import 'package:student_management_system/models/subscription_fee.dart';

import '../../models/Student_model.dart';

Future<void> generatePdf({
  required List<Studentmodel> students,
  required String title,
  required String selectedGrade,
  required SubscriptionFee? selectedSubscription,
}) async {
  final pdf = pw.Document();
  final fontData = await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf');
  final arabicFont = pw.Font.ttf(fontData);

  // ✅ 1. حساب إجمالي الدخل
  double totalIncome = 0;
  for (final student in students) {
    final paidSub = student.studentPaidSubscriptions?.firstWhere(
      (s) => s.subscriptionId == selectedSubscription?.id,
      orElse: () => StudentPaidSubscriptions(
        description: '',
        subscriptionId: selectedSubscription?.id ?? '',
        paidAmount: 0,
      ),
    );
    totalIncome += paidSub?.paidAmount ?? 0;
  }

  // ✅ 2. تقسيم الطلاب لمجموعات (مثلاً كل 25 طالب في جدول) لتجنب التهنيق
  const int chunkSize = 25;

  pdf.addPage(
    pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
      build: (context) {
        List<pw.Widget> content = [];

        // الهيدر العلوي
        content.add(pw.Text(title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)));
        content.add(pw.SizedBox(height: 5));
        content.add(pw.Text(
            "المرحلة: $selectedGrade | الاشتراك: ${selectedSubscription?.subscriptionName ?? 'غير محدد'}",
            style: const pw.TextStyle(fontSize: 12)));
        content.add(pw.SizedBox(height: 10));

        // كارت الإجمالي
        content.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(5)),
            child: pw.Text(
              "إجمالي المبالغ المدفوعة: ${totalIncome.toStringAsFixed(2)} جنيه",
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800),
            ),
          ),
        );
        content.add(pw.SizedBox(height: 15));

        // بناء الجداول المقسمة
        for (var i = 0; i < students.length; i += chunkSize) {
          final chunk = students.sublist(
              i,
              i + chunkSize > students.length
                  ? students.length
                  : i + chunkSize);

          content.add(
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2), // متبقي
                1: pw.FlexColumnWidth(1.2), // مطلوب
                2: pw.FlexColumnWidth(1.2), // مدفوع
                3: pw.FlexColumnWidth(1.5), // الهاتف
                4: pw.FlexColumnWidth(2.5), // الاسم
              },
              children: [
                // رأس الجدول يظهر فقط في أول chunk
                if (i == 0)
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _headerCell('المتبقي'),
                      _headerCell('المطلوب'),
                      _headerCell('المدفوع'),
                      _headerCell('رقم الهاتف'),
                      _headerCell('اسم الطالب'),
                    ],
                  ),
                // بيانات الطلاب
                ...chunk.map((student) {
                  final paidSub = student.studentPaidSubscriptions?.firstWhere(
                    (s) => s.subscriptionId == selectedSubscription?.id,
                    orElse: () => StudentPaidSubscriptions(
                      description: '',
                      subscriptionId: selectedSubscription?.id ?? '',
                      paidAmount: 0,
                    ),
                  );

                  final paidAmount = paidSub?.paidAmount ?? 0;
                  final totalDue =
                      selectedSubscription?.subscriptionAmount ?? 0;
                  final remaining = totalDue - paidAmount;

                  return pw.TableRow(
                    children: [
                      _cell(remaining.toStringAsFixed(2)),
                      _cell(totalDue.toStringAsFixed(2)),
                      _cell(paidAmount.toStringAsFixed(2)),
                      _cell(student.phoneNumber ?? '---'),
                      _cell(student.name ?? '---', isName: true),
                    ],
                  );
                }),
              ],
            ),
          );
          content.add(pw.SizedBox(height: 0)); // دمج الجداول بصرياً
        }

        return content;
      },
    ),
  );

  // ✅ 3. تسمية الملف بشكل معبر
  final String fileName =
      "${title}_${selectedGrade}_${selectedSubscription?.subscriptionName ?? ''}"
          .replaceAll(
              RegExp(r'[<>:"/\\|?*]'), ' '); // تنظيف الاسم من الرموز الممنوعة

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
    name: fileName,
  );
}

// دالة مساعدة لتنسيق خلايا العناوين
pw.Widget _headerCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
  );
}

// دالة مساعدة لتنسيق خلايا البيانات
pw.Widget _cell(String text, {bool isName = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(
      text,
      textAlign: isName ? pw.TextAlign.right : pw.TextAlign.center,
      style: const pw.TextStyle(fontSize: 10),
    ),
  );
}