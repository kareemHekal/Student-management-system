import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/absence_app/day_record.dart';

import '../../cards/absence_card.dart';
import '../../models/absence_app/student_absence_model.dart';
import '../../theme/colors_app.dart';
import '../pdf_genrators/absent_generator.dart';
import 'month_absence_details_page.dart';

class AbsencesListPage extends StatelessWidget {
  final List<StudentAbsencesModel> absences;
  final List<DayRecord> currentAbsentDays;
  final List<DayRecord> currentAttendedDays;
  final String studentName;

  const AbsencesListPage(
      {Key? key,
      required this.studentName,
      required this.currentAbsentDays,
      required this.currentAttendedDays,
      required this.absences})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Create current month absence model
    StudentAbsencesModel currentMonth = StudentAbsencesModel(
      monthName: "الشهر الحالي",
      attendedDays: currentAttendedDays,
      absentDays: currentAbsentDays,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                await runWithLoading(
                  context,
                  () async {
                    final pdfBytes = await generateAbsenceReportPdf(
                      studentName: studentName,
                      absences: absences,
                      currentAbsentDays: currentAbsentDays,
                      currentAttendedDays: currentAttendedDays,
                    );
                    await Printing.layoutPdf(
                      onLayout: (format) async => pdfBytes,
                      name: "absence_report_${studentName}.pdf",
                    );
                  },
                );
              },
              icon: Icon(
                Icons.print,
                color: AppColors.white,
              ))
        ],
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
        ),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset("assets/images/logo.png", height: 100, width: 90),
        toolbarHeight: 150,
      ),
      body: Column(
        children: [
          // ✅ ثابت أعلى الصفحة
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MonthDetailsPage(
                          monthModel: currentMonth, studentName: studentName),
                    ),
                  );
                },
                child: AbsenceCard(absence: currentMonth)),
          ),

          const Divider(thickness: 1),

          // ✅ Expanded list below
          Expanded(
            child: absences.isEmpty
                ? Center(
                    child: Text(
                      'لا يوجد بيانات حضور بعد',
                      style: TextStyle(fontSize: 16, color: Colors.green[700]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: absences.length,
                    itemBuilder: (context, index) {
                      final absence = absences[index];

                      // Wrap the card in GestureDetector or InkWell
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MonthDetailsPage(
                                  monthModel: absence,
                                  studentName: studentName),
                            ),
                          );
                        },
                        child: AbsenceCard(absence: absence),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
