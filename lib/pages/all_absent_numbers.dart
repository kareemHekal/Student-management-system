import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:student_management_system/models/day_record.dart';

import '../cards/absence_card.dart';
import '../colors_app.dart';
import '../models/absence_model.dart';
import 'pdf_genrators/absent_generator.dart';

class AbsencesListPage extends StatelessWidget {
  final List<AbsenceModel> absences;
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
    AbsenceModel currentMonth = AbsenceModel(
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
                final pdfBytes = await generateAbsenceReportPdf(
                  studentName: studentName,
                  absences: absences,
                  currentAbsentDays: currentAbsentDays,
                  currentAttendedDays: currentAttendedDays,
                );

                await Printing.layoutPdf(
                  onLayout: (format) async => pdfBytes,
                  name: "absence_report_كرييم.pdf",
                );
              },
              icon: Icon(
                Icons.print,
                color: app_colors.white,
              ))
        ],
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: app_colors.green),
        ),
        backgroundColor: app_colors.darkGrey,
        title: Image.asset("assets/images/logo.png", height: 100, width: 90),
        toolbarHeight: 150,
      ),
      body: Column(
        children: [
          // ✅ ثابت أعلى الصفحة
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AbsenceCard(absence: currentMonth),
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
                return AbsenceCard(absence: absence);
              },
            ),
          ),
        ],
      ),
    );
  }
}
