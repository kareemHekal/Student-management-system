import 'package:flutter/material.dart';

import '../Alert dialogs/add_edit_exam.dart';
import '../Alert dialogs/delete_exam.dart';
import '../models/exam_model.dart';
import '../pages/exam_grades_checker.dart';
import '../theme/colors_app.dart'; // Import AppColors

// Assuming these helper methods exist in a class or extension for reuse
// I'll define them here for completeness based on previous context
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
      // Assuming RTL context
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
              borderRadius: BorderRadius.circular(22), // Consistent radius
              // VIBRANT GRADIENT THEME
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
                // ===== Decorative Circles (Dynamic Placement) =====
                // Large Circle on the Bottom Right Corner
                Positioned(
                  bottom: -30,
                  right: -30,
                  child: _CardHelpers.buildCircle(100, 0.15),
                ),
                // Small Circle on the Top Left Edge
                Positioned(
                  top: 10,
                  left: 10,
                  child: _CardHelpers.buildCircle(50, 0.1),
                ),

                // ===== Card Content =====
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Title Row with Edit & Delete Actions ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.school, // Exam related icon
                            size: 28,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exam.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    AppColors.white, // White text on gradient
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Action Buttons (Edit and Delete) in Circles
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Edit Icon in Circle
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

                              // 2. Delete Icon in Circle
                              _CardHelpers.buildActionCircle(
                                icon: Icons.delete_forever,
                                tooltip: 'حذف الامتحان',
                                // Use Red for the background of the delete action
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

                      // --- Mini Exams List ---
                      if (exam.miniExams == null || exam.miniExams!.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'لا يوجد نماذج للامتحان',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.secondaryMain,
                              // Use secondary color for emphasis
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'النماذج الفرعية:',
                                style: TextStyle(
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
                                  // Subtle background
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      mini.miniExamName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'الدرجة الكاملة: ${mini.fullGrade.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textOnDark,
                                        // Use secondary color for the grade
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