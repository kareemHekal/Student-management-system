import 'package:flutter/material.dart';

import '../Alert dialogs/add_edit_exam.dart';
import '../Alert dialogs/delete_exam.dart';
import '../models/exam_model.dart';

class ExamCard extends StatelessWidget {
  final ExamModel exam;
  final String gradeName;

  const ExamCard({super.key, required this.exam, required this.gradeName});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green[50],
      shadowColor: Colors.green[200],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with Edit & Delete
            Row(
              children: [
                Expanded(
                  child: Text(
                    exam.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'تعديل الامتحان',
                  onPressed: () {
                    showAddEditExamDialog(
                        gradeName: gradeName, exam: exam, context: context);
                  },
                  icon: Icon(Icons.edit, color: Colors.blue[700]),
                ),
                IconButton(
                  tooltip: 'حذف الامتحان',
                  onPressed: () {
                    showDeleteExamDialog(
                      context: context,
                      gradeName: gradeName,
                      examId: exam.id!,
                      examName: exam.name,
                    );
                  },
                  icon: Icon(Icons.delete, color: Colors.red[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mini Exams List
            if (exam.miniExams == null || exam.miniExams!.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'لا يوجد نماذج للامتحان',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: exam.miniExams!.map((mini) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mini.miniExamName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'الدرجة الكاملة: ${mini.fullGrade.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
