import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';
import '../studetnstreambuilder.dart';
import '../theme/colors_app.dart';

class AllStudentsTab extends StatefulWidget {
  const AllStudentsTab({super.key});

  @override
  State<AllStudentsTab> createState() => _AllStudentsTabState();
}

String? grade;
bool isLoading = true;
List<String>? grades;
late bool thereIsGrades;

class _AllStudentsTabState extends State<AllStudentsTab> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      await fetchGrades();
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> fetchGrades() async {
    List<String> fetchedGrades = await FirebaseFunctions.getGradesList();
    setState(() {
      grades = fetchedGrades;
      if (fetchedGrades.isEmpty) {
        thereIsGrades = false;
      } else {
        thereIsGrades = true;
        grade = grades![0];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Center(child: Image.asset("assets/images/logo.png")),
        ),
        const SizedBox(height: 50),
        DefaultTabController(
          length: grades?.length ?? 0,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/HomeScreen', (route) => false);
                },
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppColors.secondaryMain),
              ),
              backgroundColor: AppColors.primaryMain,
              title: Image.asset(
                "assets/images/logo.png",
                height: 100,
                width: 90,
              ),
              toolbarHeight: 120,
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
              child: thereIsGrades
                  ? Column(
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
                  Expanded(
                    child: StudentStreamBuilder(grade: grade ?? ""),
                  ),
                ],
              )
                  : const Text(
                "لا توجد مراحل دراسية، يجب إضافة مرحلة أولاً.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
