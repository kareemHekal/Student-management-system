import 'package:flutter/material.dart';
import 'package:student_management_system/models/Magmo3aModel.dart';
import 'package:student_management_system/pages/absent/AbssentPage.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';

class AbsenceGroupCard extends StatelessWidget {
  // Logic parameters from your first version
  final Magmo3amodel magmo3aModel;
  final String selectedDateStr;
  final String selectedDay;

  const AbsenceGroupCard({
    required this.magmo3aModel,
    required this.selectedDateStr,
    required this.selectedDay,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
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
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -25,
              right: -25,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryMain.withOpacity(0.2),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 90,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryMain.withOpacity(0.3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  _buildDayBadge(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInfoSection()),

                  // The navigation logic you need to keep
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios,
                        size: 20, color: AppColors.secondaryMain),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AbsentPage(
                            selectedDateStr: selectedDateStr,
                            magmo3aModel: magmo3aModel,
                            selectedDay: selectedDay,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end, // Right align for Arabic
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoRow(
          icon: Icons.school,
          label: "الصف",
          value: magmo3aModel.grade ?? "",
        ),
        const SizedBox(height: 10),
        _buildInfoRow(
          icon: Icons.access_time,
          label: "الوقت",
          value:
              magmo3aModel.time != null ? _formatTime(magmo3aModel.time!) : "",
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryMain),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "$label: ",
                  style: AppTextStyles.customText(
                    fontSize: 16,
                    color: AppColors.secondaryMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: AppTextStyles.customText(
                    fontSize: 16,
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textDirection: TextDirection.rtl,
          ),
        )
      ],
    );
  }

  Widget _buildDayBadge() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryMain,
            AppColors.secondaryMain.withOpacity(0.85)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Text(
            translateDayToArabic(magmo3aModel.day ?? ""),
            textAlign: TextAlign.center,
            style: AppTextStyles.customText(
              fontSize: 22,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String translateDayToArabic(String day) {
    switch (day.toLowerCase()) {
      case "saturday":
        return "السبت";
      case "sunday":
        return "الأحد";
      case "monday":
        return "الاثنين";
      case "tuesday":
        return "الثلاثاء";
      case "wednesday":
        return "الأربعاء";
      case "thursday":
        return "الخميس";
      case "friday":
        return "الجمعة";
      default:
        return day;
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute ${time.hour >= 12 ? "م" : "ص"}";
  }
}
