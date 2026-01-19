import 'package:flutter/material.dart';
import 'package:student_management_system/alert_dialogs/add_edit_exam.dart';
import 'package:student_management_system/alert_dialogs/delete_exam.dart';

import '../models/exam_model.dart';
import '../pages/exam_grades_checker.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart'; // استيراد ملف الستايل الخاص بك

class _CardHelpers {
  static Widget buildCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget buildActionCircle({
    required IconData icon,
    required Color circleColor,
    required Color iconColor,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class ExamCard extends StatelessWidget {
  final ExamModel exam;
  final String gradeName;

  const ExamCard({super.key, required this.exam, required this.gradeName});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExamResultPage(
                  gradeName: gradeName,
                  examId: exam.id ?? "",
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryMain,
                  AppColors.secondaryMain,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMain.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: -30,
                  right: -30,
                  child: _CardHelpers.buildCircle(100, 0.15),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _CardHelpers.buildCircle(50, 0.1),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.school,
                            size: 28,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exam.name,
                              style: AppTextStyles.customText(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CardHelpers.buildActionCircle(
                                icon: Icons.edit,
                                tooltip: 'تعديل الامتحان',
                                circleColor: AppColors.white.withOpacity(0.15),
                                iconColor: AppColors.white,
                                onPressed: () {
                                  showAddEditExamDialog(
                                      gradeName: gradeName,
                                      exam: exam,
                                      context: context);
                                },
                              ),
                              const SizedBox(width: 8),

                              _CardHelpers.buildActionCircle(
                                icon: Icons.delete_forever,
                                tooltip: 'حذف الامتحان',
                                circleColor: AppColors.statusAbsent,
                                iconColor: AppColors.white,
                                onPressed: () {
                                  showDeleteExamDialog(
                                    context: context,
                                    gradeName: gradeName,
                                    examId: exam.id!,
                                    examName: exam.name,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(
                          color: AppColors.white, height: 20, thickness: 0.5),

                      if (exam.miniExams == null || exam.miniExams!.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'لا يوجد نماذج للامتحان',
                            style: AppTextStyles.customText(
                              fontSize: 16,
                              color: AppColors.secondaryMain,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'النماذج الفرعية:',
                                style: AppTextStyles.customText(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            ...exam.miniExams!.map((mini) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      mini.miniExamName,
                                      style: AppTextStyles.customText(
                                        fontSize: 16,
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'الدرجة الكاملة: ${mini.fullGrade.toStringAsFixed(0)}',
                                      style: AppTextStyles.customText(
                                        fontSize: 16,
                                        color: AppColors.textOnDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}