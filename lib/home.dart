import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:student_management_system/absent_home_screen.dart';

import 'Nav_Bar_Tabs/Add_student_tab.dart';
import 'Nav_Bar_Tabs/groups_tab.dart';
import 'pages/drawer.dart';
import 'theme/colors_app.dart';
import 'theme/text_style.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  /// التحكم في صفحات الـ Body
  final _pageController = PageController(initialPage: 0);

  /// التحكم في شريط التنقل السفلي
  final NotchBottomBarController _notchController =
      NotchBottomBarController(index: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// الصفحات الموجودة في التنقل
  final List<Widget> _bodyTabs = [
    const GroupsTab(),
    const AddStudentTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final _advancedDrawerController = AdvancedDrawerController();

    return AdvancedDrawer(
      backdrop: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondaryMain,
              AppColors.primaryDark,
            ],
          ),
        ),
      ),
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      disabledGestures: false,
      // فعلت الإيماءات لتجربة مستخدم أفضل
      childDecoration: BoxDecoration(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
          ),
        ],
        borderRadius: const BorderRadius.all(Radius.circular(25)),
      ),
      drawer: const CustomDrawer(),
      child: Scaffold(
        extendBody: true, // مهم جداً لجعل الـ Navbar يبدو طافياً
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: AppColors.primaryMain,
          elevation: 0,
          title: Image.asset(
            "assets/images/logo.png",
            height: 80, // قللت الارتفاع قليلاً ليتناسب مع التصميم المودرن
          ),
          toolbarHeight: 110,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AbsentHomePage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.secondaryMain),
            )
          ],
          leading: IconButton(
            onPressed: () => _advancedDrawerController.showDrawer(),
            icon: ValueListenableBuilder<AdvancedDrawerValue>(
              valueListenable: _advancedDrawerController,
              builder: (_, value, __) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    value.visible ? Icons.clear : Icons.clear_all_outlined,
                    color: AppColors.secondaryMain,
                    size: 30,
                    key: ValueKey<bool>(value.visible),
                  ),
                );
              },
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(bottom: 25),
          child: PageView(
            padEnds: true,

            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            // نعتمد على الـ Tap فقط
            children: _bodyTabs,
          ),
        ),
        bottomNavigationBar: AnimatedNotchBottomBar(
          notchBottomBarController: _notchController,
          color: AppColors.primaryMain,
          showLabel: true,
          notchColor: AppColors.secondaryMain,
          removeMargins: false,
          bottomBarWidth: MediaQuery.of(context).size.width,
          durationInMilliSeconds: 300,
          itemLabelStyle: AppTextStyles.customText(
            fontSize: 10,
            color: Colors.white,
          ),
          bottomBarItems: const [
            BottomBarItem(
              inActiveItem: Icon(Icons.home_filled, color: Colors.white70),
              activeItem: Icon(Icons.home_filled, color: Colors.white70),
              itemLabel: 'الرئيسية',
            ),
            BottomBarItem(
              inActiveItem:
                  Icon(Icons.person_add_alt_1_rounded, color: Colors.white70),
              activeItem:
                  Icon(Icons.person_add_alt_1_rounded, color: Colors.white70),
              itemLabel: 'إضافة طالب',
            ),
          ],
          onTap: (index) {
            _pageController.jumpToPage(index);
            (
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          },
          kIconSize: 24.0,
          kBottomRadius: 25.0,
        ),
      ),
    );
  }
}