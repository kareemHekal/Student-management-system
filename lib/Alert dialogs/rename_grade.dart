import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';

Future<void> renameGrade({
  required BuildContext context,
  required String oldGrade,
}) async {
  final TextEditingController gradeController =
      TextEditingController(text: oldGrade);
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'اسم المرحلة الجديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: gradeController,
            decoration: InputDecoration(
              hintText: 'اسم المرحلة الجديد',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'من فضلك أدخل اسم المرحلة الجديد';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              FirebaseFunctions.renameGrade(oldGrade, gradeController.text);
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      );
    },
  );
}
