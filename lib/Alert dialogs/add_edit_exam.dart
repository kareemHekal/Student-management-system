import 'package:flutter/material.dart';

import '../firebase/exams_functions.dart';
import '../models/exam_model.dart';
import '../models/mini_exam.dart';

Future<void> showAddEditExamDialog({
  required BuildContext context,
  required String gradeName,
  ExamModel? exam, // null → add, not null → edit
}) async {
  final _formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  final examNameController = TextEditingController(text: exam?.name ?? '');
  final miniExamFields = exam?.miniExams
          ?.map((e) => MiniExamField(
                miniExamNameController:
                    TextEditingController(text: e.miniExamName),
                fullGradeController:
                    TextEditingController(text: e.fullGrade.toString()),
              ))
          .toList() ??
      [];

  void addMiniExamField() {
    miniExamFields.add(MiniExamField(
      miniExamNameController: TextEditingController(),
      fullGradeController: TextEditingController(),
    ));
    // scroll to bottom after a frame
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void removeMiniExamField(int index) {
    miniExamFields[index].miniExamNameController.dispose();
    miniExamFields[index].fullGradeController.dispose();
    miniExamFields.removeAt(index);
  }

  final isEdit = exam != null;
  final themeColor = isEdit ? Colors.blue : Colors.green;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: themeColor[50],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            isEdit ? 'تعديل امتحان' : 'إضافة امتحان',
            style:
                TextStyle(color: themeColor[900], fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Exam Name
                    TextFormField(
                      controller: examNameController,
                      decoration: InputDecoration(
                        labelText: 'اسم الامتحان',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: themeColor.shade700),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: themeColor.shade900, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'من فضلك أدخل اسم الامتحان';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Mini Exams Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الامتحانات الفرعية',
                            style: TextStyle(fontSize: 16)),
                        IconButton(
                          onPressed: () => setState(addMiniExamField),
                          icon: Icon(Icons.add, color: themeColor[800]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ...List.generate(miniExamFields.length, (index) {
                      final field = miniExamFields[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: field.miniExamNameController,
                                decoration: InputDecoration(
                                  labelText: 'اسم الامتحان الفرعي',
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: themeColor.shade700),
                                      borderRadius: BorderRadius.circular(10)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: themeColor.shade900, width: 2),
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'أدخل اسم الامتحان الفرعي';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: field.fullGradeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'الدرجة الكاملة',
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: themeColor.shade700),
                                      borderRadius: BorderRadius.circular(10)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: themeColor.shade900, width: 2),
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (value) {
                                  final n = double.tryParse(value ?? '');
                                  if (value == null || value.isEmpty) {
                                    return 'أدخل الدرجة';
                                  } else if (n == null || n <= 0) {
                                    return 'الدرجة يجب أن تكون رقم صالح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => removeMiniExamField(index)),
                              icon: Icon(Icons.delete, color: themeColor[700]),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(color: themeColor[900])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor[700]),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newExam = ExamModel(
                    id: exam?.id,
                    name: examNameController.text.trim(),
                    miniExams: List.generate(miniExamFields.length, (i) {
                      final oldMini =
                          exam?.miniExams != null && i < exam!.miniExams!.length
                              ? exam.miniExams![i]
                              : null;

                      return MiniExam(
                        id: oldMini?.id ?? "",
                        miniExamName: miniExamFields[i]
                            .miniExamNameController
                            .text
                            .trim(),
                        fullGrade: double.parse(
                            miniExamFields[i].fullGradeController.text),
                      );
                    }),
                  );

                  // Firestore add or update
                  if (isEdit) {
                    await FirebaseExams.updateExam(gradeName, newExam);
                  } else {
                    await FirebaseExams.addExam(gradeName, newExam);
                  }

                  Navigator.pop(context);
                }
              },
              child: Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      });
    },
  );
}

// Helper class for dynamic mini exams
class MiniExamField {
  final TextEditingController miniExamNameController;
  final TextEditingController fullGradeController;

  MiniExamField({
    required this.miniExamNameController,
    required this.fullGradeController,
  });
}
