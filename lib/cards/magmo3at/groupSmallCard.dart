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
                blurRadius: 14,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Stack(
            children: [
              // ===== decorative circles =====
              Positioned(
                top: -25,
                left: -25,
                child: _circle(80, 0.08),
              ),
              Positioned(
                bottom: -20,
                right: 40,
                child: _circle(60, 0.25),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  // ================= UI Parts =================

  Widget _buildDayBadge() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryMain,
            AppColors.secondaryMain.withOpacity(0.85),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          translateDayToArabic(magmo3aModel?.day ?? ""),
          textAlign: TextAlign.center,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoRow(
          icon: Icons.school,
          label: "الصف",
          value: magmo3aModel?.grade ?? "",
        ),
        const SizedBox(height: 8),
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
        Icon(icon, size: 16, color: AppColors.secondaryMain),
        const SizedBox(width: 6),
        RichText(
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: [
              TextSpan(
                text: "$label: ",
                // تم التأكد من استخدام الستايل المخصص هنا
                style: AppTextStyles.customText(
                  fontSize: 14,
                  color: AppColors.secondaryMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: value,
                // تم التأكد من استخدام الستايل المخصص هنا
                style: AppTextStyles.customText(
                  fontSize: 14,
                  color: AppColors.white,
                  // تم تعديله للون الأبيض لزيادة الوضوح على التدرج
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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

  // ================= Helpers =================

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