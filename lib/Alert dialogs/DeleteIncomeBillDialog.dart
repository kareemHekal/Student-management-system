import 'package:flutter/material.dart';

class DeleteIncomeBillDialog extends StatelessWidget {
  final String title;
  final String content;
  final Future<void> Function() onConfirm; // Use Future for async operations
  final String cancelButtonText;
  final String confirmButtonText;

  const DeleteIncomeBillDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.cancelButtonText = "Cancel",
    this.confirmButtonText = "Delete",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Modern rounded corners
      ),
      backgroundColor: Colors.red[50],
      // Light red background
      title: Text(
        title,
        style: TextStyle(
          color: Colors.red[900], // Dark red for the title
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
              color: Colors.red[700], // Medium red for content text
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
          child: Text(cancelButtonText),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red[600],
            // White text on red button
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 5, // Subtle shadow for depth
          ),
          child: Text(confirmButtonText),
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
