import 'package:flutter/material.dart';
import '../../theme/text_style.dart';
import '../../models/absence_app/student_absence_model.dart';
import '../../models/absence_app/day_record.dart';
import '../../theme/colors_app.dart';

class MonthDetailsPage extends StatelessWidget {
  final StudentAbsencesModel monthModel;
  final String studentName;

  const MonthDetailsPage({
    Key? key,
    required this.monthModel,
    required this.studentName,
  }) : super(key: key);

  bool _isFuture(String dateStr) {
    try {
      DateTime recordDate = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      return recordDate.isAfter(today);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pastAttended =
        monthModel.attendedDays.where((d) => !_isFuture(d.date)).toList();
    final pastAbsent =
        monthModel.absentDays.where((d) => !_isFuture(d.date)).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FE),
        appBar: AppBar(
          toolbarHeight: 70,
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.white,
              )),
          title: Text(
            monthModel.monthName,
            style: AppTextStyles.customText(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          backgroundColor: AppColors.primaryMain,
          elevation: 0,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          bottom: TabBar(
            // اللون عند الاختيار
            indicatorColor: AppColors.secondaryMain,
            indicatorWeight: 3,
            labelColor: AppColors.secondaryMain,
            // اللون في حالة عدم الاختيار (أبيض)
            unselectedLabelColor: AppColors.white,
            labelStyle: AppTextStyles.customText(
                fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: AppTextStyles.customText(fontSize: 14),
            tabs: const [
              Tab(text: "أيام الحضور"),
              Tab(text: "أيام الغياب"),
            ],
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            // عرض اسم الطالب داخل الـ Scaffold
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      color: AppColors.primaryMain, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "الطالب: $studentName",
                    style: AppTextStyles.customText(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildSummaryCard(pastAttended.length, pastAbsent.length),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildDaysList(pastAttended, isAbsent: false),
                  _buildDaysList(pastAbsent, isAbsent: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysList(List<DayRecord> records, {required bool isAbsent}) {
    if (records.isEmpty) {
      return _buildEmptyState(
          isAbsent ? "لا يوجد أيام غياب سجلت" : "لا يوجد أيام حضور سجلت");
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: records.length,
      itemBuilder: (context, index) {
        return _buildStatusTile(records[index], isAbsent: isAbsent);
      },
    );
  }

  Widget _buildSummaryCard(int attendedCount, int absentCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCircle("حضور", attendedCount, AppColors.statusPresent),
          Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.2)),
          _buildStatCircle("غياب", absentCount, AppColors.statusAbsent),
        ],
      ),
    );
  }

  Widget _buildStatCircle(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: AppTextStyles.customText(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: AppTextStyles.customText(
              fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatusTile(DayRecord record, {required bool isAbsent}) {
    bool isCompensation = !isAbsent && record.secondary != null;
    Color statusColor = isAbsent
        ? AppColors.statusAbsent
        : (isCompensation ? AppColors.statusLate : AppColors.statusPresent);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.15), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAbsent
                ? Icons.close_rounded
                : (isCompensation
                    ? Icons.swap_horiz_rounded
                    : Icons.check_rounded),
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          "${record.day} | ${record.date}",
          style: AppTextStyles.customText(
              fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: isAbsent
              ? Text("تغيب عن موعد مجموعته الأساسي",
                  style: AppTextStyles.customText(
                      fontSize: 13, color: AppColors.textSecondary))
              : isCompensation
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("حضور تعويضي لموعد سابق",
                            style: AppTextStyles.customText(
                                fontSize: 13,
                                color: AppColors.statusLate,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          "الموعد الفائت: ${record.secondary!.day} (${record.secondary!.date}) (${_formatTime(record.secondary!.time)})",
                          style: AppTextStyles.customText(
                              fontSize: 12, color: Colors.grey[600]!),
                        ),
                      ],
                    )
                  : Text("حضر في موعده (${_formatTime(record.time)})",
                      style: AppTextStyles.customText(
                          fontSize: 13, color: AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(message,
              style:
                  AppTextStyles.customText(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'م' : 'ص';
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }
}
