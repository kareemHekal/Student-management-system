import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import 'verifiy_password.dart';

void DeleteGradeDialog(BuildContext context, String gradeToDelete) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFFFE5E5),
        // light red background
        title: const Text(
          "⚠️ حذف الصف",
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'هل أنت متأكد أنك تريد حذف الصف "$gradeToDelete"؟\n\n'
            'عند تنفيذ هذه العملية سيتم:\n'
            '🟥   حذف جميع الطلاب المنتمين إلى هذا الصف نهائيًا.\n\n'
            '💡 إذا كنت تريد فقط تغيير اسم الصف دون حذف الطلاب، '
            'اضغط على أيقونة ✏️ لتعديل الاسم، وسيتم تحديث اسم الصف لكل الطلاب تلقائيًا.\n\n'
            '⚠️ هذا الإجراء لا يمكن التراجع عنه.',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: Colors.red,
              height: 1.4,
              fontSize: 16,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFBDBD),
              // soft red background for cancel
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "إلغاء",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              showVerifyPasswordDialog(
                context: context,
                onVerified: () async {
                  await runWithLoading(context, () async {
                    await FirebaseFunctions.deleteGradeFromList(gradeToDelete);
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم حذف الصف بنجاح")),
                    );
                  }
                },
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "حذف",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}
