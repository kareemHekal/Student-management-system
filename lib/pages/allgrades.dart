import 'package:flutter/material.dart';
import 'package:student_management_system/alert_dialogs/delete_grade.dart';
import 'package:student_management_system/alert_dialogs/rename_grade.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

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
    final TextEditingController gradeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryMain,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Text(
                  'إضافة صف جديد',
                  style: AppTextStyles.customText(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  "من فضلك أدخل اسم الصف الدراسي الجديد ليتم اعتماده في النظام.",
                  style: AppTextStyles.customText(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: gradeController,
                  style: AppTextStyles.customText(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'اسم الصف',
                    hintText: 'مثل: الصف الأول الثانوي',
                    prefixIcon: const Icon(Icons.edit_calendar_rounded,
                        color: AppColors.primaryMain),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                          color: AppColors.primaryMain, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'من فضلك أدخل اسم الصف';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'إلغاء',
                      style: AppTextStyles.customText(
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMain,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      String newGrade = gradeController.text.trim();
                      await runWithLoading(context, () async {
                        try {
                          await FirebaseFunctions.addGradeToList(newGrade);
                          await FirebaseFunctions.createGradeSubscriptionDoc(
                            GradeSubscriptionsModel(
                              gradeName: newGrade,
                              subscriptions: [],
                            ),
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // إغلاق الـ Dialog
                            AppSnackBars.showSuccess(
                                context, "تمت إضافة الصف $newGrade بنجاح");
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackBars.showError(
                                context, "حدث خطأ أثناء الإضافة");
                          }
                        }
                      });
                    },
                    child: Text(
                      'حفظ الصف',
                      style: AppTextStyles.customText(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
