import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/firebase/auth_services.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/models/admin/subsription.dart';
import 'package:student_management_system/models/admin/teacher.dart';
import 'package:student_management_system/provider.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import 'terms_privacy_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. التعريفات الأساسية
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _handleRegister() async {
    final teacherProvider = context.read<TeacherProvider>();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    // 1. التحقق من البيانات (Validations)
    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      AppSnackBars.showError(context, "برجاء ملء جميع البيانات");
      return;
    }

    if (name.split(' ').length < 2) {
      AppSnackBars.showError(context, "برجاء كتابة الاسم ثنائي على الأقل");
      return;
    }

    final phoneRegex = RegExp(r'^01[0125][0-9]{8}$');
    if (!phoneRegex.hasMatch(phone)) {
      AppSnackBars.showError(context, "رقم الهاتف غير صحيح");
      return;
    }

    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      AppSnackBars.showError(context, "صيغة البريد الإلكتروني غير صحيحة");
      return;
    }

    if (password.length < 6) {
      AppSnackBars.showError(
          context, "كلمة المرور ضعيفة (يجب ألا تقل عن 6 رموز)");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. تسجيل المدرس في الـ Auth والـ Firestore
      await AuthService().registerTeacher(email, password, name, phone);

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // 3. تفعيل الباقة التجريبية (خطوة أساسية قبل الدخول)
        // بنعمل await هنا عشان نضمن إنها خلصت قبل ما المدرس يدخل يشوف حسابه

        await FirebaseFunctions.renewBasicSubscription(
          plan: Subscription(
            name: "الباقة التجريبية",
            description: "تجربة مجانية لمدة 14 يوم لـ 30 طالب",
            durationInDays: 14,
            price: 0,
            subscriptionType: SubscriptionType.adminSubscription,
            totalStudents: 30,
          ),
            paymentRef: "لا يوجد لانها باقه تجريبه مجانيه ");

        // 4. الحل السحري: بناء المدرس محلياً فوراً
        // عشان صفحة الخطط الجاية تلاقي بيانات المدرس جاهزة في الـ Provider
        Teacher localTeacher = Teacher(
          id: currentUser.uid,
          name: name,
          email: email,
          phoneNumber: phone,
          createdAt: DateTime.now(),
          isActive: false,
          subscriptionEndTime: DateTime.now(),
          currentStudentCount: 0,
          activeBoosts: [],
        );

        teacherProvider.setTeacher(localTeacher);

        teacherProvider
            .refreshTeacherData()
            .catchError((e) => debugPrint("Background sync wait: $e"));
      } else {
        throw Exception("فشل في استلام بيانات المستخدم من Auth");
      }

      if (!mounted) return;

      AppSnackBars.showSuccess(
          context, "تم إنشاء الحساب بنجاح! حصلت على 14 يوم تجربة مجانية.");

      // 6. الانتقال لصفحة خطط الاشتراك
      Navigator.pushReplacementNamed(context, "/subscriptionPlansPage");
    } catch (e) {
      if (!mounted) return;
      AppSnackBars.showError(context, "حدث خطأ: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // لاحظ أن _handleRegister لم تعد هنا
    return Scaffold(
      backgroundColor: const Color(0xFFEBFFF4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // الهيدر
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primaryMain,
                    AppColors.primaryMain.withOpacity(0.8)
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(50)),
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Image.asset("assets/images/logo.png", height: 70),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text("إنشاء حساب جديد",
                      style: AppTextStyles.customText(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("سجل بياناتك للبدء في إدارة غيابك",
                      style: AppTextStyles.customText(
                          color: Colors.white.withOpacity(0.9), fontSize: 14)),
                ],
              ),
            ),

            // كارت البيانات
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          nextFocus: _phoneFocus,
                          hint: "اسم المدرس الثلاثي",
                          icon: Icons.person_rounded,
                          action: TextInputAction.next),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          nextFocus: _emailFocus,
                          hint: "رقم الهاتف",
                          icon: Icons.phone_android_rounded,
                          inputType: TextInputType.phone,
                          action: TextInputAction.next),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          nextFocus: _passwordFocus,
                          hint: "البريد الإلكتروني",
                          icon: Icons.alternate_email_rounded,
                          inputType: TextInputType.emailAddress,
                          action: TextInputAction.next),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        hint: "كلمة المرور",
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        action: TextInputAction.done,
                        onToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? CircularProgressIndicator(
                              color: AppColors.primaryMain)
                          : SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryMain,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    elevation: 0),
                                onPressed: _handleRegister,
                                child: Text("إنشاء الحساب",
                                    style: AppTextStyles.customText(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                            ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermsPrivacyPage(),
                            ),
                          );
                        },
                        child: Text(
                          "بإنشاء الحساب، أنت توافق على الشروط وسياسة الخصوصية",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.customText(
                            fontSize: 12,
                            color: AppColors.primaryMain,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // زر العودة
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: RichText(
                text: TextSpan(
                  text: "لديك حساب بالفعل؟ ",
                  style: AppTextStyles.customText(
                      color: Colors.grey[600]!, fontSize: 14),
                  children: [
                    TextSpan(
                        text: "سجل دخولك",
                        style: AppTextStyles.customText(
                            color: AppColors.primaryMain,
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String hint,
    required IconData icon,
    required TextInputAction action,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: action,
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          _handleRegister();
        }
      },
      obscureText: isPassword && !isVisible,
      keyboardType: inputType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryMain),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: onToggle)
            : null,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }
}
