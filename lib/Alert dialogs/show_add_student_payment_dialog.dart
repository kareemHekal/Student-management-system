import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'package:student_management_system/theme/snack_bar.dart';

import '../loadingFile/loading_alert/run_with_loading.dart';

class addStudentPaidDialog extends StatefulWidget {
  final double paidAmount;
  final double fullPrice;
  final Function(double, String) onSave;

  const addStudentPaidDialog({
    super.key,
    required this.paidAmount,
    required this.fullPrice,
    required this.onSave,
  });

  @override
  State<addStudentPaidDialog> createState() => _addStudentPaidDialogState();
}

class _addStudentPaidDialogState extends State<addStudentPaidDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController amountController;
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    amountController =
        TextEditingController(text: widget.paidAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    amountController.dispose();
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
          color: AppColors.secondaryMain,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.payments_outlined,
                color: AppColors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'تحديث الدفع',
              style: AppTextStyles.customText(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Price Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryMain.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: AppColors.secondaryMain.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إجمالي قيمة الاشتراك:',
                      style: AppTextStyles.customText(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${widget.fullPrice.toStringAsFixed(2)} \$',
                      style: AppTextStyles.customText(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryMain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Amount Input
              TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.customText(
                    fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'المبلغ المدفوع',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.money_outlined,
                      color: AppColors.secondaryMain),
                  filled: true,
                  fillColor: Colors.grey[50],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                        color: AppColors.secondaryMain, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                        color: AppColors.statusAbsent, width: 1),
                  ),
                ),
                validator: (value) {
                  final enteredAmount = double.tryParse(value ?? '') ?? -1;
                  if (value == null || value.isEmpty) {
                    return 'من فضلك أدخل المبلغ';
                  } else if (enteredAmount < 0) {
                    return 'مبلغ غير صالح';
                  } else if (enteredAmount > widget.fullPrice + 0.01) {
                    return 'لا يمكن أن يتجاوز السعر الكامل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Description Input
              TextFormField(
                controller: descriptionController,
                maxLines: 2,
                style: AppTextStyles.customText(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'الوصف أو الملاحظة',
                  hintText: 'أضف ملاحظة (اختياري)...',
                  prefixIcon: const Icon(Icons.note_alt_outlined,
                      color: AppColors.secondaryMain),
                  filled: true,
                  fillColor: Colors.grey[50],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                        color: AppColors.secondaryMain, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      actions: [
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
                  backgroundColor: AppColors.secondaryMain,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final enteredAmount =
                        double.tryParse(amountController.text) ?? 0.0;
                    final description = descriptionController.text.trim();

                    await runWithLoading(context, () async {
                      await widget.onSave(enteredAmount, description);
                      if (context.mounted) {
                        AppSnackBars.showSuccess(
                            context, "تم تحديث الدفعة بنجاح ✅");
                        Navigator.pop(context);
                      }
                    });
                  }
                },
                child: Text(
                  'حفظ التعديل',
                  style: AppTextStyles.customText(
                    color: AppColors.white,
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
}