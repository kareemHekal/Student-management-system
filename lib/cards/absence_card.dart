import 'package:flutter/material.dart';

import '../models/absence_model.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart';

class AbsenceCard extends StatelessWidget {
  final AbsenceModel absence;

  const AbsenceCard({Key? key, required this.absence}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- Calculations ---
    int attended = absence.attendedDays.length;
    int absent = absence.absentDays.length;
    int total = attended + absent;
    double attendanceRatio = total == 0 ? 0 : attended / total;

    // --- New UI Structure ---
    return Directionality(
      // Assuming this is used in an RTL context based on the example and Arabic text
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              // Using a subtle gradient from the primary and secondary colors
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
              // ===== Decorative Circles (Background Elements) =====
              Positioned(
                top: -25,
                left: -25,
                child: _buildCircle(80, 0.08),
              ),
              Positioned(
                bottom: -20,
                right: 40,
                child: _buildCircle(60, 0.25),
              ),

              // ===== Card Content =====
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    // Attendance Ratio Badge (Left side in RTL)
                    _buildAttendanceBadge(attendanceRatio),
                    const SizedBox(width: 16),
                    // Month Name and Details
                    Expanded(
                      child: _buildInfoSection(
                          attended, absent, absence.monthName),
                    ),
                    // Calendar Icon (Visual separator/indicator)
                    Icon(
                      Icons.calendar_month,
                      size: 36,
                      color: AppColors.white.withOpacity(
                          0.8), // Changed to white/light for the dark background
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for the decorative background circles
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

  // Helper method for the circular attendance badge
  Widget _buildAttendanceBadge(double ratio) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 70, // Slightly larger
          height: 70,
          child: CircularProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.white.withOpacity(0.2),
            // Light background
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
            // White/light progress
            strokeWidth: 6,
          ),
        ),
        Text(
          '${(ratio * 100).toInt()}%',
          style: AppTextStyles.customText(
            // Use custom text style
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.white, // Text on dark background
          ),
        ),
      ],
    );
  }

  // Helper method for the month name and attendance data
  Widget _buildInfoSection(int attended, int absent, String monthName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Align to start (Right in RTL)
      children: [
        Text(
          monthName,
          style: AppTextStyles.customText(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.white, // Text on dark background
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Attended Days
            _buildAttendanceDetail(
              label: 'حضور',
              count: attended,
              color: AppColors.white.withOpacity(0.9), // Slightly lighter color
            ),
            const SizedBox(width: 12),
            // Absent Days
            _buildAttendanceDetail(
              label: 'غياب',
              count: absent,
              color: AppColors.white.withOpacity(0.9),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method for the individual attendance/absence counts
  Widget _buildAttendanceDetail(
      {required String label, required int count, required Color color}) {
    return Row(
      children: [
        // Using a distinct color for the count for emphasis
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
            color: color,
          ),
        ),
      ],
    );
  }
}