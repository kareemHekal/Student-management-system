import 'package:flutter/material.dart';
import '../Appbar_TAbs/1s to Add Student.dart';
import '../Appbar_TAbs/2s to Add Student.dart';
import '../Appbar_TAbs/3s to Add Students.dart';
import '../colors_app.dart';

class AddStudentTab extends StatefulWidget {
  const AddStudentTab({super.key});

  @override
  State<AddStudentTab> createState() => _AddStudentTabState();
}

class _AddStudentTabState extends State<AddStudentTab> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Center(child: Image.asset("assets/images/1......1.png")),
        ),
        const SizedBox(height: 50),
        DefaultTabController(
          length: 3,
          child: Scaffold(
            body: Column(
              children: [
                Container(
                  color: app_colors.green,
                  child:  const TabBar(
                    labelColor: app_colors.orange,
                    indicatorColor: app_colors.orange,
                    indicatorWeight: 5,
                    indicatorSize:TabBarIndicatorSize.tab,
                    unselectedLabelColor: Colors.white,
                    tabs:[
                      Tab(
                        child: Text(" 1 S"),
                      ),
                      Tab(
                        child: Text(" 2 S"),
                      ),
                      Tab(
                        child: Text(" 3 S"),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: TabBarView(children: [
                    one(),
                    two(),
                    three(),
                  ]),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}