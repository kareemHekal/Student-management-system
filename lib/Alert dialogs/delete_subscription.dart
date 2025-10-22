import 'package:flutter/material.dart';

import '../firebase/firebase_functions.dart';

class DeleteSubscriptionDialog extends StatelessWidget {
  final String gradeName;
  final String subscriptionName;

  const DeleteSubscriptionDialog({
    Key? key,
    required this.gradeName,
    required this.subscriptionName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.red[50],
      title: Text(
        "حذف الاشتراك",
        style: TextStyle(
          color: Colors.red[900],
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Text(
        "هل أنت متأكد أنك تريد حذف هذا الاشتراك؟",
        style: TextStyle(
          color: Colors.red[700],
          fontSize: 16,
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red[900],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text("إلغاء"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red[600],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 5,
          ),
          child: const Text("حذف"),
          onPressed: () async {
            await FirebaseFunctions.deleteSubscriptionFromGrade(
                gradeName, subscriptionName);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("تم حذف الاشتراك بنجاح"),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ],
    );
  }
}
