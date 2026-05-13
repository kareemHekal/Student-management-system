import 'package:flutter/material.dart';

import '../models/absence_app/student_absence_model.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart';

class AbsenceCard extends StatelessWidget {
  final StudentAbsencesModel absence;

  const AbsenceCard({Key? key, required this.absence}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- Calculations ---
    int attended = absence.attendedDays.length;
    int absent = absence.absentDays.length;
    int total = attended + absent;
    double attendanceRatio = total == 0 ? 0 : attended / total;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          // ضمان ارتفاع متناسق
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
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // زخارف خلفية متجاوبة
                Positioned(
                  top: -25,
                  left: -25,
                  child: _buildCircle(
                      MediaQuery.of(context).size.width * 0.2, 0.08),
                ),
                Positioned(
                  bottom: -20,
                  right: 40,
                  child: _buildCircle(
                      MediaQuery.of(context).size.width * 0.15, 0.2),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      // دائرة النسبة بمرونة داخلية
                      _buildAttendanceBadge(attendanceRatio),

                      const SizedBox(width: 16),

                      // قسم المعلومات (اسم الشهر والإحصائيات)
                      Expanded(
                        child: _buildInfoSection(
                            attended, absent, absence.monthName),
                      ),

                      const SizedBox(width: 8),

                      // أيقونة التقويم (تختفي في الشاشات الصغيرة جداً لتوفير مساحة)
                      if (MediaQuery.of(context).size.width > 340)
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 32,
                          color: AppColors.white.withOpacity(0.7),
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

  Widget _buildCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAttendanceBadge(double ratio) {
    return SizedBox(
      width: 65,
      height: 65,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
            strokeWidth: 5,
          ),
          FittedBox(
            // حماية النسبة المئوية
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                '${(ratio * 100).toInt()}%',
                style: AppTextStyles.customText(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(int attended, int absent, String monthName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          // حماية اسم الشهر
          fit: BoxFit.scaleDown,
          child: Text(
            monthName,
            style: AppTextStyles.customText(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          // استخدام Wrap بدلاً من Row لضمان عدم حدوث Overflow في أرقام الحضور/الغياب
          spacing: 12,
          runSpacing: 4,
          children: [
            _buildAttendanceDetail(
              label: 'حضور',
              count: attended,
            ),
            _buildAttendanceDetail(
              label: 'غياب',
              count: absent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceDetail({required String label, required int count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: AppTextStyles.customText(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.customText(
            fontSize: 14,
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}