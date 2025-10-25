import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../BottomSheets/add_magmo3a.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Magmo3aModel.dart';
import '../models/Studentmodel.dart';
import '../pages/all students in one group.dart';

class Magmo3aWidget extends StatelessWidget {
  final Magmo3amodel magmo3aModel;

  const Magmo3aWidget({required this.magmo3aModel, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => AddMagmo3a(
            existingMagmo3a: magmo3aModel,
            oldDay: magmo3aModel.days,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Slidable(
          startActionPane: ActionPane(
            motion: DrawerMotion(),
            extentRatio: 0.5,
            children: [
              SlidableAction(
                borderRadius: BorderRadius.circular(30),
                onPressed: (context) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.red[50],
                        title: Text(
                          'حذف المجموعة',
                          style: TextStyle(
                            color: Colors.red[900],
                            fontSize: 20,
                          ),
                        ),
                        content: Text(
                          'هل أنت متأكد أنك تريد حذف هذه المجموعة؟\n\n'
                          'عند تنفيذ هذه العملية سيتم أيضًا حذف اسم هذه المجموعة من قائمة المجموعات الخاصة بالطلاب المنتمين إليها.',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[900],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            child: Text(
                              'إلغاء',
                              style: TextStyle(
                                  color: Colors.red[900], fontSize: 16),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red[600],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'تأكيد الحذف',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            onPressed: () async {
                              try {
                                await FirebaseFunctions.deleteMagmo3aFromDay(
                                    magmo3aModel.days ?? "", magmo3aModel.id);
                                Navigator.pop(context);

                                Stream<QuerySnapshot<Studentmodel>>
                                    studentsStream =
                                    FirebaseFunctions.getStudentsByGroupId(
                                        magmo3aModel.grade ?? "",
                                        magmo3aModel.id);
                                studentsStream.listen((snapshot) async {
                                  for (var doc in snapshot.docs) {
                                    var student = doc.data();
                                    student.hisGroups?.removeWhere(
                                        (group) => group.id == magmo3aModel.id);
                                    student.hisGroupsId
                                        ?.remove(magmo3aModel.id);

                                    await FirebaseFunctions
                                        .updateStudentInCollection(
                                      student.grade ?? "",
                                      student.id,
                                      student,
                                    );
                                  }
                                });
                              } catch (e) {
                                print("Error deleting group: $e");
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                backgroundColor: const Color(0xFFFE4A49),
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'حذف',
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              color: app_colors.ligthGreen,
              child: Container(
                height: 150,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _buildVerticalLine(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDaysList(),
                          const SizedBox(height: 10),
                          _buildGradeAndTimeAndType(),
                        ],
                      ),
                    ),
                    _buildDetailsButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        decoration: BoxDecoration(
          color: app_colors.green,
          borderRadius: BorderRadius.circular(25),
        ),
        width: 5,
        height: 200,
      ),
    );
  }

  Widget _buildDaysList() {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              decoration: BoxDecoration(
                color: app_colors.darkGrey,
                border: Border.all(
                  color: app_colors.green,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Text(
                magmo3aModel.days ?? "",
                style: const TextStyle(
                  fontSize: 30,
                  color: app_colors.green,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGradeAndTimeAndType() {
    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "الصف: ",
                      style: TextStyle(
                        fontSize: 17,
                        color: app_colors.darkGrey,
                      ),
                    ),
                    TextSpan(
                      text: magmo3aModel.grade ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        color: app_colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "الوقت: ",
                      style: TextStyle(
                        fontSize: 17,
                        color: app_colors.darkGrey,
                      ),
                    ),
                    TextSpan(
                      text: magmo3aModel.time != null
                          ? _formatTime(magmo3aModel.time!)
                          : '',
                      style: const TextStyle(
                        fontSize: 20,
                        color: app_colors.green,
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

  Widget _buildDetailsButton(context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentInAgroup(
                  magmo3aModel: magmo3aModel,
                ),
              ),
            );
          },
          icon: Container(
            decoration: BoxDecoration(
              color: app_colors.darkGrey,
              border: Border.all(
                color: app_colors.green,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              color: app_colors.green,
            ),
          ),
        ),
      ],
    );
  }
}
