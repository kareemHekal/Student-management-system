import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import 'verifiy_password.dart';

class DeleteSubscriptionDialog extends StatelessWidget {
  final String gradeName;
  final String id;

  const DeleteSubscriptionDialog({
    Key? key,
    required this.gradeName,
    required this.id,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.red[50],
      title: Text(
        "حذف الاشتراك",
        style: TextStyle(
          color: Colors.red[900],
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          'هل أنت متأكد أنك تريد حذف هذا الاشتراك؟\n\n'
          'عند تنفيذ هذه العملية سيتم أيضًا حذف اسم هذا الاشتراك من جميع الفواتير المرتبطة به، '
          'ولكن ستظل تفاصيل الفواتير كما هي دون حذف.',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: Colors.red[700],
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red[900],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text("إلغاء"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red[600],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 5,
          ),
          child: const Text("حذف"),
          onPressed: () async {
            showVerifyPasswordDialog(
              context: context,
              onVerified: () async {
                await runWithLoading(context, () async {
                  await FirebaseFunctions.deleteSubscriptionFromGrade(
                    gradeName,
                    id,
                  );
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("تم حذف الاشتراك بنجاح"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }
}
