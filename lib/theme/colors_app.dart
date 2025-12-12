import 'dart:ui';

class AppColors {
  // ===== Primary Colors =====
  static const primaryMain = Color(0xff2E3A87);
  static const secondaryMain = Color(0xff4FC3A1);
  static const primaryDark = Color(0xff1B2560);

  // ===== Text Colors =====
  static const textPrimary = Color(0xff101A4B); // نص رئيسي داكن
  static const textSecondary = Color(0xff4A4A4A); // نص ثانوي للـ subtitles
  static const textOnDark = Color(0xffffffff); // نص على خلفية داكنة

  // ===== Button Colors =====
  static const buttonPrimary = primaryMain;
  static const buttonSecondary = secondaryMain;
  static const buttonDisabled = Color(0xffC8C9CB);

  // ===== Status Colors (إضافي للغياب) =====
  static const statusPresent = Color(0xff4FC3A1); // حضور – أخضر
  static const statusAbsent = Color(0xffF56C6C); // غياب – أحمر
  static const statusLate = Color(0xffFBC02D); // تأخير – أصفر

  static const white = Color(0xffFFFFFF);
  static const black = Color(0xff363636);
}
