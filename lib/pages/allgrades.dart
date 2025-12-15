import 'package:flutter/material.dart';

import '../Alert dialogs/delete_grade.dart';
import '../Alert dialogs/rename_grade.dart';
import '../cards/grade_card.dart';
import '../firebase/firebase_functions.dart';
import '../models/grade_subscriptions_model.dart';
import '../theme/colors_app.dart';
import 'exams_for_grade.dart';
import 'subscriptions_for_grade.dart';

class Allgrades extends StatefulWidget {
  const Allgrades({super.key});

  @override
  State<Allgrades> createState() => _AllgradesState();
}

class _AllgradesState extends State<Allgrades> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              showAddGradeDialog(context);
            },
            icon:
                const Icon(Icons.add, size: 40, color: AppColors.secondaryMain),
          )
        ],
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/HomeScreen', (route) => false);
          },
          icon:
              const Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
        ),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset(
          "assets/images/logo.png",
          height: 100,
          width: 90,
        ),
        toolbarHeight: 120,
      ),
      body: StreamBuilder<List<String>>(
        stream: FirebaseFunctions.getGradesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("حدث خطأ أثناء تحميل الصفوف."));
          }

          List<String> secondaries = snapshot.data ?? [];

          return secondaries.isEmpty
              ? const Center(child: Text("لا توجد صفوف متاحة."))
              : ListView.builder(
                  itemCount: secondaries.length,
                  itemBuilder: (context, index) {
                    return GradeActionCard(
                      onDelete: () {
                        DeleteGradeDialog(context, secondaries[index]);
                      },
                      gradeName: secondaries[index],
                      onRename: () {
                        // Original rename logic
                        renameGrade(
                            context: context, oldGrade: secondaries[index]);
                      },
                      onNavigateToExams: () {
                        // Original navigate to exams logic
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExamsForGrade(
                              gradeName: secondaries[index],
                            ),
                          ),
                        );
                      },
                      onNavigateToSubscriptions: () {
                        // Original navigate to subscriptions logic
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubscriptionsForGrade(
                              gradeName: secondaries[index],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
        },
      ),
    );
  }



  void showAddGradeDialog(BuildContext context) {
    TextEditingController gradeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("إضافة صف جديد"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("من فضلك أدخل اسم الصف الجديد."),
              TextFormField(
                controller: gradeController,
                decoration: const InputDecoration(
                  labelText: "اسم الصف",
                  hintText: "أدخل اسم الصف",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("إلغاء"),
            ),
            TextButton(
              onPressed: () async {
                String newGrade = gradeController.text.trim();
                if (newGrade.isNotEmpty) {
                  await FirebaseFunctions.addGradeToList(newGrade);
                  await FirebaseFunctions.createGradeSubscriptionDoc(
                      GradeSubscriptionsModel(
                          gradeName: newGrade, subscriptions: []));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تمت إضافة الصف بنجاح")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("من فضلك أدخل اسم الصف")),
                  );
                }
              },
              child: const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }
}
