import 'package:flutter/material.dart';

import '../models/admin/teacher.dart';
import 'firebase/firebase_functions.dart';

class TeacherProvider with ChangeNotifier {
  Teacher? _currentTeacher;

  Teacher? get teacher => _currentTeacher;

  // بننادي الدالة دي أول ما المدرس يسجل دخول
  void setTeacher(Teacher teacher) {
    _currentTeacher = teacher;
    notifyListeners();
  }

  // بنناديها عند تسجيل الخروج
  void logout() {
    _currentTeacher = null;
    notifyListeners();
  }

  Future<void> refreshTeacherData() async {
    // تأكد إن فيه مدرس مسجل دخول أصلاً قبل ما تطلب بياناته
    if (_currentTeacher == null) return;

    try {
      // طلب البيانات المحدثة بناءً على الـ ID الحالي
      Teacher? updatedTeacher =
          await FirebaseFunctions.getTeacherById(_currentTeacher!.id);

      if (updatedTeacher != null) {
        _currentTeacher = updatedTeacher;
        notifyListeners(); // تحديث الواجهات (مثل عداد الطلاب في الـ Dashboard)
      }
    } catch (e) {
      debugPrint("خطأ في تحديث بيانات المدرس: $e");
    }
  }
}