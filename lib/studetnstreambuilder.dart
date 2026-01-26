import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';
import 'BottomSheets/student_chosen_pdf.dart';
import 'cards/student/StudentWidget.dart';
import 'models/Student_model.dart';
import 'theme/colors_app.dart';

class StudentStreamBuilder extends StatefulWidget {
  final String grade;

  StudentStreamBuilder({required this.grade, super.key});

  @override
  State<StudentStreamBuilder> createState() => _StudentStreamBuilderState();
}

class _StudentStreamBuilderState extends State<StudentStreamBuilder> {
  final _searchController = TextEditingController();
  List<Studentmodel> _filteredStudents = [];
  int numberofstudents = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredStudents.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Center(child: Image.asset("assets/images/logo.png")),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMain,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.print,
                                      color: Colors.white),
                                  onPressed: () {
                                    StudentChosenPdf.show(
                                        context: context,
                                        students: _filteredStudents);
                                  },
                                ),
                                Text(
                                  "عدد الطلاب: $numberofstudents",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            child: TextFormField(
                              style:
                                  const TextStyle(color: AppColors.primaryMain),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'ابحث عن الطالب',
                                hintStyle: const TextStyle(
                                    color: AppColors.primaryMain),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 20.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: AppColors.secondaryMain,
                                      width: 2.0),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: AppColors.secondaryMain,
                                      width: 2.0),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppColors.secondaryMain),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                ),
                              ),
                              cursorColor: AppColors.primaryMain,
                              controller: _searchController,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<List<Studentmodel>>(
                        stream: FirebaseFunctions.getAllStudentsByGrade(
                            widget.grade),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Studentmodel>> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('حدث خطأ: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (numberofstudents != 0) {
                                setState(() {
                                  numberofstudents = 0;
                                });
                              }
                            });
                            return Center(
                                child: Text(
                                    'لا يوجد طلاب للمرحلة: ${widget.grade}'));
                          }

                          var students = snapshot.data!;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (numberofstudents != students.length) {
                              setState(() {
                                numberofstudents = students.length;
                              });
                            }
                          });

                          if (_searchController.text.isNotEmpty) {
                            _filteredStudents = students.where((student) {
                              return student.name?.toLowerCase().contains(
                                      _searchController.text.toLowerCase()) ??
                                  false;
                            }).toList();
                          } else {
                            _filteredStudents = students;
                          }

                          return ListView.builder(
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return StudentWidget(
                                studentModel: student,
                                IsComingFromGroup: false,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
