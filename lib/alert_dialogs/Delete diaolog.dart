import 'package:flutter/material.dart';

import '../loadingFile/loading_alert/run_with_loading.dart';

class CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<String>? tags;
  final Future<void> Function(List<String>) onConfirm;
  final String cancelButtonText;
  final String confirmButtonText;

  CustomConfirmDialog({
    required this.title,
    required this.content,
    this.tags,
    required this.onConfirm,
    this.cancelButtonText = "إلغاء",
    this.confirmButtonText = "تأكيد",
  });

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
          SizedBox(height: 8),
          Text(
            "لقد اخترت: ${tags?.isEmpty ?? true ? "لا شيء" : tags!.join(', ')}",
            style: TextStyle(color: Colors.orange[900]),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red[900],
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: TextStyle(fontWeight: FontWeight.bold),
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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 5,
          ),
          child: Text(confirmButtonText),
            onPressed: () async {
              // Save a stable context reference (e.g., the page context)
              final parentContext = context;

              await runWithLoading(parentContext, () async {
                await onConfirm(tags ?? []);
              });

              // Safely pop the dialog after the async work
              if (parentContext.mounted && Navigator.canPop(parentContext)) {
                Navigator.pushNamedAndRemoveUntil(
                    context, "/HomeScreen", (_) => false);
              }
            }),
      ],
    );
  }
}
