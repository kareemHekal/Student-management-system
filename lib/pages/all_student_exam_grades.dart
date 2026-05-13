import 'package:flutter/material.dart';
import 'package:student_management_system/alert_dialogs/add_exam_degree.dart';

import '../cards/student/student_exam_grade.dart';
import '../models/Student_model.dart';
import '../models/student_exam_grade.dart';
import '../theme/colors_app.dart';

class AllStudentExamGrades extends StatelessWidget {
  final Studentmodel student;

  const AllStudentExamGrades({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final exams = student.studentExamsGrades ?? [];
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              showAddStudentExamGradeDialog(
                context: Navigator.of(context, rootNavigator: true).context,
                gradeName: student.grade ?? "",
                studentId: student.id,
              );
            },
            icon:
                const Icon(Icons.add, size: 40, color: AppColors.secondaryMain),
          ),
        ],
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
        ),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset("assets/images/logo.png", height: 100, width: 90),
        toolbarHeight: 150,
      ),

      /// Main body
      body: exams.isEmpty
          ? const Center(
              child: Text(
                'لا توجد درجات لهذا الطالب بعد',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: exams.length,
              separatorBuilder: (context, index) => const Divider(
                thickness: 1.5,
                color: Colors.grey,
              ),
              itemBuilder: (context, index) {
                final StudentExamGrade examGrade = exams[index];
                return StudentExamCard(
                  studentId: student.id,
                  gradeName: student.grade ?? "",
                  examGrade: examGrade,
                );
              },
            ),
    );
  }
}
