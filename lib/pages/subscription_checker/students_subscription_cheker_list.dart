import 'package:flutter/material.dart';
import 'package:student_management_system/cards/student/StudentWidget.dart';
import 'package:student_management_system/models/Student_model.dart';

class StudentResultListPage extends StatelessWidget {
  final String title;
  final List<Studentmodel> students;
  final String grade;
  final Color themeColor;
  final VoidCallback onPdfPressed;

  const StudentResultListPage({
    super.key,
    required this.title,
    required this.students,
    required this.grade,
    required this.themeColor,
    required this.onPdfPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        toolbarHeight: 100,
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: onPdfPressed,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: "تحميل ملف PDF",
          )
        ],
      ),
      body: students.isEmpty
          ? const Center(child: Text("لا يوجد طلاب في هذه القائمة"))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              itemCount: students.length,
              itemBuilder: (context, index) {
                return StudentWidget(
                  studentModel: students[index],
                  grade: grade,
                  IsComingFromGroup: false, // As requested
                );
              },
            ),
    );
  }
}
