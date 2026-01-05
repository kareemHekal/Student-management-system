import 'package:flutter/material.dart';

import 'loading_dialog.dart';

Future<void> runWithLoading(BuildContext context,
    Future<void> Function() task, {
      String? loadingText,
    }) async {
  // 1. Capture the Navigator immediately!
  // This stays valid even if the 'context' widget is destroyed.
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => LoadingDialog(text: loadingText),
  );

  try {
    await task();
  } catch (e) {
    // Use the captured navigator to pop
    if (navigator.canPop()) navigator.pop();
    _showErrorDialog(context, e.toString());
    return;
  }

  // 2. Use the captured navigator to close the loading dialog
  if (navigator.canPop()) {
    navigator.pop();
  }
}

void _showErrorDialog(BuildContext context, String message) {
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("حدث خطأ"),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("حسناً")),
      ],
    ),
  );
}