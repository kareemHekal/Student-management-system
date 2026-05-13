import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../firebase/exams_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import '../models/exam_model.dart';
import '../models/mini_exam.dart';

Future<void> showAddEditExamDialog({
  required BuildContext context,
  required String gradeName,
  ExamModel? exam,
}) async {
  final _formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  final examNameController = TextEditingController(text: exam?.name ?? '');

  final List<MiniExamField> miniExamFields = exam?.miniExams
          ?.map((e) => MiniExamField(
                miniExamNameController:
                    TextEditingController(text: e.miniExamName),
                fullGradeController:
                    TextEditingController(text: e.fullGrade.toString()),
              ))
          .toList() ??
      [];

  void addMiniExamField() {
    miniExamFields.add(MiniExamField(
      miniExamNameController: TextEditingController(),
      fullGradeController: TextEditingController(),
    ));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void removeMiniExamField(int index) {
    miniExamFields[index].miniExamNameController.dispose();
    miniExamFields[index].fullGradeController.dispose();
    miniExamFields.removeAt(index);
  }

  final isEdit = exam != null;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
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
            child: Text(
              isEdit ? 'تعديل الامتحان' : 'إضافة امتحان جديد',
              style: AppTextStyles.customText(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          content: Form(
            key: _formKey,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 15),
                    _buildModernField(
                      controller: examNameController,
                      label: 'اسم الامتحان',
                      icon: Icons.edit_note,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'أدخل الاسم'
                              : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الامتحانات الفرعية',
                            style: AppTextStyles.customText(
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => setState(addMiniExamField),
                          icon: const Icon(Icons.add_circle,
                              color: AppColors.secondaryMain, size: 28),
                        ),
                      ],
                    ),
                    ...List.generate(miniExamFields.length, (index) {
                      final field = miniExamFields[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildModernField(
                                controller: field.miniExamNameController,
                                label: 'اسم الفرعي',
                                validator: (val) =>
                                    val!.isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildModernField(
                                controller: field.fullGradeController,
                                label: 'الدرجة',
                                isNumber: true,
                                validator: (val) =>
                                    val!.isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => removeMiniExamField(index)),
                              icon: const Icon(Icons.delete_sweep,
                                  color: AppColors.statusAbsent),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style:
                      AppTextStyles.customText(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await runWithLoading(context, () async {
                    final newExam = ExamModel(
                      id: exam?.id,
                      name: examNameController.text.trim(),
                      miniExams: List.generate(miniExamFields.length, (i) {
                        final oldMini = exam?.miniExams != null &&
                                i < exam!.miniExams!.length
                            ? exam.miniExams![i]
                            : null;
                        return MiniExam(
                          id: oldMini?.id ?? "",
                          miniExamName: miniExamFields[i]
                              .miniExamNameController
                              .text
                              .trim(),
                          fullGrade: double.parse(
                              miniExamFields[i].fullGradeController.text),
                        );
                      }),
                    );

                    // Logic choice
                    if (isEdit) {
                      await FirebaseExams.updateExam(gradeName, newExam);
                    } else {
                      await FirebaseExams.addExam(gradeName, newExam);
                    }

                    // --- Use your reusable component here ---
                    if (context.mounted) {
                      AppSnackBars.showSuccess(
                          context,
                          isEdit
                              ? "تم تحديث بيانات الامتحان"
                              : "تمت إضافة الامتحان بنجاح");
                    }
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text('حفظ',
                  style: AppTextStyles.customText(color: Colors.white)),
            ),
          ],
        );
      });
    },
  );
}

class MiniExamField {
  final TextEditingController miniExamNameController;
  final TextEditingController fullGradeController;

  MiniExamField({
    required this.miniExamNameController,
    required this.fullGradeController,
  });
}

Widget _buildModernField({
  required TextEditingController controller,
  required String label,
  IconData? icon,
  bool isNumber = false,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon:
          icon != null ? Icon(icon, color: AppColors.primaryMain) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryMain, width: 2),
      ),
    ),
    validator: validator,
  );
}