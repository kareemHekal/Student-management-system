import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_management_system/models/admin/teacher.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // تسجيل حساب جديد لأول مرة
  Future<UserCredential?> registerTeacher(
      String email, String password, String name, String phone) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // إنشاء نسخة المدرس في Firestore بقيم افتراضية (غير مفعل)
      await _db.collection('teachers').doc(res.user!.uid).set({
        'name': name,
        'phoneNumber': phone,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': false, // لا يفتح إلا بموافقتك
        'totalStudents': 0,
        'subscriptionTotalStudents': 0,
        'subscriptionEndTime': DateTime.now().toIso8601String(), // ينتهي الآن
      });
      return res;
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الدخول مع فحص البيانات
  Future<Teacher?> loginTeacher(String email, String password) async {
    UserCredential res = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    DocumentSnapshot doc =
        await _db.collection('teachers').doc(res.user!.uid).get();

    if (doc.exists) {
      return Teacher.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> signOut() => _auth.signOut();
}
