import 'package:flutter/material.dart';
import '../colors_app.dart';

class NoConnectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_off, size: 80, color: app_colors.darkGrey),
            SizedBox(height: 20),
            Text(
              'يجب أن يكون لديك اتصال بالإنترنت أولاً.',
              style: TextStyle(fontSize: 24, color: app_colors.darkGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
