import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:student_management_system/absent_home_screen.dart';

import 'Nav_Bar_Tabs/Add_student_tab.dart';
import 'Nav_Bar_Tabs/groups_tab.dart';
import 'pages/drawer.dart';
import 'theme/colors_app.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _currant_index = 0;
  final List<Widget> _bodytabs = [
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
            begin: Alignment.bottomLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryMain, // فوق شمال
              AppColors.secondaryMain, // تحت يمين
            ],
          ),
        ),
      ),
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      disabledGestures: true,
      childDecoration: const BoxDecoration(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      drawer: CustomDrawer(),
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: AppColors.primaryMain,
          title: Image.asset(
            "assets/images/logo.png",
            height: 100,
            width: 90,
          ),
          toolbarHeight: 120,
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AbsentHomePage(),
                    ),
                    (route) => false,
                  );
                },
                icon: Icon(Icons.qr_code_outlined,
                    color: AppColors.secondaryMain))
          ],
          leading: IconButton(
            onPressed: () {
              _advancedDrawerController.showDrawer();
            },
            icon: ValueListenableBuilder<AdvancedDrawerValue>(
              valueListenable: _advancedDrawerController,
              builder: (_, value, __) {
                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: Semantics(
                    child: Icon(
                      color: AppColors.secondaryMain,
                      size: 30,
                      value.visible ? Icons.clear : Icons.clear_all_outlined,
                      key: ValueKey<bool>(value.visible),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        body: _bodytabs[_currant_index],
        bottomNavigationBar: CurvedNavigationBar(
          animationCurve: Curves.linear,
          height: 60,
          onTap: (index) {
            setState(() {
              _currant_index = index;
            });
          },
          backgroundColor: Colors.transparent,
          color: AppColors.primaryMain,
          animationDuration: const Duration(seconds: 1),
          items: [
            Icon(Icons.home,
                color: _currant_index == 0
                    ? AppColors.secondaryMain
                    : Colors.white),
            Icon(Icons.add,
                color: _currant_index == 1
                    ? AppColors.secondaryMain
                    : Colors.white),
          ],
        ),
      ),
    );
  }
}
