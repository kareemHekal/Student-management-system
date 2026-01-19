import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../firebase/firebase_functions.dart';
import '../loadingFile/loading_alert/run_with_loading.dart';
import 'verifiy_password.dart';

class ResetGradeAndStudentSubscriptionsDialog extends StatefulWidget {
  const ResetGradeAndStudentSubscriptionsDialog({super.key});

  @override
  State<ResetGradeAndStudentSubscriptionsDialog> createState() =>
      _ResetGradeAndStudentSubscriptionsDialogState();
}

class _ResetGradeAndStudentSubscriptionsDialogState
    extends State<ResetGradeAndStudentSubscriptionsDialog> {
  bool resetSubs = false;
  bool resetAbsence = false;
  bool deleteExams = false;
  bool deleteGroups = false;
  bool deleteStudents = false;

  List<String> allGrades = [];
  List<String> selectedGrades = [];
  bool isLoadingGrades = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      List<String> grades = await FirebaseFunctions.getGradesList();
      setState(() {
        allGrades = grades;
        selectedGrades = [];
        isLoadingGrades = false;
      });
    } catch (e) {
      setState(() => isLoadingGrades = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: EdgeInsets.zero,
      title: _buildHeader(),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _buildSectionHeader(
                  Icons.layers_outlined, '1. تحديد المراحل المستهدفة'),
              const SizedBox(height: 12),
              _buildGradeSelector(),
              const SizedBox(height: 24),
              _buildSectionHeader(Icons.settings, '2. خيارات التنظيف'),
              const SizedBox(height: 8),
              _buildOption(
                title: 'تصفير مبالغ الاشتراكات',
                subtitle:
                    'سيتم مسح سجلات الدفع المالي واشتراكات المرحلة والطلاب.',
                icon: Icons.monetization_on_outlined,
                value: resetSubs,
                onChanged: (v) => setState(() => resetSubs = v!),
              ),
              _buildOption(
                title: 'تصفير سجلات الحضور والغياب',
                subtitle: 'سيتم مسح كافة أيام الغياب والحضور وإحصائيات الطلاب.',
                icon: Icons.calendar_today_outlined,
                value: resetAbsence,
                onChanged: (v) => setState(() => resetAbsence = v!),
              ),
              _buildOption(
                title: 'حذف الامتحانات والنتائج',
                subtitle:
                    'سيتم حذف كافة الامتحانات المسجلة ودرجات الطلاب تماماً.',
                icon: Icons.assignment_outlined,
                value: deleteExams,
                onChanged: (v) => setState(() => deleteExams = v!),
              ),
              _buildOption(
                title: 'حذف جميع المجموعات',
                subtitle: 'سيتم مسح جميع مجموعات الدروس المرتبطة بالأيام.',
                icon: Icons.groups_outlined,
                value: deleteGroups,
                onChanged: (v) => setState(() => deleteGroups = v!),
              ),
              const Divider(height: 32, thickness: 1),
              _buildOption(
                title: 'حذف الطلاب نهائياً',
                subtitle:
                    'تحذير: سيتم مسح بيانات الطلاب بالكامل من قاعدة البيانات.',
                icon: Icons.person_remove_outlined,
                value: deleteStudents,
                color: Colors.red[700]!,
                onChanged: (v) => setState(() => deleteStudents = v!),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: _buildActions(context),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.customText(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGradeSelector() {
    if (isLoadingGrades) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // تغيير لون الإطار للأحمر إذا لم يتم اختيار أي شيء
              color: selectedGrades.isEmpty
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                activeColor: AppColors.statusAbsent,
                dense: true,
                title: const Text("اختيار كافة المراحل",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                value: allGrades.isNotEmpty &&
                    selectedGrades.length == allGrades.length,
                onChanged: (val) => setState(
                    () => selectedGrades = val! ? List.from(allGrades) : []),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (allGrades.isNotEmpty) const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allGrades.length,
                  itemBuilder: (context, index) {
                    final grade = allGrades[index];
                    return CheckboxListTile(
                      activeColor: AppColors.statusAbsent,
                      dense: true,
                      title: Text(grade, style: const TextStyle(fontSize: 13)),
                      value: selectedGrades.contains(grade),
                      onChanged: (val) => setState(() => val!
                          ? selectedGrades.add(grade)
                          : selectedGrades.remove(grade)),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (selectedGrades.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8, right: 8),
            child: Text(
              "* يجب اختيار مرحلة دراسية واحدة على الأقل",
              style: TextStyle(
                  color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.statusAbsent,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_delete_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text(
            'مركز الصيانة وإعادة التعيين',
            style: AppTextStyles.customText(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يرجى توخي الحذر عند اختيار البيانات للحذف',
            style:
                AppTextStyles.customText(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
    Color color = Colors.black87,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: value ? color.withOpacity(0.03) : Colors.transparent,
      ),
      child: CheckboxListTile(
        activeColor: color == Colors.black87 ? AppColors.statusAbsent : color,
        secondary: Icon(icon,
            color: value
                ? (color == Colors.black87 ? AppColors.statusAbsent : color)
                : Colors.grey[400]),
        title: Text(title,
            style: AppTextStyles.customText(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(subtitle,
            style:
                TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4)),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    bool isAnythingSelected = resetSubs ||
        resetAbsence ||
        deleteExams ||
        deleteGroups ||
        deleteStudents;

    return [
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء العملية',
                  style: AppTextStyles.customText(
                      color: AppColors.textSecondary, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusAbsent,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: (selectedGrades.isEmpty || !isAnythingSelected)
                  ? null
                  : () => _handleConfirm(context),
              child: Text(
                'بدء التنفيذ',
                style: AppTextStyles.customText(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  void _handleConfirm(BuildContext context) {
    final parentContext = context;
    showVerifyPasswordDialog(
      context: parentContext,
      onVerified: () async {
        await runWithLoading(parentContext, () async {
          try {
            for (final grade in selectedGrades) {
              await FirebaseFunctions.resetGradeData(
                daysList: [
                  "Saturday",
                  "Sunday",
                  "Monday",
                  "Tuesday",
                  "Wednesday",
                  "Thursday",
                  "Friday"
                ],
                gradeName: grade,
                resetSubscriptions: resetSubs,
                resetAbsence: resetAbsence,
                deleteExams: deleteExams,
                deleteGroups: deleteGroups,
                deleteStudents: deleteStudents,
              );
            }

            if (parentContext.mounted) {
              AppSnackBars.showSuccess(
                  parentContext, "تمت عملية إعادة التعيين بنجاح");
              Navigator.pushNamedAndRemoveUntil(
                  parentContext, "/HomeScreen", (_) => false);
            }
          } catch (e) {
            if (parentContext.mounted) {
              AppSnackBars.showError(parentContext, "حدث خطأ غير متوقع: $e");
            }
          }
        });
      },
    );
  }
}