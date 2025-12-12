import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors_app.dart';

class AppTextStyles {
  static TextStyle customText({
    double fontSize = 16,
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return GoogleFonts.mada(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
