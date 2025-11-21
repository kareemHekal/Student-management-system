import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Studentmodel.dart';
import '../pages/EditStudent.dart';

class SmallStudentCard extends StatelessWidget {
  final Studentmodel studentModel;
  final String? grade;

  const SmallStudentCard(
      {required this.studentModel, required this.grade, super.key});

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
                    style: TextStyle(
                      color: Colors.red[800],
                    ),
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
                      onPressed: () async {
                        try {
                          await FirebaseFunctions
                              .deleteStudentFromHisCollection(
                            studentModel.grade ?? "",
                            studentModel.id,
                          );

                          // بعد النجاح
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("تم حذف الطالب بنجاح"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e, stack) {
                          // رسالة الخطأ
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("حدث خطأ أثناء حذف الطالب: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }

                          debugPrint("❌ Error deleting student: $e");
                          debugPrint("📌 StackTrace: $stack");
                        }
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
          color: app_colors.white,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    QrImageView(
                      data: studentModel.id ?? 'default_id',
                      version: QrVersions.auto,
                      size: 210.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoRow(
                            context, studentModel.name ?? 'غير معروف'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(context, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              selectionColor: app_colors.darkGrey.withOpacity(0.5),
              cursorColor: app_colors.darkGrey,
            ),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(
              color: app_colors.black,
              fontSize: 25,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }
}
