import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:student_management_system/models/Student_model.dart';

import '../../BottomSheets/more_bottom_sheet_in_absent_page.dart';
import '../../absent_home_screen.dart';
import '../../cards/absence_cards/absent_student_card.dart';
import '../../firebase/firebase_functions.dart';
import '../../loadingFile/loading_alert/run_with_loading.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/absence_app/absence_model.dart';
import '../../theme/colors_app.dart';
import '../../theme/snack_bar.dart';
import '../../theme/text_style.dart';
import 'view_model/cubit.dart';
import 'view_model/intent.dart';
import 'view_model/states.dart';

class AbsentPage extends StatelessWidget {
  final Magmo3amodel magmo3aModel;
  final String selectedDateStr;
  final String selectedDay;

  const AbsentPage({
    Key? key,
    required this.magmo3aModel,
    required this.selectedDateStr,
    required this.selectedDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AbsentCubit(
          magmo3aModel: magmo3aModel,
          selectedDateStr: selectedDateStr,
          selectedDay: selectedDay)
        ..handleIntent(FetchAbsence()),
      child: BlocConsumer<AbsentCubit, AbsentState>(
        listener: (context, state) {
          if (state is AbsentError) {
            // Handles all errors (Firebase, logic, duplicate student)
            AppSnackBars.showError(context, state.error);
          }
          if (state is ScanSuccess) {
            // Handles success messages
            AppSnackBars.showSuccess(
                context, '✅ تم تسجيل حضور ${state.student.name} بنجاح!');
          }
        },
        builder: (context, state) {
          final cubit = context.read<AbsentCubit>();
          final selectedDate = DateTime.parse(cubit.selectedDateStr);
          final today = DateTime.now();
          final afterTomorrow = today.add(const Duration(days: 2));

          if (state is AbsentLoading) {
            return const Scaffold(
                body: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryMain)));
          }

          return Scaffold(
            backgroundColor: const Color(0xffF8F9FE),
            // Light background for contrast
            appBar: _buildPremiumAppBar(
                context, cubit, selectedDate, afterTomorrow),
            body: selectedDate.isAfter(afterTomorrow)
                ? _buildFutureDateWarning()
                : _buildBody(context, cubit, selectedDate, afterTomorrow),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar(BuildContext context,
      AbsentCubit cubit, DateTime selectedDate, DateTime afterTomorrow) {
    return AppBar(
      backgroundColor: AppColors.primaryMain,
      elevation: 0,
      toolbarHeight: 100,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        onPressed: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AbsentHomePage()),
          (route) => false,
        ),
      ),
      centerTitle: true,
      title: Image.asset("assets/images/logo.png", height: 60),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      actions: [
        if (cubit.isAttendanceStarted == true &&
            selectedDate.isBefore(afterTomorrow)) ...[
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  shape: BoxShape.circle),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.white),
            ),
            onPressed: () => cubit.handleIntent(ScanQrIntent(context: context)),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.white),
            onPressed: () => _showMoreSheet(context, cubit),
          ),
        ],
      ],
      bottom: cubit.isAttendanceStarted == true
          ? _buildAppBarSearchAndStats(cubit)
          : null,
    );
  }

  PreferredSizeWidget _buildAppBarSearchAndStats(AbsentCubit cubit) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(130),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: TextFormField(
              controller: cubit.searchController,
              onChanged: (val) => cubit.handleIntent(SearchStudent(query: val)),
              style: AppTextStyles.customText(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                hintText: 'ابحث عن اسم الطالب...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.primaryMain),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.statusAbsent),
                  onPressed: () {
                    cubit.searchController.clear();
                    cubit.handleIntent(SearchStudent(query: ''));
                  },
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(bottom: 15, left: 20, right: 20, top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statChip(
                    "الكل: ${cubit.numberOfStudents}", AppColors.primaryDark),
                _statChip("غياب: ${cubit.absentStudents.length}",
                    AppColors.statusAbsent),
                _statChip("حضور: ${cubit.attendStudents.length}",
                    AppColors.statusPresent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: AppTextStyles.customText(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBody(BuildContext context, AbsentCubit cubit,
      DateTime selectedDate, DateTime afterTomorrow) {
    if (cubit.isAttendanceStarted != true &&
        cubit.attendStudents.isEmpty &&
        selectedDate.isBefore(afterTomorrow)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined,
                size: 100, color: AppColors.primaryMain.withOpacity(0.2)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMain,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                cubit.numberOfStudents = cubit.absentStudents.length;
                await FirebaseFunctions.addAbsenceToSubcollection(
                  cubit.selectedDay,
                  cubit.magmo3aModel.id,
                  AbsenceModel(
                    date: cubit.selectedDateStr,
                    numberOfStudents: cubit.numberOfStudents ?? 0,
                    absentStudentIds:
                        cubit.absentStudents.map((e) => e.id).toList(),
                    attendStudentIds:
                        cubit.attendStudents.map((e) => e.id).toList(),
                  ),
                );
                cubit.handleIntent(StartTakingAttendance());
              },
              child: Text("ابدأ تسجيل الغياب الآن",
                  style: AppTextStyles.customText(
                      color: AppColors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    if (cubit.filteredAbsentStudentsList.isEmpty) {
      return _emptyAbsentState(); // Show empty state
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: cubit.filteredAbsentStudentsList.length,
      itemBuilder: (context, index) {
        final student = cubit.filteredAbsentStudentsList[index];
        return GestureDetector(
          onLongPress: () =>
              _showConfirmAttendanceDialog(context, cubit, student),
          child: AbsentStudentWidget(
            selectedDate: cubit.selectedDay,
            selectedDateStr: cubit.selectedDateStr,
            magmo3aModel: cubit.magmo3aModel,
            studentModel: student,
            grade: cubit.magmo3aModel.grade,
          ),
        );
      },
    );
  }

  void _showConfirmAttendanceDialog(
      BuildContext context, AbsentCubit cubit, Studentmodel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: _dialogHeader(Icons.check_circle_outline, "تحضير الطالب"),
        content: Text(
          "هل تريد تحضير الطالب ${student.name}؟\nسيتم نقله من قائمة الغياب.",
          style: AppTextStyles.customText(fontSize: 15),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("إلغاء",
                  style: AppTextStyles.customText(
                      color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusPresent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await runWithLoading(context, () async {
                await cubit.handleIntent(AddStudentToPresent(
                    student: student, realStudentId: student.id));
              });
            },
            child: Text("تأكيد الحضور",
                style: AppTextStyles.customText(
                    color: AppColors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dialogHeader(IconData icon, String title) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.primaryMain,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.white),
          const SizedBox(width: 10),
          Text(title,
              style: AppTextStyles.customText(
                  color: AppColors.white, fontWeight: FontWeight.bold))
        ]),
      );

  void _showMoreSheet(BuildContext context, AbsentCubit cubit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomBottomSheet(
        cubit: cubit,
        // مرر الـ cubit مباشرة
        absentStudent: cubit.absentStudents,
        attendStudent: cubit.attendStudents,
        date: cubit.selectedDateStr,
        numberOfStudents: cubit.numberOfStudents ?? 0,
        selectedDay: cubit.selectedDay,
        magmo3aModel: cubit.magmo3aModel,
        filteredStudentsList: cubit.filteredAbsentStudentsList,
      ),
    );
  }

  Widget _buildFutureDateWarning() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 80, color: AppColors.statusAbsent),
          const SizedBox(height: 16),
          Text("لا يمكنك تسجيل الحضور لتواريخ مستقبلية.",
              style: AppTextStyles.customText(
                  color: AppColors.statusAbsent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _emptyAbsentState() {
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
            'لا يوجد طلاب غائبون',
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
}
