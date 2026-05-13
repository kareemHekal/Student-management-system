import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/alert_dialogs/Notify%20Absence.dart';
import 'package:student_management_system/cards/student/student_card_functions.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/Magmo3aModel.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/provider.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

class AbsentStudentWidget extends StatefulWidget {
  final Studentmodel studentModel;
  final String? grade;
  final String selectedDateStr;
  final String selectedDate;
  final Magmo3amodel magmo3aModel;

  const AbsentStudentWidget({
    required this.magmo3aModel,
    required this.selectedDateStr,
    required this.selectedDate,
    required this.studentModel,
    required this.grade,
    super.key,
  });

  @override
  State<AbsentStudentWidget> createState() => _AbsentStudentWidgetState();
}

class _AbsentStudentWidgetState extends State<AbsentStudentWidget> {
  final TextEditingController _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(15),
      // زيادة الـ Padding قليلاً للراحة البصرية
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
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),
          Divider(color: AppColors.white.withOpacity(.3), thickness: .6),
          const SizedBox(height: 10),
          _buildInfoSection(),
          const SizedBox(height: 12),
          _buildStudentDaysList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.white.withOpacity(.2),
            radius: 24,
            child: const Icon(Icons.person, color: AppColors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentModel.name ?? "",
                  style: AppTextStyles.customText(
                      fontSize: 16,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "الإضافة: ${widget.studentModel.dateofadd}",
                    style: AppTextStyles.customText(
                        fontSize: 11, color: AppColors.white.withOpacity(0.8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          _buildActionButtons(context, constraints.maxWidth),
        ],
      );
    });
  }

  Widget _buildActionButtons(BuildContext context, double maxWidth) {
    // إذا كانت الشاشة صغيرة جداً، نستخدم Wrap بدلاً من Row للأزرار
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _iconBtn(Icons.message_outlined, () => _showWhatsAppDialog(context)),
        _iconBtn(Icons.add_comment_rounded, () => _showAddNoteDialog(context)),
        _iconBtn(Icons.info_outline, () => _showNotesDialog(context)),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: AppColors.white.withOpacity(.18), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.white, size: 18),
        ),
      );

  void _showNotesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryMain),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "ملاحظات الطالب",
                style: AppTextStyles.customText(
                  fontSize: 18,
                  color: AppColors.primaryMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _dialogSectionTitle("عذر الغياب:"),
              Text(
                _getNoteForDate(widget.selectedDateStr),
                style: AppTextStyles.customText(
                    fontSize: 14, color: AppColors.textPrimary),
              ),
              const Divider(height: 25),
              _dialogSectionTitle("ملاحظة دائمة:"),
              Text(
                widget.studentModel.note ?? "لا توجد ملاحظة",
                style: AppTextStyles.customText(
                    fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إغلاق",
                style: AppTextStyles.customText(color: AppColors.primaryMain)),
          ),
        ],
      ),
    );
  }

  Widget _dialogSectionTitle(String title) => Text(
        title,
        style: AppTextStyles.customText(
          fontSize: 13,
          color: AppColors.secondaryMain,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _buildInfoSection() {
    return Column(
      children: [
        _infoLine("رقم الهاتف", widget.studentModel.phoneNumber ?? "N/A"),
        const SizedBox(height: 4),
        _infoLine("رقم ولي الأمر", widget.studentModel.fatherPhone ?? "N/A"),
      ],
    );
  }

  Widget _infoLine(String label, String value) => Row(
        children: [
          Text("$label:",
              style: AppTextStyles.customText(
                  fontSize: 13, color: AppColors.white.withOpacity(0.9))),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onLongPress: () => StudentActionsHelper.launchPhone(value),
              child: FittedBox(
                alignment: Alignment.centerRight,
                fit: BoxFit.scaleDown,
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.customText(
                        fontSize: 14,
                        color: AppColors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      );

  Widget _buildStudentDaysList() {
    final groups = widget.studentModel.hisGroups ?? [];
    if (groups.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: groups.map((g) {
        final time = (g.time != null)
            ? StudentActionsHelper.formatTime12Hour(g.time)
            : "—";

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today,
                  size: 12, color: AppColors.white.withOpacity(0.8)),
              const SizedBox(width: 5),
              Text(
                g.day ?? "",
                style: AppTextStyles.customText(
                  fontSize: 12,
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const VerticalDivider(color: Colors.white24, width: 10),
              Text(
                time,
                style: AppTextStyles.customText(
                  fontSize: 11,
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getNoteForDate(String dateKey) {
    if (widget.studentModel.notes == null) return "لا توجد ملاحظات";
    for (var note in widget.studentModel.notes!) {
      if (note.containsKey(dateKey)) return note[dateKey] ?? "";
    }
    return "لا توجد ملاحظات لتاريخ اليوم";
  }

  void _showWhatsAppDialog(BuildContext context) {
    final teacher =
        Provider.of<TeacherProvider>(context, listen: false).teacher;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: SelectRecipientDialogContent(
            sendMessageToFather: () =>
                StudentActionsHelper.sendWhatsAppAbsenceMessage(
                    teacher: teacher?.name ?? "",
                    studentName: widget.studentModel.name!,
                    parentRole: 'father',
                    phoneNumber: widget.studentModel.fatherPhone ?? ""),
            sendMessageToMother: () =>
                StudentActionsHelper.sendWhatsAppAbsenceMessage(
                    teacher: teacher?.name ?? "",
                    studentName: widget.studentModel.name!,
                    parentRole: 'mother',
                    phoneNumber: widget.studentModel.motherPhone ?? ""),
            sendMessageToStudent: () =>
                StudentActionsHelper.sendWhatsAppAbsenceMessage(
                    studentName: widget.studentModel.name!,
                    teacher: teacher?.name ?? "",
                    parentRole: 'student',
                    phoneNumber: widget.studentModel.phoneNumber ?? ""),
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    if (_getNoteForDate(widget.selectedDateStr) ==
        "لا توجد ملاحظات لتاريخ اليوم") {
      _noteController.text = "";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة عذر غياب',
            style: AppTextStyles.customText(fontWeight: FontWeight.bold)),
        content: TextField(
            controller: _noteController,
            style: AppTextStyles.customText(),
            decoration: const InputDecoration(hintText: "الملاحظة...")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("إلغاء",
                  style: AppTextStyles.customText(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              String dateKey = widget.selectedDateStr;
              widget.studentModel.notes ??= [];
              widget.studentModel.notes!.add({dateKey: _noteController.text});
              runWithLoading(context, () async {
                try {
                  await FirebaseFunctions.updateStudentInCollection(
                      widget.grade!,
                      widget.studentModel.id,
                      widget.studentModel);
                  Navigator.pop(context);
                  AppSnackBars.showSuccess(context, "تم اضافه الملاحظه بنجاح ");
                } catch (e) {
                  AppSnackBars.showError(context, "حدثت مشكله $e");
                }
              });
            },
            child: Text("حفظ",
                style: AppTextStyles.customText(
                    color: AppColors.primaryMain, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
