import 'package:fatma_elorbany/firebase/firebase_functions.dart';
import 'package:flutter/material.dart';

Future<void> renameGrade({
  required BuildContext context,
  required String oldGrade,
}) async {
  final TextEditingController gradeController =
      TextEditingController(text: oldGrade);
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          ' new grade name',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: gradeController,
            decoration: InputDecoration(
              hintText: 'new grade name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return ' enter new grade name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              FirebaseFunctions.renameGrade(oldGrade, gradeController.text);
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}
