import 'package:el_tooltip/el_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Studentmodel.dart';
import '../pages/EditStudent.dart';

class StudentWidget extends StatelessWidget {
  final Studentmodel studentModel;
  final String? grade;

  StudentWidget({required this.studentModel, required this.grade, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.fromSwatch().copyWith(
                    primary: Colors.red, // Primary color for the dialog
                  ),
                ),
                child: AlertDialog(
                  backgroundColor: Colors.red[100], // Light red background
                  title: Text(
                    "Delete Student",
                    style: TextStyle(
                      color: Colors.red[900], // Darker red for title
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    "Are you sure you want to delete this student?",
                    style: TextStyle(
                        color:
                            Colors.red[800]), // Slightly darker red for content
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[900], // Dark red for text
                      ),
                      child: Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red[
                            700], // Darker red background for delete button
                      ),
                      child: Text("Delete"),
                      onPressed: () {
                        FirebaseFunctions.deleteStudentFromHisCollection(
                            studentModel.grade??"", studentModel.id);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return EditStudentScreen(
              student: studentModel,
              grade: grade,
            );
          }));
        },
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: app_colors.ligthGreen,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${studentModel.dateofadd}"),
                    ElTooltip(
                      position: ElTooltipPosition.leftCenter,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          "assets/images/comment.gif",
                          width: 50,
                          height: 50,
                        ),
                      ),
                      content:
                          Text("${studentModel.note ?? "there is no note"}"),
                    ),
                  ],
                ),


                const SizedBox(height: 10),

                _buildInfoRow(context, false,"Name:", studentModel.name ?? 'N/A'),
                _buildInfoRow(context, true,"Phone Number:",
                    studentModel.phoneNumber ?? 'N/A'),
                _buildInfoRow(context,true, "Mother Number:",
                    studentModel.motherPhone ?? 'N/A'),
                _buildInfoRow(context, true,"Father Number:",
                    studentModel.fatherPhone ?? 'N/A'),

                _buildInfoRow(context,false, "Grade:", studentModel.grade ?? 'N/A'),
                const SizedBox(height: 10),

                // Display days from Magmo3amodel

                _buildStudentDaysList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, bool isnumber, String label, String value) {
    void _launchPhoneNumber(String phoneNumber) async {
      final String phoneUrl = 'tel:$phoneNumber';
      if (await canLaunchUrlString(phoneUrl)) {
        await launchUrlString(phoneUrl);
      } else {
        print('Could not launch $phoneNumber');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: app_colors.green,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: app_colors.green.withOpacity(0.5),
                  cursorColor: app_colors.green,
                ),
              ),
              child: GestureDetector(
                onLongPress: isnumber ? () => _launchPhoneNumber(value) : null, // Check isnumber
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: app_colors.orange,
                      fontSize: 25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Widget to display student-specific days if available
  Widget _buildStudentDaysList() {
    List<Map<String, dynamic>> daysWithTimes = [
      {'day': studentModel.firstDay, 'time': studentModel.firstDayTime},
      {'day': studentModel.secondDay, 'time': studentModel.secondDayTime},
      {'day': studentModel.thirdDay, 'time': studentModel.thirdDayTime},
      {'day': studentModel.forthday, 'time': studentModel.forthdayTime}
    ];

    // Remove days that are null
    daysWithTimes.removeWhere((entry) => entry['day'] == null);

    return Row(
      children: [
        const Text(
          "Student Days:",
          style: TextStyle(
            color: app_colors.green,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: daysWithTimes.map((entry) {
                String day = entry['day'] ?? '';
                TimeOfDay? time = entry['time'];

                // Convert TimeOfDay to 12-hour format with AM/PM
                String timeString =
                    time != null ? _formatTime12Hour(time) : 'No Time';

                return Row(
                  children: [
                    Chip(
                      label: Column(
                        children: [
                          Text(
                            day,
                            style: const TextStyle(
                              color: app_colors.orange,
                            ),
                          ),
                          Text(
                            timeString,
                            style: const TextStyle(
                              color: app_colors.orange,
                              fontSize: 12, // Smaller font for time
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: app_colors.green,
                    ),
                    const SizedBox(width: 8),
                    // Add some space between each day
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

// Helper function to format TimeOfDay to 12-hour format with AM/PM
  String _formatTime12Hour(TimeOfDay time) {
    final int hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod; // Convert 0 to 12 for midnight/noon
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final String minute =
        time.minute.toString().padLeft(2, '0'); // Ensure two digits for minutes
    return '$hour:$minute $period';
  }
}
