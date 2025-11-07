import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';

Future<void> showChangePasswordDialog(BuildContext context) async {
  final TextEditingController newPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تغيير كلمة المرور',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'كلمة المرور الجديدة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock_open),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'من فضلك أدخل كلمة المرور الجديدة';
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              await runWithLoading(context, () async {
                final success = await FirebaseFunctions.changePassword(
                  newPasswordController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog first

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'تم تغيير كلمة المرور بنجاح'
                            : 'حدث خطأ أثناء تغيير كلمة المرور',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      margin: const EdgeInsets.only(
                          bottom: 70, left: 10, right: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              });
            },
            child: const Text('حفظ'),
          ),
        ],
      );
    },
  );
}
