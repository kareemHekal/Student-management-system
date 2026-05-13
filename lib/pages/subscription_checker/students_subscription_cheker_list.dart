import 'package:flutter/material.dart';

import '../../models/Student_model.dart';
import '../../theme/text_style.dart';

// استورد ويدجت StudentWidget هنا
// import '../widgets/student_widget.dart';

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
      backgroundColor: const Color(0xffF8FAFF),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        title: Text(title,
            style: AppTextStyles.customText(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: themeColor,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              onPressed: onPdfPressed,
              icon: const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.white)),
        ],
      ),
      body: students.isEmpty
          ? Center(
              child: Text("لا يوجد طلاب",
                  style: AppTextStyles.customText(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: students.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // ملاحظة: تأكد من استيراد StudentWidget بشكل صحيح
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: ListTile(
                    title: Text(students[index].name ?? "",
                        style: AppTextStyles.customText(fontSize: 15)),
                    subtitle: Text(grade,
                        style: AppTextStyles.customText(
                            fontSize: 12, color: Colors.grey)),
                    leading: CircleAvatar(
                        backgroundColor: themeColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: themeColor)),
                  ),
                );
              },
            ),
    );
  }
}