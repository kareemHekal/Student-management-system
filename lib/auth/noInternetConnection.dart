import 'package:flutter/material.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 100, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              "انقطع الاتصال بالإنترنت",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("يرجى التحقق من الشبكة للمتابعة..."),
            const SizedBox(height: 30),
            const CircularProgressIndicator(strokeWidth: 2),
            // بيدي إحساس إنه بيحاول يرجع
          ],
        ),
      ),
    );
  }
}