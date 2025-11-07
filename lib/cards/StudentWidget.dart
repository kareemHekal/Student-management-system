import 'package:el_tooltip/el_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Alert dialogs/Notify Absence.dart';
import '../bloc/Edit Student/edit_student_cubit.dart';
import '../colors_app.dart';
import '../constants.dart';
import '../firebase/firebase_functions.dart';
import '../models/Studentmodel.dart';
import '../pages/EditStudent.dart';

class StudentWidget extends StatelessWidget {
  bool IsComingFromGroup;
  final Studentmodel studentModel;
  final String? grade;

  StudentWidget(
      {required this.studentModel,
      required this.IsComingFromGroup,
      required this.grade,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onLongPress: () {
          IsComingFromGroup == true
              ? null
              : showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.fromSwatch().copyWith(
                          primary: Colors.red,
                        ),
                      ),
                      child: AlertDialog(
                        backgroundColor: Colors.red[100],
                        title: Text(
                          "حذف الطالب",
                          style: TextStyle(
                            color: Colors.red[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          "هل أنت متأكد أنك تريد حذف هذا الطالب؟",
                          style: TextStyle(color: Colors.red[800]),
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[900],
                            ),
                            child: Text("إلغاء"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red[700],
                            ),
                            child: Text("حذف"),
                            onPressed: () {
                              FirebaseFunctions.deleteStudentFromHisCollection(
                                  studentModel.grade ?? "", studentModel.id);
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => StudentEditCubit(student: studentModel),
                child: EditStudentScreen(
                  grade: grade,
                  student: studentModel,
                ),
              ),
            ),
          );
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
                  children: [
                    Text("${studentModel.dateofadd}"),
                    Spacer(),
                    _buildIconButton(
                      imagePath: "assets/images/whatsapp.png",
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: app_colors.ligthGreen,
                            title: const Text(
                              'تحب تبعت الرسالة لمين؟',
                              style: TextStyle(color: app_colors.darkGrey),
                            ),
                            content: SelectRecipientDialogContent(
                              sendMessageToFather: () async =>
                                  _sendMessageToParent('father'),
                              sendMessageToMother: () async =>
                                  _sendMessageToParent('mother'),
                              sendMessageToStudent: () async =>
                                  _sendMessageToParent('student'),
                            ),
                            actions: [
                              Material(
                                color: Colors.transparent,
                                elevation: 10,
                                shadowColor: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: app_colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                  ),
                                  child: const Text('إلغاء'),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    ElTooltip(
                      position: ElTooltipPosition.leftCenter,
                      content:
                          Text("${studentModel.note ?? "لا توجد ملاحظات"}"),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          "assets/images/comment.gif",
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                    context, false, "الاسم:", studentModel.name ?? 'N/A'),
                _buildInfoRow(context, true, "رقم الطالب:",
                    studentModel.phoneNumber ?? 'N/A'),
                _buildInfoRow(context, true, "رقم الأم:",
                    studentModel.motherPhone ?? 'N/A'),
                _buildInfoRow(context, true, "رقم الأب:",
                    studentModel.fatherPhone ?? 'N/A'),
                _buildInfoRow(
                    context, false, "المرحلة:", studentModel.grade ?? 'N/A'),
                const SizedBox(height: 10),
                _buildStudentDaysList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, bool isnumber, String label, String value) {
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
              color: app_colors.darkGrey,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: app_colors.darkGrey.withOpacity(0.5),
                  cursorColor: app_colors.darkGrey,
                ),
              ),
              child: GestureDetector(
                onLongPress: isnumber ? () => _launchPhoneNumber(value) : null,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: app_colors.green,
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

  void _sendMessageToParent(String parentRole) {
    String genderSpecificMessage;

    if (parentRole == 'father') {
      genderSpecificMessage = """
عزيزي والد ${studentModel.name} 

أطيب التحيات،  
${Constants.teacherName}
      """;
    } else if (parentRole == 'mother') {
      genderSpecificMessage = """
عزيزتي والدة ${studentModel.name}  

أطيب التحيات،  
${Constants.teacherName}
""";
    } else {
      genderSpecificMessage = """
عزيزي ${studentModel.name}،

أطيب التحيات،  
${Constants.teacherName}
      """;
    }

    if (parentRole == 'father') {
      _sendWhatsAppMessage(studentModel.fatherPhone!, genderSpecificMessage);
    } else if (parentRole == 'mother') {
      _sendWhatsAppMessage(studentModel.motherPhone!, genderSpecificMessage);
    } else {
      _sendWhatsAppMessage(studentModel.phoneNumber!, genderSpecificMessage);
    }
  }

  Future<void> _sendWhatsAppMessage(String rawPhone, String message) async {
    final cleanedPhone = rawPhone.replaceAll('+', '').replaceAll(' ', '');
    final String formattedPhone = cleanedPhone.startsWith('0')
        ? '20${cleanedPhone.substring(1)}'
        : cleanedPhone;
    final String encodedMessage = Uri.encodeComponent(message);

    final String url = 'https://wa.me/$formattedPhone?text=$encodedMessage';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print("WhatsApp is not installed or cannot be opened.");
    }
  }

  Widget _buildStudentDaysList() {
    List<Map<String, dynamic>> daysWithTimes =
        studentModel.hisGroups?.map((group) {
              return {
                'day': group.days,
                'time': group.time != null
                    ? {'hour': group.time?.hour, 'minute': group.time?.minute}
                    : null,
              };
            }).toList() ??
            [];

    daysWithTimes.removeWhere((entry) => entry['day'] == null);

    return Row(
      children: [
        const Text(
          "أيام الطالب:",
          style: TextStyle(
            color: app_colors.darkGrey,
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
                TimeOfDay? time = entry['time'] != null
                    ? TimeOfDay(
                        hour: entry['time']['hour'],
                        minute: entry['time']['minute'])
                    : null;

                String timeString =
                    time != null ? _formatTime12Hour(time) : 'لا يوجد وقت';

                return Row(
                  children: [
                    Chip(
                      label: Column(
                        children: [
                          Text(
                            day,
                            style: const TextStyle(
                              color: app_colors.green,
                            ),
                          ),
                          Text(
                            timeString,
                            style: const TextStyle(
                              color: app_colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: app_colors.darkGrey,
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required String imagePath,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Image.asset(
            imagePath,
            width: 30,
            height: 30,
          ),
        ),
      ],
    );
  }

  String _formatTime12Hour(TimeOfDay time) {
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String period = time.period == DayPeriod.am ? 'صباحًا' : 'مساءً';
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
