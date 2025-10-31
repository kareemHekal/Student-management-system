import 'package:flutter/material.dart';
import 'package:student_management_system/Alert%20dialogs/add_edit_exam.dart';

import '../cards/exam_card.dart'; // Import your ExamCard
import '../colors_app.dart';
import '../firebase/exams_functions.dart';
import '../models/exam_model.dart';

class ExamsForGrade extends StatelessWidget {
  final String gradeName;

  const ExamsForGrade({super.key, required this.gradeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              showAddEditExamDialog(gradeName: gradeName, context: context);
            },
            icon: const Icon(Icons.add, size: 40, color: app_colors.green),
          )
        ],
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: app_colors.green),
        ),
        backgroundColor: app_colors.darkGrey,
        title: Image.asset("assets/images/logo.png", height: 100, width: 90),
        toolbarHeight: 150,
      ),
      body: StreamBuilder<List<ExamModel>>(
        stream: FirebaseExams.getExamsStream(gradeName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل البيانات',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final exams = snapshot.data ?? [];

          if (exams.isEmpty) {
            return Center(
              child: Text(
                'لا توجد امتحانات لهذه المرحلة',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: exams.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final exam = exams[index];
              return ExamCard(
                exam: exam,
                gradeName: gradeName,
              );
            },
          );
        },
      ),
    );
  }
}
