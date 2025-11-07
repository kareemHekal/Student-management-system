import 'package:flutter/material.dart';

import '../firebase/exams_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';

Future<void> showDeleteStudentExamGradeDialog({
  required BuildContext context,
  required String gradeName,
  required String studentId,
  required String examId,
  required String miniExamId,
  required String examName,
  required String miniExamName,
}) async {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.red[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 30),
            const SizedBox(width: 8),
            const Text(
              "تأكيد الحذف",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "هل أنت متأكد أنك تريد حذف درجة هذا الطالب في:",
              style: TextStyle(fontSize: 15.5, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text("📘 الامتحان: $examName",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text("🧾 النموذج: $miniExamName",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              "❗ سيتم إزالة الدرجة نهائيًا ولا يمكن التراجع عن هذا الإجراء.",
              style: TextStyle(
                color: Colors.red[900],
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              "إلغاء",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_forever,
                  size: 20, color: Colors.white),
              label: const Text(
                "حذف",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            onPressed: () async {
              final parentContext =
                  Navigator.of(context, rootNavigator: true).context;

              await runWithLoading(context, () async {
                await FirebaseExams.deleteStudentExamGrade(
                  gradeName: gradeName,
                  studentId: studentId,
                  examId: examId,
                  miniExamId: miniExamId,
                );
              });

              if (context.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "✅ تم حذف درجة الطالب بنجاح",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    margin:
                        const EdgeInsets.only(bottom: 70, left: 10, right: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );

                Navigator.pushNamedAndRemoveUntil(
                  parentContext,
                  '/StudentsTab',
                  (route) => false,
                );
              }
            },
          ),
        ],
      );
    },
  );
}
