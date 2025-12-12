import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Alert dialogs/Notify Absence.dart';
import '../bloc/Edit Student/edit_student_cubit.dart';
import '../firebase/firebase_functions.dart';
import '../models/Studentmodel.dart';
import '../pages/EditStudent.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart';

class StudentWidget extends StatelessWidget {
  final Studentmodel studentModel;
  final bool IsComingFromGroup;
  final String? grade;

  const StudentWidget({
    required this.studentModel,
    required this.IsComingFromGroup,
    required this.grade,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openEditPage(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12), // كان 16
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topRight,
            colors: [
              AppColors.primaryMain.withOpacity(.55), // خليته أوضح
              AppColors.secondaryMain.withOpacity(.55), // نفس الكلام
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8), // كان 12
            Divider(color: Colors.white.withOpacity(.28), thickness: .6),
            const SizedBox(height: 8),
            _buildInfoSection(),
            const SizedBox(height: 8),
            _buildGroupsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        _buildNamesAndDate(),
        const Spacer(),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      backgroundColor: AppColors.white.withOpacity(.25),
      radius: 28,
      child: Icon(
        Icons.person,
        size: 34,
        color: AppColors.primaryMain,
      ),
    );
  }

  Widget _buildNamesAndDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          studentModel.name ?? "",
          style: AppTextStyles.customText(
            fontSize: 18,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          "صف الطالب:  ${studentModel.grade}",
          style: AppTextStyles.customText(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.normal,
          ),
        )
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        _iconButton(Icons.message_outlined, () => _sendDialog(context)),
        _iconButton(Icons.sticky_note_2, () => _showNoteDialog(context)),
        if (!IsComingFromGroup)
          _iconButton(Icons.delete_forever_outlined, () {
            _deleteDialog(context);
          }),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _info("الاسم", studentModel.name ?? "N/A"),
        _info("رقم الطالب", studentModel.phoneNumber ?? "N/A", isPhone: true),
        _info("رقم الأم", studentModel.motherPhone ?? "N/A", isPhone: true),
        _info("رقم الأب", studentModel.fatherPhone ?? "N/A", isPhone: true),
        _info("المرحلة", studentModel.grade ?? "N/A"),
      ],
    );
  }

  Widget _info(String label, String value, {bool isPhone = false}) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4), // كان 6
            child: Row(
              children: [
                Text(
                  "$label:",
                  style: AppTextStyles.customText(
                    fontSize: 15, // أصغر سنة
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onLongPress:
                        isPhone ? () => launchUrlString("tel:$value") : null,
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.customText(
                        fontSize: 16,
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.white.withOpacity(.20), // أخفّ و أنعم
            thickness: .5,
          ),
        ],
      );

  Widget _iconButton(IconData icon, VoidCallback onPressed) => GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryMain.withOpacity(.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryMain, size: 22),
        ),
      );

  Widget _buildGroupsList() {
    final days = studentModel.hisGroups ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: days.map((g) {
        final time = (g.time != null)
            ? "${g.time!.hour}:${g.time!.minute.toString().padLeft(2, '0')}"
            : "—";

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondaryMain.withOpacity(.3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.secondaryMain),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                g.days ?? "",
                style: AppTextStyles.customText(
                  fontSize: 14,
                  color: AppColors.primaryMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: AppTextStyles.customText(
                  fontSize: 12,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          "ملاحظات",
          style: AppTextStyles.customText(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          studentModel.note ?? "لا توجد ملاحظات",
          style: AppTextStyles.customText(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _deleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "حذف الطالب",
          style: AppTextStyles.customText(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          "هل انت متأكد من حذف الطالب؟",
          style: AppTextStyles.customText(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.normal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إلغاء",
              style: AppTextStyles.customText(
                fontSize: 14,
                color: AppColors.primaryMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              FirebaseFunctions.deleteStudentFromHisCollection(
                studentModel.grade ?? "",
                studentModel.id,
              );
              Navigator.pop(context);
            },
            child: Text(
              "حذف",
              style: AppTextStyles.customText(
                fontSize: 14,
                color: AppColors.statusAbsent,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _openEditPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => StudentEditCubit(student: studentModel),
          child: EditStudentScreen(grade: grade, student: studentModel),
        ),
      ),
    );
  }

  void _sendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "إرسال رسالة",
          style: AppTextStyles.customText(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SelectRecipientDialogContent(
          sendMessageToFather: () async => _sendWA(
              studentModel.fatherPhone ?? "",
              "عزيزي والد ${studentModel.name}"),
          sendMessageToMother: () async => _sendWA(
              studentModel.motherPhone ?? "",
              "عزيزتي والدة ${studentModel.name}"),
          sendMessageToStudent: () async => _sendWA(
              studentModel.phoneNumber ?? "", "عزيزي ${studentModel.name}"),
        ),
      ),
    );
  }

  void _sendWA(String phone, String msg) {
    final cleaned = phone.replaceAll('+', '').replaceAll(' ', '');
    final formatted =
        cleaned.startsWith('0') ? '20${cleaned.substring(1)}' : cleaned;
    final encoded = Uri.encodeComponent(msg);
    launchUrlString("https://wa.me/$formatted?text=$encoded");
  }
}
