import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors_app.dart'; // For your custom green theme
import '../firebase/firebase_functions.dart';
import '../models/subscription_fee.dart';

Future<void> showAddOrEditSubscriptionDialog(
  BuildContext context,
  String gradeName, {
  SubscriptionFee? subscriptionFee,
}) async {
  final bool isEdit = subscriptionFee != null;

  final TextEditingController nameController =
      TextEditingController(text: subscriptionFee?.subscriptionName ?? '');
  final TextEditingController amountController = TextEditingController(
      text: subscriptionFee?.subscriptionAmount.toString() ?? '');
  final formKey = GlobalKey<FormState>();

  // 🎨 Define color scheme
  final Color mainColor = isEdit ? Colors.blue.shade50 : app_colors.ligthGreen;
  final Color textColor = isEdit ? Colors.blue.shade900 : app_colors.green;
  final Color accentColor = isEdit ? Colors.blue.shade400 : app_colors.green;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: mainColor,
        title: Text(
          isEdit ? 'تعديل الاشتراك' : 'إضافة اشتراك جديد',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 18,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'اسم الاشتراك (مثلاً: شهر يناير)',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accentColor),
                  ),
                  prefixIcon: Icon(Icons.text_fields, color: accentColor),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'من فضلك أدخل اسم الاشتراك';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                style: TextStyle(color: textColor),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'المبلغ (مثلاً: 150)',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accentColor),
                  ),
                  prefixIcon: Icon(Icons.monetization_on, color: accentColor),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'من فضلك أدخل المبلغ';
                  }
                  if (double.tryParse(value) == null) {
                    return 'من فضلك أدخل رقم صالح';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 3,
            ),
            child: Text(isEdit ? 'تعديل' : 'حفظ'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (isEdit) {
                  await FirebaseFunctions.updateSubscriptionInGrade(
                    gradeName,
                    SubscriptionFee(
                      id: subscriptionFee.id,
                      subscriptionName: nameController.text.trim(),
                      subscriptionAmount:
                          double.tryParse(amountController.text.trim()) ?? 0.0,
                    ),
                  );
                } else {
                  await FirebaseFunctions.addSubscriptionToGrade(
                    gradeName,
                    nameController.text.trim(),
                    double.tryParse(amountController.text.trim()) ?? 0.0,
                  );
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit
                          ? 'تم تعديل الاشتراك بنجاح'
                          : 'تم إضافة الاشتراك بنجاح',
                    ),
                    backgroundColor: accentColor,
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
