import 'package:flutter/material.dart';

import '../../colors_app.dart';

class SelectRecipientDialogContent extends StatelessWidget {
  final VoidCallback sendMessageToFather;
  final VoidCallback sendMessageToMother;
  final VoidCallback sendMessageToStudent;

  const SelectRecipientDialogContent({
    Key? key,
    required this.sendMessageToFather,
    required this.sendMessageToMother,
    required this.sendMessageToStudent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text('ولي الأمر (الأب)',
              style: TextStyle(color: app_colors.green)),
          onTap: () {
            Navigator.of(context).pop();
            sendMessageToFather();
          },
        ),
        ListTile(
          title: Text('ولي الأمر (الأم)',
              style: TextStyle(color: app_colors.green)),
          onTap: () {
            Navigator.of(context).pop();
            sendMessageToMother();
          },
        ),
        ListTile(
          title: Text('الطالب', style: TextStyle(color: app_colors.green)),
          onTap: () {
            Navigator.of(context).pop();
            sendMessageToStudent();
          },
        ),
      ],
    );
  }
}
