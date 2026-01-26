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
    // Get screen width for relative scaling
    final double screenWidth = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              // Using minHeight instead of fixed height for responsiveness
              constraints: const BoxConstraints(minHeight: 100),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // ===== Responsive Decorative circles =====
                    Positioned(
                      top: -screenWidth * 0.05,
                      left: -screenWidth * 0.05,
                      child: _circle(screenWidth * 0.15, 0.08),
                    ),
                    Positioned(
                      bottom: -screenWidth * 0.04,
                      right: screenWidth * 0.08,
                      child: _circle(screenWidth * 0.12, 0.22),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          _buildDayBadge(screenWidth),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildInfoSection(screenWidth),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= UI =================

  Widget _buildDayBadge(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.035,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryMain,
            AppColors.secondaryMain.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        translateDayToArabic(magmo3aModel?.day ?? ""),
        style: AppTextStyles.customText(
          // Adjust font size based on screen width
          fontSize: screenWidth < 360 ? 15 : 18,
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoRow(
          screenWidth: screenWidth,
          icon: Icons.school,
          label: "الصف",
          value: magmo3aModel?.grade ?? "",
        ),
        const SizedBox(height: 6),
        _infoRow(
          screenWidth: screenWidth,
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
    required double screenWidth,
    required IconData icon,
    required String label,
    required String value,
  }) {
    double responsiveFontSize = screenWidth < 360 ? 13 : 15;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          icon,
          size: screenWidth < 360 ? 15 : 17,
          color: AppColors.secondaryMain,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: RichText(
            textDirection: TextDirection.rtl,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$label :  ",
                  style: AppTextStyles.customText(
                    fontSize: responsiveFontSize,
                    color: AppColors.secondaryMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: AppTextStyles.customText(
                    fontSize: responsiveFontSize,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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