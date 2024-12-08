import 'package:flutter/material.dart';

import '../add_student_widget.dart';

class three extends StatelessWidget {
  const three({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [Column
      (
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Center(child: Image.asset("assets/images/1......1.png")),
        ),
        SizedBox(height: 50)
      ],
    ),AddStudentTab_(level: "3 secondary",)]);
  }
}
