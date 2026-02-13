import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';

import '../../BottomSheets/add_magmo3a.dart';
import '../../models/Magmo3aModel.dart';
import '../../pages/all students in one group.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart';

class Magmo3aWidget extends StatelessWidget {
  final Magmo3amodel magmo3aModel;

  const Magmo3aWidget({required this.magmo3aModel, super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
      child: Slidable(
        // الجزء الخاص بالسحب للحذف
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.35,
          children: [
            CustomSlidableAction(
              onPressed: (_) => _showDeleteDialog(context),
              backgroundColor: AppColors.statusAbsent,
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                bottomLeft: Radius.circular(22),
              ),
              child: const Icon(Icons.delete_sweep_rounded, size: 28),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => _openEditSheet(context),
          child: Container(
            // تحديد ارتفاع أدنى لضمان مظهر متناسق
            constraints: const BoxConstraints(minHeight: 115),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [AppColors.primaryMain, AppColors.secondaryMain],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMain.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                alignment: Alignment.center,
                // لضمان توسيط المحتوى داخل الـ Stack
                children: [
                  // --- زخارف الخلفية ---
                  Positioned(
                    top: -25,
                    right: -25,
                    child: _buildDecorativeCircle(screenWidth * 0.25, 0.12),
                  ),
                  Positioned(
                    bottom: -30,
                    left: screenWidth * 0.15,
                    child: _buildDecorativeCircle(90, 0.1),
                  ),

                  // --- المحتوى الرئيسي ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      // توسيط عمودي مثالي للسطر
                      children: [
                        // 1. Badge اليوم
                        _buildDayBadge(screenWidth),

                        const SizedBox(width: 14),

                        // 2. قسم النصوص (الصف والوقت)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            // توسيط النصوص عمودياً
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildInfoRow(
                                icon: Icons.school_outlined,
                                label: "الصف",
                                value: magmo3aModel.grade ?? "غير محدد",
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                icon: Icons.timer_outlined,
                                label: "الوقت",
                                value: magmo3aModel.time != null
                                    ? _formatTime(magmo3aModel.time!)
                                    : "--:--",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // 3. زر السهم المطور (دائرة مكبرة ولون ثانوي)
                        _buildArrowButton(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ودجت زخرفة الدوائر
  Widget _buildDecorativeCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withOpacity(opacity),
      ),
    );
  }

  // ودجت Badge اليوم
  Widget _buildDayBadge(double screenWidth) {
    return Container(
      constraints: BoxConstraints(minWidth: screenWidth * 0.18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withOpacity(0.25)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          translateDayToArabic(magmo3aModel.day ?? ""),
          style: AppTextStyles.customText(
            fontSize: 20,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // سطر المعلومات (أيقونة + نص)
  Widget _buildInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      // يبدأ من الأعلى لو نزل سطرين
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          // محاذاة بسيطة للأيقونة مع أول سطر
          child: Icon(icon, size: 17, color: AppColors.white.withOpacity(0.85)),
        ),
        const SizedBox(width: 8),
        Expanded(
          // يسمح للنص بأخذ المساحة المتبقية والنزول لسطر جديد
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "$label: ",
                  style: AppTextStyles.customText(
                    fontSize: 15, // حجم الخط ثابت وواضح
                    color: AppColors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: AppTextStyles.customText(
                    fontSize: 16,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            textDirection: TextDirection.rtl,
            softWrap: true, // تفعيل النزول لسطر جديد تلقائياً
            maxLines: 2, // يسمح بحد أقصى سطرين (يمكنك زيادتها لو أردت)
            overflow: TextOverflow.visible, // إظهار النص بالكامل
          ),
        ),
      ],
    );
  }

  // زر السهم المطور
  Widget _buildArrowButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllStudedntsInOneGroup(magmo3aModel: magmo3aModel),
          ),
        );
      },
      child: Container(
        width: 46, // حجم الدائرة مكبر
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border:
              Border.all(color: AppColors.white.withOpacity(0.3), width: 1.5),
        ),
        child: const Icon(
          Icons.arrow_forward_ios_outlined, // اتجاه مناسب للعربية
          size: 20,
          color: AppColors.white,
        ),
      ),
    );
  }

  // --- دوال المساعدة ---

  String translateDayToArabic(String day) {
    final Map<String, String> days = {
      "saturday": "السبت",
      "sunday": "الأحد",
      "monday": "الاثنين",
      "tuesday": "الثلاثاء",
      "wednesday": "الأربعاء",
      "thursday": "الخميس",
      "friday": "الجمعة",
    };
    return days[day.toLowerCase()] ?? day;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "ص" : "م";
    return "$hour:$minute $period";
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text("حذف المجموعة",
            style: AppTextStyles.customText(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.statusAbsent)),
        content: Text("هل أنت متأكد من حذف هذه المجموعة نهائياً؟",
            style: AppTextStyles.customText(
                fontSize: 15, color: AppColors.textPrimary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusAbsent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final nav = Navigator.of(dialogContext);
              await runWithLoading(dialogContext, () async {
                await FirebaseFunctions.deleteMagmo3aFromDay(
                  magmo3aId: magmo3aModel.id,
                  day: magmo3aModel.day ?? "",
                  grade: magmo3aModel.grade ?? "",
                );
              });
              if (dialogContext.mounted) nav.pop();
            },
            child: Text("تأكيد",
                style: AppTextStyles.customText(
                    color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMagmo3a(
        existingMagmo3a: magmo3aModel,
        oldDay: magmo3aModel.day,
      ),
    );
  }
}