import 'package:flutter/material.dart';
import '../colors_app.dart';
import '../models/absence_model.dart';

class AbsenceCard extends StatelessWidget {
  final AbsenceModel absence;

  const AbsenceCard({Key? key, required this.absence}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int attended = absence.attendedDays ?? 0;
    int absent = absence.absentDays ?? 0;
    int total = attended + absent;
    double attendanceRatio = total == 0 ? 0 : attended / total;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [app_colors.ligthGreen, app_colors.ligthGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: app_colors.green.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Circular attendance indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: attendanceRatio,
                    backgroundColor: app_colors.green.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(app_colors.green),
                    strokeWidth: 6,
                  ),
                ),
                Text(
                  '${(attendanceRatio * 100).toInt()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: app_colors.darkGrey),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Month name and attendance info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    absence.monthName,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: app_colors.green),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'أيام الحضور: $attended',
                        style:
                            TextStyle(fontSize: 14, color: app_colors.darkGrey),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'أيام الغياب: $absent',
                        style:
                            TextStyle(fontSize: 14, color: app_colors.darkGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Calendar icon
            Icon(
              Icons.calendar_month,
              size: 36,
              color: app_colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
