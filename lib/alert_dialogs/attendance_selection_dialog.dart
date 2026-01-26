import 'package:flutter/material.dart';
import 'package:student_management_system/cards/magmo3at/magmo3a_for_display_widget.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/models/Magmo3aModel.dart';
import 'package:student_management_system/models/absence_app/secondary_record.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';

class AttendanceSelectionDialog extends StatefulWidget {
  final List<Magmo3amodel> studentCurrentGroups;
  final String studentName;
  final String studentGrade;
  final String currentDate;
  final bool startWithSelectionPage;
  final Function(SecondaryRecord? record) onConfirm;

  const AttendanceSelectionDialog({
    super.key,
    required this.studentCurrentGroups,
    required this.studentName,
    required this.studentGrade,
    required this.currentDate,
    required this.onConfirm,
    this.startWithSelectionPage = false,
  });

  @override
  State<AttendanceSelectionDialog> createState() =>
      _AttendanceSelectionDialogState();
}

class _AttendanceSelectionDialogState extends State<AttendanceSelectionDialog>
    with SingleTickerProviderStateMixin {
  late int _currentPage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.startWithSelectionPage ? 1 : 0;
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _calculateNearestDate(String targetDayName) {
    final currentBaseDate = DateTime.parse(widget.currentDate);
    final daysOfWeek = {
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
    };
    int targetDay =
        daysOfWeek[targetDayName.toLowerCase()] ?? currentBaseDate.weekday;
    int diff = targetDay - currentBaseDate.weekday;
    if (diff > 3)
      diff -= 7;
    else if (diff < -3) diff += 7;
    DateTime nearestDate = currentBaseDate.add(Duration(days: diff));
    return "${nearestDate.year}-${nearestDate.month.toString().padLeft(2, '0')}-${nearestDate.day.toString().padLeft(2, '0')}";
  }

  void _handleSelection(Magmo3amodel? model) {
    SecondaryRecord? record;
    if (model != null) {
      String finalDate = _calculateNearestDate(model.day ?? "Saturday");
      record = SecondaryRecord(
          magmo3aId: model.id,
          date: finalDate,
          day: model.day ?? "",
          time: model.time);
    }
    widget.onConfirm(record);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: _currentPage == 0 ? 350 : 650,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
                child: _currentPage == 0
                    ? _buildMainPage()
                    : _buildAllGroupsTabs()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryMain,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Text("تسجيل حضور",
              style: AppTextStyles.customText(
                  fontSize: 18,
                  color: AppColors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.studentName,
              style: AppTextStyles.customText(
                  fontSize: 15,
                  color: AppColors.secondaryMain,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMainPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          _buildOptionTile("تحضير هنا", "المجموعة الحالية", Icons.location_on,
              AppColors.secondaryMain, () => _handleSelection(null)),
          const SizedBox(width: 15),
          _buildOptionTile("تغيير", "مجموعة بديلة", Icons.swap_horiz,
              AppColors.primaryMain, () => setState(() => _currentPage = 1)),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
      String t, String s, IconData i, Color c, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.3)),
          ),
          child: Column(children: [
            Icon(i, color: c, size: 40),
            const SizedBox(height: 10),
            Text(t,
                style: AppTextStyles.customText(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text(s,
                style: AppTextStyles.customText(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildAllGroupsTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.secondaryMain,
          labelColor: AppColors.primaryMain,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.customText(
              fontSize: 14, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "سبت"),
            Tab(text: "أحد"),
            Tab(text: "اثنين"),
            Tab(text: "ثلاثاء"),
            Tab(text: "أربعاء"),
            Tab(text: "خميس"),
            Tab(text: "جمعة")
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              "Saturday",
              "Sunday",
              "Monday",
              "Tuesday",
              "Wednesday",
              "Thursday",
              "Friday"
            ].map((day) => _buildStreamedList(day)).toList(),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _currentPage = 0),
          child: Text("رجوع",
              style: AppTextStyles.customText(
                  color: AppColors.primaryMain, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildStreamedList(String day) {
    return StreamBuilder<List<Magmo3amodel>>(
      stream: FirebaseFunctions.getAllDocsFromDayWithGrade(
          day, widget.studentGrade),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.secondaryMain,
            ),
          );
        }
        var allGroups = snapshot.data ?? [];
        var filteredGroups = allGroups
            .where(
                (g) => !widget.studentCurrentGroups.any((sg) => sg.id == g.id))
            .toList();
        if (filteredGroups.isEmpty)
          return Center(
              child: Text("لا توجد مجموعات بديلة",
                  style: AppTextStyles.customText(
                      color: AppColors.textSecondary)));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filteredGroups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => InkWell(
            onTap: () => _handleSelection(filteredGroups[index]),
            child: Magmo3aWidgetWithoutSlidable(
                magmo3aModel: filteredGroups[index]),
          ),
        );
      },
    );
  }
}
