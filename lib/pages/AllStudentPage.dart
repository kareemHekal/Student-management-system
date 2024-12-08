

import 'package:flutter/material.dart';


import '../Appbar_TAbs/All 1 S.dart';
import '../Appbar_TAbs/All 2 S.dart';
import '../Appbar_TAbs/All 3 S.dart';
import '../colors_app.dart';



class AllStudentsTab extends StatelessWidget {
  const AllStudentsTab({super.key});

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
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/HomeScreen',(route)=>false);
                },
                icon: const Icon(Icons.arrow_back_ios, color: app_colors.orange),
              ),
              backgroundColor: app_colors.green,
              title: Image.asset(
                "assets/images/2....2.png",
                height: 100,
                width: 90,
              ),
              toolbarHeight: 120,
            ),
            body: Column(
              children: [
                Container(
                  color: app_colors.green,
                  child:  const TabBar(
                    isScrollable: false,
                    labelColor: app_colors.orange,
                    indicatorColor: app_colors.orange,
                    indicatorWeight: 5,
                    indicatorSize:TabBarIndicatorSize.tab,
                    unselectedLabelColor: Colors.white,
                    tabs:[
                      Tab(
                        child: Text(" 1S"),
                      ),
                      Tab(
                        child: Text(" 2S"),
                      ),
                      Tab(
                        child: Text(" 3S"),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: TabBarView(children: [
                    FirstS(),
                    SecondS(),
                    ThirdS(),
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