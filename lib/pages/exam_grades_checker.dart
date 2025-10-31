import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';

import '../colors_app.dart';
import '../firebase/exams_functions.dart';
import '../models/Studentmodel.dart';
import '../models/exam_model.dart';
import 'pdf_genrators/exam_pdf_generator.dart';

class ExamResultPage extends StatefulWidget {
  final String gradeName;
  final String examId;

  const ExamResultPage({
    super.key,
    required this.gradeName,
    required this.examId,
  });

  @override
  State<ExamResultPage> createState() => _ExamResultPageState();
}

class _ExamResultPageState extends State<ExamResultPage> {
  bool loading = true;

  ExamModel? examModel;
  List<Studentmodel> students = [];

  /// Map<miniExamId, List<Map<String, dynamic>>>
  final Map<String, List<Map<String, dynamic>>> resultData = {};

  /// List of students who didn't attend at all
  final List<Studentmodel> didntAttend = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    // Get exam data
    examModel =
        await FirebaseExams.getExamById(widget.gradeName, widget.examId);

    // Get students
    final studentRef =
        FirebaseFunctions.getSecondaryCollection(widget.gradeName);

    final studentSnap = await studentRef.get();
    students = studentSnap.docs.map((e) => e.data()).toList();

    // Prepare mini exam lists
    for (var mini in examModel!.miniExams ?? []) {
      resultData[mini.id] = [];
    }

    // Sort student grades
    for (var student in students) {
      final gradeList = student.studentExamsGrades ?? [];

      final matching =
          gradeList.where((e) => e.examId == widget.examId).toList();

      if (matching.isEmpty) {
        didntAttend.add(student);
        continue;
      }

      for (var g in matching) {
        resultData[g.miniExamId]?.add({
          "name": student.name,
          "score": double.tryParse(g.studentGrade) ?? 0,
        });
      }
    }

    for (var miniId in resultData.keys) {
      resultData[miniId]!.sort((a, b) => b["score"].compareTo(a["score"]));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: app_colors.green),
        ),
        backgroundColor: app_colors.darkGrey,
        title: Image.asset("assets/images/logo.png", height: 100, width: 90),
        toolbarHeight: 150,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.insert_chart_rounded,
                            size: 70,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "تقرير درجات الامتحان",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "هذا التقرير يحتوي على درجات الطلاب في كل جزء من الامتحان،"
                            "\nبالإضافة إلى قائمة الطلاب الذين لم يؤدوا الامتحان.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                final pdfBytes = await generateExamReportPdf(
                                  exam: examModel!,
                                  students: students,
                                  gradeName: widget.gradeName,
                                );

                                await Printing.layoutPdf(
                                  onLayout: (format) async => pdfBytes,
                                  name:
                                      "${examModel!.name}_${widget.gradeName}.pdf",
                                );
                              } catch (e) {
                                print("PDF Error: $e");
                              }
                            },
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: app_colors.white,
                            ),
                            label: const Text(
                              "إنشاء ملف PDF",
                              style: TextStyle(
                                color: app_colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
