import 'package:flutter/material.dart';

import '../add_student_widget.dart';

class one extends StatelessWidget {
  const one({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Image.asset("assets/images/1......1.png"),
                ),
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
        AddStudentScreen(level: "1 secondary"),
      ],
    );
  }
}
