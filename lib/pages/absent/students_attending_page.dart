import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:student_management_system/cards/absence_cards/absent_student_card.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/Magmo3aModel.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import 'view_model/cubit.dart';
import 'view_model/intent.dart';
import 'view_model/states.dart';

class StudentsAttending extends StatelessWidget {
  final String selectedDay;
  final Magmo3amodel magmo3aModel;
  final AbsentCubit cubit;

  const StudentsAttending({
    required this.cubit,
    required this.selectedDay,
    required this.magmo3aModel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AbsentCubit, AbsentState>(
      listener: (context, state) {
        if (state is AbsentError) {
          AppSnackBars.showError(context, state.error);
        }
      },
      builder: (context, state) {
        final students = cubit.filteredAttendStudentsList.isNotEmpty
            ? cubit.filteredAttendStudentsList
            : cubit.attendStudents;

        return Scaffold(
          backgroundColor: const Color(0xffF8F9FE),
          appBar: _buildAppBar(context, cubit, students.length),
          body: Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset("assets/images/logo.png", width: 250),
                ),
              ),
              _buildContent(context, cubit, students),
            ],
          ),
        );
      },
    );
  }

  // ------------------- APP BAR -------------------
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AbsentCubit cubit,
    int total,
  ) {
    return AppBar(
      backgroundColor: AppColors.primaryMain,
      elevation: 0,
      toolbarHeight: 90,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Image.asset("assets/images/logo.png", height: 60),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          child: Column(
            children: [
              TextFormField(
                controller: cubit.searchController,
                onChanged: (q) => cubit.searchAttendingStudents(q),
                style: AppTextStyles.customText(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.white,
                  hintText: 'ابحث في قائمة الحاضرين...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.secondaryMain,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.statusAbsent,
                    ),
                    onPressed: () {
                      cubit.searchController.clear();
                      cubit.searchAttendingStudents("");
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryMain.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondaryMain.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  'إجمالي الحضور: $total',
                  style: AppTextStyles.customText(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------- CONTENT -------------------
  Widget _buildContent(
    BuildContext context,
    AbsentCubit cubit,
    List<Studentmodel> students,
  ) {
    if (students.isEmpty) {
      return _emptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];

        return GestureDetector(
          onLongPress: () => _showRestoreDialog(context, student),
          child: AbsentStudentWidget(
            grade: student.grade,
            magmo3aModel: cubit.magmo3aModel,
            selectedDateStr: cubit.selectedDateStr,
            selectedDate: cubit.selectedDay,
            studentModel: student,
          ),
        );
      },
    );
  }

  // ------------------- EMPTY STATE -------------------
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 80,
            color: AppColors.primaryMain.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد طلاب حاضرون',
            style: AppTextStyles.customText(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- RESTORE DIALOG -------------------
  void _showRestoreDialog(BuildContext context, Studentmodel student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: _dialogHeader(
          Icons.settings_backup_restore_rounded,
          "استرجاع الطالب",
        ),
        content: Text(
          'هل تريد تحويل "${student.name}" من الحضور إلى الغياب؟',
          style: AppTextStyles.customText(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إلغاء",
              style: AppTextStyles.customText(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMain,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await runWithLoading(context, () async {
                try {
                  await context
                      .read<AbsentCubit>()
                      .handleIntent(RestoreStudentToAbsent(student: student));

                  AppSnackBars.showSuccess(
                      context, '✅ تم تسجيل غياب ${student.name} بنجاح!');
                } catch (e) {
                  AppSnackBars.showError(context, '$e');
                }
              });
            },
            child: Text(
              "تأكيد",
              style: AppTextStyles.customText(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogHeader(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryMain,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTextStyles.customText(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
