import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';
import 'verifiy_password.dart';

class ResetGradeAndStudentSubscriptionsDialog extends StatelessWidget {
  const ResetGradeAndStudentSubscriptionsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Text(
        'إعادة تعيين الاشتراكات',
        style: TextStyle(
          color: Colors.red[900],
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: const Text(
        'هل أنت متأكد أنك تريد حذف جميع الاشتراكات والامتحانات الخاصة بكل المراحل والطلاب؟\n\n'
        'عند تنفيذ هذه العملية سيتم:\n'
        '🟥 حذف جميع الاشتراكات المسجلة لكل مرحلة.\n'
        '🟥 حذف جميع الاشتراكات المدفوعة لكل الطلاب في هذه المراحل.\n'
        '🟥 حذف عدد أيام الغياب والحضور المسجل لكل طالب.\n'
        '🟥 حذف جميع الامتحانات والدرجات الخاصة بكل مرحلة ولكل طالب.\n\n'
        '⚠️ هذا الإجراء لا يمكن التراجع عنه، تأكد قبل المتابعة.',
        textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: Colors.red,
            height: 1.5,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
      )),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'إلغاء',
            style: TextStyle(color: Colors.red[900], fontSize: 16),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            showVerifyPasswordDialog(
              context: context,
              onVerified: () async {
                try {
                  List<String> fetchedGrades =
                      await FirebaseFunctions.getGradesList();
                  for (final grade in fetchedGrades) {
                    await FirebaseFunctions.resetGradeSubscriptionsAndAbsences(
                        grade);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم حذف جميع الاشتراكات بنجاح ✅'),
                      backgroundColor: Colors.red[700],
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ أثناء حذف الاشتراكات: $e'),
                      backgroundColor: Colors.red[900],
                    ),
                  );
                }
              },
            );
          },
          child: const Text(
            'تأكيد الحذف',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
