import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/models/daily_invoice.dart';
import 'package:student_management_system/models/payment.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

class DeleteStudentWithSettlementDialog extends StatefulWidget {
  final Studentmodel student;
  final String date;
  final String day;

  const DeleteStudentWithSettlementDialog({
    super.key,
    required this.student,
    required this.date,
    required this.day,
  });

  @override
  State<DeleteStudentWithSettlementDialog> createState() =>
      _DeleteStudentWithSettlementDialogState();
}

class _DeleteStudentWithSettlementDialogState
    extends State<DeleteStudentWithSettlementDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController amountController =
      TextEditingController(text: "0");
  final TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    reasonController.text = "تصفية حساب الطالب: ${widget.student.name}";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: AppColors.statusAbsent, // Red color for deletion
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Text(
          "تصفية وحذف طالب",
          style: AppTextStyles.customText(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
      titlePadding: EdgeInsets.zero,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                "سيتم حذف ${widget.student.name} نهائياً. يرجى تسجيل المبلغ المسترد (إن وجد):",
                style: AppTextStyles.customText(
                    fontSize: 14, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "المبلغ المسترد",
                  prefixIcon: const Icon(Icons.money_off,
                      color: AppColors.statusAbsent),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? "أدخل 0 إذا لم يوجد مبلغ" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "ملاحظات الحذف",
                  prefixIcon:
                      const Icon(Icons.note, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("إلغاء",
              style: AppTextStyles.customText(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusAbsent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _handleFinalDelete,
          child: Text("تأكيد الحذف النهائي",
              style: AppTextStyles.customText(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _handleFinalDelete() async {
    if (!_formKey.currentState!.validate()) return;

    await runWithLoading(context, () async {
      final double amount = double.tryParse(amountController.text) ?? 0.0;
      final firestore = FirebaseFirestore.instance;

      // 1. Record the Expense (even if 0)
      final docRef = firestore.collection('big_invoices').doc(widget.date);
      final newPayment = Payment(
        amount: amount,
        description: reasonController.text.trim(),
        dateTime: DateTime.now(),
      );

      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        final bigInvoice = DailyInvoice.fromJson(docSnapshot.data()!);
        bigInvoice.payments.add(newPayment);
        await docRef.update(bigInvoice.toJson());
      } else {
        await docRef.set(DailyInvoice(
          date: widget.date,
          day: widget.day,
          invoices: [],
          payments: [newPayment],
        ).toJson());
      }

      // 2. Delete the Student
      await FirebaseFunctions.deleteStudentFromHisCollection(
        widget.student.grade ?? "",
        widget.student.id,
      );

      if (mounted) {
        Navigator.pop(context); // Close Dialog
        AppSnackBars.showSuccess(context, "تم حذف الطالب وتسجيل المصروف");
      }
    });
  }
}
