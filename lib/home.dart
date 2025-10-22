import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import 'Nav_Bar_Tabs/Add_student_tab.dart';
import 'Nav_Bar_Tabs/students_tab.dart';
import 'colors_app.dart';
import 'pages/drawertate<Homescreen> {
  int _currant_index = 0;
  final List<Widget> _bodytabs = [
    const GroupsTab(),
    const AddStudentTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: CustomDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: app_colors.darkGrey,
        title: Image.asset(
          "assets/images/2....2.png",
          height: 100,
          width: 90,
        ),
        toolbarHeight: 120,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              "assets/images/app.png", // Your icon image path
              height: 30, // Adjust the height as needed
              width: 30, // Adjust the width as needed
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Open the drawer
            },
          ),
        ),
      ),
      body: _bodytabs[_currant_index],
      bottomNavigationBar: CurvedNavigationBar(
        animationCurve: Curves.linear,
        height: 65,

        onTap: (index) {
          setState(() {
            _currant_index = index;
          });
        },
        backgroundColor: Colors.transparent,
        color: app_colors.darkGrey,
        animationDuration: const Duration(seconds: 1),
        items: [
          Icon(Icons.home,
              color: _currant_index == 0 ? app_colors.green : Colors.white),
          Icon(Icons.add,
              color: _currant_index == 1 ? app_colors.green : Colors.white),
        ],
      ),
    );
  }
}
