import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Magmo3as.dart';

class Sunday extends StatelessWidget {
  const Sunday({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
              child: Image.asset(
                  width: 250,
                  height: 250,
                  "assets/images/studenizer_logo_2.png")),
          SizedBox(height: 50)
        ],
      ),
      Magmo3as(
        day: "Sunday",
      )
    ]);
  }
}
