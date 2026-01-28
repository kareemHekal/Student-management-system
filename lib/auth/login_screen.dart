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
  bool _isPasswordVisible = false; // لمتابعة حالة إظهار الباسورد

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppSnackBars.showError(context, "برجاء ملء جميع البيانات");
      return;
    }

    setState(() => _isLoading = true);
    try {
      Teacher? teacher = await AuthService().loginTeacher(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

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
                builder: (context) => SubscriptionExpiredScreen()),
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
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // اللوجو مع Hero animation وتأثير ظل ناعم
              Hero(
                tag: 'app_logo',
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMain.withOpacity(0.15),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "assets/images/logo.png",
                    height: 140,
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "تسجيل الدخول",
                style: AppTextStyles.customText(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryMain),
              ),
              const SizedBox(height: 10),
              Text(
                "مرحباً بك في نظام إدارة غيابك",
                style: AppTextStyles.customText(
                    fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                controller: _emailController,
                hint: "البريد الإلكتروني",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                hint: "كلمة المرور",
                icon: Icons.lock_outline,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onToggle: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),

              const SizedBox(height: 40),
              _isLoading
                  ? CircularProgressIndicator(color: AppColors.primaryMain)
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          elevation: 3,
                        ),
                        onPressed: _handleLogin,
                        child: Text("دخول",
                            style: AppTextStyles.customText(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
                    ),
              const SizedBox(height: 25),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: RichText(
                  text: TextSpan(
                    text: "ليس لديك حساب؟ ",
                    style: AppTextStyles.customText(
                        color: AppColors.textSecondary, fontSize: 15),
                    children: [
                      TextSpan(
                        text: "سجل الآن كـ مدرس",
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
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      style: AppTextStyles.customText(),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryMain),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggle,
              )
            : null,
        hintText: hint,
        hintStyle: AppTextStyles.customText(
            color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primaryMain, width: 1.5),
        ),
      ),
    );
  }
}
