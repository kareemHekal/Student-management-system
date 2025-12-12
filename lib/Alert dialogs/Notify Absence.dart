import 'package:flutter/material.dart';

import '../loadingFile/loading_alert/run_with_loading.dart'; // make sure this is where runWithLoading is
import '../theme/colors_app.dart';

class SelectRecipientDialogContent extends StatelessWidget {
  final Future<void> Function() sendMessageToFather;
  final Future<void> Function() sendMessageToMother;
  final Future<void> Function() sendMessageToStudent;

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
              style: TextStyle(color: AppColors.secondaryMain)),
          onTap: () async {
            Navigator.of(context).pop();
            runWithLoading(context, () async {
              await sendMessageToFather();
            });
          },
        ),
        ListTile(
          title: Text('ولي الأمر (الأم)',
              style: TextStyle(color: AppColors.secondaryMain)),
          onTap: () async {
            Navigator.of(context).pop();
            runWithLoading(context, () async {
              await sendMessageToMother();
            });
          },
        ),
        ListTile(
          title:
              Text('الطالب', style: TextStyle(color: AppColors.secondaryMain)),
          onTap: () async {
            Navigator.of(context).pop();
            runWithLoading(context, () async {
              await sendMessageToStudent();
            });
          },
        ),
      ],
    );
  }
}
