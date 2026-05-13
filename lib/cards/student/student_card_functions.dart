import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StudentActionsHelper {
  // Format 12-hour time for the chips
  static String formatTime12Hour(TimeOfDay time) {
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String period = time.period == DayPeriod.am ? 'ص' : 'م';
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // Handle Phone Calls
  static Future<void> launchPhone(String phoneNumber) async {
    final String phoneUrl = 'tel:$phoneNumber';
    if (await canLaunchUrlString(phoneUrl)) {
      await launchUrlString(phoneUrl);
    }
  }

  // Handle WhatsApp logic with dynamic message generation
  static Future<void> sendWhatsAppAbsenceMessage({
    required String studentName,
    required String parentRole,
    required String phoneNumber,
    required String teacher,
  }) async {
    String message;

    if (parentRole == 'father') {
      message =
          "عزيزي والد الطالب $studentName،\n\nنود إعلامكم بأن ابنكم غائب اليوم عن حصة الأستاذة $teacher.\n\nمع خالص التحية،\n$teacher";
    } else if (parentRole == 'mother') {
      message =
          "عزيزتي والدة الطالب $studentName،\n\nنود إعلامكم بأن ابنكم غائب اليوم عن حصة الأستاذة $teacher.\n\nمع خالص التحية،\n$teacher";
    } else {
      message =
          "الطالب $studentName،\n\nلقد تغيبت اليوم عن حصة الأستاذة $teacher.\nيرجى مراجعة الدروس الفائتة.\n\nمع التحية،\n$teacher";
    }

    final cleaned = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
    final formatted =
        cleaned.startsWith('0') ? '20${cleaned.substring(1)}' : cleaned;
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$formatted?text=$encoded';

    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }
}
