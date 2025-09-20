import 'package:fatma_elorbany/firebase/firebase_functions.dart';
import 'package:flutter/material.dart';

Future<void> showVerifyPasswordDialog({
  required BuildContext context,
  required Function() onVerified,
}) async {
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
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
              if (formKey.currentState!.validate()) {
                final isCorrect =
                await FirebaseFunctions.verifyPassword(passwordController.text);
                if (isCorrect) {
                  Navigator.pop(context); // Close password dialog
                  onVerified(); // Call your callback
                } else {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wrong password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}
