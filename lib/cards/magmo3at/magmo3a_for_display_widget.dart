import 'package:flutter/material.dart';

import '../../models/Magmo3aModel.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart';

class Magmo3aWidgetWithoutSlidable extends StatelessWidget {
  final Magmo3amodel? magmo3aModel;

  const Magmo3aWidgetWithoutSlidable({
    super.key,
    required this.magmo3aModel,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
                color: AppColors.primaryMain.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ===== Decorative circles =====
              Positioned(
                top: -20,
                left: -20,
                child: _circle(60, 0.08),
              ),
              Positioned(
                bottom: -18,
                right: 30,
                child: _circle(45, 0.22),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    _buildDayBadge(),
                    const SizedBox(width: 14),
                    Expanded(child: _buildInfoSection()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  Widget _buildDayBadge() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryMain,
            AppColors.secondaryMain.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          translateDayToArabic(magmo3aModel?.day ?? ""),
          style: AppTextStyles.customText(
            fontSize: 18,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _infoRow(
          icon: Icons.school,
          label: "الصف",
          value: magmo3aModel?.grade ?? "",
        ),
        const SizedBox(height: 4),
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
        Icon(
          icon,
          size: 17,
          color: AppColors.secondaryMain,
        ),
        const SizedBox(width: 6),
        RichText(
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: [
              TextSpan(
                text: "$label :  ",
                style: AppTextStyles.customText(
                  fontSize: 15,
                  color: AppColors.secondaryMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: value,
                style: AppTextStyles.customText(
                  fontSize: 15,
                  color: AppColors.white,
                  // تم تغييره للون الأبيض ليتناسب مع الخلفية الملونة
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= Helpers =================

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
    return "$hour:$minute ${time.hour >= 12 ? 'م' : 'ص'}";
  }
}