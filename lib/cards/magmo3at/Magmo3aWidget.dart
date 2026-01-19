import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';

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
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
      child: Slidable(
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.4,
          children: [
            CustomSlidableAction(
              onPressed: (_) => _showDeleteDialog(context),
              backgroundColor: AppColors.statusAbsent,
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20)),
              child: const Icon(Icons.delete_rounded, size: 28),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => _openEditSheet(context),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      _buildDayBadge(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoSection()),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios,
                            size: 20, color: AppColors.secondaryMain),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentInAgroup(magmo3aModel: magmo3aModel),
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
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end, // المحتوى لليمين
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoRow(
          icon: Icons.school, // أيقونة الصف (قبعة)
          label: "الصف",
          value: magmo3aModel.grade ?? "",
        ),
        const SizedBox(height: 10),
        _buildInfoRow(
          icon: Icons.access_time, // أيقونة الوقت (ساعة)
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
      mainAxisAlignment: MainAxisAlignment.end, // من اليمين للشمال
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryMain), // الأيقونة أول
        const SizedBox(width: 6),
        RichText(
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: [
              TextSpan(
                text: "$label: ",
                style: AppTextStyles.customText(
                  fontSize: 16,
                  color: AppColors.secondaryMain, // لون الـ label
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: value,
                style: AppTextStyles.customText(
                  fontSize: 16,
                  color: AppColors.textOnDark, // لون الـ value
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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
        return day; // لو مش موجود يتركها كما هي
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute ${time.hour >= 12 ? "م" : "ص"}";
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.statusAbsent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded,
                  color: AppColors.statusAbsent, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              "حذف المجموعة",
              style: AppTextStyles.customText(
                fontSize: 18,
                color: AppColors.statusAbsent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "متأكد إنك عايز تحذف المجموعة؟\nهيتم شيل اسمها من الطلاب كمان.",
          style: AppTextStyles.customText(
              fontSize: 15, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إلغاء",
              style: AppTextStyles.customText(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusAbsent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              FirebaseFunctions.deleteMagmo3aFromDay(
                  magmo3aModel.day ?? "", magmo3aModel.id);
            },
            child: Text(
              "تأكيد الحذف",
              style: AppTextStyles.customText(
                  fontSize: 15, color: AppColors.textOnDark),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => AddMagmo3a(
        existingMagmo3a: magmo3aModel,
        oldDay: magmo3aModel.day,
      ),
    );
  }
}
