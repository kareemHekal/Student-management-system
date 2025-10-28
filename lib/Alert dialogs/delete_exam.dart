import 'package:flutter/material.dart';

import '../firebase/exams_functions.dart';

Future<void> showDeleteExamDialog({
  required BuildContext context,
  required String gradeName,
  required String examId,
  required String examName,
}) async {
  final themeColor = Colors.red; // red for delete warning

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: themeColor[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'حذف الامتحان',
          style: TextStyle(color: themeColor[900], fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف الامتحان "$examName"؟\n\n'
          'هذا سيؤدي إلى حذف هذا الامتحان من جميع الطلاب الذين لديهم هذا الامتحان.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: themeColor[900])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themeColor[700]),
            onPressed: () async {
              // Call your delete function
              await FirebaseExams.deleteExam(gradeName, examId);
              Navigator.pop(context);
            },
            child: Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
