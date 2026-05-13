import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/firebase/auth_services.dart';
import 'package:student_management_system/home.dart';
import 'package:student_management_system/models/admin/teacher.dart';
import 'package:student_management_system/provider.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import 'subscription_expired_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppSnackBars.showError(
          context, "برجاء إدخال البريد الإلكتروني وكلمة المرور");
      return;
    }

    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      AppSnackBars.showError(context, "صيغة البريد الإلكتروني غير صحيحة");
      return;
    }

    setState(() => _isLoading = true);
    try {
      Teacher? teacher = await AuthService().loginTeacher(email, password);

      if (teacher != null) {
        if (!mounted) return;
        Provider.of<TeacherProvider>(context, listen: false)
            .setTeacher(teacher);

        if (teacher.hasActiveSubscription) {
          AppSnackBars.showSuccess(
              context, "أهلاً بك يا أستاذ ${teacher.name}");
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Homescreen()),
            (route) => false,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const SubscriptionExpiredScreen()),
          );
        }
      }
    } catch (e) {
      AppSnackBars.showError(context, "فشل تسجيل الدخول: تأكد من البيانات");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. خلفية متدرجة (Gradient Background)
          Container(
            height: size.height,
            width: size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.primaryMain,
                  // اللون الأساسي بتاعك فوق
                  AppColors.primaryMain.withOpacity(0.7),
                  // تدرج للأسفل
                  const Color(0xFFEBFFF4),
                  // 🟢 اللون السحري: أبيض بلمسة خضراء هادية جداً
                  const Color(0xFFF7FCF9),
                  // أفتح شوية في النهاية
                ],
                stops: const [0.0, 0.2, 0.7, 1.0], // توزيع الألوان
              ),
            ),
          ),

          // 2. محتوى الصفحة
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // اللوجو مع تأثير زجاجي خفيف (Frosted Glass effect concept)
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/logo.png",
                          height: 100,
                          width: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      "مرحباً بك مجدداً",
                      style: AppTextStyles.customText(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "سجل دخولك للمتابعة",
                      style: AppTextStyles.customText(
                          fontSize: 16, color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 40),

                    // 3. كارت المدخلات (Input Card)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        // لون الكارت "كريمي" فاتح عشان يظهر فوق الأبيض المخضر
                        color: const Color(0xFFFDFDFD),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            // ظل بلون أخضر غامق خفيف جداً بدل الأسود عشان يندمج مع الخلفية
                            color: const Color(0xFF1B5E20).withOpacity(0.3),
                            blurRadius: 35,
                            spreadRadius: 2,
                            offset: const Offset(0, 15),
                          ),
                        ],
                        border: Border.all(
                            color: const Color(0xFFE8F5E9),
                            width: 1.5), // برواز أخضر باهت جداً
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            hint: "البريد الإلكتروني",
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _passwordController,
                            hint: "كلمة المرور",
                            icon: Icons.lock_open_rounded,
                            isPassword: true,
                            isVisible: _isPasswordVisible,
                            onToggle: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? CircularProgressIndicator(
                                  color: AppColors.primaryMain)
                              : SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryMain,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      elevation: 0,
                                    ),
                                    onPressed: _handleLogin,
                                    child: Text("تسجيل الدخول",
                                        style: AppTextStyles.customText(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17)),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // زرار التسجيل في الأسفل
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: RichText(
                        text: TextSpan(
                          text: "ليس لديك حساب؟ ",
                          style: AppTextStyles.customText(
                              color: AppColors.textSecondary, fontSize: 15),
                          children: [
                            TextSpan(
                              text: "سجل الآن",
                              style: AppTextStyles.customText(
                                  color: AppColors.primaryMain,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            style: AppTextStyles.customText(fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryMain, size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                onPressed: onToggle,
              )
                  : null,
              hintText: hint,
              hintStyle: AppTextStyles.customText(
                  color: Colors.grey[400]!, fontSize: 14),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
            ),
          ),
        ),
      ],
    );
  }
}