import 'package:flutter/material.dart';

import '../Alert dialogs/delete_student_exam_grade.dart';
import '../Alert dialogs/edit_student_exam_grade.dart';
import '../colors_app.dart';
import '../firebase/exams_functions.dart';
import '../models/exam_model.dart';
import '../models/mini_exam.dart';
import '../models/student_exam_grade.dart';

class StudentExamCard extends StatefulWidget {
  final String gradeName;
  final String studentId;
  final StudentExamGrade examGrade;

  const StudentExamCard({
    Key? key,
    required this.studentId,
    required this.gradeName,
    required this.examGrade,
  }) : super(key: key);

  @override
  State<StudentExamCard> createState() => _StudentExamCardState();
}

class _StudentExamCardState extends State<StudentExamCard> {
  ExamModel? exam;
  MiniExam? miniExam;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamAndMiniExam();
  }

  Future<void> _loadExamAndMiniExam() async {
    final examResult = await FirebaseExams.getExamById(
        widget.gradeName, widget.examGrade.examId);

    MiniExam? foundMini;
    if (examResult != null && examResult.miniExams != null) {
      try {
        foundMini = examResult.miniExams!
            .firstWhere((m) => m.id == widget.examGrade.miniExamId);
      } catch (_) {}
    }

    setState(() {
      exam = examResult;
      miniExam = foundMini;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (exam == null || miniExam == null) {
      return const Center(child: Text("❌ Exam not found"));
    }

    double studentScore = 0;
    double totalScore = miniExam!.fullGrade;

    try {
      studentScore = double.parse(
          widget.examGrade.studentGrade.split('from').first.trim());
    } catch (_) {}

    double ratio = totalScore > 0 ? (studentScore / totalScore) : 0;

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
            /// Title Row with Edit/Delete
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam!.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        miniExam!.miniExamName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'تعديل الدرجة أو الملاحظة',
                  onPressed: () async {
                    await showEditStudentExamGradeDialog(
                      context: context,
                      gradeName: widget.gradeName,
                      studentId: widget.studentId,
                      examGrade: widget.examGrade,
                      examName: exam!.name,
                      miniExamName: miniExam!.miniExamName,
                      fullGrade: miniExam!.fullGrade,
                    );
                  },
                  icon: Icon(Icons.edit, color: Colors.blue[700]),
                ),
                IconButton(
                  tooltip: 'حذف هذا الامتحان من سجل الطالب',
                  onPressed: () {
                    showDeleteStudentExamGradeDialog(
                      context: context,
                      gradeName: widget.gradeName,
                      studentId: widget.studentId,
                      examId: exam?.id ?? "",
                      miniExamId: miniExam!.id,
                      examName: exam!.name,
                      miniExamName: miniExam!.miniExamName,
                    );
                  },
                  icon: Icon(Icons.delete, color: Colors.red[700]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Grade Info Row
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'درجة الطالب: ${widget.examGrade.studentGrade}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'الدرجة الكاملة: ${miniExam!.fullGrade.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🟢 Progress Indicator (Much Bigger)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50, // ⬅️ bigger circle
                      height: 50,
                      child: CircularProgressIndicator(
                        value: ratio,
                        backgroundColor: app_colors.green.withOpacity(0.3),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(app_colors.green),
                        strokeWidth: 8, // ⬅️ thicker ring
                      ),
                    ),
                    Text(
                      '${(ratio * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16, // ⬅️ larger text
                        fontWeight: FontWeight.bold,
                        color: app_colors.darkGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    widget.examGrade.description.isEmpty
                        ? 'لا يوجد ملاحظات'
                        : widget.examGrade.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
