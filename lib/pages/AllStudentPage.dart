import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/theme/snack_bar.dart';

import '../firebase/firebase_functions.dart';
import '../studetnstreambuilder.dart';
import '../theme/colors_app.dart';
import 'student/edit_student/EditStudent.dart';

class AllStudentsTab extends StatefulWidget {
  const AllStudentsTab({super.key});

  @override
  State<AllStudentsTab> createState() => _AllStudentsTabState();
}

class _AllStudentsTabState extends State<AllStudentsTab> {
  MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  String? grade;
  bool isLoading = true;
  List<String>? grades;
  late bool thereIsGrades;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchGrades();
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  Future<void> fetchGrades() async {
    List<String> fetchedGrades = await FirebaseFunctions.getGradesList();

    if (!mounted) return;

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
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner,
                      color: AppColors.secondaryMain, size: 28),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AiBarcodeScanner(
                          sheetTitle: "بحث شامل عن طالب",
                          controller: MobileScannerController(
                            detectionSpeed: DetectionSpeed.noDuplicates,
                          ),
                          onDetect: (BarcodeCapture capture) async {
                            final String? scannedId =
                                capture.barcodes.first.rawValue;
                            if (scannedId == null) return;

                            await _scannerController.stop();

                            try {
                              await runWithLoading(context, () async {
                                final List<String> grades =
                                    await FirebaseFunctions.getGradesList();

                                Studentmodel? foundStudent;

                                for (String grade in grades) {
                                  final studentsInGrade =
                                      await FirebaseFunctions
                                          .getAllStudentsByGrade_future(grade);

                                  try {
                                    foundStudent = studentsInGrade
                                        .firstWhere((s) => s.id == scannedId);
                                    break;
                                  } catch (e) {
                                    continue;
                                  }
                                }

                                if (foundStudent != null) {
                                  if (!context.mounted) return;

                                  Future.delayed(Duration.zero, () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EditStudentScreen(
                                                  student: foundStudent!)),
                                    );
                                  });
                                } else {
                                  AppSnackBars.showError(context,
                                      "عذراً، هذا الطالب غير مسجل في أي صف");
                                  // رجع شغل الكاميرا لو ملقناهوش
                                  await _scannerController.start();
                                }
                              });
                            } catch (e) {
                              debugPrint("❌ Error: $e");
                              await _scannerController.start();
                            }
                          },
                        ),
                      ),
                    );
                  },
                )
              ],
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
              toolbarHeight: 80,
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
                                  labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 10),
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
                                  tabs:
                                      grades!.map((g) => Tab(text: g)).toList(),
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
