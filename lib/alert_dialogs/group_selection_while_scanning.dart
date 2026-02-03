import 'package:flutter/material.dart';
import 'package:student_management_system/cards/magmo3at/magmo3a_for_display_widget.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/Magmo3aModel.dart';
import 'package:student_management_system/models/absence_app/secondary_record.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';

class GroupSelectionWhileScanning extends StatelessWidget {
  final List<Magmo3amodel> studentGroups;
  final String studentName;
  final String currentDate;
  final Function(SecondaryRecord record) onConfirm;

  const GroupSelectionWhileScanning({
    super.key,
    required this.studentGroups,
    required this.studentName,
    required this.currentDate,
    required this.onConfirm,
  });

  String _calculateNearestDate(String targetDayName) {
    final currentBaseDate = DateTime.parse(currentDate);
    final daysOfWeek = {
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
    };
    int targetDay =
        daysOfWeek[targetDayName.toLowerCase()] ?? currentBaseDate.weekday;
    int diff = targetDay - currentBaseDate.weekday;
    if (diff > 3)
      diff -= 7;
    else if (diff < -3) diff += 7;
    DateTime nearestDate = currentBaseDate.add(Duration(days: diff));
    return "${nearestDate.year}-${nearestDate.month.toString().padLeft(2, '0')}-${nearestDate.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 500,
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
              child: Text(
                "اختر مجموعة الطالب الأصلية لتعويضه فيها",
                textAlign: TextAlign.center,
                style: AppTextStyles.customText(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: studentGroups.isEmpty
                  ? Center(
                      child: Text("لا توجد مجموعات مسجلة",
                          style: AppTextStyles.customText()))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: studentGroups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final group = studentGroups[index];
                        return InkWell(
                          onTap: () async {
                            await runWithLoading(context, () async {
                              final date = await _calculateNearestDate(
                                  group.day ?? "Saturday");
                              await onConfirm(SecondaryRecord(
                                  magmo3aId: group.id,
                                  date: date,
                                  day: group.day ?? "",
                                  time: group.time));
                              Navigator.pop(context);
                            });
                          },
                          child:
                              Magmo3aWidgetWithoutSlidable(magmo3aModel: group),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryMain,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Text("تحديد المجموعة الأصلية",
              style: AppTextStyles.customText(
                  fontSize: 18,
                  color: AppColors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(studentName,
              style: AppTextStyles.customText(
                  fontSize: 15,
                  color: AppColors.secondaryMain,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
