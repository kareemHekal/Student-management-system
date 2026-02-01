import 'package:flutter/material.dart';

import '../../models/Magmo3aModel.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart';

class Groupsmallcard extends StatelessWidget {
  final Magmo3amodel? magmo3aModel;

  const Groupsmallcard({super.key, required this.magmo3aModel});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(8),
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
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(top: -25, left: -25, child: _circle(80, 0.08)),
                Positioned(bottom: -20, right: 40, child: _circle(60, 0.25)),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      // حماية البادج ليأخذ مساحة مناسبة فقط
                      Flexible(flex: 2, child: _buildDayBadge()),
                      const SizedBox(width: 14),
                      // قسم المعلومات يأخذ المساحة الأكبر
                      Expanded(flex: 5, child: _buildInfoSection()),
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: FittedBox(
          // حماية اسم اليوم من الخروج عن حدود البادج
          fit: BoxFit.scaleDown,
          child: Text(
            translateDayToArabic(magmo3aModel?.day ?? ""),
            textAlign: TextAlign.center,
            style: AppTextStyles.customText(
              fontSize: 16, // صغرنا الخط قليلاً ليتناسب مع الكارت الصغير
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoRow(
          icon: Icons.school,
          label: "الصف",
          value: magmo3aModel?.grade ?? "",
        ),
        const SizedBox(height: 6),
        _infoRow(
          icon: Icons.access_time,
          label: "الوقت",
          value: magmo3aModel?.time != null
              ? _formatTime(magmo3aModel!.time!)
              : "",
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // استخدام Expanded مع FittedBox لحماية السطر بالكامل
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTextStyles.customText(
                    fontSize: 14,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  " :$label",
                  style: AppTextStyles.customText(
                    fontSize: 14,
                    color: AppColors.secondaryMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(icon, size: 16, color: AppColors.secondaryMain),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondaryMain.withOpacity(opacity),
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