import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/alert_dialogs/Notify%20Absence.dart';
import 'package:student_management_system/alert_dialogs/delete_student_with_settlement.dart';
import 'package:student_management_system/provider.dart';

import '../../bloc/Edit Student/edit_student_cubit.dart';
import '../../models/Student_model.dart';
import '../../pages/student/edit_student/EditStudent.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart';
import 'student_card_functions.dart';

class StudentWidget extends StatelessWidget {
  final Studentmodel studentModel;
  final bool IsComingFromGroup;

  const StudentWidget({
    required this.studentModel,
    required this.IsComingFromGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openEditPage(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topRight,
            colors: [
              AppColors.primaryMain.withOpacity(.85),
              AppColors.secondaryMain.withOpacity(.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Divider(color: AppColors.white.withOpacity(.3), thickness: .6),
            const SizedBox(height: 8),
            _buildInfoSection(context),
            const SizedBox(height: 12),
            _buildGroupsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      // عشان لو النص نزل سطرين يفضل الأفاتار والأزرار فوق
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        // هنا الـ Expanded بيضمن إن النص ياخد كل المساحة المتاحة
        // بس من غير ما يضغط على الأزرار اللي جمبه
        Expanded(child: _buildNamesAndDate()),
        const SizedBox(width: 8),
        // الأزرار هنا واخدة مساحتها الطبيعية (Intrinsic width)
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildNamesAndDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          studentModel.name ?? "",
          // شيلنا الـ FittedBox
          // حددنا إن الاسم ممكن ينزل لسطرين كحد أقصى قبل ما يعمل نقاط
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.customText(
            fontSize: 17,
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2), // مسافة بسيطة بين الاسم والصف
        Text(
          "صف الطالب:  ${studentModel.grade}",
          style: AppTextStyles.customText(
            fontSize: 12,
            color: AppColors.white.withOpacity(0.9),
          ),
        )
      ],
    );
  }

  Widget _buildAvatar() {
    final bool isMale = studentModel.gender == 'ذكر';
    final IconData genderIcon = isMale ? Icons.person : Icons.person_3;
    final Color avatarColor =
        isMale ? AppColors.white.withOpacity(.2) : Colors.pink.withOpacity(.2);

    return CircleAvatar(
      backgroundColor: avatarColor,
      radius: 25,
      child: Icon(genderIcon, size: 30, color: AppColors.white),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconButton(Icons.message_outlined, () => _sendDialog(context)),
        const SizedBox(width: 6),
        _iconButton(Icons.sticky_note_2, () => _showNoteDialog(context)),
        if (!IsComingFromGroup) ...[
          const SizedBox(width: 6),
          _iconButton(
              Icons.delete_forever_outlined, () => _deleteDialog(context)),
        ],
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      children: [
        _info("رقم الطالب", studentModel.phoneNumber ?? "N/A"),
        _info("رقم ولي الأمر", studentModel.fatherPhone ?? "N/A"),
        if (studentModel.motherPhone != null &&
            studentModel.motherPhone!.isNotEmpty)
          _info("رقم ولي الأمر 2", studentModel.motherPhone!),
      ],
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "$label:",
                  style: AppTextStyles.customText(
                    fontSize: 13,
                    color: AppColors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onLongPress: () => StudentActionsHelper.launchPhone(value),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      // في الأرقام الإنجليزية يفضل اليسار
                      child: Text(
                        value,
                        style: AppTextStyles.customText(
                          fontSize: 14,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: AppColors.white.withOpacity(.1), thickness: .5),
          ],
        ),
      );

  Widget _iconButton(IconData icon, VoidCallback onPressed) => GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.white, size: 25),
        ),
      );

  Widget _buildGroupsList() {
    final days = studentModel.hisGroups ?? [];
    if (days.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((g) {
        final time = (g.time != null)
            ? StudentActionsHelper.formatTime12Hour(g.time)
            : "—";
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                g.day ?? "",
                style: AppTextStyles.customText(
                    fontSize: 11,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                time,
                style: AppTextStyles.customText(
                    fontSize: 10, color: AppColors.white.withOpacity(0.9)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // الدوال المساعدة (Notes, Delete, Edit, Send) ستبقى كما هي في المنطق مع تعديلات بسيطة في ستايل الدايالوج
  void _showNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("ملاحظات الطالب",
            style: AppTextStyles.customText(
                fontSize: 18,
                color: AppColors.primaryMain,
                fontWeight: FontWeight.bold)),
        content: Text(studentModel.note ?? "لا توجد ملاحظات حالياً.",
            style: AppTextStyles.customText(
                fontSize: 15, color: AppColors.textPrimary)),
      ),
    );
  }

  void _deleteDialog(BuildContext context) {
    final DateTime now = DateTime.now();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteStudentWithSettlementDialog(
        student: studentModel,
        date:
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        day: _getDayName(now.weekday),
      ),
    );
  }

  void _openEditPage(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BlocProvider(
                create: (_) => StudentEditCubit(student: studentModel),
                child: EditStudentScreen(student: studentModel))));
  }

  void _sendDialog(BuildContext context) {
    final teacher =
        Provider.of<TeacherProvider>(context, listen: false).teacher;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("إرسال رسالة واتساب",
            style: AppTextStyles.customText(
                fontSize: 18,
                color: AppColors.primaryMain,
                fontWeight: FontWeight.bold)),
        content: SelectRecipientDialogContent(
          sendMessageToFather: () =>
              StudentActionsHelper.sendWhatsAppAbsenceMessage(
                  teacher: teacher?.name ?? "",
                  studentName: studentModel.name!,
                  parentRole: 'father',
                  phoneNumber: studentModel.fatherPhone ?? ""),
          sendMessageToMother: () =>
              StudentActionsHelper.sendWhatsAppAbsenceMessage(
                  teacher: teacher?.name ?? "",
                  studentName: studentModel.name!,
                  parentRole: 'mother',
                  phoneNumber: studentModel.motherPhone ?? ""),
          sendMessageToStudent: () =>
              StudentActionsHelper.sendWhatsAppAbsenceMessage(
                  studentName: studentModel.name!,
                  teacher: teacher?.name ?? "",
                  parentRole: 'student',
                  phoneNumber: studentModel.phoneNumber ?? ""),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return "";
    }
  }
}