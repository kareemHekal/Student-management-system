import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_management_system/home.dart';

import '../../firebase/firebase_functions.dart';
import '../../models/Magmo3aModel.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart';
import 'cards/magmo3at/absence_group_card.dart'; // Ensure this uses your premium style

class AbsentHomePage extends StatefulWidget {
  const AbsentHomePage({super.key});

  @override
  State<AbsentHomePage> createState() => _AbsentHomePageState();
}

class _AbsentHomePageState extends State<AbsentHomePage> {
  DateTime _date = DateTime.now();
  String _selectedDay = '';
  String _selectedDateStr = '';

  @override
  void initState() {
    super.initState();
    // Initialize with correct day name and date string
    _updateDateDetails(DateTime.now());
  }

  void _updateDateDetails(DateTime date) {
    _selectedDay = DateFormat('EEEE').format(date);
    _selectedDateStr = DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FE), // Consistent light background
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
          Column(
            children: [
              const SizedBox(height: 10),
              _buildModernTimeline(),
              const SizedBox(height: 20),
              Expanded(child: _buildGroupsList()),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      leading: IconButton(
          onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const Homescreen()),
              (route) => false),
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.secondaryMain)),
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: AppColors.primaryMain,
      elevation: 0,
      toolbarHeight: 120,
      title: Image.asset(
        "assets/images/logo.png",
        height: 70,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(35),
        ),
      ),
    );
  }

  Widget _buildModernTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: EasyDateTimeLine(
        initialDate: _date,
        onDateChange: (selectedDate) {
          setState(() {
            _date = selectedDate;
            _updateDateDetails(selectedDate);
          });
        },
        headerProps: EasyHeaderProps(
            monthPickerType: MonthPickerType.dropDown,
            dateFormatter: DateFormatter.fullDateDayAsStrMY()),
        dayProps: EasyDayProps(
          dayStructure: DayStructure.dayStrDayNum,
          activeDayStyle: DayStyle(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.primaryMain, AppColors.secondaryMain],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          inactiveDayStyle: DayStyle(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
          ),
          todayStyle: DayStyle(
            decoration: BoxDecoration(
              color: AppColors.secondaryMain.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondaryMain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList() {
    return StreamBuilder<List<Magmo3amodel>>(
      stream: FirebaseFunctions.getAllDocsFromDay(_selectedDay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryMain),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        var magmo3as = snapshot.data ?? [];

        if (magmo3as.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          separatorBuilder: (context, index) => const SizedBox(height: 5),
          itemCount: magmo3as.length,
          itemBuilder: (context, index) {
            return AbsenceGroupCard(
              selectedDay: _selectedDay,
              magmo3aModel: magmo3as[index],
              selectedDateStr: _selectedDateStr,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 80, color: AppColors.primaryMain.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "لا توجد مجموعات في هذا اليوم",
            style: AppTextStyles.customText(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.statusAbsent, size: 50),
          const SizedBox(height: 10),
          Text("حدث خطأ ما", style: AppTextStyles.customText()),
          TextButton(
            onPressed: () => setState(() {}),
            child: Text("إعادة المحاولة",
                style: AppTextStyles.customText(color: AppColors.primaryMain)),
          )
        ],
      ),
    );
  }
}
