import 'package:flutter/material.dart';

import '../firebase/exams_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import '../models/exam_model.dart';
import '../models/mini_exam.dart';
import '../models/student_exam_grade.dart';

Future<void> showAddStudentExamGradeDialog({
  required BuildContext context,
  required String gradeName,
  required String studentId,
}) async {
  final exams = await FirebaseExams.getExams(gradeName);

  ExamModel? selectedExam;
  MiniExam? selectedMiniExam;
  final studentGradeController = TextEditingController();
  final descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // <-- form key for validation

  int step = 1;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.green[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(
              step == 1 ? 'اختر الامتحان' : 'أدخل درجة الطالب',
              style: TextStyle(
                  color: Colors.green[900], fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: step == 1
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<ExamModel>(
                            value: selectedExam,
                            decoration: InputDecoration(
                              labelText: 'اختر الامتحان',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: Colors.green.shade700)),
                            ),
                            items: exams
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (exam) {
                              setState(() {
                                selectedExam = exam;
                                selectedMiniExam = null;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'اختر الامتحان' : null,
                          ),
                          const SizedBox(height: 12),
                          if (selectedExam != null)
                            DropdownButtonFormField<MiniExam>(
                              value: selectedMiniExam,
                              decoration: InputDecoration(
                                labelText: 'اختر الامتحان الفرعي',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.green.shade700)),
                              ),
                              items: selectedExam!.miniExams
                                  ?.map(
                                    (me) => DropdownMenuItem(
                                      value: me,
                                      child: Text(me.miniExamName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (mini) {
                                setState(() {
                                  selectedMiniExam = mini;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'اختر الامتحان الفرعي' : null,
                            ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'الدرجة الكاملة للامتحان الفرعي: ${selectedMiniExam?.fullGrade ?? ''}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: studentGradeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'درجة الطالب',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (value) {
                                final val = double.tryParse(value ?? '');
                                if (val == null) return 'أدخل درجة صحيحة';
                                if (val >
                                    (selectedMiniExam?.fullGrade ??
                                        double.infinity)) {
                                  return 'درجة الطالب لا يمكن أن تتجاوز الدرجة الكاملة';
                                }
                                if (val < 0) return 'درجة الطالب غير صحيحة';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                labelText: 'ملاحظة (اختياري)',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.green[900]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                ),
                onPressed: () async {
                  if (step == 1) {
                    if (selectedExam != null && selectedMiniExam != null) {
                      setState(() => step = 2);
                    }
                  } else {
                    if (!(_formKey.currentState?.validate() ?? false)) return;

                    await runWithLoading(context, () async {
                      final parentContext =
                          Navigator.of(context, rootNavigator: true).context;
                      final gradeValue =
                          double.parse(studentGradeController.text.trim());

                      final newGrade = StudentExamGrade(
                        studentGrade: gradeValue.toString(),
                        examId: selectedExam?.id ?? "",
                        miniExamId: selectedMiniExam!.id,
                        description: descriptionController.text.trim(),
                      );

                      await FirebaseExams.addStudentExamGrade(
                        gradeName,
                        studentId,
                        newGrade,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "✅ تم إضافة درجة الطالب بنجاح",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
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
                      }
                    });
                  }
                },
                child: const Text(
                  'حفظ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
