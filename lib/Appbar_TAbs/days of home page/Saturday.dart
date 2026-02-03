import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Magmo3as.dart';

class Saturday extends StatelessWidget {
  const Saturday({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // الصورة كخلفية باهتة
        Center(
          child: Opacity(
            opacity: 0.05,
            child: Image.asset(
              "assets/images/studenizer_logo_2.png",
              width: MediaQuery.of(context).size.width * 0.8,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Magmo3as فوق الصورة
        Magmo3as(day: "Saturday"),
      ],
    );
  }
}
