import 'package:flutter/material.dart';

import 'BottomSheets/add_magmo3a.dart';
import 'models/Magmo3aModel.dart';
import 'cards/Magmo3aWidget.dart';
import 'colors_app.dart';
import 'firebase/firebase_functions.dart';
import 'loadingFile/loadingWidget.dart';

class Magmo3as extends StatelessWidget {
  String day;

  Magmo3as({required this.day, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // the add icon
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                    color: app_colors.darkGrey,
                    borderRadius: BorderRadius.circular(30)),
                child: IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom),
                              child: AddMagmo3a(),
                            ));
                  },
                  icon: Icon(Icons.add),
                  color: app_colors.green,
                  iconSize: 30,
                ),
              ),
            )
          ],
        ),
        StreamBuilder<List<Magmo3amodel>>(
          stream: FirebaseFunctions.getAllDocsFromDay(day),
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

            // ✅ Sort by time (earlier first)
            magmo3as.sort((a, b) {
              if (a.time == null && b.time == null) return 0;
              if (a.time == null) return 1; // put nulls at the end
              if (b.time == null) return -1;
              final aMinutes = a.time!.hour * 60 + a.time!.minute;
              final bMinutes = b.time!.hour * 60 + b.time!.minute;
              return aMinutes.compareTo(bMinutes);
            });

            if (magmo3as.isEmpty) {
              return Center(
                child: Text(
                  "لا توجد مجموعات",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 25,
                    color: app_colors.black,
                  ),
                ),
              );
            }

            return Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    );
  }
}
