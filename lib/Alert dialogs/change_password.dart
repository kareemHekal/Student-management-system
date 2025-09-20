import 'package:fatma_elorbany/firebase/firebase_functions.dart';
import 'package:flutter/material.dart';
Future<void> showChangePasswordDialog(BuildContext context) async {
  final TextEditingController newPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'New Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock_open),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter new password';
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
                final success =
                await FirebaseFunctions.changePassword(newPasswordController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Password changed successfully'
                        : 'Error changing password'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
