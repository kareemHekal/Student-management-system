import 'package:flutter/material.dart';
import 'package:student_management_system/pages/student/add_student/add_student_widget.dart';

import '../firebase/firebase_functions.dart';
import '../theme/colors_app.dart';

class AddStudentTab extends StatefulWidget {
  const AddStudentTab({super.key});

  @override
  State<AddStudentTab> createState() => _AddStudentTabState();
}

class _AddStudentTabState extends State<AddStudentTab> {
  String? grade;
  List<String>? grades;

  @override
  void initState() {
    super.initState();
    fetchGrades();
  }

  Future<void> fetchGrades() async {
    List<String> fetchedGrades = await FirebaseFunctions.getGradesList();
    setState(() {
      grades = fetchedGrades;
      if (grades!.isNotEmpty) {
        grade = grades![0]; // Default to the first grade
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (grades == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (grades!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "لا توجد صفوف دراسيه متاحه يجب اضافه صفوف اولا ",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: grades!.length,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              color: AppColors.primaryMain,
              child: TabBar(
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                dividerColor: Colors.transparent,
                onTap: (index) {
                  setState(() {
                    grade = grades![index];
                  });
                },
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.secondaryMain,
                labelColor: AppColors.secondaryMain,
                unselectedLabelColor: Colors.white,
                tabs: grades!.map((g) => Tab(text: g)).toList(),
              ),
            ),
            Expanded(child: AddStudentScreen(grade: grade)),
          ],
        ),
      ),
    );
  }
}
