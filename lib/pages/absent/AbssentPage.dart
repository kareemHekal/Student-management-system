import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:student_management_system/alert_dialogs/attendance_selection_dialog.dart';
import 'package:student_management_system/models/Student_model.dart';

import '../../BottomSheets/more_bottom_sheet_in_absent_page.dart';
import '../../absent_home_screen.dart';
import '../../cards/absence_cards/absent_student_card.dart';
import '../../loadingFile/loading_alert/run_with_loading.dart';
import '../../models/Magmo3aModel.dart';
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
        selectedDay: selectedDay,
      ),
      child: BlocConsumer<AbsentCubit, AbsentState>(
        listener: (context, state) {
          if (state is AbsentError) {
            AppSnackBars.showError(context, state.error);
          }
          if (state is ScanSuccess) {
            AppSnackBars.showSuccess(
                context, '✅ تم تسجيل حضور ${state.student.name} بنجاح!');
          }
        },
        builder: (context, state) {
          final cubit = context.read<AbsentCubit>();

          // --- التحميل الأولي (Overlay Loading) ---
          if (state is AbsentInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              runWithLoading(context, () async {
                await cubit.handleIntent(FetchAbsence());
              });
            });
          }

          final selectedDate = DateTime.parse(cubit.selectedDateStr);
          final today = DateTime.now();
          final afterTomorrow = today.add(const Duration(days: 3));

          return Scaffold(
            backgroundColor: const Color(0xffF8F9FE),
            appBar: _buildPremiumAppBar(
                context, cubit, selectedDate, afterTomorrow),
            // ✅ تم ربط الـ body بفلتر التحميل الأول
            body: selectedDate.isAfter(afterTomorrow)
                ? _buildFutureDateWarning()
                : _buildBody(context, cubit, selectedDate, afterTomorrow),
          );
        },
      ),
    );
  }

  // ... (App Bar & Stats Chip functions remain the same) ...
  PreferredSizeWidget _buildPremiumAppBar(BuildContext context,
      AbsentCubit cubit, DateTime selectedDate, DateTime afterTomorrow) {
    return AppBar(
      backgroundColor: AppColors.primaryMain,
      elevation: 0,
      toolbarHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        onPressed: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AbsentHomePage()),
          (route) => false,
        ),
      ),
      centerTitle: true,
      title: Image.asset("assets/images/logo.png", height: 50),
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
                _statChip("المجموعة: ${cubit.numberOfStudents}",
                    AppColors.primaryDark),
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
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  // ------------------- BODY -------------------
  Widget _buildBody(BuildContext context, AbsentCubit cubit,
      DateTime selectedDate, DateTime afterTomorrow) {
    // ✅ 1. إذا لم ينتهِ التحميل الأول بعد، لا تظهر شيئاً (الـ Loading Overlay شغال)
    if (!cubit.isFirstLoadDone) {
      return _buildShimmerLoading();
    }

    // ✅ 2. بعد انتهاء التحميل، نختبر هل نُظهر زر "البدء"؟
    if (cubit.isAttendanceStarted != true &&
        cubit.attendStudents.isEmpty &&
        selectedDate.isBefore(afterTomorrow)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined,
                size: 100, color: AppColors.primaryMain.withOpacity(0.1)),
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
                await runWithLoading(context, () async {
                  await cubit.handleIntent(StartTakingAttendance());
                });
              },
              child: Text("ابدأ تسجيل الغياب الآن",
                  style: AppTextStyles.customText(
                      color: AppColors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // ✅ 3. إذا كان التحميل تم والغياب بدأ، نُظهر القائمة أو الحالة الفارغة
    if (cubit.filteredAbsentStudentsList.isEmpty) {
      return _emptyAbsentState();
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

  // ... (بقية الـ Dialogs والـ States تظل كما هي) ...
  void _showConfirmAttendanceDialog(
      BuildContext context, AbsentCubit cubit, Studentmodel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: _dialogHeader(Icons.check_circle_outline, "تحضير الطالب"),
        content: Text("هل تريد تحضير الطالب ${student.name}؟",
            style: AppTextStyles.customText(fontSize: 15)),
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
              // ملاحظة: Navigator.pop(context) هنا قد تغلق الصفحة نفسها لو لم يكن هناك شيء قبلها
              // Navigator.pop(context);

              final rootContext = context;

              await showDialog(
                // أضف await هنا
                context: context,
                builder: (dialogContext) {
                  return AttendanceSelectionDialog(
                    studentGrade: student.grade ?? "",
                    studentCurrentGroups: student.hisGroups ?? [],
                    studentName: student.name ?? "",
                    currentDate: selectedDateStr,
                    onConfirm: (selectedMagmo3a) async {
                      Future.microtask(() async {
                        if (!rootContext.mounted) return;
                        await runWithLoading(rootContext, () async {
                          await cubit.handleIntent(AddStudentToPresent(
                            student: student,
                            secondaryRecord: selectedMagmo3a,
                          ));
                          Navigator.pop(context);
                        });
                      });
                    },
                  );
                },
              );
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
          Icon(Icons.people_outline_rounded,
              size: 80, color: AppColors.primaryMain.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('لا يوجد طلاب غائبون',
              style: AppTextStyles.customText(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.primaryMain.withOpacity(0.2),
          highlightColor: AppColors.secondaryMain.withOpacity(0.4),
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(12),
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.primaryMain.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 5),
                // 1. مكان الأيقونة الدائرية
                Container(
                  width: 55,
                  height: 55,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 15),

                // 2. محاكاة النصوص
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // مستطيل الاسم
                      Container(
                        width: 180,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // مستطيل الكود
                      Container(
                        width: 100,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. شكل جانبي صغير مكان حالة الحضور
                Container(
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 5),
              ],
            ),
          ),
        );
      },
    );
  }
}
