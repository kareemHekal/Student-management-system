import 'package:flutter/material.dart';
import 'package:student_management_system/BottomSheets/student_chosen_pdf.dart';

import '../cards/student/StudentWidget.dart';
import '../firebase/firebase_functions.dart';
import '../loadingFile/loadingWidget.dart';
import '../models/Magmo3aModel.dart';
import '../models/Student_model.dart';
import '../theme/colors_app.dart';

class StudentInAgroup extends StatefulWidget {
  Magmo3amodel magmo3aModel;

  StudentInAgroup({required this.magmo3aModel, super.key});

  @override
  State<StudentInAgroup> createState() => _StudentInAgroupState();
}

class _StudentInAgroupState extends State<StudentInAgroup> {
  final _searchController = TextEditingController();
  List<Studentmodel> filteredStudents = [];
  List<Studentmodel> allStudents = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _loadInitialStudents();
  }

  Future<void> _loadInitialStudents() async {
    var stream = FirebaseFunctions.getStudentsByGroupId(
      widget.magmo3aModel.grade ?? "",
      widget.magmo3aModel.id,
    );

    stream.listen((snapshot) {
      final students = snapshot.docs.map((e) => e.data()).toList();
      setState(() {
        allStudents = students;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf,
                color: AppColors.secondaryMain),
            onPressed: () {
              StudentChosenPdf.show(context: context, students: allStudents);
            },
          ),
        ],
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              const Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
        ),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset(
          "assets/images/logo.png",
          height: 100,
          width: 90,
        ),
        toolbarHeight: 150,
      ),
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
                      height: 130,
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            child: TextFormField(
                              style:
                                  const TextStyle(color: AppColors.primaryMain),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'ابحث',
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
                          Text(
                            "عدد الطلاب في هذه المجموعة: ${allStudents.length}",
                            style: const TextStyle(
                              color: AppColors.secondaryMain,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder(
                      stream: FirebaseFunctions.getStudentsByGroupId(
                        widget.magmo3aModel.grade ?? "",
                        widget.magmo3aModel.id,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: DiscreteCircle(
                              color: AppColors.primaryMain,
                              size: 30,
                              secondCircleColor: AppColors.secondaryMain,
                              thirdCircleColor: AppColors.secondaryMain,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("حدث خطأ ما"),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('حاول مرة أخرى'),
                                ),
                              ],
                            ),
                          );
                        }

                        var students =
                            snapshot.data?.docs.map((e) => e.data()).toList() ??
                                [];
                        allStudents = students;
                        filteredStudents = students;

                        if (_searchController.text.isNotEmpty) {
                          filteredStudents = students.where((student) {
                            return student.name?.toLowerCase().contains(
                                    _searchController.text.toLowerCase()) ??
                                false;
                          }).toList();
                        }

                        if (students.isEmpty) {
                          return Center(
                            child: Text(
                              "لا يوجد طلاب",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 25, color: AppColors.black),
                            ),
                          );
                        }

                        return Expanded(
                          child: ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 5),
                            itemBuilder: (context, index) {
                              return StudentWidget(
                                IsComingFromGroup: true,
                                grade: filteredStudents[index].grade,
                                studentModel: filteredStudents[index],
                              );
                            },
                            itemCount: filteredStudents.length,
                          ),
                        );
                      },
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
