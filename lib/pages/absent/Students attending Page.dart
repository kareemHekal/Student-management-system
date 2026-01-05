import 'package:flutter/material.dart';
import 'package:student_management_system/cards/absence_cards/absent_student_model.dart';

import '../../firebase/firebase_functions.dart';
import '../../loadingFile/loading_alert/run_with_loading.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/Student_model.dart';
import '../../models/absence_app/absence_model.dart';
import '../../models/absence_app/day_record.dart';
import '../../theme/colors_app.dart';
import '../../theme/snack_bar.dart';
import '../../theme/text_style.dart';
import 'AbssentPage.dart';

class StudentsAttending extends StatefulWidget {
  final AbsenceModel absenceModel;
  final String selectedDay;
  final Magmo3amodel magmo3aModel;

  const StudentsAttending({
    required this.absenceModel,
    required this.magmo3aModel,
    required this.selectedDay,
    super.key,
  });

  @override
  _StudentsAttendingState createState() => _StudentsAttendingState();
}

class _StudentsAttendingState extends State<StudentsAttending> {
  late List<Studentmodel> filteredStudents;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredStudents = widget.absenceModel.attendStudents;
  }

  void _filterStudents(String query) {
    setState(() {
      filteredStudents = widget.absenceModel.attendStudents
          .where((student) =>
              student.name!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FE),
      appBar: _buildPremiumAppBar(),
      body: Stack(
        children: [
          // Background Watermark
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset("assets/images/logo.png", width: 250),
            ),
          ),
          _buildContent(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryMain,
      elevation: 0,
      toolbarHeight: 90,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        onPressed: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => AbsentPage(
              selectedDay: widget.selectedDay,
              magmo3aModel: widget.magmo3aModel,
              selectedDateStr: widget.absenceModel.date,
            ),
          ),
          (route) => false,
        ),
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
                controller: _searchController,
                onChanged: _filterStudents,
                style: AppTextStyles.customText(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.white,
                  hintText: 'ابحث في قائمة الحاضرين...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.secondaryMain),
                  suffixIcon: IconButton(
                    icon:
                        const Icon(Icons.clear, color: AppColors.statusAbsent),
                    onPressed: () {
                      _searchController.clear();
                      _filterStudents('');
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
                      color: AppColors.secondaryMain.withOpacity(0.5)),
                ),
                child: Text(
                  'إجمالي الحضور: ${filteredStudents.length}',
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

  Widget _buildContent() {
    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded,
                size: 80, color: AppColors.primaryMain.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              'لا يوجد طلاب حاضرون حالياً',
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

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return Card(
          elevation: 0,
          color: Colors.transparent,
          child: GestureDetector(
            onLongPress: () => _showRestoreDialog(student),
            // Reusing the same Student Widget for consistency
            child: AbsentStudentWidget(
              grade: student.grade,
              magmo3aModel: widget.magmo3aModel,
              selectedDateStr: widget.absenceModel.date,
              selectedDate: widget.selectedDay,
              studentModel: student,
            ),
          ),
        );
      },
    );
  }

  void _showRestoreDialog(Studentmodel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: _buildDialogHeader(
            Icons.settings_backup_restore_rounded, "استرجاع الطالب"),
        content: Text(
          'هل أنت متأكد أنك تريد تحويل "${student.name}" من قائمة الحضور إلى قائمة الغياب؟',
          style: AppTextStyles.customText(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء",
                style:
                    AppTextStyles.customText(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMain,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _handleRestore(student),
            child: Text(
              "تأكيد الاسترجاع",
              style: AppTextStyles.customText(
                  color: AppColors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogHeader(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryMain,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white),
          const SizedBox(width: 12),
          Text(title,
              style: AppTextStyles.customText(
                  color: AppColors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _handleRestore(Studentmodel student) async {
    Navigator.pop(context); // Close dialog
    runWithLoading(context, () async {
      try {
        // 1. Logic updates
        widget.absenceModel.absentStudents.add(student);
        widget.absenceModel.attendStudents
            .removeWhere((s) => s.id == student.id);

        student.countingAbsentDays ??= [];
        student.countingAbsentDays!.add(
            DayRecord(date: widget.absenceModel.date, day: widget.selectedDay));

        student.countingAttendedDays?.removeWhere(
          (dr) =>
              dr.date == widget.absenceModel.date &&
              dr.day == widget.selectedDay,
        );

        // 2. Firebase updates
        await FirebaseFunctions.updateStudentInCollection(
            widget.magmo3aModel.grade ?? "", student.id, student);
        await FirebaseFunctions.updateAbsenceByDateInSubcollection(
          widget.selectedDay,
          widget.magmo3aModel.id,
          widget.absenceModel.date,
          widget.absenceModel,
        );

        // 3. UI Update
        _filterStudents(_searchController.text);
        AppSnackBars.showSuccess(
            context, 'تم نقل ${student.name} للغياب بنجاح');
      } catch (e) {
        AppSnackBars.showError(context, 'حدث خطأ: $e');
      }
    });
  }
}
