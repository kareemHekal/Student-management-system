import 'package:flutter/material.dart';
import 'package:student_management_system/alert_dialogs/delete_student_exam_grade.dart';
import 'package:student_management_system/alert_dialogs/edit_student_exam_grade.dart';

import '../../firebase/exams_functions.dart';
import '../../models/exam_model.dart';
import '../../models/mini_exam.dart';
import '../../models/student_exam_grade.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart';

class StudentExamCard extends StatefulWidget {
  final String gradeName;
  final String studentId;
  final StudentExamGrade examGrade;

  const StudentExamCard({
    Key? key,
    required this.studentId,
    required this.gradeName,
    required this.examGrade,
  }) : super(key: key);

  @override
  State<StudentExamCard> createState() => _StudentExamCardState();
}

class _StudentExamCardState extends State<StudentExamCard> {
  ExamModel? exam;
  MiniExam? miniExam;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamAndMiniExam();
  }

  Future<void> _loadExamAndMiniExam() async {
    final examResult = await FirebaseExams.getExamById(
        widget.gradeName, widget.examGrade.examId);

    MiniExam? foundMini;
    if (examResult != null && examResult.miniExams != null) {
      try {
        foundMini = examResult.miniExams!
            .firstWhere((m) => m.id == widget.examGrade.miniExamId);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        exam = examResult;
        miniExam = foundMini;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (exam == null || miniExam == null) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            "❌ لم يتم العثور على الامتحان",
            style: AppTextStyles.customText(
                color: Colors.red[800]!, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    double studentScore = 0;
    double totalScore = miniExam!.fullGrade;

    try {
      studentScore = double.parse(
          widget.examGrade.studentGrade.split('from').first.trim());
    } catch (_) {}

    double ratio = totalScore > 0 ? (studentScore / totalScore) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Directionality(
        textDirection: TextDirection.rtl,
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
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            // حماية الزوايا والدوائر الخلفية
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                    bottom: -10,
                    left: -20,
                    child: _CardHelpers.buildCircle(120, 0.1)),
                Positioned(
                    top: -10,
                    right: -10,
                    child: _CardHelpers.buildCircle(80, 0.15)),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(context),
                      const Divider(
                          color: AppColors.white, thickness: 0.5, height: 25),

                      // حاوية الدرجات الملونة
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            // درجة الطالب
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'درجة الطالب: ${widget.examGrade.studentGrade}',
                                  style: AppTextStyles.customText(
                                    fontSize: 16,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // فاصل صغير
                            Container(
                                width: 1,
                                height: 20,
                                color: AppColors.white.withOpacity(0.3)),
                            const SizedBox(width: 8),
                            // الدرجة الكاملة
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'من: ${miniExam!.fullGrade.toStringAsFixed(0)}',
                                  style: AppTextStyles.customText(
                                    fontSize: 16,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressAndNotes(ratio),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // حماية أسماء الامتحانات الطويلة من التصادم مع الأزرار
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  exam!.name,
                  style: AppTextStyles.customText(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  miniExam!.miniExamName,
                  style: AppTextStyles.customText(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // أزرار التحكم
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardHelpers.buildActionCircle(
              icon: Icons.edit,
              tooltip: 'تعديل',
              circleColor: AppColors.white.withOpacity(0.15),
              iconColor: AppColors.white,
              onPressed: () async {
                await showEditStudentExamGradeDialog(
                  context: context,
                  gradeName: widget.gradeName,
                  studentId: widget.studentId,
                  examGrade: widget.examGrade,
                  examName: exam!.name,
                  miniExamName: miniExam!.miniExamName,
                  fullGrade: miniExam!.fullGrade,
                );
              },
            ),
            const SizedBox(width: 8),
            _CardHelpers.buildActionCircle(
              icon: Icons.delete_forever,
              tooltip: 'حذف',
              circleColor: AppColors.statusAbsent,
              iconColor: AppColors.white,
              onPressed: () {
                showDeleteStudentExamGradeDialog(
                  context: context,
                  gradeName: widget.gradeName,
                  studentId: widget.studentId,
                  examId: exam?.id ?? "",
                  miniExamId: miniExam!.id,
                  examName: exam!.name,
                  miniExamName: miniExam!.miniExamName,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressAndNotes(double ratio) {
    Color progressColor;
    if (ratio >= 0.8) {
      progressColor = AppColors.secondaryMain;
    } else if (ratio >= 0.5) {
      progressColor = AppColors.statusLate;
    } else {
      progressColor = AppColors.statusAbsent;
    }

    return Row(
      children: [
        // مؤشر النسبة الدائري بحجم ثابت
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                strokeWidth: 6,
              ),
              FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    '${(ratio * 100).toInt()}%',
                    style: AppTextStyles.customText(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // الملاحظات بمرونة كاملة
        Expanded(
          child: Text(
            widget.examGrade.description.isEmpty
                ? 'لا يوجد ملاحظات'
                : widget.examGrade.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.customText(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.9),
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

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
      width: 38,
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