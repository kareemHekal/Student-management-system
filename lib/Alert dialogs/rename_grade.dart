import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import 'verifiy_password.dart';

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
              String newGrade = gradeController.text.trim();

              // 2️⃣ Fetch grades list
              List<String> fetchedGrades =
                  await FirebaseFunctions.getGradesList();

              // 3️⃣ Check if new grade already exists
              if (fetchedGrades.contains(newGrade)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("الصف موجود بالفعل!"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return; // ⛔ Stop here
              }

              // 4️⃣ Continue rename
              showVerifyPasswordDialog(
                context: context,
                onVerified: () async {
                  await runWithLoading(context, () async {
                    await FirebaseFunctions.renameGrade(
                      oldGrade,
                      newGrade,
                    );
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("تم تغيير اسم الصف بنجاح"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              );
            },
            child: const Text('تأكيد'),
          ),
        ],
      );
    },
  );
}
