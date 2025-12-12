import 'package:flutter/material.dart';

import '../models/Magmo3aModel.dart';
import '../theme/colors_app.dart';

class Groupsmallcard extends StatelessWidget {
  final Magmo3amodel? magmo3aModel;
  const Groupsmallcard({super.key, required this.magmo3aModel});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          color: AppColors.secondaryMain,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: 150,
                      child: Column(
                        children: [
                          _buildDaysList(),
                          const SizedBox(height: 10),
                          _buildGradeAndTimeAndType(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysList() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryMain,
                border: Border.all(
                  color: AppColors.secondaryMain,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Text(
                magmo3aModel?.days ?? "",
                style: const TextStyle(
                  fontSize: 22,
                  color: AppColors.secondaryMain,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGradeAndTimeAndType() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RichText(
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "الصف: ",
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.primaryMain,
                      ),
                    ),
                    TextSpan(
                      text: magmo3aModel?.grade ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        color: AppColors.secondaryMain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "الوقت: ",
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.primaryMain,
                      ),
                    ),
                    TextSpan(
                      text: magmo3aModel?.time != null
                          ? _formatTime(magmo3aModel!.time!)
                          : '',
                      style: const TextStyle(
                        fontSize: 20,
                        color: AppColors.secondaryMain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final isPm = hour >= 12;
    final formattedHour = hour > 12 ? hour - 12 : hour;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return "$formattedHour:$formattedMinute ${isPm ? 'م' : 'ص'}";
  }
}
