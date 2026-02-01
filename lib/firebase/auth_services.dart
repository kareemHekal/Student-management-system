import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_management_system/models/admin/teacher.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // تسجيل حساب جديد لأول مرة
  Future<UserCredential?> registerTeacher(
      String email, String password, String name, String phone) async {
    try {
      // 1. إنشاء الحساب في Firebase Auth
      UserCredential res = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // 2. إنشاء كائن (Object) من المدرس بالقيم الابتدائية "الخام"
      // نستخدم الموديل نفسه لضمان توافق الحقول
      Teacher newTeacher = Teacher(
        id: res.user!.uid,
        // المعرف القادم من Auth
        name: name,
        phoneNumber: phone,
        createdAt: DateTime.now(),
        isActive: false,
        // لا يفتح إلا بموافقتك
        subscriptionEndTime: DateTime.now(),
        // ينتهي فوراً (يحتاج تفعيل)
        baseStudentLimit: 0,
        // ليمت صفر حتى يحدد الأدمن باقة
        currentStudentCount: 0,
        activeBoosts: [], // لستة فارغة في البداية
      );

      // 3. رفع البيانات باستخدام toJson() لضمان عدم نسيان أي حقل
      // وتجنب كتابة الكيز (Keys) يدوياً
      await _db
          .collection('teachers')
          .doc(res.user!.uid)
          .set(newTeacher.toJson());

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
