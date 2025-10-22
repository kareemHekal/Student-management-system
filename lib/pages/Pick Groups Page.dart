import 'package:flutter/material.dart';

import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../loadingFile/loadingWidget.dart';
import '../cards/magmo3afor display widget.dart';
import '../models/Magmo3aModel.dart';

class ChoosedaysToAttend extends StatefulWidget {
  final String? level;
  ChoosedaysToAttend({this.level, super.key});

  @override
  _SeconddayState createState() => _SeconddayState();
}

class _SeconddayState extends State<ChoosedaysToAttend> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with two tabs
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    // Dispose the controller to free up resources
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: app_colors.green),
        ),
        backgroundColor: app_colors.darkGrey,
        title: Image.asset(
          "assets/images/2....2.png",
          height: 100,
          width: 90,
        ),
        toolbarHeight: 120,
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          controller: _tabController,
          tabs:const [
            Tab(text: "Saturday"),
            Tab(text: "Sunday"),
            Tab(text: "Monday"),
            Tab(text: "Tuesday"),
            Tab(text: "Wednesday"),
            Tab(text: "Thursday"),
            Tab(text: "Friday"),

          ],
          indicatorColor: app_colors.green,
          labelColor: app_colors.green,
          unselectedLabelColor: app_colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupList("Saturday"), // Stream for Saturday
          _buildGroupList("Sunday"),   // Stream for Sunday
          _buildGroupList("Monday"),   // Stream for Monday
          _buildGroupList("Tuesday"),  // Stream for Tuesday
          _buildGroupList("Wednesday"),// Stream for Wednesday
          _buildGroupList("Thursday"), // Stream for Thursday
          _buildGroupList("Friday"),   // Stream for Friday
          // Stream for Tuesday
        ],
      ),
    );
  }

  Widget _buildGroupList(String day) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Center(child: Image.asset("assets/images/1......1.png")),
        ),
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  "اختر المجموعة فقط",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: app_colors.darkGrey, fontSize: 30),
                ),
                const SizedBox(height: 20),
                StreamBuilder<List<Magmo3amodel>>(
                  stream: FirebaseFunctions.getAllDocsFromDayWithGrade(day, widget.level ?? ""),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: DiscreteCircle(
                          color: app_colors.darkGrey,
                          size: 30,
                          secondCircleColor: app_colors.ligthGreen,
                          thirdCircleColor: app_colors.green,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          children: [
                            const Text("حدث خطأ ما"),
                            ElevatedButton(
                              onPressed: () {
                                // يمكنك تنفيذ منطق إعادة المحاولة هنا
                              },
                              child: const Text('أعد المحاولة'),
                            ),
                          ],
                        ),
                      );
                    }

                    var Magmo3as = snapshot.data ?? [];

                    if (Magmo3as.isEmpty) {
                      return Center(
                        child: Text(
                          "لا توجد مجموعات",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 25, color: app_colors.black),
                        ),
                      );
                    }

                    return Expanded(
                      child: ListView.separated(
                        separatorBuilder: (context, index) => const SizedBox(
                          height: 12,
                        ),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context, Magmo3as[index]);
                            },
                            child: Magmo3aWidgetWithoutSlidable(
                              magmo3aModel: Magmo3as[index],
                            ),
                          );
                        },
                        itemCount: Magmo3as.length,
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
