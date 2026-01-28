import 'package:flutter/material.dart';
import '../models/admin/teacher.dart';

class TeacherProvider with ChangeNotifier {
  Teacher? _currentTeacher;

  Teacher? get teacher => _currentTeacher;

  // بننادي الدالة دي أول ما المدرس يسجل دخول
  void setTeacher(Teacher teacher) {
    _currentTeacher = teacher;
    notifyListeners(); // دي بتخلي أي شاشة بتسمع للمدرس تتحدث فوراً
  }

  // بنناديها عند تسجيل الخروج
  void logout() {
    _currentTeacher = null;
    notifyListeners();
  }
}
