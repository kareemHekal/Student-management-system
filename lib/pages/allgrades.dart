import 'package:flutter/material.dart';

import '../Alert dialogs/rename_grade.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/grade_subscriptions_model.dart';
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
            icon: const Icon(Icons.add, size: 40, color: app_colors.green),
          )
        ],
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/HomeScreen', (route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios, color: app_colors.green),
        ),
        backgroundColor: app_colors.darkGrey,
        title: Image.asset(
          "assets/images/2....2.png",
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
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: GestureDetector(
                        onLongPress: () {
                          onLongPressDelete(context, secondaries[index]);
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading:
                              const Icon(Icons.school, color: app_colors.green),
                          title: Text(
                            secondaries[index],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            // important to prevent overflow
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: app_colors.green),
                                onPressed: () {
                                  renameGrade(
                                      context: context,
                                      oldGrade: secondaries[index]);
                                },
                              ),
                              const SizedBox(
                                  width: 10), // use SizedBox for spacing
                              IconButton(
                                icon: const Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    color: app_colors.green),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SubscriptionsForGrade(
                                        gradeName: secondaries[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  void onLongPressDelete(BuildContext context, String gradeToDelete) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("حذف الصف"),
          content: Text("هل أنت متأكد أنك تريد حذف الصف: $gradeToDelete؟"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("إلغاء"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFunctions.deleteGradeFromList(gradeToDelete);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم حذف الصف بنجاح")),
                );
              },
              child: const Text("حذف"),
            ),
          ],
        );
      },
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
