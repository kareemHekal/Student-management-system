import 'package:flutter/material.dart';

import '../theme/colors_app.dart';

class NoConnectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryMain,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_off, size: 80, color: AppColors.primaryMain),
            SizedBox(height: 20),
            Text(
              'يجب أن يكون لديك اتصال بالإنترنت أولاً.',
              style: TextStyle(fontSize: 24, color: AppColors.primaryMain),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
