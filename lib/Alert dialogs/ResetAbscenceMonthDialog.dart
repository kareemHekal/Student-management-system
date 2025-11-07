import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';

class StartNewMonthDialog extends StatefulWidget {
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
      title: Text(
        'تسجيل عدد ايام حضور وغياب كل طالب للشهر المنتهي',
        style: TextStyle(color: Colors.green[900], fontSize: 20),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ادخل اسم الشهر الذي انتهى',
              style: TextStyle(color: Colors.green[800], fontSize: 14),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: monthController,
              decoration: InputDecoration(
                hintText: 'ادخل اسم الشهر الي خلص',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال اسم الشهر';
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            Text(
              'سيتم حفظ عدد أيام الحضور والغياب للشهر السابق وبدء عد أيام الشهر الجديد.',
              style: TextStyle(color: Colors.green[800], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('إلغاء', style: TextStyle(color: Colors.green[400])),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final finishedMonthName = monthController.text.trim();

              // Show the loading and run the Firestore function
              await runWithLoading(context, () async {
                await FirebaseFunctions.saveMonthAndStartNew(finishedMonthName);
              });

              // Close the dialog after loading finishes
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pushNamedAndRemoveUntil(
                    context, "/HomeScreen", (_) => false);
              }

              // Optional: show a success message
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("تم حفظ الشهر '$finishedMonthName' بنجاح"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
        ),
      ],
      backgroundColor: Colors.green[50],
    );
  }
}
