import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart'; // Using your custom snackbar logic
import 'package:student_management_system/theme/text_style.dart';

import '../loadingFile/loading_alert/run_with_loading.dart';

class EditPaidDialog extends StatefulWidget {
  final double paidAmount;
  final double fullPrice;
  final Function(double newAmount, double allAmount, String description) onSave;

  const EditPaidDialog({
    super.key,
    required this.paidAmount,
    required this.fullPrice,
    required this.onSave,
  });

  @override
  State<EditPaidDialog> createState() => _EditPaidDialogState();
}

class _EditPaidDialogState extends State<EditPaidDialog> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorText;

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingAmount = widget.fullPrice - widget.paidAmount;

    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.primaryDark, // Positive green theme
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_card_rounded, color: AppColors.white),
            const SizedBox(width: 12),
            Text(
              'إضافة مبلغ دفع',
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
              // Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: AppColors.primaryDark.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    _buildBalanceRow("السعر الكامل", widget.fullPrice,
                        isBold: false),
                    const Divider(height: 16),
                    _buildBalanceRow("المدفوع حالياً", widget.paidAmount,
                        color: AppColors.statusPresent),
                    _buildBalanceRow("المتبقي للدفع", remainingAmount,
                        color: AppColors.statusAbsent, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Amount Input
              _buildModernTextField(
                controller: amountController,
                label: 'المبلغ الجديد',
                hint: '0.00',
                icon: Icons.monetization_on_outlined,
                isNumber: true,
                errorText: _errorText,
              ),
              const SizedBox(height: 16),
              // Note Input
              _buildModernTextField(
                controller: descriptionController,
                label: 'الوصف أو الملاحظة',
                hint: 'مثلاً: دفعة جزئية...',
                icon: Icons.edit_note_rounded,
                isMultiline: true,
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
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final newAmount = double.tryParse(amountController.text) ?? 0;
                  final allPaid = widget.paidAmount + newAmount;
                  final description = descriptionController.text.trim();

                  setState(() {
                    if (newAmount <= 0) {
                      _errorText = 'من فضلك أدخل مبلغاً صالحاً';
                    } else if (allPaid > widget.fullPrice + 0.01) {
                      // Adding small delta for double precision
                      _errorText = 'المبلغ يتجاوز المتبقي ($remainingAmount)';
                    } else {
                      _errorText = null;
                    }
                  });

                  if (_errorText == null) {
                    await runWithLoading(context, () async {
                      await widget.onSave(newAmount, allPaid, description);
                      if (context.mounted) {
                        AppSnackBars.showSuccess(
                            context, "تم تحديث مبلغ الدفع بنجاح ✅");
                        Navigator.pop(context);
                      }
                    });
                  }
                },
                child: Text(
                  'تحديث',
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

  Widget _buildBalanceRow(String label, double amount,
      {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.customText(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(
            "${amount.toStringAsFixed(2)} \$",
            style: AppTextStyles.customText(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    bool isMultiline = false,
    String? errorText,
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
        errorText: errorText,
        errorMaxLines: 2,
        prefixIcon: Icon(icon, color: AppColors.primaryDark, size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
      ),
    );
  }
}