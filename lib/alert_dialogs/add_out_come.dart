import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/theme/snack_bar.dart';

import '../loadingFile/loading_alert/run_with_loading.dart';
import '../models/daily_invoice.dart';
import '../models/payment.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart'; // Ensure this path matches your AppTextStyles

class AddExpenseDialog extends StatefulWidget {
  final String date;
  final String day;

  const AddExpenseDialog({
    super.key,
    required this.date,
    required this.day,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void dispose() {
    totalAmountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.primaryMain,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Text(
          "إضافة مصروف جديد",
          style: AppTextStyles.customText(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // Amount Field
            _buildModernField(
              controller: totalAmountController,
              label: "المبلغ الإجمالي",
              hint: "0.00",
              icon: Icons.payments_outlined,
              isNumber: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال المبلغ';
                }
                if (double.tryParse(value) == null) {
                  return 'أدخل رقم صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Description Field
            _buildModernField(
              controller: descriptionController,
              label: "الوصف / ملاحظة",
              hint: "مثلاً: فواتير كهرباء، إيجار...",
              icon: Icons.notes_outlined,
              isMultiline: true,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      actions: <Widget>[
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style:
                      AppTextStyles.customText(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonSecondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  // 1. UI Validation
                  if (!(_formKey.currentState?.validate() ?? false)) return;

                  // 2. Start Loading and call the logic
                await runWithLoading(context, () async {
                  await FirebaseFunctions.addPaymentToFirestore(
                    date: widget.date,
                    day: widget.day,
                    amountText: totalAmountController.text,
                    description: descriptionController.text,
                  );

                    // 3. Post-logic UI steps
                    if (context.mounted) {
                      AppSnackBars.showSuccess(
                          context, "تم تسجيل المصروف بنجاح ✅");
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/HomeScreen', (route) => false);
                    }
                  });
                },
                child: Text(
                  'حفظ المصروف',
                  style: AppTextStyles.customText(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Modern Input Builder
  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    bool isMultiline = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: isMultiline ? 2 : 1,
      style: AppTextStyles.customText(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryMain, size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: AppTextStyles.customText(
            color: AppColors.textSecondary, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              const BorderSide(color: AppColors.primaryMain, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.statusAbsent, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}