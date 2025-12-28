import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';
import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import '../models/subscription_fee.dart';
import '../theme/colors_app.dart';
import 'verifiy_password.dart';

Future<void> showAddOrEditSubscriptionDialog(BuildContext context,
    String gradeName, {
      SubscriptionFee? subscriptionFee,
    }) async {
  final bool isEdit = subscriptionFee != null;

  final TextEditingController nameController =
      TextEditingController(text: subscriptionFee?.subscriptionName ?? '');
  final TextEditingController amountController = TextEditingController(
      text: subscriptionFee?.subscriptionAmount.toString() ?? '');
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.white,
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
            isEdit ? 'تعديل بيانات الاشتراك' : 'إضافة اشتراك جديد',
            style: AppTextStyles.customText(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _buildModernTextField(
                controller: nameController,
                label: 'اسم الاشتراك',
                hint: 'مثلاً: شهر يناير',
                icon: Icons.description_outlined,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'من فضلك أدخل اسم الاشتراك'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: amountController,
                label: 'المبلغ المستحق',
                hint: '0.00',
                icon: Icons.monetization_on_outlined,
                isNumber: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'من فضلك أدخل المبلغ';
                  if (double.tryParse(value) == null) return 'أدخل رقم صالح';
                  return null;
                },
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'إلغاء',
                    style: AppTextStyles.customText(
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEdit
                        ? AppColors.primaryMain
                        : AppColors.secondaryMain,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;

                    await runWithLoading(context, () async {
                      if (isEdit) {
                        await showVerifyPasswordDialog(
                          context: context,
                          onVerified: () async {
                            await FirebaseFunctions.updateSubscriptionInGrade(
                              gradeName,
                              SubscriptionFee(
                                id: subscriptionFee.id,
                                subscriptionName: nameController.text.trim(),
                                subscriptionAmount: double.tryParse(
                                        amountController.text.trim()) ??
                                    0.0,
                              ),
                            );

                            if (context.mounted) {
                              AppSnackBars.showSuccess(
                                  context, 'تم تعديل الاشتراك بنجاح');
                            }
                          },
                        );
                      } else {
                        await FirebaseFunctions.addSubscriptionToGrade(
                          gradeName,
                          nameController.text.trim(),
                          double.tryParse(amountController.text.trim()) ?? 0.0,
                        );

                        if (context.mounted) {
                          AppSnackBars.showSuccess(
                              context, 'تم إضافة الاشتراك بنجاح');
                        }
                      }

                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                  child: Text(
                    isEdit ? 'تعديل' : 'حفظ',
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
    },
  );
}

/// Reusable Modern TextField Helper
Widget _buildModernTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  bool isNumber = false,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: isNumber
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    inputFormatters: inputFormatters,
    style: AppTextStyles.customText(fontSize: 15),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryMain, size: 22),
      filled: true,
      fillColor: Colors.grey[50],
      labelStyle: AppTextStyles.customText(
          color: AppColors.textSecondary, fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.primaryMain, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.statusAbsent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.statusAbsent, width: 1.5),
      ),
    ),
    validator: validator,
  );
}