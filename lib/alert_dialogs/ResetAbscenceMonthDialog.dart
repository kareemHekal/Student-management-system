import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';

class StartNewMonthDialog extends StatefulWidget {
  const StartNewMonthDialog({super.key});

  @override
  State<StartNewMonthDialog> createState() => _StartNewMonthDialogState();
}

class _StartNewMonthDialogState extends State<StartNewMonthDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController monthController = TextEditingController();

  @override
  void dispose() {
    monthController.dispose();
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
          color: AppColors.secondaryMain, // Fresh Green Theme
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded,
                color: AppColors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'بدء شهر جديد',
                style: AppTextStyles.customText(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Text(
                'أرشفة بيانات الشهر المنتهي وبدء عداد جديد',
                textAlign: TextAlign.center,
                style: AppTextStyles.customText(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: monthController,
                style: AppTextStyles.customText(
                    fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'اسم الشهر المنتهي',
                  hintText: 'مثال: أكتوبر 2023',
                  prefixIcon: const Icon(Icons.history_toggle_off_rounded,
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال اسم الشهر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryMain.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.secondaryMain.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.secondaryMain, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'سيتم تصفير عداد الحضور والغياب الحالي وحفظه في السجل التاريخي للطلاب.',
                        style: AppTextStyles.customText(
                          color: AppColors.secondaryMain,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
                    final finishedMonthName = monthController.text.trim();

                    await runWithLoading(context, () async {
                      await FirebaseFunctions.saveMonthAndStartNew(
                          finishedMonthName);
                    });

                    if (context.mounted) {
                      AppSnackBars.showSuccess(
                          context, "تم أرشفة شهر $finishedMonthName بنجاح ✅");
                      Navigator.pushNamedAndRemoveUntil(
                          context, "/HomeScreen", (_) => false);
                    }
                  }
                },
                child: Text(
                  'تأكيد',
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