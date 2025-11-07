import 'package:flutter/material.dart';

import '../firebase/exams_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import '../models/student_exam_grade.dart';

Future<void> showEditStudentExamGradeDialog({
  required BuildContext context,
  required String gradeName,
  required String studentId,
  required StudentExamGrade examGrade,
  required String examName,
  required String miniExamName,
  required double fullGrade,
}) async {
  final gradeController = TextEditingController(text: examGrade.studentGrade);
  final descController = TextEditingController(text: examGrade.description);

  String? errorText;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.green.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.green.shade800, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "تعديل درجة الطالب",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📘 الامتحان: $examName",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            )),
                        Text("📝 النموذج: $miniExamName",
                            style: TextStyle(color: Colors.green.shade800)),
                        Text("🏁 الدرجة الكاملة: $fullGrade",
                            style: TextStyle(color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: gradeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.score, color: Colors.green.shade700),
                      labelText: "درجة الطالب",
                      labelStyle: TextStyle(color: Colors.green.shade900),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.green.shade700, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.note_alt, color: Colors.green.shade700),
                      labelText: "ملاحظات",
                      labelStyle: TextStyle(color: Colors.green.shade900),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.green.shade700, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.only(bottom: 8, right: 8, left: 8),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.close),
                label: const Text("إلغاء"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("حفظ"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                onPressed: () async {
                  final parentContext =
                      Navigator.of(context, rootNavigator: true).context;

                  final gradeValue =
                      double.tryParse(gradeController.text.trim()) ?? -1;

                  if (gradeValue < 0 || gradeValue > fullGrade) {
                    setState(() {
                      errorText = "يجب أن تكون الدرجة بين 0 و $fullGrade";
                    });
                    return;
                  }

                  final updated = StudentExamGrade(
                    studentGrade: gradeController.text.trim(),
                    examId: examGrade.examId,
                    miniExamId: examGrade.miniExamId,
                    description: descController.text.trim(),
                  );

                  runWithLoading(context, () async {
                    await FirebaseExams.updateStudentExamGrade(
                      gradeName: gradeName,
                      studentId: studentId,
                      updatedGrade: updated,
                    );

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "✅ تم تعديل درجة الطالب بنجاح",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                        margin: const EdgeInsets.only(
                            bottom: 70, left: 10, right: 10),
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
                  });
                },
              ),
            ],
          );
        },
      );
    },
  );
}
