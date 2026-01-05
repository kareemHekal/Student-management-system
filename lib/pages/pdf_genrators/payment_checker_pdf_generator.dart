import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_management_system/models/student_paid_subscription.dart';
import 'package:student_management_system/models/subscription_fee.dart';

import '../../models/Student_model.dart';

Future<void> generatePdf(
    {required List<Studentmodel> students,
    required String title,
    required String selectedGrade,
    required SubscriptionFee? selectedSubscription}) async {
  final pdf = pw.Document();
  final arabicFont =
      pw.Font.ttf(await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf'));

  // ✅ Calculate total income
  double totalIncome = 0;
  for (final student in students) {
    final paidSub = student.studentPaidSubscriptions?.firstWhere(
      (s) => s.subscriptionId == selectedSubscription!.id,
      orElse: () => StudentPaidSubscriptions(
        description: '',
        subscriptionId: selectedSubscription!.id,
        paidAmount: 0,
      ),
    );
    totalIncome += paidSub?.paidAmount ?? 0;
  }

  pdf.addPage(
    pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      build: (context) => [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text("المرحلة: ${selectedGrade ?? 'غير محدد'}",
            style: pw.TextStyle(font: arabicFont)),
        pw.Text(
            "الاشتراك: ${selectedSubscription?.subscriptionName ?? 'غير محدد'}",
            style: pw.TextStyle(font: arabicFont)),
        pw.SizedBox(height: 10),

        // ✅ Show total income at the top
        pw.Text(
          "إجمالي المبالغ المدفوعة: ${totalIncome.toStringAsFixed(2)} جنيه",
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
            font: arabicFont,
          ),
        ),

        pw.SizedBox(height: 15),

        pw.TableHelper.fromTextArray(
          headers: [
            'المبلغ المتبقي',
            'المبلغ المطلوب',
            'المبلغ المدفوع',
            'رقم الطالب',
            'اسم الطالب'
          ],
          data: students.map((student) {
            final paidSub = student.studentPaidSubscriptions?.firstWhere(
              (s) => s.subscriptionId == selectedSubscription!.id,
              orElse: () => StudentPaidSubscriptions(
                description: '',
                subscriptionId: selectedSubscription!.id,
                paidAmount: 0,
              ),
            );

            final paidAmount = paidSub?.paidAmount ?? 0;
            final totalDue = selectedSubscription!.subscriptionAmount;
            final remaining = totalDue - paidAmount;

            return [
              remaining.toStringAsFixed(2),
              totalDue.toStringAsFixed(2),
              paidAmount.toStringAsFixed(2),
              student.phoneNumber ?? '---',
              student.name ?? '---',
            ];
          }).toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
          cellStyle: pw.TextStyle(font: arabicFont, fontSize: 12),
          cellAlignment: pw.Alignment.centerRight,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
