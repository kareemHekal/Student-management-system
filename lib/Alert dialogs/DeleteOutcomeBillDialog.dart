import 'package:flutter/material.dart';

class DeleteOutcomeBillDialog extends StatelessWidget {
  final String title;
  final String content;
  final Future<void> Function() onConfirm;

  const DeleteOutcomeBillDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.red[50],
      title: Text(
        title,
        style: TextStyle(
          color: Colors.red[900],
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            content,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 16,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red[900],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text("إلغاء"),
          onPressed: () {
            Navigator.pop(context);
          },
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
          child: const Text("تأكيد"),
          onPressed: () async {
            await onConfirm();
            Navigator.pushNamedAndRemoveUntil(
                context, "/HomeScreen", (route) => false);
          },
        ),
      ],
    );
  }
}
