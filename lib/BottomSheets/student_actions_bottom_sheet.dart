import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../firebase/firebase_functions.dart';
import '../models/Invoice.dart';
import '../models/Student_model.dart';
import '../models/subscription_fee.dart';
import '../pages/all_bills_for_student.dart';
import '../pages/all_student_exam_grades.dart';
import '../pages/pdf_genrators/student_pdf_generator.dart';
import '../theme/colors_app.dart';

class StudentActionsBottomSheet {
  static void show({
    required BuildContext context,
    required Studentmodel student,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionItem(
                icon: Icons.list_alt,
                label: 'الفواتير',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AllBillsForStudent(studentId: student.id),
                    ),
                  );
                },
              ),
              _ActionItem(
                icon: Icons.assessment,
                label: 'الدرجات',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AllStudentExamGrades(student: student),
                    ),
                  );
                },
              ),
              _ActionItem(
                icon: Icons.print,
                label: "تقرير شامل",
                onPressed: () async {
                  try {
                    // 1️⃣ تحميل كل الفواتير الخاصة بالطالب
                    List<Invoice> invoices =
                        await FirebaseFunctions.getInvoicesByStudentNumber(
                            student.id);

                    // 2️⃣ تحميل كل الاشتراكات المرتبطة بالفواتير
                    Map<String, SubscriptionFee> subscriptionFees = {};
                    for (var invoice in invoices) {
                      final sub = await FirebaseFunctions.getSubscriptionById(
                          invoice.grade, invoice.subscriptionFeeID);
                      subscriptionFees[invoice.subscriptionFeeID] = sub!;
                    }

                    // 3️⃣ توليد الـ PDF
                    final pdfBytes = await generateFullStudentPdf(
                      student: student,
                      invoices: invoices,
                      subscriptionFees: subscriptionFees,
                    );

                    // 4️⃣ عرض نافذة الطباعة / حفظ PDF
                    await Printing.layoutPdf(
                      onLayout: (format) async => pdfBytes,
                      name: "${student.name}_full_report.pdf",
                    );
                  } catch (e) {
                    print("❌ حدث خطأ أثناء إنشاء التقرير: $e");
                  }
                },
              ),
              // أضف هذا العنصر داخل Row في دالة show الخاصة بـ StudentActionsBottomSheet
              _ActionItem(
                icon: Icons.move_up_rounded,
                label: 'تغيير الصف',
                onPressed: () {
                  Navigator.pop(context);
                  showMoveStudentDialog(context, student);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void showMoveStudentDialog(
      BuildContext context, Studentmodel student) {
    String? selectedGrade;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // نحتاج StatefulBuilder لتحديث الاختيار داخل الـ Dialog
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              titlePadding: EdgeInsets.zero,
              title:
                  _buildHeader("نقل الطالب لصف آخر", Icons.swap_horiz_rounded),
              content: FutureBuilder<List<String>>(
                future: FirebaseFunctions.getGradesList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()));
                  }

                  final grades = snapshot.data ?? [];
                  // حذف الصف الحالي من القائمة حتى لا يختاره بالخطأ
                  grades.remove(student.grade);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "سيتم حذف جميع سجلات الغياب، المجموعات، والاشتراكات الحالية للطالب عند نقله.",
                        style: AppTextStyles.customText(
                            fontSize: 13, color: Colors.red[700]!),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'اختر الصف الجديد',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        value: selectedGrade,
                        items: grades
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedGrade = val),
                      ),
                    ],
                  );
                },
              ),
              actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('إلغاء',
                            style: AppTextStyles.customText(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMain,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: selectedGrade == null
                            ? null
                            : () async {
                                await runWithLoading(context, () async {
                                  try {
                                    await FirebaseFunctions
                                        .moveStudentToNewGrade(
                                      student: student,
                                      oldGrade: student.grade!,
                                      newGrade: selectedGrade!,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      AppSnackBars.showSuccess(
                                          context, "تم نقل الطالب بنجاح");
                                      // اختيارياً: العودة للشاشة الرئيسية لتحديث البيانات
                                      Navigator.pushNamedAndRemoveUntil(context,
                                          "/HomeScreen", (route) => false);
                                    }
                                  } catch (e) {
                                    if (context.mounted)
                                      AppSnackBars.showError(
                                          context, "حدث خطأ: $e");
                                  }
                                });
                              },
                        child: Text('تأكيد النقل',
                            style: AppTextStyles.customText(
                                color: AppColors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

// دالة مساعدة لشكل الهيدر (بنفس ستايلك السابق)
  static Widget _buildHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primaryMain,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white),
          const SizedBox(width: 12),
          Text(title,
              style: AppTextStyles.customText(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white)),
        ],
      ),
    );
  }
}

/// Reusable widget for action icon + label
class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.secondaryMain, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
