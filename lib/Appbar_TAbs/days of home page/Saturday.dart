import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Magmo3as.dart';

class Saturday extends StatelessWidget {
  const Saturday({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [Column
      (
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
          Center(
              child: Image.asset(
                  width: 500,
                  height: 500,
                  "assets/images/studenizer_logo_2.png")),
          SizedBox(height: 50)
      ],
    ),Magmo3as(day: "Saturday",)]);
  }
}
