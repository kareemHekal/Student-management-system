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
          // constraints تضمن أن الكارت له شكل متناسق حتى لو كانت البيانات قليلة
          constraints: const BoxConstraints(minHeight: 90),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.primaryMain, AppColors.secondaryMain],
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // زخارف متجاوبة تعتمد على نسب مئوية من مساحة الكارت
                Positioned(
                  top: -20,
                  left: -20,
                  child: _circle(MediaQuery.of(context).size.width * 0.2, 0.08),
                ),
                Positioned(
                  bottom: -15,
                  right: 30,
                  child:
                      _circle(MediaQuery.of(context).size.width * 0.15, 0.15),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // حماية البادج ليصغر حجمه داخلياً إذا ضاقت المساحة
                      Flexible(
                        flex: 2,
                        child: _buildDayBadge(),
                      ),
                      const SizedBox(width: 14),
                      // قسم المعلومات
                      Expanded(
                        flex: 5,
                        child: _buildInfoSection(),
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

  Widget _buildDayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryMain,
            AppColors.secondaryMain.withOpacity(0.85)
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          translateDayToArabic(magmo3aModel?.day ?? ""),
          style: AppTextStyles.customText(
            fontSize: 17,
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
        // استخدام Expanded مع FittedBox يجعل السطر "مطاطياً"
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
                    fontSize: 15,
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  " :$label",
                  style: AppTextStyles.customText(
                    fontSize: 15,
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
    return "$hour:$minute ${time.hour >= 12 ? 'م' : 'ص'}";
  }
}