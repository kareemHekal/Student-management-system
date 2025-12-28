import 'package:flutter/material.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';
import '../firebase/exams_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import '../models/exam_model.dart';
import '../models/mini_exam.dart';
import '../models/student_exam_grade.dart';
import '../theme/colors_app.dart';

Future<void> showAddStudentExamGradeDialog({
  required BuildContext context,
  required String gradeName,
  required String studentId,
}) async {
  final exams = await FirebaseExams.getExams(gradeName);

  ExamModel? selectedExam;
  MiniExam? selectedMiniExam;
  final studentGradeController = TextEditingController();
  final descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int step = 1;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step == 1 ? 'اختيار الامتحان' : 'تسجيل الدرجة',
                    style: AppTextStyles.customText(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStepDot(active: true),
                      const SizedBox(width: 4),
                      _buildStepDot(active: step == 2),
                    ],
                  )
                ],
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: step == 1
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDropdown<ExamModel>(
                              label: 'اختر الامتحان الأساسي',
                              value: selectedExam,
                              items: exams
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e.name)))
                                  .toList(),
                              onChanged: (exam) => setState(() {
                                selectedExam = exam;
                                selectedMiniExam = null;
                              }),
                            ),
                            const SizedBox(height: 16),
                            if (selectedExam != null)
                              _buildDropdown<MiniExam>(
                                label: 'اختر الامتحان الفرعي',
                                value: selectedMiniExam,
                                items: selectedExam!.miniExams
                                        ?.map((me) => DropdownMenuItem(
                                            value: me,
                                            child: Text(me.miniExamName)))
                                        .toList() ??
                                    [],
                                onChanged: (mini) =>
                                    setState(() => selectedMiniExam = mini),
                              ),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.secondaryMain.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.secondaryMain
                                          .withOpacity(0.3)),
                                ),
                                child: Text(
                                  'الدرجة الكاملة: ${selectedMiniExam?.fullGrade ?? ''}',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.customText(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondaryMain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildGradeField(
                                controller: studentGradeController,
                                label: 'درجة الطالب',
                                fullGrade: selectedMiniExam?.fullGrade,
                              ),
                              const SizedBox(height: 16),
                              _buildNoteField(
                                controller: descriptionController,
                                label: 'ملاحظات إضافية (اختياري)',
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (step == 2) {
                          setState(() => step = 1);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        step == 2 ? 'رجوع' : 'إلغاء',
                        style: AppTextStyles.customText(
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: step == 1
                            ? AppColors.primaryMain
                            : AppColors.statusPresent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (step == 1) {
                          if (selectedExam != null &&
                              selectedMiniExam != null) {
                            setState(() => step = 2);
                          }
                        } else {
                          if (!(_formKey.currentState?.validate() ?? false))
                            return;

                          await runWithLoading(context, () async {
                            final parentContext =
                                Navigator.of(context, rootNavigator: true)
                                    .context;
                            final gradeValue = double.parse(
                                studentGradeController.text.trim());

                            final newGrade = StudentExamGrade(
                              studentGrade: gradeValue.toString(),
                              examId: selectedExam?.id ?? "",
                              miniExamId: selectedMiniExam!.id,
                              description: descriptionController.text.trim(),
                            );

                            await FirebaseExams.addStudentExamGrade(
                                gradeName, studentId, newGrade);

                            if (context.mounted) {
                              // Use reusable SnackBar component
                              AppSnackBars.showSuccess(
                                  parentContext, "تم إضافة درجة الطالب بنجاح");

                              Navigator.pushNamedAndRemoveUntil(parentContext,
                                  '/StudentsTab', (route) => false);
                            }
                          });
                        }
                      },
                      child: Text(
                        step == 1 ? 'التالي' : 'حفظ الدرجة',
                        style: AppTextStyles.customText(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

// --- UI Helpers ---

Widget _buildStepDot({required bool active}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    height: 6,
    width: active ? 20 : 6,
    decoration: BoxDecoration(
      color:
          active ? AppColors.secondaryMain : AppColors.white.withOpacity(0.4),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

Widget _buildDropdown<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required Function(T?) onChanged,
}) {
  return DropdownButtonFormField<T>(
    value: value,
    icon: const Icon(Icons.arrow_drop_down_circle_outlined,
        color: AppColors.primaryMain),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.customText(
          fontSize: 14, color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!)),
    ),
    items: items,
    onChanged: onChanged,
  );
}

Widget _buildGradeField(
    {required TextEditingController controller,
    required String label,
    double? fullGrade}) {
  return TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textAlign: TextAlign.center,
    style: AppTextStyles.customText(fontSize: 20, fontWeight: FontWeight.bold),
    decoration: InputDecoration(
      labelText: label,
      floatingLabelAlignment: FloatingLabelAlignment.center,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator: (value) {
      final val = double.tryParse(value ?? '');
      if (val == null) return 'أدخل درجة صحيحة';
      if (fullGrade != null && val > fullGrade)
        return 'لا يمكن تجاوز $fullGrade';
      if (val < 0) return 'درجة غير صحيحة';
      return null;
    },
  );
}

Widget _buildNoteField(
    {required TextEditingController controller, required String label}) {
  return TextFormField(
    controller: controller,
    maxLines: 2,
    decoration: InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}