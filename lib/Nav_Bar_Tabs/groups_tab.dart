import 'package:flutter/material.dart';

import '../Appbar_TAbs/days of home page/Friday.dart';
import '../Appbar_TAbs/days of home page/Monday.dart';
import '../Appbar_TAbs/days of home page/Saturday.dart';
import '../Appbar_TAbs/days of home page/Sunday.dart';
import '../Appbar_TAbs/days of home page/Thursday.dart';
import '../Appbar_TAbs/days of home page/Tuesday.dart';
import '../Appbar_TAbs/days of home page/Wednesday.dart';
import '../BottomSheets/add_magmo3a.dart';
import '../theme/colors_app.dart';
import '../theme/text_style.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  double buttonRight = 20;
  double buttonBottom = 80;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// الخلفية + التابات
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Center(child: Image.asset("assets/images/logo.png")),
        ),

        DefaultTabController(
          length: 7,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                Container(
                  color: AppColors.primaryMain,
                  child: TabBar(
                    labelColor: AppColors.secondaryMain,
                    indicatorColor: AppColors.secondaryMain,
                    indicatorWeight: 5,
                    dividerHeight: 2,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.tab,
                    unselectedLabelColor: Colors.white,
                    physics: NeverScrollableScrollPhysics(),
                    tabs: [
                      Tab(
                          child: Text("السبت",
                              style: AppTextStyles.customText(
                                  fontSize: 12,
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.bold))),
                      Tab(
                          child: Text("الأحد",
                              style: AppTextStyles.customText(
                                  fontSize: 12,
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.bold))),
                      Tab(
                          child: Text("الإثنين",
                              style: AppTextStyles.customText(
                                  fontSize: 12,
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.bold))),
                      Tab(
                          child: Text("الثلاثاء",
                              style: AppTextStyles.customText(
                                  fontSize: 12,
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.bold))),
                      Tab(
                          child: Text("الأربعاء",
                              style: AppTextStyles.customText(
                                  fontSize: 12,
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.bold))),
                      Tab(
                          child: Text("الخميس",
                              style: AppTextStyles.customText(
                                  fontSize: 12,
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.bold))),
                      Tab(
                          child: Text("الجمعة",
                              style: AppTextStyles.customText(
                                  fontSize: 12,
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      Saturday(),
                      Sunday(),
                      Monday(),
                      Tuesday(),
                      Wednesday(),
                      Thursday(),
                      Friday(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        /// ================================
        /// 🔥 الزرار المتحرك Draggable Button
        /// ================================
        Positioned(
          right: buttonRight,
          bottom: buttonBottom,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                buttonRight -= details.delta.dx; // ناقص عشان يتحرك صح
                buttonBottom -= details.delta.dy;

                final screen = MediaQuery.of(context).size;
                buttonRight = buttonRight.clamp(10, screen.width - 75);
                buttonBottom = buttonBottom.clamp(100, screen.height - 250);
              });
            },
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryMain,
                    AppColors.secondaryMain.withOpacity(0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: Colors.black.withOpacity(0.2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white, size: 30),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: AddMagmo3a(),
                    ),
                  );
                },
              ),
            ),
          ),
        )
      ],
    );
  }
}
