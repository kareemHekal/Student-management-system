import 'package:flutter/material.dart';
import 'package:student_management_system/alert_dialogs/add_edit_exam.dart';
import 'package:student_management_system/alert_dialogs/delete_exam.dart';

import '../models/exam_model.dart';
import '../pages/exam_grades_checker.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart';

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
      width: 38, // تصغير بسيط للملاءمة
      height: 38,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(icon, color: iconColor, size: 18),
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
                colors: [AppColors.primaryMain, AppColors.secondaryMain],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMain.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned(
                    bottom: -30,
                    right: -30,
                    child: _CardHelpers.buildCircle(
                        MediaQuery.of(context).size.width * 0.3, 0.1),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(context),
                        const Divider(
                            color: AppColors.white, height: 24, thickness: 0.5),
                        if (exam.miniExams == null || exam.miniExams!.isEmpty)
                          _buildEmptyMiniExams()
                        else
                          _buildMiniExamsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.assignment_turned_in_rounded,
            size: 24, color: AppColors.white),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              exam.name,
              style: AppTextStyles.customText(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardHelpers.buildActionCircle(
              icon: Icons.edit,
              tooltip: 'تعديل',
              circleColor: AppColors.white.withOpacity(0.15),
              iconColor: AppColors.white,
              onPressed: () => showAddEditExamDialog(
                  gradeName: gradeName, exam: exam, context: context),
            ),
            const SizedBox(width: 6),
            _CardHelpers.buildActionCircle(
              icon: Icons.delete_forever,
              tooltip: 'حذف',
              circleColor: AppColors.statusAbsent,
              iconColor: AppColors.white,
              onPressed: () => showDeleteExamDialog(
                  context: context,
                  gradeName: gradeName,
                  examId: exam.id!,
                  examName: exam.name),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyMiniExams() {
    return Text(
      'لا يوجد نماذج للامتحان حالياً',
      style: AppTextStyles.customText(
        fontSize: 14,
        color: AppColors.secondaryMain.withOpacity(0.9),
      ),
    );
  }

  Widget _buildMiniExamsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'النماذج الفرعية:',
          style: AppTextStyles.customText(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        // استخدام ListView.builder إذا كانت النماذج كثيرة جداً (اختياري)
        // هنا سنستخدم map لأن النماذج غالباً لا تتعدى الـ 5
        ...exam.miniExams!.map((mini) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    mini.miniExamName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.customText(
                        fontSize: 14, color: AppColors.white),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'الدرجة: ${mini.fullGrade.toStringAsFixed(0)}',
                      style: AppTextStyles.customText(
                        fontSize: 14,
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}