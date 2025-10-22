import 'package:flutter/material.dart';
import '../cards/absence_card.dart';
import '../colors_app.dart';
import '../models/absence_model.dart';

class AbsencesListPage extends StatelessWidget {
  final List<AbsenceModel> absences;

  const AbsencesListPage({Key? key, required this.absences}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: app_colors.green),
        ),
        backgroundColor: app_colors.darkGrey,
        title: Image.asset("assets/images/2....2.png", height: 100, width: 90),
        toolbarHeight: 150,
      ),
      body: absences.isEmpty
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
    );
  }
}
