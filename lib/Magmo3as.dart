import 'package:flutter/material.dart';

import 'cards/magmo3at/Magmo3aWidget.dart';
import 'firebase/firebase_functions.dart';
import 'loadingFile/loadingWidget.dart';
import 'models/Magmo3aModel.dart';
import 'theme/colors_app.dart';

class Magmo3as extends StatefulWidget {
  String day;

  Magmo3as({required this.day, super.key});

  @override
  State<Magmo3as> createState() => _Magmo3asState();
}

class _Magmo3asState extends State<Magmo3as> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              StreamBuilder<List<Magmo3amodel>>(
                stream: FirebaseFunctions.getAllDocsFromDay(widget.day),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: DiscreteCircle(
                        color: AppColors.primaryMain,
                        size: 30,
                        secondCircleColor: AppColors.secondaryMain,
                        thirdCircleColor: AppColors.secondaryMain,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        children: [
                          const Text("حدث شئ خطأ"),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('حاول مره اخري'),
                          ),
                        ],
                      ),
                    );
                  }

                  var magmo3as = snapshot.data ?? [];

                  // sort by time
                  magmo3as.sort((a, b) {
                    if (a.time == null && b.time == null) return 0;
                    if (a.time == null) return 1;
                    if (b.time == null) return -1;
                    final aMinutes = a.time!.hour * 60 + a.time!.minute;
                    final bMinutes = b.time!.hour * 60 + b.time!.minute;
                    return aMinutes.compareTo(bMinutes);
                  });

                  if (magmo3as.isEmpty) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          "لا توجد مجموعات",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 25,
                                    color: AppColors.black,
                                  ),
                        ),
                      ),
                    );
                  }

                  return Expanded(
                    child: ListView.separated(
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return Magmo3aWidget(
                          magmo3aModel: magmo3as[index],
                        );
                      },
                      itemCount: magmo3as.length,
                    ),
                  );
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
