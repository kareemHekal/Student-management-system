import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/alert_dialogs/Notify%20Absence.dart';
import 'package:student_management_system/cards/student/student_card_functions.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/models/Magmo3aModel.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/provider.dart';
import 'package:student_management_system/theme/colors_app.dart';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topRight,
          colors: [
            AppColors.primaryMain.withOpacity(.8),
            AppColors.secondaryMain.withOpacity(.8),
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
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          Divider(color: AppColors.white.withOpacity(.3), thickness: .6),
          const SizedBox(height: 8),
          _buildInfoSection(),
          const SizedBox(height: 8),
          _buildStudentDaysList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.white.withOpacity(.2),
          radius: 26,
          child: Icon(Icons.person, color: AppColors.white, size: 30),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.studentModel.name ?? "",
                  style: AppTextStyles.customText(
                      fontSize: 17,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold)),
              Text("الإضافة: ${widget.studentModel.dateofadd}",
                  style: AppTextStyles.customText(
                      fontSize: 12, color: AppColors.white.withOpacity(0.8))),
            ],
          ),
        ),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        _iconBtn(Icons.message_outlined, () => _showWhatsAppDialog(context)),
        const SizedBox(width: 8),
        _iconBtn(Icons.add_comment_rounded, () => _showAddNoteDialog(context)),
        const SizedBox(width: 8),
        // Simplified to a standard Icon Button that triggers a Dialog
        _iconBtn(Icons.info_outline, () => _showNotesDialog(context)),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.white.withOpacity(.15), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
      );

// New modern Dialog to replace the Tooltip
  void _showNotesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryMain),
            const SizedBox(width: 10),
            Text(
              "ملاحظات الطالب",
              style: AppTextStyles.customText(
                fontSize: 18,
                color: AppColors.primaryMain,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end, // RTL alignment
          children: [
            Text(
              "عذر الغياب:",
              style: AppTextStyles.customText(
                fontSize: 14,
                color: AppColors.secondaryMain,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getNoteForDate(widget.selectedDateStr),
              style: AppTextStyles.customText(
                  fontSize: 15, color: AppColors.textPrimary),
            ),
            const Divider(height: 20),
            Text(
              "ملاحظة دائمة:",
              style: AppTextStyles.customText(
                fontSize: 14,
                color: AppColors.secondaryMain,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.studentModel.note ?? "لا توجد ملاحظة",
              style: AppTextStyles.customText(
                  fontSize: 15, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إغلاق",
              style: AppTextStyles.customText(color: AppColors.primaryMain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _infoLine("رقم الهاتف", widget.studentModel.phoneNumber ?? "N/A"),
        _infoLine("رقم ولي الأمر", widget.studentModel.fatherPhone ?? "N/A"),
      ],
    );
  }

  Widget _infoLine(String label, String value) => Row(
        children: [
          Text("$label:",
              style: AppTextStyles.customText(
                  fontSize: 14, color: AppColors.white.withOpacity(0.9))),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onLongPress: () => StudentActionsHelper.launchPhone(value),
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.customText(
                      fontSize: 15,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );

  Widget _buildStudentDaysList() {
    // Accessing the list from widget.studentModel as per your first snippet
    final groups = widget.studentModel.hisGroups ?? [];

    return Wrap(
      spacing: 8, // Horizontal space between items
      runSpacing: 6, // Vertical space between lines
      children: groups.map((g) {
        final time = (g.time != null)
            ? StudentActionsHelper.formatTime12Hour(g.time!)
            : "—";

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // Important: prevents Row from taking full width
            children: [
              Text(
                g.day ?? "",
                style: AppTextStyles.customText(
                  fontSize: 13,
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: AppTextStyles.customText(
                  fontSize: 12,
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
        content: SelectRecipientDialogContent(
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
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    _noteController.text = _getNoteForDate(widget.selectedDateStr);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عذر غياب'),
        content: TextField(
            controller: _noteController,
            decoration: const InputDecoration(hintText: "الملاحظة...")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              // Firebase update logic
              String dateKey = widget.selectedDateStr;
              widget.studentModel.notes ??= [];
              widget.studentModel.notes!.add({dateKey: _noteController.text});
              FirebaseFunctions.updateStudentInCollection(widget.selectedDate,
                  widget.magmo3aModel.id, widget.studentModel);
              Navigator.pop(context);
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }
}
